import { APIGatewayProxyEvent, APIGatewayProxyResult, Context } from 'aws-lambda';
import { Logger } from '@aws-lambda-powertools/logger';
import { saveRemix } from '../data';
import { SQS } from 'aws-sdk';

const logger = new Logger();
const sqs = new SQS();
const queueUrl = process.env.GENERATOR_QUEUE_URL || 'NOT_SET';

type RemixWorkoutRequest = {
  feedback: string;
  workoutId: string;
  originalWorkoutId?: string;
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
  // Append awsRequestId to each log statement
  logger.appendKeys({
    awsRequestId: context.awsRequestId,
  });

  const userId = event.requestContext.authorizer?.claims['sub'];
  const request: RemixWorkoutRequest = JSON.parse(event.body || '{}');
  const workoutId = event.pathParameters?.id || request.workoutId;

  // update workout to complete and create a feedback item
  const saveRemixResp = await saveRemix({ workoutId, userId, remixRequest: request.feedback });
  if (saveRemixResp.error) {
    logger.error(saveRemixResp.error.message);
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: `Failed to save remix request: ${saveRemixResp.error.message}`,
      }),
    };
  }

  const messageBody = {
    event: 'workout.remixed',
    userId,
    workoutId,
    remixId: saveRemixResp.remixId,
  };
  try {
    await sqs
      .sendMessage({
        QueueUrl: queueUrl, // TODO: use priority queue to fast track remixes
        MessageBody: JSON.stringify(messageBody),
      })
      .promise();
  } catch (error: any) {
    logger.error('Error sending message to SQS to generate remix', error);
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: `Failed to start remix generation: ${error.message}`,
      }),
    };
  }

  return {
    statusCode: 200,
    body: JSON.stringify({ workoutId, remixId: saveRemixResp.remixId }),
  };
};
