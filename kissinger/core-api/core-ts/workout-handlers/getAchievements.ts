import { APIGatewayProxyEvent, APIGatewayProxyResult, Context } from 'aws-lambda';
import { Logger } from '@aws-lambda-powertools/logger';
import { getWorkoutHistory } from '../data';
import { CompletedWorkout } from '../data/model';
const logger = new Logger();


// Helper function to get the start of the week for a given date
export function getStartOfWeek(date: Date): Date {
  const start = new Date(date);
  start.setHours(0, 0, 0, 0);
  start.setDate(start.getDate() - start.getDay());
  return start;
}

export function calculateMetrics(records: CompletedWorkout[]): {
  totalWorkouts: number;
  currentStreak: number;
  longestStreak: number;
} {
  if (records.length === 0) {
    return {
      totalWorkouts: 0,
      currentStreak: 0,
      longestStreak: 0
    };
  }

  const totalWorkouts = records.length;
  // Calculate current streak
  let currentStreak = 0;
  if (records.length > 0) {
    let currentDate = new Date();
    let currentWeekStart = getStartOfWeek(currentDate);
    let workoutsThisWeek = 0;

    for (let record of records) {
      const recordDate = new Date(record.completedAt ?? record.updatedAt);
      if (recordDate >= currentWeekStart) {
        workoutsThisWeek++;
      } else {
        if (workoutsThisWeek >= 4) {
          currentStreak++;
        }
        workoutsThisWeek = 0; // reset for the next week
        currentWeekStart.setDate(currentWeekStart.getDate() - 7);
        if (recordDate >= currentWeekStart) {
          workoutsThisWeek++;
        }
      }
    }
    if (workoutsThisWeek >= 4) {
      currentStreak++; // check the last week
    }
  }

  // Calculate longest streak
  let longestStreak = 0;
  let tempStreak = 0;
  let currentWeekStart = getStartOfWeek(new Date(records[0].completedAt ?? records[0].updatedAt));
  let workoutsThisWeek = 0;

  for (let record of records) {
    const recordDate = new Date(record.completedAt ?? record.updatedAt);
    if (recordDate >= currentWeekStart) {
      workoutsThisWeek++;
    } else {
      if (workoutsThisWeek >= 4) {
        tempStreak++;
      } else {
        longestStreak = Math.max(longestStreak, tempStreak);
        tempStreak = 0;
      }
      workoutsThisWeek = 1; // reset for the next week
      currentWeekStart.setDate(currentWeekStart.getDate() - 7);
    }
  }
  if (workoutsThisWeek >= 4) {
    tempStreak++;
  }
  longestStreak = Math.max(longestStreak, tempStreak); // check at the end

  return {
    totalWorkouts,
    currentStreak,
    longestStreak
  };
}


export const handler = async (event: APIGatewayProxyEvent, context: Context): Promise<APIGatewayProxyResult> => {
  let userId = event.requestContext.authorizer?.claims['sub'];

  logger.appendKeys({
    awsRequestId: context.awsRequestId,
    userId,
  });

  const queryResponse = await getWorkoutHistory({ userId });
  if (queryResponse.error) {
    logger.error('Failed to query workout history', queryResponse.error);
    return {
      statusCode: 500,
      body: JSON.stringify({
        code: 'UNKNOWN',
        message: 'Failed to get workout history',
      }),
    };
  }

  const metrics = calculateMetrics(queryResponse.records);

  return {
    statusCode: 200,
    body: JSON.stringify(metrics),
  };
};
