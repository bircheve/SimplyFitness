import { APIGatewayProxyEvent, APIGatewayProxyResult, Context } from 'aws-lambda';
import { Logger } from '@aws-lambda-powertools/logger';
import { OpenAIService } from '../openai';
import { Exercise, ExerciseSection, exerciseSections } from '../data/model';
import { getWorkout, updateWorkoutBody } from '../data';

const logger = new Logger();
const openAIService = new OpenAIService({ logger });

type AddExerciseRequest = {
  workoutId: string;
  section: ExerciseSection;
};

type AddExerciseResponse = {
  exercise: Exercise;
}

const parseBody = (body: string): AddExerciseRequest => {
  const bodyObj = JSON.parse(body);
  if (!bodyObj.workoutId) throw new Error('workoutId is required');
  if (!bodyObj.section) throw new Error('section is required');

  if (typeof bodyObj.section !== 'string' && !exerciseSections.includes(bodyObj.section)) {
    throw new Error(`section must be one of ${exerciseSections.join(', ')}`);
  }
  return bodyObj;
};

/**
 *
 *
 * Event doc: https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-lambda-proxy-integrations.html#api-gateway-simple-proxy-for-lambda-input-format
 * @param {APIGatewayProxyEvent} event - API Gateway Lambda Proxy Input Format
 * @param {Context} object - API Gateway Lambda $context variable
 *
 * Return doc: https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-lambda-proxy-integrations.html
 * @returns {APIGatewayProxyResult} object - API Gateway Lambda Proxy Output Format
 *
 */
export const handler = async (event: APIGatewayProxyEvent, context: Context): Promise<APIGatewayProxyResult> => {
  const userId = event.requestContext.authorizer?.claims['sub'];
  logger.appendKeys({
    awsRequestId: context.awsRequestId,
    method: event.httpMethod,
    resource: event.resource,
    userId,
  });

  let request: AddExerciseRequest
  try {
    request = parseBody(event.body ?? '');
  } catch (error: any) {
    logger.error('Failed to parse request body', error);
    return {
      statusCode: 400,
      body: JSON.stringify({
        message: error.message,
      }),
    };
  }

  const getWorkoutResp = await getWorkout({ userId, workoutId: request.workoutId });
  if (getWorkoutResp.error) {
    logger.error('Failed to find workout', { error: getWorkoutResp.error.message });
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: `Failed to find workout: ${getWorkoutResp.error.message}`,
      }),
    };
  }

  const addExerciseResp = await openAIService.addExercise({ section: request.section, formattedWorkout: getWorkoutResp.item.workout });
  if (addExerciseResp.error) {
    logger.error('Failed to get new exercise from OpenAI', { error: addExerciseResp.error.message });
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: `Failed to generate new exercise: ${addExerciseResp.error.message}`,
      }),
    };
  }

  try {
    getWorkoutResp.item.workout.work[request.section].exercises.push(addExerciseResp.exercise);
  } catch (error) {
    logger.error('Failed to add new exercise to workout', { error });
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: `Failed to add new exercise to workout: ${error}`,
      }),
    };
  }

  const updateWorkoutResp = await updateWorkoutBody({ userId, workoutId: request.workoutId, formattedWorkout: getWorkoutResp.item.workout });
  if (updateWorkoutResp.error) {
    logger.error("Failed to update workout body with new exercise", { error: updateWorkoutResp.error.message });
  }

  const response: AddExerciseResponse = { exercise: addExerciseResp.exercise }
  return {
    statusCode: 200,
    body: JSON.stringify(response),
  };
};
