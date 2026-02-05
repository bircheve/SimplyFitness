import { APIGatewayProxyEvent, APIGatewayProxyResult, Context } from 'aws-lambda';
import { Logger } from '@aws-lambda-powertools/logger';
import { ErrorCodes, getTodaysWorkout } from '../data';
const logger = new Logger();

type ValidResponse = {
  muscle_groups: string[];
  work: {
    warmup: TimeBasedWorkout;
    main: StrengthBasedWorkout;
    cardio: TimeBasedWorkout;
    cooldown: TimeBasedWorkout;
  };
};

type StrengthBasedWorkout = {
  exercises: {
    name: string;
    instructions: string;
    equipment: string;
    muscle_groups: string[];
    sets: number[];
  }[];
};

type TimeBasedWorkout = {
  exercises: {
    duration: number;
    name: string;
    instructions: string;
    equipment: string;
  }[];
};

type BasicResponse = {
  statusCode: number;
  body: string;
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
  logger.appendKeys({
    awsRequestId: context.awsRequestId,
  });

  let userId = event.requestContext.authorizer?.claims['sub'];
  let userTimezone = event.headers['Timezone'] || 'America/Denver';

  const queryResponse = await getTodaysWorkout({ userId, userTimezone });
  const response = { statusCode: 200, body: '' };

  switch (queryResponse.error?.code) {
    case ErrorCodes.ERROR:
      response.statusCode = 500;
      response.body = JSON.stringify({
        message: `Failed to get workout: ${queryResponse.error.message}`,
      });
      break;
    case ErrorCodes.NO_WORKOUT_FOUND:
      response.body = JSON.stringify({
        message: `No workout found`,
        code: ErrorCodes.NO_WORKOUT_FOUND,
      });
      break;
    case ErrorCodes.SCHEDULED_FOR_LATER:
      response.body = JSON.stringify({
        message: `Workout scheduled for later`,
        code: ErrorCodes.SCHEDULED_FOR_LATER,
      });
      break;
    case ErrorCodes.WORKOUT_PENDING:
      response.body = JSON.stringify({
        message: `Workout pending`,
        code: ErrorCodes.WORKOUT_PENDING,
      });
      break;
    default:
      response.body = JSON.stringify(queryResponse.record);
      break;
  }

  return response;
};
