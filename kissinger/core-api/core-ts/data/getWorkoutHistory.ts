import { DynamoDB } from 'aws-sdk';
import { clientOptions } from './clientOptions';
import { CompletionStatus } from './model';

export type GetHistoryRequest = {
  userId: string;
};

export type GetHistoryResponse = {
  records: any[]
  error?: Error;
};

const dynamoDb = new DynamoDB.DocumentClient(clientOptions);
const TableName = process.env.STORY_TABLE || 'sf-Story-dev';

export const getWorkoutHistory = async ({ userId }: GetHistoryRequest): Promise<GetHistoryResponse> => {
  const params: DynamoDB.DocumentClient.QueryInput = {
    TableName,
    KeyConditionExpression: '#pk = :pk and begins_with(#sk, :sk)',
    FilterExpression: '#status = :status',
    ProjectionExpression: '#id, #status, #completedAt, #secondsElapsed, #summary, #workout, #updatedAt',
    ExpressionAttributeNames: {
      '#pk': 'PK',
      '#sk': 'SK',
      '#status': 'status',
      '#id': 'id',
      '#secondsElapsed': 'secondsElapsed',
      '#summary': 'summary',
      '#workout': 'workout',
      '#completedAt': 'completedAt',
      '#updatedAt': 'updatedAt'
    },
    ExpressionAttributeValues: {
      ':pk': `USER#${userId}`,
      ':sk': `WORKOUT#`,
      ':status': CompletionStatus.COMPLETE,
    },
  };


  try {
    const resp = await dynamoDb.query(params).promise();
    // sorting in app as a quick fix for now
    resp.Items?.sort((a, b) => {
      return new Date(b.completedAt ?? b.updatedAt).getTime() - new Date(a.completedAt ?? a.updatedAt).getTime();
    });
    return { records: resp.Items ?? [] };
  } catch (error) {
    return { records: [], error: error as Error };
  }
};
