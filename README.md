<p align="center">
  <img src="docs/images/Simplyfit_Logo-Horizontal.png" alt="SimplyFit Logo" width="400">
</p>

<p align="center">
  <img src="https://img.shields.io/badge/iOS-16.0+-000000?style=flat&logo=apple&logoColor=white" alt="iOS">
  <img src="https://img.shields.io/badge/Swift-5.0-FA7343?style=flat&logo=swift&logoColor=white" alt="Swift">
  <img src="https://img.shields.io/badge/AWS-SAM-FF9900?style=flat&logo=amazon-aws&logoColor=white" alt="AWS SAM">
  <img src="https://img.shields.io/badge/Python-3.9-3776AB?style=flat&logo=python&logoColor=white" alt="Python">
  <img src="https://img.shields.io/badge/TypeScript-5.0-3178C6?style=flat&logo=typescript&logoColor=white" alt="TypeScript">
</p>

An AI-powered fitness application that creates personalized workout plans based on user preferences, fitness goals, and available equipment. The app combines a native iOS frontend with a serverless AWS backend to deliver customized fitness experiences.

## Architecture

### iOS App (`simplyfit/`)
- **SwiftUI** - Modern declarative UI framework
- **AWS Amplify** - Authentication, API integration, and cloud services
- **Combine** - Reactive programming for state management
- **Async/Await** - Modern Swift concurrency patterns

### Backend (`kissinger/`)
- **AWS SAM** - Infrastructure as Code for serverless deployment
- **AWS Lambda** - Serverless compute (Python & TypeScript)
- **Amazon DynamoDB** - NoSQL database with single-table design
- **Amazon Cognito** - User authentication and authorization
- **Amazon SQS** - Message queuing for async workout generation
- **OpenAI API** - AI-powered workout plan generation

## Project Structure

```
SimplyFitness/
├── simplyfit/                    # iOS Application
│   ├── simplyFit/
│   │   ├── Views/               # SwiftUI views
│   │   ├── Models/              # Data models
│   │   ├── Utilities/           # Helper classes
│   │   └── Resources/           # Assets and config
│   ├── amplify/                 # AWS Amplify configuration
│   └── simplyFit.xcodeproj/     # Xcode project
│
└── kissinger/                    # Backend Services
    ├── db/                      # DynamoDB table definitions
    ├── typeform-webhook/        # Python Lambda - Typeform integration
    │   └── webhook-handler/     # Webhook processing logic
    └── core-api/                # TypeScript API
        └── core-ts/
            ├── workout-handlers/  # Workout CRUD operations
            ├── consumers/         # SQS message processors
            ├── data/              # DynamoDB data access layer
            ├── openai/            # OpenAI integration
            └── services/          # Shared business logic
```

## Key Technical Highlights

### iOS Application
- **Modern Swift Concurrency**: Utilizes async/await patterns throughout the codebase
- **Reactive State Management**: Combines SwiftUI's state management with Combine publishers
- **AWS Amplify Integration**: Seamless authentication flow with Cognito
- **Custom UI Components**: Reusable SwiftUI components for consistent design

### Backend Services
- **Single-Table DynamoDB Design**: Efficient data access patterns with composite keys
- **Event-Driven Architecture**: SQS-based message processing for async operations
- **AI Integration**: OpenAI API integration for generating personalized workout plans
- **Lambda Powertools**: Structured logging, tracing, and metrics
- **Multi-Stack SAM Deployment**: Modular infrastructure with nested stacks

### Data Flow
1. User completes fitness questionnaire (via Typeform)
2. Webhook handler processes submission and stores user story
3. Message sent to SQS queue to trigger workout generation
4. Workout generator calls OpenAI API with user context
5. Generated workout stored in DynamoDB
6. iOS app fetches personalized workouts via authenticated API

## App Preview

<p align="center">
  <img src="docs/images/SimplyFit-AppIcon-1024.png" alt="SimplyFit App Icon" width="200">
</p>

*Additional screenshots coming soon*

## Getting Started

### Prerequisites
- Xcode 14.0+
- iOS 16.0+ device or simulator
- AWS CLI configured with appropriate credentials
- AWS SAM CLI
- Node.js 18+
- Python 3.9+

### iOS App Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/SimplyFitness.git
   cd SimplyFitness
   ```

2. Install dependencies:
   ```bash
   cd simplyfit
   pod install  # if using CocoaPods
   ```

3. Configure Amplify:
   ```bash
   amplify init
   amplify push
   ```

4. Open `simplyFit.xcworkspace` in Xcode

5. Configure required credentials (see Configuration section)

6. Build and run on simulator or device

### Backend Setup

1. Navigate to backend directory:
   ```bash
   cd kissinger
   ```

2. Install dependencies:
   ```bash
   cd core-api/core-ts && npm install
   ```

3. Build the SAM application:
   ```bash
   sam build
   ```

4. Deploy to AWS:
   ```bash
   sam deploy --guided
   ```

## Configuration

The following credentials and identifiers need to be configured:

| Variable | File | Description |
|----------|------|-------------|
| `YOUR_INTERCOM_API_KEY` | `AppDelegate.swift` | Intercom SDK API key |
| `YOUR_INTERCOM_APP_ID` | `AppDelegate.swift` | Intercom application ID |
| `YOUR_SEGMENT_WRITE_KEY` | `AnalyticsManager.swift` | Segment analytics write key |
| `YOUR_SLACK_WEBHOOK_URL_HERE` | `PlaylistView.swift`, `app.py` | Slack webhook for notifications |
| `YOUR_COGNITO_USER_POOL_ID` | `samconfig.toml` files | AWS Cognito User Pool ID |
| `YOUR_AWS_ACCOUNT_ID` | `samconfig.toml` files | AWS Account ID |
| `YOUR_TYPEFORM_FORM_ID` | `samconfig.toml` files | Typeform form identifier |

### AWS SSM Parameters

The following parameters should be stored in AWS Systems Manager Parameter Store:
- `/simplyfit/env/open-ai-api-key` - OpenAI API key
- `typeformSecret` - Typeform webhook verification secret
- `slackWebhookUrl` - Slack webhook URL for notifications

## Development

### Running Tests

**Backend (TypeScript)**:
```bash
cd kissinger/core-api/core-ts
npm run test
```

**Backend (Python)**:
```bash
cd kissinger/typeform-webhook
pytest
```

### Local Development

Start the local API:
```bash
cd kissinger
sam local start-api
```

## Team

Built by the SimplyFit team.

## License

MIT License

Copyright (c) 2023 SimplyFit

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
