import { APIGatewayProxyEvent, APIGatewayProxyResult, Context } from 'aws-lambda';
import { Logger } from '@aws-lambda-powertools/logger';
import { getWorkoutHistory } from '../data';
const logger = new Logger();

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

  const queryResponse = await getWorkoutHistory({ userId });
  if (queryResponse.error) {
    logger.error('Failed to query workout history', queryResponse.error);
    return {
      statusCode: 500,
      body: JSON.stringify({
        code: 'UNKNOWN',
        message: 'Failed to query DynamoDB',
      }),
    };
  }

  const data = {
    count: queryResponse.records.length,
    workouts: queryResponse.records,
  }

  return {
    statusCode: 200,
    body: JSON.stringify(data),
  };
};
