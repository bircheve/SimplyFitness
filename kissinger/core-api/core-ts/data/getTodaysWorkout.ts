import { DynamoDB } from 'aws-sdk';
import { clientOptions } from './clientOptions';
import { GPTStatus, StoryEntity, Workout } from './model';

export type GetTodaysWorkoutRequest = {
  userId: string;
  userTimezone: string;
};

export enum ErrorCodes {
  ERROR = 'ERROR',
  NO_WORKOUT_FOUND = 'NO_WORKOUT_FOUND',
  SCHEDULED_FOR_LATER = 'SCHEDULED_FOR_LATER',
  WORKOUT_PENDING = 'WORKOUT_PENDING',
}

type TodayError = {
  code: ErrorCodes;
  message: string;
};

export type GetTodaysWorkoutResponse = {
  record?: Workout;
  error?: TodayError;
};

const dynamoDb = new DynamoDB.DocumentClient(clientOptions);
const TableName = process.env.STORY_TABLE || 'sf-Story-dev';

const scheduledForFutureDate = (dateStr: string, userTimezone: string): boolean => {
  const dateOptions = { timeZone: userTimezone, hour12: false };

  // Convert current date to user's timezone and get the start of the day
  const currentDateInUserTzStr = new Date().toLocaleString('en-US', dateOptions);
  const currentDateInUserTz = new Date(currentDateInUserTzStr);
  currentDateInUserTz.setHours(0, 0, 0, 0);

  // Get the start of the day for scheduled date
  const scheduledFor = new Date(dateStr);
  scheduledFor.setHours(0, 0, 0, 0);

  // Compare the dates
  return scheduledFor.getTime() > currentDateInUserTz.getTime();
}

export const getTodaysWorkout = async ({ userId, userTimezone = 'America/Denver' }: GetTodaysWorkoutRequest): Promise<GetTodaysWorkoutResponse> => {
  const params: DynamoDB.DocumentClient.QueryInput = {
    TableName,
    IndexName: 'GSI1',
    KeyConditionExpression: '#pk = :pkey',
    FilterExpression: '#entity = :entity',
    ExpressionAttributeNames: {
      '#pk': 'GSI1PK',
      '#entity': 'entity', // TODO: make an index to query by entity type, filter expressions are not efficient
    },
    ExpressionAttributeValues: {
      ':pkey': `USER#${userId}`,
      ':entity': StoryEntity.WORKOUT,
    },
    ScanIndexForward: false,
  };
  try {
    const resp = await dynamoDb.query(params).promise();

    if (!resp.Items?.length) {
      return { record: {} as Workout, error: { code: ErrorCodes.NO_WORKOUT_FOUND, message: 'No workout found' } };
    }

    let response: GetTodaysWorkoutResponse = { record: resp.Items[0] as Workout };

    if (response.record?.gptStatus === GPTStatus.PENDING) {
      return { record: {} as Workout, error: { code: ErrorCodes.WORKOUT_PENDING, message: 'Workout pending' } };
    }

    return response;
  } catch (error) {
    return { error: { code: ErrorCodes.ERROR, message: error } as TodayError };
  }
};
