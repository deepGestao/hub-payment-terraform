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
  default     = "hub-payment-subscription"
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
    MERCADO_PAGO_ACCESS_TOKEN = "TEST-1624473749863466-091818-4bc1fc34b9f2127364d6367b1ce33179-1497578571"
    MERCADO_PAGO_CLIENT_ID = "912101250944479"
    MERCADO_PAGO_CLIENT_SECRET = "LQ4QNmFmf3H8hGNCvcfF4PKMsRNL9GhN"
  }
}

variable "api_name" {
  description = "The API name"
  default = "hub-payment"
}