terraform {
  backend "s3" {
    bucket = "hub-payment-140023362908-terraform"
    region = "us-east-2"
    key    = "dynamodbs/hub-payment-customers/dev"
  }
}

provider "aws" {
  region = var.aws_region
}

resource "aws_dynamodb_table" "example" {
  name         = "${var.table_name}-${var.aws_env}"
  billing_mode = var.price_definition
  hash_key     = var.hash_key
  attribute {
    name = var.hash_key
    type = var.hash_key_type
  }
  attribute {
    name = var.global_secondary_index_name
    type = var.global_secondary_index_type
  }
  global_secondary_index {
    name            = "${var.global_secondary_index_name}-index"
    hash_key        = var.global_secondary_index_name
    projection_type = "KEYS_ONLY"
  }
}
