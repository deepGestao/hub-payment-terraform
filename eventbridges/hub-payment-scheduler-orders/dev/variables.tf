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

variable "api_destination_name" {
  description = "The API destination Name"
  default     = "hub-payment-scheduler-orders"
}

variable "api_destination_endpoint" {
  description = "The API destination Name"
  default     = "https://xh3ugyslej.execute-api.us-east-2.amazonaws.com/dev/scheduler"
}

variable "max_age_retry" {
  default = 86400
}

variable "max_number_retry" {
  default = 1
}

variable "queue_name" {
  default = "hub-payment-scheduler-dead"
}