import { DynamoDB } from 'aws-sdk';
import { clientOptions } from './clientOptions';

export type DeleteWorkoutRequest = {
  userId: string;
  workoutId: string;
};

export type DeleteWorkoutResponse = {
  error?: Error;
};

const dynamoDb = new DynamoDB.DocumentClient(clientOptions);
const TableName = process.env.STORY_TABLE || 'sf-Story-dev';

export const deleteWorkout = async (input: DeleteWorkoutRequest): Promise<DeleteWorkoutResponse> => {
  const params: DynamoDB.DocumentClient.Delete = {
    TableName,
    Key: {
      PK: `USER#${input.userId}`,
      SK: `WORKOUT#${input.workoutId}`,
    },
  };
  try {
    await dynamoDb.delete(params).promise();
    return {};
  } catch (error) {
    return { error: error as Error };
  }
};
