terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-east-1"
}


# VPC
resource "aws_vpc" "vpn-vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "vpn-vpc"
  }
}


# Security Groups
resource "aws_security_group" "main-security-group" {
  name    = "main-security-group"
  vpc_id  = aws_vpc.vpn-vpc.id


  ingress {
    description      = "Allow Incoming SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = [ "0.0.0.0/0" ] # ist nicht optional
#    cidr_blocks      = [aws_vpc.vpn-vpc.cidr_block] # ist nicht optional
#    ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]

  }

}


# Subnets
resource "aws_subnet" "client-subnet" {
  vpc_id     = aws_vpc.vpn-vpc.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "client-subnet"
  }
}

resource "aws_subnet" "main-subnet" {
  vpc_id     = aws_vpc.vpn-vpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "main-subnet"
  }
}


# Route Table Associations 
resource "aws_route_table_association" "client-subnet_to_main-route-table" {
  subnet_id      = aws_subnet.client-subnet.id
  route_table_id = aws_route_table.main-route-table.id
}


# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpn-vpc.id

  tags = {
    Name = "main"
  }
}


# SSH-Key
resource "aws_key_pair" "my-key" {
  #key_name = "my-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCyIciYPwVbuxYsbic9B+E2lOtUTSaQJ+baaybUkmlu/m8odDmgub9Yn+/m2+6wb6/aA4a2+B9MhLSkqskx5kt/TEsICHezmf4XHb++wlRBLDOmQD55AhUfCvUIbUjq/gejLec4HRivns2rlYesfvI8vJw5zUzheRwi+cqql8PVMYGe3ydP9KPovKAovWN/3Ok+cdXFKqcep2SOx6g41HVl3zb5o5AcLQC+aB3FnJQskhpq3ReueazaXm9IW5Y19n1t+PGjjSamc0tachoRutqW2AM2LLdJhhZ9VqQSjkkPw/up2ok/C3S1OOR0wcdhAOTr/2L2FThLkUmVFUqfHQ6X55Mh14mZlVi169lcAXJVw6epMWYiL69Fhp3eCPGx3upO61khyzAOFijaNJ8hgwC2xlV6WU3ukpLG4plFaB+pi5KZZd3ahqIh6AZT2pbydxswKi6WiquWurl/KDk2CrFD/atPhAQ0CqILZE+EupEq8KUOLCtWL4zyv27S9YbXyME= root@localhost"

}


# AWS Instances
resource "aws_instance" "client_instance" {
  ami           = "ami-0cff7528ff583bf9a" # Amazon Linux
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.client-subnet.id
  associate_public_ip_address = true
  key_name = aws_key_pair.my-key.key_name
  vpc_security_group_ids = [ aws_security_group.main-security-group.id ]

  tags = {
    Name = var.client_instance_name
  }

  # copy the bash script to the new instance
  provisioner "file" {
    source      = "scripts/init_vpn-client.sh"
    destination = "/tmp/init_vpn-client.sh"
  }

  # Establishes connection to be used by all
  # generic remote provisioners (i.e. file/remote-exec)
  connection {
    type        = "ssh"
    user        = "ec2-user"
    #password = var.root_password
    private_key = "${file("id_rsa")}"
    host        = self.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/init_vpn-client.sh",
      "sudo /tmp/init_vpn-client.sh",
    ]
  }

}

resource "aws_instance" "vpn_server_instance" {
  ami           = "ami-0cff7528ff583bf9a" # Amazon Linux
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.main-subnet.id
  key_name = aws_key_pair.my-key.key_name
  associate_public_ip_address = true
  vpc_security_group_ids = [ aws_security_group.main-security-group.id ]

  tags = {
    Name = var.vpn_server_instance_name
  }

#  connection {
#    type        = "ssh"
#    user        = "ec2-user"
#    #password = var.root_password
#    private_key = "${file("id_rsa")}"
#    host        = self.public_ip
#  }

#  provisioner "remote-exec" {
#    inline = [
#      "echo 'vpn server' > ~/hello.txt"
#    ]
#  }  
#}
}

resource "aws_instance" "webserver_instance" {
  ami           = "ami-0cff7528ff583bf9a" # Amazon Linux
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.main-subnet.id
  key_name = aws_key_pair.my-key.key_name

  tags = {
    Name = var.webserver_instance_name
  }
}

resource "aws_route_table" "main-route-table" {
    vpc_id = aws_vpc.vpn-vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
    }

    tags = {
      Name = "main-route-table"
    }    
}

