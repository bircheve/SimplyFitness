import { CognitoIdentityServiceProvider } from 'aws-sdk';

export class CognitoService {
  private cognitoClient: CognitoIdentityServiceProvider;
  private userPoolId: string;

  constructor(userPoolId: string) {
    this.cognitoClient = new CognitoIdentityServiceProvider();
    this.userPoolId = userPoolId;
  }

  async getUserBySub(sub: string): Promise<CognitoIdentityServiceProvider.AdminGetUserResponse> {
    const params: CognitoIdentityServiceProvider.AdminGetUserRequest = {
      UserPoolId: this.userPoolId,
      Username: sub
    };

    return this.cognitoClient.adminGetUser(params).promise();
  }
}

// Usage:
// const cognitoService = new CognitoService('YOUR_USER_POOL_ID');

// cognitoService.getUserBySub('USER_SUB').then(response => {
//     console.log('User details:', response);
// }).catch(error => {
//     console.error('Error fetching user:', error);
// });
