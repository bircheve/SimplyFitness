#!/usr/bin/env sh

export OPEN_AI_API_KEY=$(aws ssm get-parameter --name /simplyfit/env/open-ai-api-key --query Parameter.Value --output text --profile default)
export STORY_TABLE=Story-dev

npm run compile
cd ..
sam build
sam local invoke GenerateWorkoutConsumerFunction -e events/sqs-event.json --profile default
