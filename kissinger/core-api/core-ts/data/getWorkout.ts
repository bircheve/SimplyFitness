import { DynamoDB } from 'aws-sdk';
import { clientOptions } from './clientOptions';

export type GetWorkoutRequest = {
  userId: string;
  workoutId: string;
};

export type GetWorkoutResponse = {
  item: any;
  error?: Error;
};

export type GetSharedWorkoutRequest = {
  workoutId: string;
};

export type GetSharedWorkoutResponse = {
  item?: any;
  error?: Error;
};

const dynamoDb = new DynamoDB.DocumentClient(clientOptions);
const TableName = process.env.STORY_TABLE || 'sf-Story-dev';

export const getWorkout = async ({ userId, workoutId }: GetWorkoutRequest): Promise<GetWorkoutResponse> => {
  const params: DynamoDB.DocumentClient.GetItemInput = {
    TableName,
    Key: {
      PK: `USER#${userId}`,
      SK: `WORKOUT#${workoutId}`,
    },
  };
  try {
    const resp = await dynamoDb.get(params).promise();
    if (!resp.Item) {
      throw new Error("Item not found");
    }
    return { item: resp.Item ?? [] };
  } catch (error) {
    return { item: [], error: error as Error };
  }
};

export const getSharedWorkout = async ({ workoutId }: GetSharedWorkoutRequest): Promise<GetSharedWorkoutResponse> => {
  const params: DynamoDB.DocumentClient.QueryInput = {
    TableName,
    IndexName: 'GSI2',
    KeyConditionExpression: '#gsipk = :gsipk AND #gsisk = :gsisk',
    ExpressionAttributeNames: {
      '#gsipk': 'GSI2PK',
      '#gsisk': 'GSI2SK',
    },
    ExpressionAttributeValues: {
      ':gsipk': `WORKOUT#${workoutId}`,
      ':gsisk': '#SHARED#',
    },
  };
  try {
    const resp = await dynamoDb.query(params).promise();
    if (!resp.Items || resp.Items.length === 0) {
      throw new Error("Item not found");
    }
    return { item: resp.Items[0] }
  } catch (error) {
    return { error: error as Error };
  }
};
