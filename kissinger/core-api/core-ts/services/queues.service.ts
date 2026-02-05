import { SQS } from 'aws-sdk';

interface IQueueService {
  sendMessage(queueUrl: string, message: string): Promise<SQS.SendMessageResult>;
}

export class QueueService implements IQueueService {
  private sqs: SQS;
  constructor(sqs?: SQS) {
    this.sqs = sqs ?? new SQS();
  }

  public async sendMessage(queueUrl: string, message: string): Promise<SQS.SendMessageResult> {
    const params = {
      MessageBody: message,
      QueueUrl: queueUrl,
    };
    return this.sqs.sendMessage(params).promise();
  }
}