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
  access_key = "AKIAZ5DUCOBMFXG4PGFU"                     # retrieve this when opening the cloud playground
  secret_key = "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" # retrieve this when opening the cloud playground
}

resource "aws_vpc" "my_vpc" {
  cidr_block = "172.125.0.0/16"
  tags = {
    "Name"  = "my_vpc"
    "stage" = "dev"
  }
}

resource "aws_subnet" "public" {
  cidr_block = "172.125.1.0/24"
  vpc_id     = aws_vpc.my_vpc.id

  tags = {
    "Name" = "public_subnet"
  }
}

resource "aws_subnet" "private" {
  cidr_block = "172.125.2.0/24"
  vpc_id     = aws_vpc.my_vpc.id


  tags = {
    "Name" = "private_subnet"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    "Name" = "internet_gateway"
  }
}

resource "aws_route_table" "internet" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    "Name" = "my_internet_rtb"
  }
}

resource "aws_nat_gateway" "ngw" {
  subnet_id     = aws_subnet.public.id
  allocation_id = aws_eip.nat_public_ip.id

  depends_on = [aws_internet_gateway.igw]

  tags = {
    "Name" = "nat_gateway"
  }
}

resource "aws_eip" "nat_public_ip" {
  tags = {
    "Name" = "nat_public_ip"
  }

}

resource "aws_route_table" "private_to_public" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.ngw.id
  }

  tags = {
    "Name" = "my_private_to_public_rtb"
  }
}

resource "aws_route_table_association" "public_subnet_to_public_rtb" {
  route_table_id = aws_route_table.internet.id
  subnet_id      = aws_subnet.public.id
}

resource "aws_route_table_association" "private_subnet_to_private_rtb" {
  route_table_id = aws_route_table.private_to_public.id
  subnet_id      = aws_subnet.private.id
}

resource "aws_instance" "lone_wolf" {
  ami                    = "ami-0aa7d40eeae50c9a9" # amazon linux
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.private.id
  key_name               = aws_key_pair.general_ssh_key.key_name
  vpc_security_group_ids = [aws_security_group.public_access_sg.id]

  tags = {
    "Name" = "lone_wolf"
  }
}

resource "aws_instance" "bastion" {
  ami                         = "ami-0aa7d40eeae50c9a9" # amazon linux
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public.id
  associate_public_ip_address = true
  key_name                    = aws_key_pair.general_ssh_key.key_name
  vpc_security_group_ids      = [aws_security_group.public_access_sg.id]

  tags = {
    "Name" = "bastion"
  }
}

resource "aws_security_group" "public_access_sg" {
  vpc_id = aws_vpc.my_vpc.id

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




resource "aws_key_pair" "general_ssh_key" {
  key_name   = "lone_wolf_acces_key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC19pAthFUrFk7KHycvSQ3YkG+ZTSMfM6V22eXFlMCB2nnQR/DLcOvT+u27xH48XzRgf/qCCTwsZZMnLDcakzHOPCqZYuPnKU4mt1WdRSjVIvw8ym73PYNIT3t1N4sC1+SsyzwSkqASMo9KO9IZdmDwjyGOEccRhc60u6LrbBE4ohQmDCDW7Xqy/dcgFn87yF4eFE4wXQi4lxY5LZjef+3fCvyRbSqklTg5Kc10x0yCUsw9wfuNvvVSX26sMIJP+RnoyMULF+nJ2O78pw9oLGelBvbhNYoR5snDq7dZRbs2nGGSm4Relbxyql5kn1cEGVjLqbVY288gS9SF6i6mz1IxXAQZerAEfS4wpWtsQTi5Hhmjv7YWsJgAWDsSd3OibtjOXeSGGDnoF7ozmJ5Vq+KnUy17BBU5pTSlCFzzuKQgahprXV47xCJOWiKpDuRnlwOOIUMtNL3xY64kXQxrFmnWI4W1KRqQTi9kId1V53Qnl/s6nlQGJaYBWxR9IJz9QeMt2IV13yeewBc9JPYM5CoSA2xIjqeDwHrbY14h07wSESZIGXGIA6D7bBafpiO+C0knOVIgPBJiSOnJxEJzU1XpSSMlY0jXFzqEaNuQPKqa86QU26HAIxUJ+rCBwORPEHwr0AcUnYx7kXkRPd7J/fI06FJ6X4w48l/KGFJvFRK+OQ=="
}

