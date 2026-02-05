import { APIGatewayProxyEvent, APIGatewayProxyResult, Context } from 'aws-lambda';
import { Logger } from '@aws-lambda-powertools/logger';
import { OpenAIService } from '../openai';
import { Exercise, ExerciseSection, Workout, exerciseSections } from '../data/model';
import { getWorkout, updateWorkoutBody } from '../data';

const logger = new Logger();

type RemoveExerciseRequest = {
  exerciseId: string;
  exerciseName: string;
  workoutId: string;
  section: ExerciseSection;
};


const parseBody = (body: string): RemoveExerciseRequest => {
  const bodyObj = JSON.parse(body);
  if (!bodyObj.exerciseId) throw new Error('exerciseId is required');
  if (!bodyObj.exerciseName) throw new Error('exerciseName is required');
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

  let request: RemoveExerciseRequest
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

  logger.appendKeys({ workoutId: request.workoutId })

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

  let workoutRecord: Workout = getWorkoutResp.item;

  // find a remove exercise from the workout by id or name
  try {
    const exerciseIndex = workoutRecord.workout.work[request.section].exercises.findIndex((e: Exercise) => e.id === request.exerciseId || e.name === request.exerciseName);
    if (exerciseIndex === -1) {
      logger.error('Failed to find exercise', { section: request.section });
      return {
        statusCode: 404,
        body: JSON.stringify({
          message: `Failed to find exercise: ${request.section}`,
        }),
      };
    }
    workoutRecord.workout.work[request.section].exercises.splice(exerciseIndex, 1);

  } catch (error) {
    logger.error('Failed to find/remove exercise', { error });
    return {
      statusCode: 404,
      body: JSON.stringify({
        message: `Failed to find exercise: ${request.section}`,
      }),
    };
  }


  const updateWorkoutResp = await updateWorkoutBody({ userId, workoutId: request.workoutId, formattedWorkout: workoutRecord.workout});
  if (updateWorkoutResp.error) {
    logger.error("Failed to update workout body with removed exercise", { error: updateWorkoutResp.error.message });
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: `Failed to remove exercise: ${updateWorkoutResp.error.message}`,
      }),
    };
  }

  return {
    statusCode: 200,
    body: JSON.stringify({}),
  };
};
