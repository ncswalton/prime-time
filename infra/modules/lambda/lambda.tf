provider "aws" {
  region = "us-east-2"
}


resource "aws_lambda_function" "lambda" {
  function_name = var.function_name
  filename      = "../package/lambda_function.zip"
  source_code_hash = filebase64sha256("../package/lambda_function.zip")
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.11"
  role          = aws_iam_role.lambda.arn

  memory_size = 1024
  timeout     = 60

  tags = {
    deployedOn = "feb26-2024"
  }

  tracing_config {
    mode = "PassThrough"
  }
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${var.api_execution_arn}/*/*"
}

resource "aws_iam_role" "lambda" {
  name = "lambda_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_cloudwatch_log_group" "log_group" {
  name              = "/aws/lambda/primeGenTest"
  retention_in_days = 14
}

resource "aws_iam_role_policy" "lambda" {
  name = "lambda"
  role = aws_iam_role.lambda.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*"
    }
  ]
}
EOF
}

output "function_name" {
  value = aws_lambda_function.lambda.function_name
}

output invoke_url {
  value = aws_lambda_function.lambda.invoke_arn
}
