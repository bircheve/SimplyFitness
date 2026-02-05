import { DynamoDB } from 'aws-sdk';
import { clientOptions } from './clientOptions';
import { CompletionStatus, GPTStatus } from './model';

export type CreateUpdateTransactionRequest = {
  userId: string;
  workoutId: string;
  status: CompletionStatus;
  summary: [{ name: string; completedSets: number; skippedSets: number }];
  secondsElapsed?: number;
};

export type CreateUpdateTransactionResponse = {
  transactionItem: DynamoDB.DocumentClient.TransactWriteItem;
  error?: Error;
};

export type UpdateWorkoutRequest = {
  formattedWorkout: any;
  formattedCompletionId: string
  userId: string;
  workoutId: string;
  gptStatus: GPTStatus;
};

export type UpdateBodyRequest = {
  workoutId: string;
  userId: string;
  formattedWorkout: any;
};

export type UpdateBodyWithSharedRequest = UpdateBodyRequest & {
  sharedWorkoutId: string;
};

export type UpdateWorkoutResponse = {
  error?: Error;
};

const TableName = process.env.STORY_TABLE || 'sf-Story-dev';
const dynamoDb = new DynamoDB.DocumentClient(clientOptions);

export const createUpdateWorkoutTransactionItem = (input: CreateUpdateTransactionRequest): CreateUpdateTransactionResponse => {
  const ts = new Date().toISOString();
  const params: DynamoDB.DocumentClient.Update = {
    TableName,
    Key: {
      PK: `USER#${input.userId}`,
      SK: `WORKOUT#${input.workoutId}`,
    },
    UpdateExpression: 'SET #status = :status, #summary = :summary, #secondsElapsed = :secondsElapsed, #updatedAt = :updatedAt, #completedAt = :completedAt',
    ExpressionAttributeNames: {
      '#status': 'status',
      '#summary': 'summary',
      '#secondsElapsed': 'secondsElapsed',
      '#updatedAt': 'updatedAt',
      '#completedAt': 'completedAt',
    },
    ExpressionAttributeValues: {
      ':status': input.status,
      ':summary': input.summary,
      ':secondsElapsed': input.secondsElapsed,
      ':updatedAt': ts,
      ':completedAt': ts,
    },
  };
  try {
    return { transactionItem: { Update: params } };
  } catch (error) {
    return { transactionItem: {}, error: error as Error };
  }
};

export const updateWorkout = async (input: UpdateWorkoutRequest): Promise<UpdateWorkoutResponse> => {
  const params: DynamoDB.DocumentClient.Update = {
    TableName,
    Key: {
      PK: `USER#${input.userId}`,
      SK: `WORKOUT#${input.workoutId}`,
    },
    UpdateExpression: 'SET #workout = :workout, #updatedAt = :updatedAt, #chatFormatCompletionId = :chatFormatCompletionId, #gptStatus = :gptStatus',
    ExpressionAttributeNames: {
      '#chatFormatCompletionId': 'chatFormatCompletionId',
      '#workout': 'workout',
      '#updatedAt': 'updatedAt',
      '#gptStatus': 'gptStatus',
    },
    ExpressionAttributeValues: {
      ':chatFormatCompletionId': input.formattedCompletionId,
      ':workout': { ...input.formattedWorkout, id: input.workoutId },
      ':updatedAt': new Date().toISOString(),
      ':gptStatus': input.gptStatus,
    },
  };
  try {
    await dynamoDb.update(params).promise();
    return {}
  } catch (error) {
    return { error: error as Error };
  }
}

export const updateWorkoutBody = async (input: UpdateBodyRequest): Promise<UpdateWorkoutResponse> => {
  const params: DynamoDB.DocumentClient.Update = {
    TableName,
    Key: {
      PK: `USER#${input.userId}`,
      SK: `WORKOUT#${input.workoutId}`,
    },
    UpdateExpression: 'SET #workout = :workout, #updatedAt = :updatedAt',
    ExpressionAttributeNames: {
      '#workout': 'workout',
      '#updatedAt': 'updatedAt',
    },
    ExpressionAttributeValues: {
      ':workout': { ...input.formattedWorkout, id: input.workoutId },
      ':updatedAt': new Date().toISOString(),
    },
  };
  try {
    await dynamoDb.update(params).promise();
    return {}
  } catch (error) {
    return { error: error as Error };
  }
}

export const updateWorkoutBodyFromShared = async (input: UpdateBodyWithSharedRequest): Promise<UpdateWorkoutResponse> => {
  const params: DynamoDB.DocumentClient.Update = {
    TableName,
    Key: {
      PK: `USER#${input.userId}`,
      SK: `WORKOUT#${input.workoutId}`,
    },
    UpdateExpression: 'SET #workout = :workout, #sharedWorkoutId = :sharedWorkoutId, #updatedAt = :updatedAt',
    ExpressionAttributeNames: {
      '#workout': 'workout',
      '#updatedAt': 'updatedAt',
      '#sharedWorkoutId': 'sharedWorkoutId',
    },
    ExpressionAttributeValues: {
      ':workout': { ...input.formattedWorkout, id: input.workoutId },
      ':sharedWorkoutId': input.sharedWorkoutId,
      ':updatedAt': new Date().toISOString(),
    },
  };
  try {
    await dynamoDb.update(params).promise();
    return {}
  } catch (error) {
    return { error: error as Error };
  }
}
