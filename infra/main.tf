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

module "storage" {
  source = "./modules/storage"
  bucket_name = var.bucket_name
  ip_address = var.ip_to_allow
}

module "lambda" {
  source = "./modules/lambda"
  function_name = var.lambda_function_name
  api_execution_arn = module.api.execution_arn
}

module "api" {
  source = "./modules/api"
  api_name = var.api_name
  stage_name = var.stage_name
  function_name = module.lambda.function_name
  bucket_name = module.storage.bucket_name
  integration_uri = module.lambda.invoke_url
}