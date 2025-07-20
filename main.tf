provider "aws" {
  region = "us-east-1"
}

# IAM for lambda
resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda_exec_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# IAM Lambda Policy Attachment
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# IAM for BedRock
resource "aws_iam_policy" "bedrock_invoke_model" {
  name        = "AllowInvokeBedrockModel"
  description = "Allows Lambda to invoke Amazon Bedrock LLM models"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "bedrock:InvokeModel"
        ],
        Resource = "arn:aws:bedrock:us-east-1::foundation-model/anthropic.claude-3-sonnet-20240229-v1:0"
      }
    ]
  })
}

# IAM BedRock Policy Attachment
resource "aws_iam_role_policy_attachment" "attach_bedrock_policy" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.bedrock_invoke_model.arn
}


# Lambda Function Definition
resource "aws_lambda_function" "llm_wrapper" {
  function_name    = "llm-lambda"
  runtime          = "python3.8"
  handler          = "lambda.llm_handler"
  role             = aws_iam_role.lambda_exec_role.arn
  filename         = "lambda.zip"
  source_code_hash = filebase64sha256("lambda.zip")
  timeout          = 30
}

# API Gateway
resource "aws_apigatewayv2_api" "http_api" {
  name          = "llm-api"
  protocol_type = "HTTP"
}

# Lambda API Permission
resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.llm_wrapper.arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}

# API Lambda Integration
resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id                 = aws_apigatewayv2_api.http_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.llm_wrapper.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

# API Lambda Routing
resource "aws_apigatewayv2_route" "default_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "POST /chat"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

# Deployment
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "$default"
  auto_deploy = true
}

# API Output Endpoint
output "api_endpoint" {
  value = aws_apigatewayv2_api.http_api.api_endpoint
}