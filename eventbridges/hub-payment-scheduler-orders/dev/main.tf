terraform {
  backend "s3" {
    bucket = "hub-payment-140023362908-terraform"
    region = "us-east-2"
    key    = "eventbridges/hub-payment-scheduler-orders/dev"
  }
}

provider "aws" {
  region = var.aws_region
}

resource "aws_cloudwatch_event_connection" "conn" {
  name               = "${var.api_destination_name}-${var.aws_env}"
  authorization_type = "API_KEY"

  auth_parameters {
    api_key {
      key   = "x-signature"
      value = "1234"
    }
  }
}

data "aws_sqs_queue" "sqs" {
  name = "${var.queue_name}-${var.aws_env}"
}

resource "aws_cloudwatch_event_api_destination" "api_destination" {
  name                             = "${var.api_destination_name}-${var.aws_env}"
  description                      = "An API Destination"
  invocation_endpoint              = var.api_destination_endpoint
  http_method                      = "POST"
  invocation_rate_limit_per_second = 20
  connection_arn                   = aws_cloudwatch_event_connection.conn.arn
}

resource "aws_cloudwatch_event_rule" "rule" {
  name = "${var.api_destination_name}-${var.aws_env}"
  event_pattern = jsonencode({
    source = [
      "${var.api_destination_name}-${var.aws_env}"
    ]
  })
}

resource "aws_cloudwatch_event_target" "target" {
  target_id = "InvokeLambda"
  arn       = aws_cloudwatch_event_api_destination.api_destination.arn
  rule      = aws_cloudwatch_event_rule.rule.name
  role_arn  = aws_iam_role.role.arn
  retry_policy {
    maximum_event_age_in_seconds = var.max_age_retry
    maximum_retry_attempts       = var.max_number_retry
  }
  dead_letter_config {
    arn = data.aws_sqs_queue.sqs.arn
  }
}

resource "aws_iam_role" "role" {
  name = "eventbridge-${var.api_destination_name}-role-${var.aws_env}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_policy" "policy" {
  name = "eventbridge-${var.api_destination_name}-policy-${var.aws_env}"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Effect" : "Allow",
        "Action" : "events:InvokeApiDestination",
        "Resource" : "arn:aws:events:${var.aws_region}:${var.aws_account}:api-destination/${var.api_destination_name}-${var.aws_env}/*"
      },
      {
        "Effect" : "Allow",
        "Action" : "sqs:SendMessage",
        "Resource" : "arn:aws:sqs:${var.aws_region}:${var.aws_account}:${var.queue_name}-${var.aws_env}"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attachment" {
  role       = aws_iam_role.role.name
  policy_arn = aws_iam_policy.policy.arn
}
