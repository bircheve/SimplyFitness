import { DynamoDB } from 'aws-sdk';
import { clientOptions } from './clientOptions';
import { v4 } from 'uuid';
import { ChatRole, CompletionStatus, GPTStatus, StoryEntity } from './model';

export type CreateWorkoutRequest = {
  userId: string;
  workout: any;
  gptStatus: GPTStatus;
  id?: string; // prevents duplicate work if SQS times out
  chatCompletionId?: string;
  remixId?: string;
  scheduleForLater?: boolean;
  userTimezone?: string;
  rawWorkoutContent?: string;
};

export type CreateWorkoutResponse = {
  workoutId: string;
  error?: Error;
};

const dynamoDb = new DynamoDB.DocumentClient(clientOptions);
const TableName = process.env.STORY_TABLE || 'sf-Story-dev';

export const createWorkout = async (input: CreateWorkoutRequest): Promise<CreateWorkoutResponse> => {
  const id = input.id ?? v4();

  const createdAt = new Date(Date.now()).toISOString();
  const pk = `USER#${input.userId}`;
  const sk = `WORKOUT#${id}`;
  const params: DynamoDB.DocumentClient.PutItemInput = {
    TableName,
    Item: {
      PK: pk,
      SK: sk,
      GSI1PK: pk,
      GSI1SK: createdAt,
      GSI2PK: sk,
      GSI2SK: `#SHARED#`,
      entity: StoryEntity.WORKOUT,
      id: id,
      status: CompletionStatus.INCOMPLETE,
      gptStatus: input.gptStatus,
      userId: input.userId,
      workout: { ...input.workout, id: id },
      chatRole: ChatRole.ASSISTANT,
      createdAt: createdAt,
      chatRawCompletionId: input.chatCompletionId,
      rawWorkout: input.rawWorkoutContent,
      remixedWorkoutId: input.remixId,
    },
  };
  try {
    await dynamoDb.put(params).promise();
    return { workoutId: id };
  } catch (error) {
    return { workoutId: '', error: error as Error };
  }
};
