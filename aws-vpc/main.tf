
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.32.0"
    }
  }
}

provider "aws" {
  region = var.region
}

#Create a vpc 
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name : "my_vpc"
  }
}

#Create a private subnet

resource "aws_subnet" "private_subnet" {
  cidr_block = "10.0.1.0/24"
  vpc_id     = aws_vpc.my_vpc.id
  tags = {
    Name : "private_subnet"
  }
}


#Create a public subnet

resource "aws_subnet" "public_subnet" {
  cidr_block = "10.0.2.0/24"
  vpc_id     = aws_vpc.my_vpc.id
  tags = {
    Name : "public_subnet"
  }
}

#Create a internet gateway
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id
  tags   = { Name : "my_igw" }
}

#Create a routing table
resource "aws_route_table" "my_rt" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }

  tags = {
    Name = "my_rt"
  }
}

resource "aws_route_table_association" "public_sub" {
  route_table_id = aws_route_table.my_rt.id
  subnet_id      = aws_subnet.public_subnet.id
}


resource "aws_instance" "myserver" {
  ami           = "ami-0c83cb1c664994bbd"
  instance_type = "t3.micro"
  subnet_id = aws_subnet.public_subnet.id
  tags = {
    Name : "myec2"
  }
}






