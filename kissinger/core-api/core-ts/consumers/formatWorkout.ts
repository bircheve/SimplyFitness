import { Context, SQSBatchItemFailure, SQSBatchResponse, SQSEvent } from 'aws-lambda';
import { Logger } from '@aws-lambda-powertools/logger';
import { Metrics, MetricUnits } from '@aws-lambda-powertools/metrics';
import { OpenAIService } from '../openai';
import { getWorkout, updateWorkout } from '../data';
import { GPTStatus } from '../data/model';
import { QueueService, SlackService } from '../services';

const logger = new Logger();
const metrics = new Metrics();
const openAIService = new OpenAIService({ logger });
const slackService = new SlackService({ webhookUrl: process.env.SLACK_WEBHOOK_URL ?? '' });
const queueService = new QueueService();

type SQSMessageBody = {
  userId: string;
  workoutId: string;
  event: 'typeform.processed' | 'workout.completed' | 'workout.remixed';
};

// TODO: add schema validation middleware with joi or class-validator
const parseBody = (body: string): SQSMessageBody => {
  return JSON.parse(body);
};

export const handler = async (event: SQSEvent, context: Context): Promise<SQSBatchResponse> => {
  logger.appendKeys({
    awsRequestId: context.awsRequestId,
  });

  const failures: SQSBatchItemFailure[] = [];

  for (const record of event.Records) {
    const { event, userId, workoutId } = parseBody(record.body);

    logger.appendKeys({ userId, workoutId, event });

    const workoutResp = await getWorkout({ userId, workoutId });
    if (workoutResp.error) {
      logger.error(`Failed to fetch raw workout from db`, { error: workoutResp.error });
      failures.push({
        itemIdentifier: record.messageId,
      });
      continue;
    }

    logger.info(`Isolating workout`);

    const isolateStart = Date.now();
    const isolateResp = await openAIService.isolateWorkout({ rawWorkout: workoutResp.item.rawWorkout });
    if (isolateResp.error) {
      logger.error('Failed to isolate workout using OpenAI', { error: isolateResp.error.message });
      failures.push({
        itemIdentifier: record.messageId,
      });
      metrics.addMetric('failedIsolate', MetricUnits.Count, 1);
      continue;
    }
    metrics.addMetric('isolateDuration', MetricUnits.Seconds, (Date.now() - isolateStart) / 1000);
    metrics.addMetric('successfulIsolate', MetricUnits.Count, 1);

    const formatStart = Date.now();
    const formatResponse = await openAIService.formatWorkout(isolateResp.workout);
    if (formatResponse.error) {
      logger.error('Failed to format workout using OpenAI', { error: formatResponse.error });
      failures.push({
        itemIdentifier: record.messageId,
      });
      metrics.addMetric('failedFormat', MetricUnits.Count, 1);
      continue;
    }
    metrics.addMetric('formatDuration', MetricUnits.Seconds, (Date.now() - formatStart) / 1000);

    // separating empty errors from other errors for now
    if (formatResponse.empty) {
      logger.warn(`Formatted empty workout`, { error: 'empty workout' });
      metrics.addMetric('failedFormat', MetricUnits.Count, 1);
      metrics.addMetric('emptyFormat', MetricUnits.Count, 1);
      try {
        await queueService.sendMessage(process.env.FORMATTER_QUEUE_URL ?? '', record.body);
        continue;
      } catch (error) {
        logger.error('Failed to requeue workout', { error });
        await slackService.sendMessage({ text: `*Failed to requeue empty workout*\nUser: ${userId}\nWorkout: ${workoutId}` });
      }
    } else {
      metrics.addMetric('successfulFormat', MetricUnits.Count, 1);
      logger.info(`Formatted workout`);
    }

    const saveResponse = await updateWorkout({
      userId,
      workoutId: workoutId,
      formattedCompletionId: formatResponse.completionId,
      formattedWorkout: formatResponse.workout,
      gptStatus: GPTStatus.COMPLETE,
    });
    if (saveResponse.error) {
      logger.error('Failed to update workout with formatted response', { error: saveResponse.error });
      failures.push({
        itemIdentifier: record.messageId,
      });
      continue;
    }

    logger.info(`Saved formatted workout`);
  }

  if (failures.length) {
    logger.error('Failed to format some workouts', { failures });
  }
  metrics.publishStoredMetrics();
  return {
    batchItemFailures: failures,
  };
};
