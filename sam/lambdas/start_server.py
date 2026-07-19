import boto3
import os

ec2 = boto3.client("ec2")
INSTANCE_ID = os.environ["INSTANCE_ID"]
API_KEY = os.environ.get("API_KEY", "")

def lambda_handler(event, context):
    # Optional API Key authentication check
    if API_KEY:
        params = event.get("queryStringParameters") or {}
        headers = event.get("headers") or {}
        provided_key = headers.get("x-api-key") or params.get("key")
        if provided_key != API_KEY:
            return {
                "statusCode": 401,
                "body": "Unauthorized: Invalid API Key"
            }

    ec2.start_instances(InstanceIds=[INSTANCE_ID])
    return {
        "statusCode": 200,
        "body": "Minecraft server starting"
    }

