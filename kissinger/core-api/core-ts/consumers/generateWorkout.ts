import { Context, SQSBatchItemFailure, SQSBatchResponse, SQSEvent } from 'aws-lambda';
import { Logger } from '@aws-lambda-powertools/logger';
import { Metrics, MetricUnits } from '@aws-lambda-powertools/metrics';
import { OpenAIService } from '../openai';
import { createWorkout, getStoryByUserId } from '../data';
import { CompletionStatus, GPTStatus } from '../data/model';
import { ChatCompletionRequestMessage } from 'openai';
import { GenerateWorkoutEvent, SystemPrompt } from '../openai/systemPrompt';
import { deleteWorkout } from '../data/deleteWorkout';
import { QueueService } from '../services';

const logger = new Logger({ serviceName: 'generate-workout-consumer' });
const metrics = new Metrics({ serviceName: 'generate-workout-consumer' });
const openAIService = new OpenAIService({ logger });
const queueService = new QueueService();

type SQSMessageBody = {
  userId: string;
  event: 'typeform.processed' | 'workout.completed' | 'workout.remixed';
  workoutId?: string;
};

// TODO: add schema validation middleware with joi or class-validator
const parseBody = (body: string): SQSMessageBody => {
  return JSON.parse(body);
};

export const buildChatHistory = (event: GenerateWorkoutEvent, history: any[]): ChatCompletionRequestMessage[] => {
  let messages = history.map((item) => {
    let message: ChatCompletionRequestMessage = { role: 'user', content: '' };
    switch (item.entity) {
      case 'story':
        message = { role: item.chatRole || 'user', content: item.prompt };
        break;
      case 'workout':
        if (event !== GenerateWorkoutEvent.WORKOUT_REMIXED && item.status !== CompletionStatus.COMPLETE) return; // skip workouts that aren't completed
        message = { role: item.chatRole ?? 'assistant', content: JSON.stringify(item.rawWorkout ?? item.workout) };
        break;
      case 'feedback':
        message = { role: item.chatRole ?? 'user', content: item.message };
        break;
      case 'remix':
        if (event !== GenerateWorkoutEvent.WORKOUT_REMIXED) return; // skip remixes for other events (e.g. workout completed)
        message = { role: item.chatRole ?? 'user', content: item.message };
        break;
      default:
        message = { role: 'user', content: JSON.stringify(item) };
    }

    return message;
  }).filter((item) => item);

  // Reverse sort order for everything after the story (first message)
  // Story is always first message + (feedback|workout|remix) in reverse order
  if (messages.length > 1) {
    for (let i = 1, j = messages.length - 1; i < j; i++, j--) {
      [messages[i], messages[j]] = [messages[j], messages[i]];
    }
  }

  const systemPrompt = new SystemPrompt();

  return [systemPrompt.message, ...messages as ChatCompletionRequestMessage[]];
};

export const handler = async (event: SQSEvent, context: Context): Promise<SQSBatchResponse> => {
  logger.appendKeys({
    awsRequestId: context.awsRequestId,
  });

  const failures: SQSBatchItemFailure[] = [];

  for (const record of event.Records) {
    const body = parseBody(record.body);
    const userId = body.userId;

    logger.appendKeys({ userId, event: body.event });

    const storyResp = await getStoryByUserId({ userId });
    if (storyResp.error) {
      logger.error(`Failed to fetch story for ${userId}`, { error: storyResp.error });
      failures.push({
        itemIdentifier: record.messageId,
      });
      continue;
    }
    const hasWorkoutPending = storyResp.records.some((record) => record.gptStatus === GPTStatus.PENDING);
    if (hasWorkoutPending) {
      logger.info(`${userId} has workout pending, skipping`);
      continue;
    }

    // create partial workout record in dynamodb to prevent duplicate work
    const partial = await createWorkout({ userId, workout: {}, gptStatus: GPTStatus.PENDING });
    if (partial.error) {
      logger.warn('Failed to create partial workout record, this may result in multiple workouts', {
        error: partial.error,
      });
    }

    let messages = buildChatHistory(body.event as GenerateWorkoutEvent, storyResp.records);
    logger.info(`story length: ${storyResp.records.length}, messages length: ${messages.length}`);

    logger.info(`Generating workout`);

    // fetch raw workout from openai
    const start = Date.now();
    const workoutResponse = await openAIService.generateWorkout(messages);
    if (workoutResponse.error) {
      logger.error('Failed to fetch workout from OpenAI', { error: workoutResponse.error });
      const deleteResp = await deleteWorkout({ userId, workoutId: partial.workoutId });
      if (deleteResp.error) {
        logger.error('Failed to delete failed workout record', { error: deleteResp.error });
      }
      failures.push({
        itemIdentifier: record.messageId,
      });
      metrics.addMetric('failedGenerate', MetricUnits.Count, 1)
      continue;
    }
    metrics.addMetric('generateDuration', MetricUnits.Seconds, (Date.now() - start) / 1000);
    metrics.addMetric('successfulGenerate', MetricUnits.Count, 1)
    logger.info(`Generated workout`);

    // save workout to dynamodb
    const saveResponse = await createWorkout({
      userId,
      workout: workoutResponse.workout,
      rawWorkoutContent: workoutResponse.rawWorkout,
      id: partial.workoutId,
      gptStatus: GPTStatus.PENDING, // update to COMPLETE once formatter is done
      chatCompletionId: workoutResponse.completionId,
    });
    if (saveResponse.error) {
      logger.error('Failed to save workout to DynamoDB', { error: saveResponse.error });
      failures.push({
        itemIdentifier: record.messageId,
      });
      continue;
    }

    // push workout to format queue
    const message = { workoutId: saveResponse.workoutId, userId, event: body.event };
    try {
      logger.info(`Sending workout to formatter queue`);
      await queueService.sendMessage(process.env.FORMATTER_QUEUE_URL ?? '', JSON.stringify(message));
    } catch (error) {
      logger.error(`Failed to send workout to formatter queue`, { error });
    }
  }

  if (failures.length) {
    logger.error('Failed to process some records', { failures });
  }
  metrics.publishStoredMetrics();
  return {
    batchItemFailures: failures,
  };
};
