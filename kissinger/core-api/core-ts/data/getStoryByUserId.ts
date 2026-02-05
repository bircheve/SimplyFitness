import { DynamoDB } from 'aws-sdk';
import { clientOptions } from './clientOptions';
import { Feedback, GPTStatus, Story } from './model';

export type GetStoryRequest = {
  userId: string;
};

export type GetStoryResponse = {
  records: any[]
  hasWorkoutPending: boolean;
  error?: Error;
};

const dynamoDb = new DynamoDB.DocumentClient(clientOptions);
const TableName = process.env.STORY_TABLE || 'sf-Story-dev';

export const getStoryByUserId = async ({ userId }: GetStoryRequest): Promise<GetStoryResponse> => {
  const params: DynamoDB.DocumentClient.QueryInput = {
    TableName,
    IndexName: 'GSI1',
    KeyConditionExpression: '#pk = :pk',
    ExpressionAttributeNames: {
      '#pk': 'GSI1PK',
    },
    ExpressionAttributeValues: {
      ':pk': `USER#${userId}`,
    },
    Limit: 15,
    ScanIndexForward: false
  };
  try {
    const resp = await dynamoDb.query(params).promise();
    let response: GetStoryResponse = { records: [], hasWorkoutPending: false };
    if (!resp.Items?.length) {
      return { ...response, error: new Error(`No story found for ${userId}`) };
    }
    return { ...response, records: resp.Items };
  } catch (error) {
    return { records: [], hasWorkoutPending: false, error: error as Error };
  }
};
