import { APIGatewayProxyEvent, APIGatewayProxyResult, Context } from 'aws-lambda';
import { Logger } from '@aws-lambda-powertools/logger';
import { GetSharedWorkoutResponse, GetWorkoutResponse, getSharedWorkout, getWorkout, updateWorkoutBodyFromShared } from '../data';
import { parse } from 'path';

const logger = new Logger();
type UseSharedWorkoutRequest = {
  workoutId: string;
  sharedWorkoutId: string;
};

const parseBody = (body: string): UseSharedWorkoutRequest => {
  const bodyObj = JSON.parse(body);
  if (!bodyObj.workoutId) throw new Error('workoutId is required');
  if (!bodyObj.sharedWorkoutId) throw new Error('sharedWorkoutId is required');

  return bodyObj as UseSharedWorkoutRequest;
};

/**
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
    userId,
  });

  let body: UseSharedWorkoutRequest;
  try {
    body = parseBody(event.body ?? '');
  } catch (error) {
    logger.error('Failed to parse request body', { error });
    return {
      statusCode: 400,
      body: JSON.stringify({ message: error }),
    }
  }

  // get original and shared workout
  const getWorkoutResp = await getWorkout({ userId, workoutId: body.workoutId });
  if (getWorkoutResp.error || !getWorkoutResp.item) {
    logger.error('Failed to get workout', { error: getWorkoutResp.error })
    return {
      statusCode: 500,
      body: JSON.stringify({ message: 'Failed to get workout' }),
    };
  }
  const getSharedWorkoutResp = await getSharedWorkout({ workoutId: body.sharedWorkoutId });
  if (getSharedWorkoutResp.error || !getSharedWorkoutResp.item) {
    logger.error('Failed to get shared workout', { error: getWorkoutResp.error })
    return {
      statusCode: 500,
      body: JSON.stringify({ message: 'Failed to get shared workout' }),
    };
  }

  // merge shared workout into original workout
  // TODO: figure out a cleaner way to create a new record instead of overwriting the original
  try {
    await updateWorkoutBodyFromShared({
      userId,
      workoutId: getWorkoutResp.item.id,
      formattedWorkout: getSharedWorkoutResp.item.workout,
      sharedWorkoutId: getSharedWorkoutResp.item.id
    })
  } catch (error) {
    logger.error('Failed to update workout body with shared workout', { error })
    return {
      statusCode: 500,
      body: JSON.stringify({ message: 'Failed to update workout' }),
    };
  }
  logger.debug('Successfully updated workout body with shared workout')

  return {
    statusCode: 200,
    body: JSON.stringify({}),
  };
};
