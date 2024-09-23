terraform {
  backend "s3" {
    bucket = "hub-payment-140023362908-terraform"
    region = "us-east-2"
    key    = "sqs/hub-payment-orders-to-process/dev"
  }
}

provider "aws" {
  region = var.aws_region
}

resource "aws_sqs_queue" "sqs" {
  name                      = "${var.queue_name}-${var.aws_env}"
  message_retention_seconds = var.message_retention_seconds
  sqs_managed_sse_enabled = true
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Id" : "__default_policy_ID",
    "Statement" : [
      {
        "Sid" : "__owner_statement",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "${var.aws_account}"
        },
        "Action" : [
          "SQS:*"
        ],
        "Resource" : "arn:aws:sqs:us-east-2:${var.aws_account}:${var.queue_name}-${var.aws_env}"
      }
    ]
  })
}
