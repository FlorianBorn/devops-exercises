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

data "aws_vpc" "main" {
  filter {
    name = "tag:Name"
    values = ["main"]
  }
}

data "aws_subnets" "all_subnets" {}

data "aws_subnet" "public" {
  filter {
    name  = "vpc-id"
    values = [data.aws_vpc.main.id]
  }
  filter {
    name  = "tag:Name"
    values = ["public"]
  }  
}

# data "aws_subnet" "private" {
#     filter {
#         name = "private"
#     }
# }

resource "aws_key_pair" "general_ssh_key" {
  key_name   = "general_ssh_access"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC19pAthFUrFk7KHycvSQ3YkG+ZTSMfM6V22eXFlMCB2nnQR/DLcOvT+u27xH48XzRgf/qCCTwsZZMnLDcakzHOPCqZYuPnKU4mt1WdRSjVIvw8ym73PYNIT3t1N4sC1+SsyzwSkqASMo9KO9IZdmDwjyGOEccRhc60u6LrbBE4ohQmDCDW7Xqy/dcgFn87yF4eFE4wXQi4lxY5LZjef+3fCvyRbSqklTg5Kc10x0yCUsw9wfuNvvVSX26sMIJP+RnoyMULF+nJ2O78pw9oLGelBvbhNYoR5snDq7dZRbs2nGGSm4Relbxyql5kn1cEGVjLqbVY288gS9SF6i6mz1IxXAQZerAEfS4wpWtsQTi5Hhmjv7YWsJgAWDsSd3OibtjOXeSGGDnoF7ozmJ5Vq+KnUy17BBU5pTSlCFzzuKQgahprXV47xCJOWiKpDuRnlwOOIUMtNL3xY64kXQxrFmnWI4W1KRqQTi9kId1V53Qnl/s6nlQGJaYBWxR9IJz9QeMt2IV13yeewBc9JPYM5CoSA2xIjqeDwHrbY14h07wSESZIGXGIA6D7bBafpiO+C0knOVIgPBJiSOnJxEJzU1XpSSMlY0jXFzqEaNuQPKqa86QU26HAIxUJ+rCBwORPEHwr0AcUnYx7kXkRPd7J/fI06FJ6X4w48l/KGFJvFRK+OQ=="

  tags = {
    "Name" = "general_ssh_key"
  }
}


# resource "aws_instance" "backend" {
#   ami = "ami-0aa7d40eeae50c9a9"
#   instance_type = "t2.micro"
#   subnet_id = data.aws_subnet.private.id
#   key_name = aws_key_pair.general_ssh_key.key_name
#   vpc_security_group_ids = [aws_security_group.backend_sg.id]

#   tags = {
#     Name = "backend"
# }
# }

resource "aws_security_group" "public_access_sg" {
  vpc_id = data.aws_vpc.main.id

  ingress {
    description = "All incoming traffic"
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "-1"
    from_port   = 0
    to_port     = 0

    #    security_groups = [ "value" ]
    self = false

  }

  egress {
    cidr_blocks      = ["0.0.0.0/0"]
    protocol         = "-1"
    ipv6_cidr_blocks = ["::/0"]
    from_port        = 0
    to_port          = 0
  }

  tags = {
    "Name" : "sg_bastion"
  }
}

resource "aws_security_group" "backend_sg" {
  vpc_id = data.aws_vpc.main.id

  ingress {
    cidr_blocks = [data.aws_vpc.main.cidr_block]
    description = "incoming SSH connection from within the VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    self        = false
  }

  tags = {
    "Name" = "backend_sg"
  }
}

resource "aws_instance" "bastion" {
  ami                         = "ami-0aa7d40eeae50c9a9" # amazon linux
  instance_type               = "t2.micro"
  subnet_id                   = data.aws_subnet.public.id
  associate_public_ip_address = true
  key_name                    = aws_key_pair.general_ssh_key.key_name
  vpc_security_group_ids      = [aws_security_group.public_access_sg.id]

  tags = {
    "Name" = "bastion"
  }
}