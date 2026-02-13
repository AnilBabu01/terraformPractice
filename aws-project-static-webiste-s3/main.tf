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
  region = var.region
}

# Generate random bucket name
resource "random_id" "rand" {
  byte_length = 4
}

# Create S3 bucket
resource "aws_s3_bucket" "website_bucket" {
  bucket = "wwww.ffplay100.xyz"
}

# Allow public access
resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = aws_s3_bucket.website_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Bucket policy for public read
resource "aws_s3_bucket_policy" "public_read" {
  bucket = aws_s3_bucket.website_bucket.id

  depends_on = [aws_s3_bucket_public_access_block.public_access]

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "PublicReadGetObject",
        Effect    = "Allow",
        Principal = "*",
        Action    = "s3:GetObject",
        Resource  = "${aws_s3_bucket.website_bucket.arn}/*"
      }
    ]
  })
}

# Enable static website hosting
resource "aws_s3_bucket_website_configuration" "website_config" {
  bucket = aws_s3_bucket.website_bucket.id

  index_document {
    suffix = "index.html"
  }
}

# Upload all files with correct content type
resource "aws_s3_object" "website_files" {
  for_each = fileset("./website", "**")

  bucket = aws_s3_bucket.website_bucket.bucket
  key    = each.value
  source = "./website/${each.value}"
  etag   = filemd5("./website/${each.value}")

  content_type = lookup(
    {
      html = "text/html"
      css  = "text/css"
      js   = "application/javascript"
      png  = "image/png"
      jpg  = "image/jpeg"
      jpeg = "image/jpeg"
      gif  = "image/gif"
    },
    split(".", each.value)[length(split(".", each.value)) - 1],
    "application/octet-stream"
  )
}

output "website_url" {
  value = aws_s3_bucket_website_configuration.website_config.website_endpoint
}
