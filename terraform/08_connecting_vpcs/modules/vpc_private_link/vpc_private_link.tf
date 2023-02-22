

######## ACCESS KEYS #############

resource "aws_key_pair" "ssh_access_key" {
  key_name = "my_access_key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC19pAthFUrFk7KHycvSQ3YkG+ZTSMfM6V22eXFlMCB2nnQR/DLcOvT+u27xH48XzRgf/qCCTwsZZMnLDcakzHOPCqZYuPnKU4mt1WdRSjVIvw8ym73PYNIT3t1N4sC1+SsyzwSkqASMo9KO9IZdmDwjyGOEccRhc60u6LrbBE4ohQmDCDW7Xqy/dcgFn87yF4eFE4wXQi4lxY5LZjef+3fCvyRbSqklTg5Kc10x0yCUsw9wfuNvvVSX26sMIJP+RnoyMULF+nJ2O78pw9oLGelBvbhNYoR5snDq7dZRbs2nGGSm4Relbxyql5kn1cEGVjLqbVY288gS9SF6i6mz1IxXAQZerAEfS4wpWtsQTi5Hhmjv7YWsJgAWDsSd3OibtjOXeSGGDnoF7ozmJ5Vq+KnUy17BBU5pTSlCFzzuKQgahprXV47xCJOWiKpDuRnlwOOIUMtNL3xY64kXQxrFmnWI4W1KRqQTi9kId1V53Qnl/s6nlQGJaYBWxR9IJz9QeMt2IV13yeewBc9JPYM5CoSA2xIjqeDwHrbY14h07wSESZIGXGIA6D7bBafpiO+C0knOVIgPBJiSOnJxEJzU1XpSSMlY0jXFzqEaNuQPKqa86QU26HAIxUJ+rCBwORPEHwr0AcUnYx7kXkRPd7J/fI06FJ6X4w48l/KGFJvFRK+OQ=="
}

######## CLIENT NETWORK #################

resource "aws_vpc" "consumer_vpc" {
  cidr_block = "10.10.0.0/16"
  
  tags = {
    "Name" = "consumer_vpc"
  }
}

resource "aws_subnet" "consumer_private" {
  vpc_id = aws_vpc.consumer_vpc.id
  cidr_block = "10.10.0.0/24"
  availability_zone_id = "use1-az1"
  
  tags = {
    "Name" = "consumer_private"
  }
}

resource "aws_instance" "client" {
  ami                    = "ami-0aa7d40eeae50c9a9" # amazon linux
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.consumer_private.id
  key_name               = aws_key_pair.ssh_access_key.key_name
  vpc_security_group_ids = [aws_security_group.client_sg.id]
  associate_public_ip_address = true

  tags = {
    "Name" = "client"
  }
}

resource "aws_internet_gateway" "client_igw" {
  vpc_id = aws_vpc.consumer_vpc.id
  tags = {
    "Name" = "client_igw"
  }
}

resource "aws_route_table" "consumer_rtb" {
  vpc_id = aws_vpc.consumer_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.client_igw.id
  }

}

resource "aws_route_table_association" "consumer_rtb_association" {
  subnet_id      = aws_subnet.consumer_private.id
  route_table_id = aws_route_table.consumer_rtb.id
}

resource "aws_security_group" "client_sg" {
  vpc_id = aws_vpc.consumer_vpc.id

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    description = "allow incoming SSH traffic"
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    self        = false
  }

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    description = "allow outgoing, HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "TCP"
    self        = false
  }

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    description = "allow outgoing, HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "TCP"
    self        = false
  }  

  tags = {
    "Name" = "provider_sg"
  }
}


############### PROVIDER #################

resource "aws_vpc" "provider_vpc" {
  cidr_block = "10.20.0.0/16"
  
  tags = {
    "Name" = "provider_vpc"
  }
}

resource "aws_subnet" "provider_private" {
    vpc_id = aws_vpc.provider_vpc.id
    availability_zone_id = "use1-az1"
  cidr_block = "10.20.0.0/24"
  
  tags = {
    "Name" = "provider_private"
  }
}

resource "aws_instance" "webserver" {
  ami                    = "ami-0aa7d40eeae50c9a9" # amazon linux
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.provider_private.id
  key_name               = aws_key_pair.ssh_access_key.key_name
  vpc_security_group_ids = [aws_security_group.webserver_sg.id]
  associate_public_ip_address = true

  user_data = <<HERE
#!/bin/bash
sudo yum install -y httpd > /tmp/user_data.log
sudo systemctl enable --now httpd >> /tmp/user_data.log
HERE

  tags = {
    "Name" = "webserver"
  }
}

resource "aws_internet_gateway" "provider_igw" {
  vpc_id = aws_vpc.provider_vpc.id
  tags = {
    "Name" = "provider_igw"
  }
}

#resource "aws_internet_gateway_attachment" "provider_igw_to_provider_vpc" {
#  internet_gateway_id = aws_internet_gateway.provider_igw.id
#  vpc_id = aws_vpc.provider_vpc.id
#}

resource "aws_route_table" "provider_rtb" {
  vpc_id = aws_vpc.provider_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.provider_igw.id
  }

}

resource "aws_route_table_association" "provider_rtb_association" {
  subnet_id      = aws_subnet.provider_private.id
  route_table_id = aws_route_table.provider_rtb.id
}

resource "aws_security_group" "webserver_sg" {
  vpc_id = aws_vpc.provider_vpc.id

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    description = "allow incoming SSH traffic"
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    self        = false
  }

  ingress {
    cidr_blocks = [aws_vpc.consumer_vpc.cidr_block]
    description = "allow incoming SSH traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "TCP"
    self        = false
  }  

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    description = "allow outgoing, HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "TCP"
    self        = false
  }

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    description = "allow outgoing, HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "TCP"
    self        = false
  }  

  tags = {
    "Name" = "provider_sg"
  }
}

