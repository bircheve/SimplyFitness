import { APIGatewayProxyEvent, APIGatewayProxyResult, Context } from 'aws-lambda';
import { Logger } from '@aws-lambda-powertools/logger';
import { createFeedbackTransactionItem, createUpdateWorkoutTransactionItem, executeWriteTransaction } from '../data';
import { CompletionStatus } from '../data/model';
import SQS from 'aws-sdk/clients/sqs';

const logger = new Logger();
const sqs = new SQS();
const queueUrl = process.env.GENERATOR_QUEUE_URL || 'NOT_SET';

// TODO: add schema validation middleware with joi or class-validator
type CompleteWorkoutRequest = {
  workoutId: string;
  summary: any;
  feedback: string;
  secondsElapsed?: number;
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
  const request: CompleteWorkoutRequest = JSON.parse(event.body || '{}');
  const workoutId = event.pathParameters?.id || request.workoutId;

  // update workout to complete and create a feedback item
  const updateReq = createUpdateWorkoutTransactionItem({
    userId,
    workoutId,
    status: CompletionStatus.COMPLETE,
    summary: request.summary,
    secondsElapsed: request.secondsElapsed,
  });
  const feedbackReq = createFeedbackTransactionItem({
    userId,
    workoutId,
    feedback: request.feedback,
    workoutSummary: request.summary,
    secondsElapsed: request.secondsElapsed,
  });

  const transaction = await executeWriteTransaction({
    transactionItems: [updateReq.transactionItem, feedbackReq.transactionItem],
  });
  if (transaction.error) {
    logger.error("Error updating workout's completion status and creating feedback", { error: transaction.error });
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: transaction.error.message,
      }),
    };
  }

  // create sqs message to generate new workout
  const messageBody = {
    userId,
    workoutId,
    event: 'workout.completed',
  };
  try {
    await sqs
      .sendMessage({
        QueueUrl: queueUrl,
        MessageBody: JSON.stringify(messageBody),
      })
      .promise();
  } catch (error: any) {
    logger.error('Error sending message to SQS to generate next workout', error);
    // TODO: alert???
  }

  return {
    statusCode: 200,
    body: JSON.stringify({}),
  };
};
