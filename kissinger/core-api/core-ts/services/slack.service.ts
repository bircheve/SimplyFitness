import fetch from 'node-fetch';

interface SlackConfig {
  webhookUrl: string;
}

interface SlackMessage {
  text: string;
  channel?: string;
  username?: string;
}

export interface ISlackService {
  sendMessage(message: SlackMessage): Promise<void>;
}

export class SlackService implements ISlackService {
  private webhookUrl: string;
  constructor(config: SlackConfig) {
    this.webhookUrl = config.webhookUrl;
  }

  async sendMessage(message: SlackMessage): Promise<void> {
    const response = await fetch(this.webhookUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(message)
    });

    if (!response.ok) {
      console.error(`Failed to send Slack message: ${response.statusText}`);
    }
  }
}
