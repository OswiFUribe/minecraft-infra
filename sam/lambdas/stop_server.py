import boto3
import os

INSTANCE_ID = os.environ["INSTANCE_ID"]

def lambda_handler(event, context):
    ec2 = boto3.client("ec2")

    ec2.stop_instances(
        InstanceIds=[INSTANCE_ID]
    )

    return {
        "statusCode": 200,
        "body": "Server stopping"
    }
