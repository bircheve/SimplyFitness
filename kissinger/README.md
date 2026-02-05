# kissinger
This repo is the main backend for simply fit. It consists of three sub "stacks": the database layer, the webhook api, and the core internal api that the client app will talk to. 

There are two API Gateways due to the fact that auth is handled differently.


## Resources
`db` defines the database layer for the application.

`typeform-webhook` contains the APIGW and handler function for typeform submission webhook events. There is no authentication set on the API. Webhook verification is handled at the function level for now.

`core-api` contains the main application API and handler functions. Authentication is handled at the API layer and is based on the Cognito User Pool the application uses. This sub repo also contains the `generateWorkout` handler, responsible for requesting generated workouts from OpenAI via chat completions.

> :bangbang: **Authentication** was originally set up using Amplify and is defined in the simplyfit app repo. This app only takes the Cognito User Pool Ids as parameters during build/deployment.


## Deployment
The app is deployed as one root stack with nested stacks, meaning only the samconfig.toml file at the root of the project defines how the entire stack is deployed.