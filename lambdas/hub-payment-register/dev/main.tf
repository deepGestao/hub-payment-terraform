terraform {
  backend "s3" {
    bucket = "hub-payment-140023362908-terraform"
    region = "us-east-2"
    key    = "lambdas/hub-payment-register/dev"
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
      MERCADO_PAGO_REGISTER      = "https://api.mercadopago.com/v1/customers"
      MERCADO_PAGO_OAUTH         = "https://api.mercadopago.com/oauth/token"
      MERCADO_PAGO_CLIENT_ID     = "${var.env["MERCADO_PAGO_CLIENT_ID"]}"
      MERCADO_PAGO_CLIENT_SECRET = "${var.env["MERCADO_PAGO_CLIENT_SECRET"]}"
      AWS_ENV                    = var.aws_env
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
          "dynamodb:PutItem",
        ]
        Resource = "arn:aws:dynamodb:${var.aws_region}:${var.aws_account}:table/hub-payment-customers-${var.aws_env}"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_custom_policy.arn
}

data "aws_api_gateway_rest_api" "api" {
  name = "${var.api_name}-${var.aws_env}"
}

resource "aws_api_gateway_resource" "resource" {
  rest_api_id = data.aws_api_gateway_rest_api.api.id
  parent_id = data.aws_api_gateway_rest_api.api.root_resource_id
  path_part = "register"
}

resource "aws_api_gateway_method" "method" {
  rest_api_id   = data.aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "integration" {
  rest_api_id             = data.aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.resource.id
  http_method             = aws_api_gateway_method.method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.my_lambda.invoke_arn
}

resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = data.aws_api_gateway_rest_api.api.id
  triggers = {
    redeployment = sha1(jsonencode([
        aws_api_gateway_resource.resource.id,
        aws_api_gateway_method.method.id,
        aws_api_gateway_integration.integration.id,
    ]))
  }
}

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.my_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "arn:aws:execute-api:${var.aws_region}:${var.aws_account}:${data.aws_api_gateway_rest_api.api.id}/*/${aws_api_gateway_method.method.http_method}${aws_api_gateway_resource.resource.path}"
}