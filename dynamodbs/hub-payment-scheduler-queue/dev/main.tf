terraform {
  backend "s3" {
    bucket = "hub-payment-140023362908-terraform"
    region = "us-east-2"
    key = "dynamodbs/hub-payment-scheduler-queue/dev"
  }
}


provider "aws" {
  region = var.aws_region
}

resource "aws_dynamodb_table" "example" {
  name = "${var.table_name}-${var.aws_env}"
  billing_mode = var.price_definition
  hash_key = var.hash_key
  range_key = var.range_key
  attribute {
    name = var.hash_key
    type = var.hash_key_type
  }
  attribute {
    name = var.range_key
    type = var.range_key_type
  }
}