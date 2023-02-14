terraform {
  required_version = "~> 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
}

provider "aws" {
  region     = "us-east-1"
  access_key = "AKIATHEUR7EUMVTNGU7E"                     # retrieve this when opening the cloud playground
  secret_key = "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" # retrieve this when opening the cloud playground
}


resource "aws_key_pair" "general_ssh_key" {
  key_name   = "general_ssh_access"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC19pAthFUrFk7KHycvSQ3YkG+ZTSMfM6V22eXFlMCB2nnQR/DLcOvT+u27xH48XzRgf/qCCTwsZZMnLDcakzHOPCqZYuPnKU4mt1WdRSjVIvw8ym73PYNIT3t1N4sC1+SsyzwSkqASMo9KO9IZdmDwjyGOEccRhc60u6LrbBE4ohQmDCDW7Xqy/dcgFn87yF4eFE4wXQi4lxY5LZjef+3fCvyRbSqklTg5Kc10x0yCUsw9wfuNvvVSX26sMIJP+RnoyMULF+nJ2O78pw9oLGelBvbhNYoR5snDq7dZRbs2nGGSm4Relbxyql5kn1cEGVjLqbVY288gS9SF6i6mz1IxXAQZerAEfS4wpWtsQTi5Hhmjv7YWsJgAWDsSd3OibtjOXeSGGDnoF7ozmJ5Vq+KnUy17BBU5pTSlCFzzuKQgahprXV47xCJOWiKpDuRnlwOOIUMtNL3xY64kXQxrFmnWI4W1KRqQTi9kId1V53Qnl/s6nlQGJaYBWxR9IJz9QeMt2IV13yeewBc9JPYM5CoSA2xIjqeDwHrbY14h07wSESZIGXGIA6D7bBafpiO+C0knOVIgPBJiSOnJxEJzU1XpSSMlY0jXFzqEaNuQPKqa86QU26HAIxUJ+rCBwORPEHwr0AcUnYx7kXkRPd7J/fI06FJ6X4w48l/KGFJvFRK+OQ=="

  tags = {
    "Name" = "general_ssh_key"
  }
}

resource "aws_s3_bucket_policy" "my_bucket_policy" {
  policy = 
}

resource "aws_s3_bucket" "my_bucket" {
  bucket = "my_global_bucket_name-12349"
  
  tags = {
    "Name" = "my_bucket"
  }
}

module "network" {
  source = "./modules/network"
  network_vpc_cidr_block = "10.0.0.0/16"
  network_public_cidr_block = "10.0.1.0/24"
  network_private_cidr_block = "10.0.2.0/24"
}

module "bastion_host" {
  source = "./modules/bastion_host"
  baho_vpc_id = module.network.vpc_id
  baho_vpc_cidr_block = "10.0.0.0/16"
  baho_ssh_key_name = aws_key_pair.general_ssh_key.key_name
  baho_subnet_id = module.network.public_subnet_id
}