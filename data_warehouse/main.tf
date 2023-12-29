variable "region" {}
variable "bucket_name" {}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {}
}
provider "aws" {
  region = var.region
}

resource "aws_s3_bucket" "iot_bucket" {
  bucket = var.bucket_name
}
