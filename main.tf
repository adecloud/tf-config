provider "aws" {
  region = "us-east-1"
}

variable vpc_cidr_block {}
variable subnet_cidr_block {}
variable avail_zone {}
variable env_prefix {} 
variable my_ip {}
variable instance_type {}
variable ami {}
variable public_key_location {}






resource "aws_vpc" "myapp-vpc" {
  cidr_block       = var.vpc_cidr_block

  tags = {
    Name = "${var.env_prefix}-vpc"
  }
}


resource "aws_subnet" "myapp-subnet-1" {
  vpc_id     = aws_vpc.myapp-vpc.id
  cidr_block = var.subnet_cidr_block
  availability_zone = var.avail_zone

  tags = {
    Name = "${var.env_prefix}-subnet-1"
  }
}

resource "aws_route_table" "my-app-route-table" {
  vpc_id = aws_vpc.myapp-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my-app-igw.id
  }

  tags = {
    Name = "${var.env_prefix}-rtb"
  }

}

resource "aws_internet_gateway" "my-app-igw" {
  vpc_id = aws_vpc.myapp-vpc.id

  tags = {
    Name = "${var.env_prefix}-igw"
  }
}

resource "aws_route_table_association" "a-rtb-subnet" {
  subnet_id      = aws_subnet.myapp-subnet-1.id
  route_table_id = aws_route_table.my-app-route-table.id
}

resource "aws_security_group" "myapp-security-group" {   
  vpc_id      = aws_vpc.myapp-vpc.id
  name = "myapp-sg"


  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = [var.my_ip]
  }

  ingress {
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
      Name = "${var.env_prefix}-sg"
  }
}

resource "aws_key_pair" "ssh-key" {
  key_name   = "suse-key"
  public_key = "${file(var.public_key_location)}"
}


resource "aws_instance" "myapp-server" {
  ami           = var.ami
  instance_type = var.instance_type
  subnet_id = aws_subnet.myapp-subnet-1.id
  vpc_security_group_ids = [aws_security_group.myapp-security-group.id]
  availability_zone = var.avail_zone
  key_name = aws_key_pair.ssh-key

  tags = {
    Name = "${var.env_prefix}-server"
  }
}


  