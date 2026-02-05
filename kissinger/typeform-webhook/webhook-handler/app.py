import hashlib
import hmac
import json
import base64
import boto3
import requests
import uuid
import os
import re
from datetime import datetime, timezone

from aws_lambda_powertools import Logger

logger = Logger()

cognito = boto3.client('cognito-idp')
ssm = boto3.client('ssm')
dynamodb = boto3.client('dynamodb')
sqs = boto3.client('sqs')

QUEUE_URL = os.environ['QUEUE_URL']
STORY_TABLE = os.environ['STORY_TABLE']
USER_POOL_ID = os.environ['USER_POOL_ID']


@logger.inject_lambda_context
def lambda_handler(event, context):
    logger.append_keys(awsRequestId=context.aws_request_id)
    raw_body = event["body"]
    received_signature = event["headers"].get("Typeform-Signature")

    if not received_signature:
        log_and_alert("Webhook signature is missing. Permission denied.")
        return {
            "statusCode": 403,
            "body": json.dumps({"detail": "Permission denied."})
        }

    sha_name, signature = received_signature.split('=', 1)

    if sha_name != 'sha256':
        log_and_alert("Webhook sha is invalid. Permission denied.")
        return {
            "statusCode": 403,
            "body": json.dumps({"detail": "Operation not supported."})
        }

    is_valid = verify_signature(signature, raw_body)

    if not is_valid:
        log_and_alert("Webhook signature is invalid. Permission denied.")
        return {
            "statusCode": 403,
            "body": json.dumps({"detail": "Invalid signature. Permission Denied."})
        }

    body = json.loads(raw_body)
    form_id = body["form_response"]["form_id"]
    token = body["form_response"]["token"]
    user_id = body['form_response']['hidden']['user_id']

    logger.append_keys(userId=user_id)

    logger.info(f"Getting user info for {user_id}")
    try:
        cognito_user = get_cognito_user(user_id)
    except cognito.exceptions.UserNotFoundException:
        log_and_alert(
            f"Failed to get user from cognito: User {user_id} not found.")
        return {"statusCode": 200, "body": json.dumps({"detail": "User not found."})}
    except Exception as e:
        log_and_alert("Failed to get user from cognito.", e)
        return {"statusCode": 200, "body": json.dumps({"detail": "User not found."})}

    first_name = get_cognito_user_attribute(
        cognito_user['UserAttributes'], 'given_name')
    last_name = get_cognito_user_attribute(
        cognito_user['UserAttributes'], 'family_name')

    # Mark the user as having completed the typeform
    update_args = {
        'typeformFormId': form_id,
        'typeformResponseToken': token
    }
    logger.info(f"Updating user {user_id} with typeformIds.")
    try:
        update_user(user_id, update_args)
    except Exception as e:
        log_and_alert(f"Unable to update user {user_id} with typeformIds.", e)
        return {
            "statusCode": 200,
            "body": json.dumps({"detail": "Unable to update user with typeformIds."})
        }

    form_definition = body["form_response"]["definition"]

    form_answers = body["form_response"]["answers"]

    question_id_to_title = get_question_id_to_title(form_definition)

    question_id_to_answer = map_question_id_to_answer(form_answers)

    question_answer_pairs = {}
    for key, value in question_id_to_title.items():
        question_answer_pairs[key] = {
            "title": value, "answer": question_id_to_answer.get(key, "")}

    birthdate = safe_get_answer(question_answer_pairs, "VYsICm8rAEYx")
    age = calculate_age(birthdate)
    height = safe_get_answer(question_answer_pairs, "Ie0vINxRmbiE")
    weight = safe_get_answer(question_answer_pairs, "U00Hv7HSJJE1")
    gender = safe_get_answer(question_answer_pairs, "7NgJc6n3fYKa")
    fitness_goals = safe_get_answer(question_answer_pairs, "EKEiaNAbhs9B")
    fitness_level = safe_get_answer(question_answer_pairs, "dN0leyRXTKwb")
    exercise_frequency = safe_get_answer(question_answer_pairs, "v3luF8GH8oTn")
    workout_duration = safe_get_answer(question_answer_pairs, "4qftExcBXdrX")
    weightlifting_duration = safe_get_answer(
        question_answer_pairs, "wORIrsd4ZVLR")
    number_of_exercises = safe_get_answer(
        question_answer_pairs, "nY5mGGjAbXgZ")
    sets_reps = safe_get_answer(question_answer_pairs, "VYFQXGfIQyAy")
    sets_reps_custom = safe_get_answer(question_answer_pairs, "hLOuuzKYATVt")
    workout_location = safe_get_answer(question_answer_pairs, "umri0ewHbWux")
    gym_name = safe_get_answer(question_answer_pairs, "fStabAHHt7Hw")
    available_equipment = safe_get_answer(
        question_answer_pairs, "9CnfCXmUgSXo")
    other_equipment = safe_get_answer(question_answer_pairs, "F0T49AYX7sf2")
    current_cardio = safe_get_answer(question_answer_pairs, "zYfBaTZMNkFI")
    include_cardio = safe_get_answer(question_answer_pairs, "lKUgraPL2qDa")
    cardio_frequency = safe_get_answer(question_answer_pairs, "ZRYPo085Loaz")
    cardio_length = safe_get_answer(question_answer_pairs, "L5vTS0xxncEz")
    preferred_cardio_types = safe_get_answer(
        question_answer_pairs, "qu9e790LtDZh")
    physical_injuries = safe_get_answer(question_answer_pairs, "zp6cr5EGryS5")
    injury_details = safe_get_answer(question_answer_pairs, "TDFLXROBWg4r")

    prompt = generate_prompt(
        first_name,
        last_name,
        age,
        gender,
        fitness_level,
        height,
        weight,
        fitness_goals,
        exercise_frequency,
        workout_duration,
        weightlifting_duration,
        number_of_exercises,
        sets_reps,
        sets_reps_custom,
        workout_location,
        available_equipment,
        current_cardio,
        include_cardio,
        cardio_frequency,
        cardio_length,
        preferred_cardio_types,
        gym_name,
        other_equipment,
        physical_injuries,
        injury_details
    )

    prompt = remove_emojis(prompt)
    send_to_slack(prompt)
    try:
        save_to_db(user_id, prompt)
    except Exception as e:
        log_and_alert("Unable to save user story to db", e)
        return {
            "statusCode": 200,
            "body": json.dumps({"detail": "Unable to save user story to db."})
        }

    try:
        sqs.send_message(MessageBody=json.dumps({"userId": user_id, "event": "typeform.processed"}),
                         QueueUrl=QUEUE_URL)
    except Exception as e:
        log_and_alert(
            f"Unable to send initiate generate workout flow for user {user_id}", e)

    return {
        "statusCode": 200,
    }


def log_and_alert(message, error=None):
    logger.error(message, exc_info=error)
    send_error_to_slack(f"{message}. Error: {error}")


def get_cognito_user(id):
    return cognito.admin_get_user(
        UserPoolId=USER_POOL_ID,
        Username=id
    )


def get_cognito_user_attribute(attribute_list, attribute_name):
    for attr in attribute_list:
        if attr['Name'] == attribute_name:
            return attr['Value']
    return None


def update_user(id, args):
    cognito.admin_update_user_attributes(
        UserPoolId=USER_POOL_ID,
        Username=id,
        UserAttributes=[
            {
                'Name': 'custom:typeform_form_id',
                'Value': args['typeformFormId']
            },
            {
                'Name': 'custom:typeform_response_id',
                'Value': args['typeformResponseToken']
            },
            {
                'Name': 'custom:trial_start_date',
                'Value': datetime.now(timezone.utc).isoformat()
            }
        ]
    )


def save_to_db(user_id, prompt):
    try:
        existing_item = dynamodb.query(
            TableName=STORY_TABLE,
            KeyConditionExpression='PK = :pk AND begins_with(SK, :sk)',
            ExpressionAttributeValues={
                ':pk': {'S': f'USER#{user_id}'},
                ':sk': {'S': 'STORY#'}
            },
            Limit=1
        )
        if len(existing_item['Items']):
            logger.info(f'User {user_id} already has a story')
            return
    except Exception as e:
        raise e

    try:
        dynamodb.put_item(
            TableName=STORY_TABLE,
            Item={
                'PK': {'S': f'USER#{user_id}'},
                'SK': {'S': f'STORY#{str(uuid.uuid4())}'},
                'GSI1PK': {'S': f'USER#{user_id}'},
                # Ensures this is the first item in the reversed sort
                'GSI1SK': {'S': '9999'},
                'entity': {'S': 'story'},
                'userId': {'S': user_id},
                'createdAt': {'S': str(datetime.now())},
                'prompt': {'S': prompt},
                'chatRole': {'S': 'user'},
            }
        )
    except Exception as e:
        raise e


def get_parameter(name):
    try:
        response = ssm.get_parameter(Name=name, WithDecryption=True)
        return response['Parameter']['Value']
    except Exception as e:
        error_message = f'Failed to get parameter {name}: {str(e)}'
        send_error_to_slack(error_message)
        raise e


def verify_signature(received_signature, payload):
    try:
        WEBHOOK_SECRET = get_parameter('typeformSecret')
        payload_bytes = bytes(payload, 'utf-8')
        digest = hmac.new(bytes(WEBHOOK_SECRET, 'utf-8'),
                          payload_bytes, hashlib.sha256).digest()
        encoded = base64.b64encode(digest).decode()

        return encoded == received_signature
    except Exception as e:
        logger.error(f'Failed to verify signature: {str(e)}')
        return False


# List of field IDs to ignore from typeform
ignore_field_ids = [
    "hyZIUMruIaXZ",
    "DG63NL7WQMQA",
    "Yx4jU94HrZmO",
    "kLdRBGA1phAA",
    "SB28ys4LYLWo",
    "54JOGweXXfUn",
    "aDs7YLH9f0NP",
    "cFB9zg6V03V1",
    "jzD4M5NDiXE5",
    "XoyWSU4xb6RZ",
    "3o0DVt2WkDHX",
    "Gr2JZAJzJJt1",
    "4VITOv32D9hb"
]


def get_question_id_to_title(data):
    try:
        question_id_to_title = {}
        for field in data['fields']:
            question_id_to_title[field['id']] = field['title']
        return question_id_to_title
    except Exception as e:
        error_message = f'Failed to get question id to title: {str(e)}'
        send_error_to_slack(error_message)
        raise e


def map_question_id_to_answer(data):
    try:
        question_id_to_answer = {}
        for answer in data:
            question_id = answer["field"]["id"]
            if "text" in answer:
                answer_value = answer["text"]
            elif "email" in answer:
                answer_value = answer["email"]
            elif "phone_number" in answer:
                answer_value = answer["phone_number"]
            elif "date" in answer:
                answer_value = answer["date"]
            elif "choice" in answer:
                answer_value = answer["choice"]["label"]
            elif "choices" in answer:
                choices = answer["choices"]
                answer_value = ', '.join(
                    choices["labels"]) if choices["labels"] else choices["other"]
            elif "number" in answer:
                answer_value = answer["number"]
            elif "boolean" in answer:
                answer_value = answer["boolean"]
            elif "file" in answer:
                answer_value = answer["file"]["url"]
            elif "payment" in answer:
                answer_value = str(answer["payment"]["successful"])
            elif "url" in answer:
                answer_value = answer["url"]
            else:
                answer_value = "Answer type not supported"
            question_id_to_answer[question_id] = answer_value
        return question_id_to_answer
    except Exception as e:
        log_and_alert(f'Failed to map question id to answer: {str(e)}')
        raise e


def format_cardio_detail(first_name, current_cardio, include_cardio, cardio_frequency, cardio_length,
                         preferred_cardio_types):
    if current_cardio == 'Yes':
        return f"3. Cardio: {first_name} includes cardio in the workouts, doing {cardio_frequency} sessions of {preferred_cardio_types} for {cardio_length}. "
    elif include_cardio == 'Yes':
        return f"3. Cardio: {first_name} plans to start including cardio in the sessions, aiming for {cardio_frequency} sessions of {preferred_cardio_types} for {cardio_length}. "
    else:
        return "3. Cardio: Don't include cardio in any plan. "


def format_environment_detail(first_name, workout_location, gym_name, available_equipment, other_equipment):
    if workout_location == 'Gym':
        return f"4. Environment: {first_name} trains at {gym_name}. "
    else:
        equipment = ', '.join([available_equipment, other_equipment]
                              ) if other_equipment else available_equipment
        return f"4. Environment: {first_name} trains at home with access to {equipment}. "


def format_injury_detail(first_name, physical_injuries, injury_details):
    if physical_injuries == 'Yes':
        return f"7. Injury: {first_name} has reported {injury_details}. "
    else:
        return ''


def format_sets_reps(sets_reps, sets_reps_custom):
    if sets_reps == 'I have a different style':
        return sets_reps_custom
    else:
        return sets_reps


def generate_prompt(first_name: str, last_name: str, age: int, gender: str, fitness_level: str, height: str,
                    weight: str, fitness_goals: str, exercise_frequency: str = None, workout_duration: str = None,
                    weightlifting_duration: str = None, number_of_exercises: str = None, sets_reps: str = None,
                    sets_reps_custom: str = None, workout_location: str = None, available_equipment: str = None,
                    current_cardio: str = None, include_cardio: str = None, cardio_frequency: str = None,
                    cardio_length: str = None, preferred_cardio_types: str = None, gym_name: str = None,
                    other_equipment: str = None, physical_injuries: str = None, injury_details: str = None):
    cardio_detail = format_cardio_detail(first_name, current_cardio, include_cardio, cardio_frequency, cardio_length,
                                         preferred_cardio_types)
    environment_detail = format_environment_detail(first_name, workout_location, gym_name, available_equipment,
                                                   other_equipment)
    injury_detail = format_injury_detail(
        first_name, physical_injuries, injury_details)

    formatted_sets_reps = format_sets_reps(sets_reps, sets_reps_custom)

    prompt = (
        f"Create a workout for {first_name} {last_name}, {age} years old, {gender}, fitness level: {fitness_level}, height: {height}, weight: {weight} lbs. "
        f"Fitness goals: {fitness_goals}. "
        f"Training frequency: {exercise_frequency} sessions/week, duration: {workout_duration} per session. "
        f"Each session includes {weightlifting_duration} of weightlifting with {number_of_exercises} performed in {formatted_sets_reps}. "
        f"{cardio_detail}"
        f"{environment_detail}"
        f"{injury_detail}"
        f"Based on {first_name}'s preferences, create a workout with a warm-up, main exercises, cardio (if included), and a cool-down."
    )

    return prompt


def safe_get_answer(question_answer_pairs, question_id):
    try:
        answer_pair = question_answer_pairs.get(
            question_id, {"answer": "Not provided"})
        return answer_pair.get("answer", "Not provided")
    except Exception as e:
        error_message = f'Failed to get answer for question_id {question_id}: {str(e)}'
        send_error_to_slack(error_message)
        raise e


def calculate_age(birthdate_str):
    try:
        birthdate = datetime.strptime(birthdate_str, "%Y-%m-%d")
        current_date = datetime.now()
        age = current_date.year - birthdate.year - (
            (current_date.month, current_date.day) < (birthdate.month, birthdate.day))

        return age
    except Exception as e:
        error_message = f'Failed to calculate age for birthdate {birthdate_str}: {str(e)}'
        send_error_to_slack(error_message)
        raise e


def remove_emojis(text):
    try:
        emoji_pattern = re.compile(
            "["
            "\U0001F1E0-\U0001F1FF"
            "\U0001F300-\U0001F5FF"
            "\U0001F600-\U0001F64F"
            "\U0001F680-\U0001F6FF"
            "\U0001F700-\U0001F77F"
            "\U0001F780-\U0001F7FF"
            "\U0001F800-\U0001F8FF"
            "\U0001F900-\U0001F9FF"
            "\U0001FA00-\U0001FA6F"
            "\U0001FA70-\U0001FAFF"
            "\U00002702-\U000027B0"
            "\U000024C2-\U0001F251"
            "\U0001f926-\U0001f937"
            "\U00010000-\U0010ffff"
            "\u200d"
            "\u2640-\u2642"
            "\u2600-\u2B55"
            "\u23cf"
            "\u23e9"
            "\u231a"
            "\u3030"
            "\ufe0f"
            "]+",
            flags=re.UNICODE,
        )
        return emoji_pattern.sub(r"", text)
    except Exception as e:
        log_and_alert(f"Failed to remove emojis from text: {str(e)}")
        raise e


def send_to_slack(prompt):
    try:
        SLACK_WEBHOOK_URL = get_parameter('slackWebhookUrl')

        # Constructing the formatted text for Slack
        formatted_message = f'*Prompt*:\n> {prompt}'

        response = requests.post(
            SLACK_WEBHOOK_URL,
            headers={'Content-type': 'application/json'},
            data=json.dumps({
                'text': formatted_message,
            })
        )
        return response.status_code
    except Exception as e:
        error_message = f'Failed to send message to Slack: {str(e)}'
        send_error_to_slack(error_message)
        raise e


def send_error_to_slack(error_message):
    # Update this with your Slack Webhook URL
    SLACK_WEBHOOK_URL = "YOUR_SLACK_WEBHOOK_URL_HERE"
    response = requests.post(
        SLACK_WEBHOOK_URL,
        headers={'Content-type': 'application/json'},
        data=json.dumps({
            'text': error_message,
        })
    )
    return response.status_code
