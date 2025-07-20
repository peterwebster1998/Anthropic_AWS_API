import json
import boto3

bedrock = boto3.client("bedrock-runtime", region_name="us-east-1")
model_id = "anthropic.claude-3-sonnet-20240229-v1:0"

def llm_handler(event, context):
    try:
        body = json.loads(event.get("body", "{}"))
        messages = body.get("messages", [])
        response = bedrock.invoke_model(
            modelId = model_id,
            contentType = "application/json",
            accept = "application/json",
            body = json.dumps({
                "messages": messages,
                "anthropic_version": "bedrock-2023-05-31",
                "max_tokens": 1000,
                "temperature": 0.3
            })
        )
        # Read the response body
        response_body = json.loads(response['body'].read())
        
        return {
            "statusCode": 200,
            "body": json.dumps(response_body)
        }
    except Exception as e:
        return {
            "statusCode": 500,
            "body": json.dumps({"error": str(e)})
        }
