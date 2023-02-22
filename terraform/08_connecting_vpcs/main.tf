terraform {
  required_version = "~> 1.3.0"

 required_providers {
   aws = {
     source = "hashicorp/aws"
     version = "~> 4.54.0"
    }
 }
}

provider "aws" {
    access_key = "AKIAV477VRBHK2UTBE7M"
    secret_key = "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"
    region = "us-east-1"
}

module "vpc_peering" {
    count = var.mode_vpc_peering ? 1 : 0
    source = "./modules/vpc_peering"
}

module "mode_vpc_private_link" {
    count = var.mode_vpc_private_link ? 1 : 0
    source = "./modules/vpc_private_link"
}