terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = ">= 3.56.0"
    }
  }
  required_version = ">= 0.14.9"
}

provider "aws" {
  region = "us-east-2"
}

# REST API Gateway
resource "aws_api_gateway_rest_api" "api" {
  name          = var.api_name
  # protocol_type = "REST"
}

# main API resource
resource "aws_api_gateway_resource" "cors_resource" {
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "PrimeGen"
  rest_api_id = aws_api_gateway_rest_api.api.id
}

# OPTIONS method for CORS
resource "aws_api_gateway_method" "options_method" {
    rest_api_id   = "${aws_api_gateway_rest_api.api.id}"
    resource_id   = "${aws_api_gateway_resource.cors_resource.id}"
    http_method   = "OPTIONS"
    authorization = "NONE"
}

# options method response
resource "aws_api_gateway_method_response" "options_200" {
  rest_api_id   = "${aws_api_gateway_rest_api.api.id}"
  resource_id   = "${aws_api_gateway_resource.cors_resource.id}"
  http_method   = "${aws_api_gateway_method.options_method.http_method}"
  status_code   = "200"
  response_models = {
    "application/json" = "Empty"
  }
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin" = true
  }
  depends_on = [aws_api_gateway_method.options_method]
}

# mock integration for OPTIONS method
resource "aws_api_gateway_integration" "options_integration" {
    rest_api_id   = "${aws_api_gateway_rest_api.api.id}"
    resource_id   = "${aws_api_gateway_resource.cors_resource.id}"
    http_method   = "${aws_api_gateway_method.options_method.http_method}"
    type          = "MOCK"
    depends_on = [aws_api_gateway_method.options_method]
}

# integration response for OPTIONS
resource "aws_api_gateway_integration_response" "options_integration_response" {
    rest_api_id   = "${aws_api_gateway_rest_api.api.id}"
    resource_id   = "${aws_api_gateway_resource.cors_resource.id}"
    http_method   = "${aws_api_gateway_method.options_method.http_method}"
    status_code   = "${aws_api_gateway_method_response.options_200.status_code}"
    response_parameters = {
        "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
        "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'",
        "method.response.header.Access-Control-Allow-Origin" = "'*'"
    }
    depends_on = [aws_api_gateway_method_response.options_200]
}

# POST method for S3
resource "aws_api_gateway_method" "cors_method" {
    rest_api_id   = "${aws_api_gateway_rest_api.api.id}"
    resource_id   = "${aws_api_gateway_resource.cors_resource.id}"
    http_method   = "POST"
    authorization = "NONE"
}

# POST method response
resource "aws_api_gateway_method_response" "cors_method_response_200" {
    rest_api_id   = "${aws_api_gateway_rest_api.api.id}"
    resource_id   = "${aws_api_gateway_resource.cors_resource.id}"
    http_method   = "${aws_api_gateway_method.cors_method.http_method}"
    status_code   = "200"
    response_parameters = {
        "method.response.header.Access-Control-Allow-Origin" = true
    }
    depends_on = [aws_api_gateway_method.cors_method]
}

# POST method integration to Lambda
resource "aws_api_gateway_integration" "integration" {
  type = "AWS_PROXY"
  resource_id = aws_api_gateway_resource.cors_resource.id
  rest_api_id= aws_api_gateway_rest_api.api.id
  http_method = "POST"
  integration_http_method = "POST"
  uri  = var.integration_uri
  depends_on = [ aws_api_gateway_method.cors_method ]
}

# API deployment
resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name = "Dev"
  depends_on = [ aws_api_gateway_integration.integration ]
}

output "invoke_url" {
  value = "https://${aws_api_gateway_rest_api.api.id}.execute-api.us-east-2.amazonaws.com"
}

output execution_arn {
  value = aws_api_gateway_rest_api.api.execution_arn
}