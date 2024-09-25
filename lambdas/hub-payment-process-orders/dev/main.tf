terraform {
  backend "s3" {
    bucket = "hub-payment-140023362908-terraform"
    region = "us-east-2"
    key    = "lambdas/hub-payment-process-orders/dev"
  }
}

provider "aws" {
  region = var.aws_region
}

resource "aws_lambda_function" "my_lambda" {
  function_name = "${var.lambda_function_name}-${var.aws_env}"
  timeout       = var.timeout
  memory_size   = var.memory_size
  architectures = ["${var.architectures}"]
  s3_bucket     = "${var.s3_bucket_name}-${var.aws_account}"
  s3_key        = "${var.aws_env}/${var.lambda_function_name}/${var.s3_key}"

  handler = "dist/index.handler"
  runtime = var.lambda_runtime

  environment {
    variables = {
      MERCADO_PAGO_PAYMENT       = "https://api.mercadopago.com/v1/payments"
      MERCADO_PAGO_OAUTH         = "https://api.mercadopago.com/oauth/token"
      MERCADO_PAGO_CLIENT_ID     = "${var.env["MERCADO_PAGO_CLIENT_ID"]}"
      MERCADO_PAGO_CLIENT_SECRET = "${var.env["MERCADO_PAGO_CLIENT_SECRET"]}"
      AWS_ENV                    = var.aws_env
      AWS_ACCOUNT                = var.aws_account
      MERCADO_PAGO_ACCESS_TOKEN  = "${var.env["MERCADO_PAGO_ACCESS_TOKEN"]}"
    }
  }

  role = aws_iam_role.lambda_exec.arn
}

resource "aws_iam_role" "lambda_exec" {
  name = "${var.lambda_function_name}-role-${var.aws_env}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_policy" "lambda_custom_policy" {
  name        = "${var.lambda_function_name}-policy-${var.aws_env}"
  description = "A custom policy for Lambda function access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "arn:aws:s3:::${var.s3_bucket_name}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:DeleteItem",
          "dynamodb:PutItem",
        ]
        Resource = [
          "arn:aws:dynamodb:${var.aws_region}:${var.aws_account}:table/hub-payment-scheduler-queue-${var.aws_env}"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:UpdateItem"
        ]
        Resource = [
          "arn:aws:dynamodb:${var.aws_region}:${var.aws_account}:table/hub-payment-scheduler-status-${var.aws_env}"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : "events:PutEvents",
        "Resource" : "arn:aws:events:${var.aws_region}:${var.aws_account}:event-bus/default"
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = [
          "arn:aws:sqs:${var.aws_region}:${var.aws_account}:${var.queue_name}-${var.aws_env}"
        ]
      }
    ]
  })
}

data "aws_sqs_queue" "sqs" {
  name = "${var.queue_name}-${var.aws_env}"
}

resource "aws_lambda_permission" "sqs_invoke" {
  statement_id  = "AllowExecutionFromSQS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.my_lambda.function_name
  principal     = "sqs.amazonaws.com"
  source_arn    = data.aws_sqs_queue.sqs.arn
}

resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = data.aws_sqs_queue.sqs.arn
  function_name    = aws_lambda_function.my_lambda.function_name
  batch_size       = 1
  enabled          = true
}


resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_custom_policy.arn
}
