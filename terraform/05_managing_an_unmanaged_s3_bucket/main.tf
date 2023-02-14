terraform {
  required_version = "~> 1.3.0"

  backend "s3" {
    bucket = "foobarbucket-1234-tfstate"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
}


provider "aws" {
  region     = "us-east-1"
  access_key = "AKIAZQWIAASQINXYSBUU"                     # retrieve this when opening the cloud playground
  secret_key = "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" # retrieve this when opening the cloud playground
}

resource "aws_s3_bucket" "foobarbucket" {
  bucket = "foobarbucket-1246"
}

resource "aws_s3_bucket_versioning" "versioning_example" {
  bucket = aws_s3_bucket.foobarbucket.id
  versioning_configuration {
    status = "Suspended"
    mfa_delete = "Disabled"
  }
}