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

variable "api_name" {
  description = "The api name"
  default = "hub-payment"
}