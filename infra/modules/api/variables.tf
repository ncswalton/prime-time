variable "api_name" {
  description = "The name of the API"
  type        = string
}
variable "function_name" {
  description = "The name of the Lambda function"
  type        = string
}
variable "bucket_name" {
  description = "The name of the S3 bucket"
  type        = string
}
variable "stage_name" {
  description = "The name of the stage"
  type        = string
}
variable integration_uri {
  description = "The URI of the integration"
  type        = string
}