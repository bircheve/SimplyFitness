import { DynamoDB } from 'aws-sdk';
import { clientOptions } from './clientOptions';
import { v4 } from 'uuid';
import { ChatRole, CompletionStatus, StoryEntity } from './model';

export type CreateRemixRequest = {
  userId: string;
  workoutId: string;
  remixRequest: string;
};

export type CreateRemixResponse = {
  remixId: string;
  error?: Error;
};

const dynamoDb = new DynamoDB.DocumentClient(clientOptions);
const TableName = process.env.STORY_TABLE || 'sf-Story-dev';

export const saveRemix = async (input: CreateRemixRequest): Promise<CreateRemixResponse> => {
  const id = v4();
  const createdAtMs = Date.now()
  const createdAt = new Date(createdAtMs).toISOString();
  const pk = `USER#${input.userId}`;
  const sk = `REMIX#${id}`;
  const params: DynamoDB.DocumentClient.PutItemInput = {
    TableName,
    Item: {
      PK: pk,
      SK: sk,
      GSI1PK: pk,
      GSI1SK: createdAt,
      id: id,
      entity: StoryEntity.REMIX,
      userId: input.userId,
      createdAt: createdAt,
      workoutId: input.workoutId,
      // generic fields for chat history
      chatRole: ChatRole.USER,
      message: input.remixRequest,
    }
  }
  try {
    await dynamoDb.put(params).promise();
    return { remixId: id };
  } catch (error) {
    return { remixId: '', error: error as Error };
  }
};