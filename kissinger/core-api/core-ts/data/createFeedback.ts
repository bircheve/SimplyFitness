import { DynamoDB } from 'aws-sdk';
import { clientOptions } from './clientOptions';
import { v4 } from 'uuid';
import { ChatRole, CompletionStatus } from './model';
import { create } from 'domain';

export type CreateFeedbackRequest = {
  userId: string;
  workoutId: string;
  workoutSummary: [{ name: string; completedSets: number; skippedSets: number }];
  feedback: string;
  secondsElapsed?: number;
};

export type CreateFeedbackResponse = {
  transactionItem: DynamoDB.DocumentClient.TransactWriteItem;
  error?: Error;
};

const TableName = process.env.STORY_TABLE || 'sf-Story-dev';

export const createFeedbackTransactionItem = (input: CreateFeedbackRequest): CreateFeedbackResponse => {
  const id = v4();
  const pk = `USER#${input.userId}`;
  const sk = `FEEDBACK#${id}`;
  const createdAtMs = Date.now();
  const createdAt = new Date(createdAtMs).toISOString();

  const feedbackMessage = `Create the next workout according to the user's preferences and feedback on the last workout: ${input.feedback}`;

  const params: DynamoDB.DocumentClient.PutItemInput = {
    TableName,
    Item: {
      PK: pk,
      SK: sk,
      GSI1PK: `USER#${input.userId}`,
      GSI1SK: createdAt,
      entity: 'feedback',
      id: id,
      feedback: input.feedback,
      secondsElapsed: input.secondsElapsed,
      workoutId: input.workoutId,
      workoutSummary: input.workoutSummary,
      userId: input.userId,
      createdAt,
      // generic fields for chat history
      chatRole: ChatRole.USER,
      message: feedbackMessage,
    },
  };
  try {
    return { transactionItem: { Put: params } };
  } catch (error) {
    return { transactionItem: {}, error: error as Error };
  }
};