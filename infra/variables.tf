variable "bucket_name" {
  description = "The name of the S3 bucket to be deployed."
  type        = string
}
variable "ip_to_allow" {
  description = "The IP to allow for S3 access."
  type        = string
}
variable "lambda_function_name" {
  description = "The name of the lambda function to be deployed."
  type        = string
}
variable "api_name" {
  description = "The name of the API Gateway to be deployed."
  type        = string
}
variable "stage_name" {
  description = "The name of the stage to be deployed."
  type        = string
}
