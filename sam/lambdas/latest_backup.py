import boto3
import os
from botocore.config import Config

BUCKET = os.environ["BUCKET_NAME"]
REGION = os.environ["AWS_REGION"]
API_KEY = os.environ.get("API_KEY", "")

config = Config(
    signature_version="s3v4",
    s3={"addressing_style": "virtual"}
)

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

    s3 = boto3.client("s3", region_name=REGION, config=config)

    response = s3.list_objects_v2(Bucket=BUCKET)

    contents = response.get("Contents", [])
    if not contents:
        return {
            "statusCode": 404,
            "body": "No backups found"
        }

    latest = sorted(
        contents,
        key=lambda x: x["LastModified"],
        reverse=True
    )[0]

    key = latest["Key"]

    url = s3.generate_presigned_url(
        "get_object",
        Params={
            "Bucket": BUCKET,
            "Key": key
        },
        ExpiresIn=600
    )

    return {
        "statusCode": 302,
        "headers": {
            "Location": url
        }
    }
