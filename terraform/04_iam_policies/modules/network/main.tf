
resource "aws_vpc" "main" {
  cidr_block = var.network_vpc_cidr_block

  tags = {
    "Name" = "main"
  }
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.network_public_cidr_block

  tags = {
    "Name" = "public"
  }
}

resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.network_private_cidr_block

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