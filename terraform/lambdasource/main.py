import json
import os
from google.oauth2 import id_token
from google.auth.transport import requests

GOOGLE_CLIENT_ID = os.environ["GOOGLE_CLIENT_ID"]

def lambda_handler(event, context):
    token = event['headers']["authorization"].replace("Bearer ", "")

    try:
        # Validate the Google OAuth2 token
        id_info = id_token.verify_oauth2_token(token, requests.Request(), GOOGLE_CLIENT_ID)

        # Return an IAM policy allowing access
        return {
            "principalId": id_info["sub"],
            "policyDocument": {
                "Version": "2012-10-17",
                "Statement": [
                    {
                        "Action": "execute-api:Invoke",
                        "Effect": "Allow",
                        "Resource": event["routeArn"]
                    }
                ]
            },
            "context": {
                "userId": id_info["sub"],
                "email": id_info["email"]
            }
        }
    except Exception as e:
        print(f'Error: {str(e)}')
        # Token validation failed
        return {
            "principalId": "user",
            "policyDocument": {
                "Version": "2012-10-17",
                "Statement": [
                    {
                        "Action": "execute-api:Invoke",
                        "Effect": "Deny",
                        "Resource": event['routeArn']
                    }
                ]
            }
        }