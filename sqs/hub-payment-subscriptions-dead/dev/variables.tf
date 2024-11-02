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

variable "queue_name" {
  description = "The queue name"
  default     = "hub-payment-subscriptions-dead"
}

variable "message_retention_seconds" {
  description = "The retention in seconds"
  default = 480
}
