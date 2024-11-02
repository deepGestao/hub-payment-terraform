terraform {
  backend "s3" {
    bucket = "hub-payment-140023362908-terraform"
    region = "us-east-2"
    key    = "apigateways/hub-payment/dev"
  }
}

provider "aws" {
  region = var.aws_region
}

resource "aws_api_gateway_rest_api" "api" {
  name = "${var.api_name}-${var.aws_env}"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "resource" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "helth_check"
}

resource "aws_api_gateway_method" "method" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.resource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.resource.id
  http_method             = aws_api_gateway_method.method.http_method
  integration_http_method = "POST"
  type                    = "MOCK"
}

resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  triggers = {
    redeployment = sha1(jsonencode([
        aws_api_gateway_resource.resource.id,
        aws_api_gateway_method.method.id,
        aws_api_gateway_integration.integration.id,
    ]))
  }
}

resource "aws_api_gateway_stage" "stage" {
  deployment_id = aws_api_gateway_deployment.deployment.id
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name = var.aws_env
}

resource "aws_api_gateway_account" "demo" {
  cloudwatch_role_arn = aws_iam_role.cloudwatch.arn
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "cloudwatch" {
  name               = "apigateway-${var.api_name}-role-${var.aws_env}"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "cloudwatch" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents",
      "logs:GetLogEvents",
      "logs:FilterLogEvents",
    ]

    resources = ["*"]
  }
}
resource "aws_iam_role_policy" "cloudwatch" {
  name   = "apigateway-${var.api_name}-policy-${var.aws_env}"
  role   = aws_iam_role.cloudwatch.id
  policy = data.aws_iam_policy_document.cloudwatch.json
}

data "aws_lambda_function" "lambda_auth" {
  function_name = "hub-payment-auth-${var.aws_env}"
}

resource "aws_api_gateway_authorizer" "custom_auth" {
  name                   = "hub-payment-auth-${var.aws_env}"
  rest_api_id            = aws_api_gateway_rest_api.api.id
  authorizer_uri         = data.aws_lambda_function.lambda_auth.invoke_arn
  authorizer_credentials = aws_iam_role.invocation_role.arn
  identity_source = "method.request.header.x-signature,method.request.header.x-request-id,method.request.querystring.data.id"
  type = "REQUEST"
}

resource "aws_iam_policy" "lambda_invoke_permission" {
  name        = "InvokeLambdaPermission-${var.aws_env}"
  description = "Permissão para o API Gateway chamar a função Lambda de autenticação."
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "lambda:InvokeFunction"
        Resource = "${data.aws_lambda_function.lambda_auth.arn}"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_lambda_invoke_permission" {
  role       = aws_iam_role.invocation_role.name
  policy_arn = aws_iam_policy.lambda_invoke_permission.arn
}

resource "aws_iam_role" "invocation_role" {
  name               = "APIGatewayInvokeLambdaRoleCustomAuthorizer-${var.aws_env}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
        Effect = "Allow"
        Sid    = ""
      }
    ]
  })
}
