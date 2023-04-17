provider "aws" {
  region = var.aws_region
}

data "aws_ami" "amazon-linux-image" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_vpc" "app-vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
      Name = "${var.env_prefix}-vpc"
  }
}

resource "aws_subnet" "app-subnet" {
  vpc_id = aws_vpc.app-vpc.id
  cidr_block = var.subnet_cidr_block
  availability_zone = var.avail_zone
  tags = {
      Name = "${var.env_prefix}-subnet"
  }
}

resource "aws_security_group" "app-secgrp" {
  name   = "app-secgrp"
  vpc_id = aws_vpc.app-vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.local_ip]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
    prefix_list_ids = []
  }

  tags = {
    Name = "${var.env_prefix}-secgrp"
  }
}

resource "aws_internet_gateway" "app-igw" {
	vpc_id = aws_vpc.app-vpc.id
    
    tags = {
     Name = "${var.env_prefix}-internet-gateway"
   }
}

resource "aws_route_table" "app-route-table" {
   vpc_id = aws_vpc.app-vpc.id

   route {
     cidr_block = "0.0.0.0/0"
     gateway_id = aws_internet_gateway.app-igw.id
   }
   # default route, mapping VPC CIDR block to "local", created implicitly and cannot be specified.

   tags = {
     Name = "${var.env_prefix}-route-table"
   }
 }

# Associate subnet with Route Table
resource "aws_route_table_association" "a-rtb-subnet" {
  subnet_id      = aws_subnet.app-subnet.id
  route_table_id = aws_route_table.app-route-table.id
}

resource "aws_key_pair" "ssh-key-location" {
  key_name   = "ssh-key"
  public_key = file(var.ssh_key)
}

resource "aws_instance" "app-server" {
  ami                         = data.aws_ami.amazon-linux-image.id
  instance_type               = var.instance_type
  key_name                    = "ssh-key"
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.app-subnet.id
  vpc_security_group_ids      = [aws_security_group.app-secgrp.id]
  availability_zone			      = "${var.aws_region}${var.avail_zone}"

  tags = {
    Name = "${var.env_prefix}-server"
  }
}

