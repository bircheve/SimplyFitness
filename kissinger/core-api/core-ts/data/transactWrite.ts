import { DynamoDB } from 'aws-sdk';
import { clientOptions } from './clientOptions';

export type ExecuteTransactionRequest = {
  transactionItems: DynamoDB.DocumentClient.TransactWriteItem[];
}

export type ExecuteTransactionResponse = {
  error?: Error;
}

const dynamoDb = new DynamoDB.DocumentClient(clientOptions);

export const executeWriteTransaction = async (input: ExecuteTransactionRequest): Promise<ExecuteTransactionResponse> => {
  try {
    await dynamoDb.transactWrite({ TransactItems: input.transactionItems }).promise();
    return {}
  } catch (error) {
    return { error: error as Error };
  }
};
