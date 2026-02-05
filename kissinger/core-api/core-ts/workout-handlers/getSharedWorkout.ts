import { APIGatewayProxyEvent, APIGatewayProxyResult, Context } from 'aws-lambda';
import { Logger } from '@aws-lambda-powertools/logger';
import { getSharedWorkout } from '../data';
import { CognitoService } from '../services';

const cognitoService = new CognitoService(process.env.COGNITO_USER_POOL_ID ?? '');
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
  let workoutId = event.pathParameters?.id ?? '';

  logger.appendKeys({ workoutId });
  const queryResponse = await getSharedWorkout({ workoutId });
  if (queryResponse.error) {
    logger.error('Failed to fetch shared workout', { error: queryResponse.error });
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: 'Error querying DynamoDB',
      }),
    };
  }

  let sharingUserName = 'SF User';
  try {
    const sharingUser = await cognitoService.getUserBySub(queryResponse.item?.userId ?? '');
    sharingUser.UserAttributes?.forEach((attr) => {
      if (attr.Name === 'given_name') {
        sharingUserName = attr.Value ?? 'SF User';
      }
    });
  } catch (error) {
    logger.error('Failed to fetch user data from cognito', { error }); 
  }


  // only return appropriate fields
  const cleanResponse = {
    id: queryResponse.item?.id,
    sharedById: queryResponse.item?.userId,
    sharedByName: sharingUserName,
    workout: queryResponse.item?.workout,
  }

  return {
    statusCode: 200,
    body: JSON.stringify(cleanResponse),
  };
};
