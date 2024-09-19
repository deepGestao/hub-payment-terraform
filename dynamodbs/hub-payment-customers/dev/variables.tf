variable "table_name" {
  description = "The table name"
  default     = "hub-payment-customers"
}

variable "aws_env" {
  description = "The env in AWS"
  default     = "dev"
}

variable "aws_region" {
  description = "The region in AWS"
  default     = "us-east-2"
}

variable "price_definition" {
  description = "The price definition from table"
  default     = "PAY_PER_REQUEST"
}

variable "hash_key" {
  description = "The hash key from the table"
  default     = "token"
}

variable "hash_key_type" {
  description = "The type of hash key"
  default     = "S"
}
