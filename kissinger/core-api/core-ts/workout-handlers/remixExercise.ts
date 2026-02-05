import { APIGatewayProxyEvent, APIGatewayProxyResult, Context } from 'aws-lambda';
import { Logger } from '@aws-lambda-powertools/logger';
import { OpenAIService } from '../openai';
import { Exercise, ExerciseSection, exerciseSections } from '../data/model';
import { getWorkout, updateWorkoutBody } from '../data';

const logger = new Logger();
const openAIService = new OpenAIService({ logger });

type RemixExerciseRequest = {
  workoutId: string;
  exerciseId: string;
  exerciseName: string;
  section: ExerciseSection;
  feedback: string;
};

type RemixExerciseResponse = {
  exercise: Exercise;
}

const parseBody = (body: string): RemixExerciseRequest => {
  const bodyObj = JSON.parse(body);
  if (!bodyObj.workoutId) throw new Error('workoutId is required');
  if (!bodyObj.section) throw new Error('section is required');
  if (!bodyObj.exerciseId && !bodyObj.exerciseName) throw new Error('exerciseId or exerciseName is required');
  if (!bodyObj.feedback) throw new Error('feedback is required');

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

  let request: RemixExerciseRequest
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

  logger.debug('remix request', { request })

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
  // find the exercise
  let exerciseIndex;
  let exercise;
  try {
    exerciseIndex = getWorkoutResp.item.workout.work[request.section].exercises
      .findIndex((e: Exercise) => e.id === request.exerciseId || e.name === request.exerciseName);
    if (exerciseIndex === -1) {
      logger.error('Failed to find exercise', { section: request.section });
      return {
        statusCode: 404,
        body: JSON.stringify({
          message: `Failed to find exercise: ${request.section}`,
        }),
      };
    }
    exercise = getWorkoutResp.item.workout.work[request.section].exercises[exerciseIndex];
  } catch (error) {
    logger.error('Failed to find/remove exercise', { error });
    return {
      statusCode: 404,
      body: JSON.stringify({
        message: `Failed to find exercise: ${request.section}`,
      }),
    };
  }

  const remixExerciseResp = await openAIService.remixExercise({
    workout: getWorkoutResp.item.workout,
    exercise,
    feedback: request.feedback,
    section: request.section
  });

  if (remixExerciseResp.error) {
    logger.error('Failed to get remixed exercise from OpenAI', { error: remixExerciseResp.error.message });
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: `Failed to generate new exercise: ${remixExerciseResp.error.message}`,
      }),
    };
  }

  // overwrite the exercise in the workout
  try {
    getWorkoutResp.item.workout.work[request.section].exercises[exerciseIndex] = remixExerciseResp.exercise;
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

  const response: RemixExerciseResponse = { exercise: remixExerciseResp.exercise }
  return {
    statusCode: 200,
    body: JSON.stringify(response),
  };
};
