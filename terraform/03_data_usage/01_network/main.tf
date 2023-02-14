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

