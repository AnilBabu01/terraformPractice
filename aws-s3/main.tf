
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.32.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.8.1"
    }
  }
}


provider "aws" {
  # Configuration options
  region = var.region
}

resource "random_id" "random_id" {
  byte_length = 8
}

resource "aws_s3_bucket" "mybucket" {
  bucket = "mybucket-${random_id.random_id.hex}"
}

resource "aws_s3_object" "uploadfile" {
  bucket = aws_s3_bucket.mybucket.bucket
  source = "./myfile.txt"
  key    = "mydata.txt"
}

