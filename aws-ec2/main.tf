
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.32.0"
    }
  }
}

provider "aws" {
  # Configuration options
  region = var.region
}

resource "aws_instance" "myserver" {
  ami           = "ami-0c83cb1c664994bbd"
  instance_type = "t3.micro"

  tags = {
    Name : "myec2"
  }
}
