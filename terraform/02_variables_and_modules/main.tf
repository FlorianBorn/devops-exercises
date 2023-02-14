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
  access_key = "AKIA2T5HEODKBB42HRMV"                     # retrieve this when opening the cloud playground
  secret_key = "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" # retrieve this when opening the cloud playground
}

resource "aws_vpc" "main" {
  cidr_block = var.cidr_vpc

  tags = {
    "Name" = "main"
  }
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.cidr_public_subnet

  tags = {
    "Name" = "public"
  }
}

resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.cidr_private_subnet

  tags = {
    "Name" = "private"
  }
}

resource "aws_key_pair" "general_ssh_key" {
  key_name   = "general_ssh_access"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC19pAthFUrFk7KHycvSQ3YkG+ZTSMfM6V22eXFlMCB2nnQR/DLcOvT+u27xH48XzRgf/qCCTwsZZMnLDcakzHOPCqZYuPnKU4mt1WdRSjVIvw8ym73PYNIT3t1N4sC1+SsyzwSkqASMo9KO9IZdmDwjyGOEccRhc60u6LrbBE4ohQmDCDW7Xqy/dcgFn87yF4eFE4wXQi4lxY5LZjef+3fCvyRbSqklTg5Kc10x0yCUsw9wfuNvvVSX26sMIJP+RnoyMULF+nJ2O78pw9oLGelBvbhNYoR5snDq7dZRbs2nGGSm4Relbxyql5kn1cEGVjLqbVY288gS9SF6i6mz1IxXAQZerAEfS4wpWtsQTi5Hhmjv7YWsJgAWDsSd3OibtjOXeSGGDnoF7ozmJ5Vq+KnUy17BBU5pTSlCFzzuKQgahprXV47xCJOWiKpDuRnlwOOIUMtNL3xY64kXQxrFmnWI4W1KRqQTi9kId1V53Qnl/s6nlQGJaYBWxR9IJz9QeMt2IV13yeewBc9JPYM5CoSA2xIjqeDwHrbY14h07wSESZIGXGIA6D7bBafpiO+C0knOVIgPBJiSOnJxEJzU1XpSSMlY0jXFzqEaNuQPKqa86QU26HAIxUJ+rCBwORPEHwr0AcUnYx7kXkRPd7J/fI06FJ6X4w48l/KGFJvFRK+OQ=="

  tags = {
    "Name" = "general_ssh_key"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    "Name" = "my_igw"
  }
}

resource "aws_route_table" "internet_rtb" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    "Name" = "internet_rtb"
  }
}

resource "aws_route_table_association" "public_subnet_to_public_rtb" {
  #gateway_id = aws_internet_gateway.igw.id
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.internet_rtb.id
}

resource "aws_instance" "backend" {
  ami = "ami-0aa7d40eeae50c9a9"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.private.id
  key_name = aws_key_pair.general_ssh_key.key_name
  vpc_security_group_ids = [aws_security_group.backend_sg.id]

  tags = {
    Name = "backend"
}
}

resource "aws_security_group" "backend_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    cidr_blocks = [ aws_vpc.main.cidr_block ]
    description = "incoming SSH connection from within the VPC"
    from_port = 22
    to_port = 22
    protocol = "TCP"
    self = false
  }

  tags = {
    "Name" = "backend_sg"
  }
}

module "bastion_host" {
  source            = "./modules/bastion_host"
  baho_ssh_key_name = aws_key_pair.general_ssh_key.key_name
  baho_vpc_id       = aws_vpc.main.id
  baho_vpc_cidr_block = aws_vpc.main.cidr_block
  baho_subnet_id    = aws_subnet.public.id
}

