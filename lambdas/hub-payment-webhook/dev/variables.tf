variable "aws_account" {
  description = "The AWS Account ID"
  default     = "140023362908"
}

variable "aws_env" {
  description = "The AWS Environment"
  default     = "dev"
}

variable "aws_region" {
  description = "The AWS region to deploy resources"
  default     = "us-east-2"
}

variable "lambda_function_name" {
  description = "The name of the Lambda function"
  default     = "hub-payment-webhook"
}

variable "s3_bucket_name" {
  description = "The S3 bucket where the Lambda code is stored"
  default     = "lambda-code"
}

variable "s3_key" {
  description = "The S3 key for the Lambda code ZIP file"
  default     = "dist.zip"
}

variable "lambda_runtime" {
  description = "The runtime environment for the Lambda function"
  default     = "nodejs18.x"
}

variable "memory_size" {
  description = "The memory size in MB for the Lambda Function"
  default     = 512
}

variable "timeout" {
  description = "The timeout in Seconds for the Lambda Function"
  default     = 30
}

variable "architectures" {
  description = "The Architecture for the Lambda Function"
  default     = "x86_64"
}

variable "env" {
  description = "Enviroment of lambda"
  default = {

  }
}

variable "api_name" {
  description = "The API name"
  default = "hub-payment"
}