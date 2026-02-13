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

# ---------------------------
# S3 BUCKET (Domain Name)
# ---------------------------
resource "aws_s3_bucket" "website_bucket" {
  bucket = var.domain_name
}

# ---------------------------
# PUBLIC ACCESS SETTINGS
# ---------------------------
resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = aws_s3_bucket.website_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# ---------------------------
# BUCKET POLICY (PUBLIC READ)
# ---------------------------
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

# ---------------------------
# ENABLE STATIC WEBSITE
# ---------------------------
resource "aws_s3_bucket_website_configuration" "website_config" {
  bucket = aws_s3_bucket.website_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

# ---------------------------
# UPLOAD WEBSITE FILES
# ---------------------------
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
      svg  = "image/svg+xml"
    },
    split(".", each.value)[length(split(".", each.value)) - 1],
    "application/octet-stream"
  )
}

# ---------------------------
# ROUTE53 HOSTED ZONE
# ---------------------------
resource "aws_route53_zone" "main" {
  name = var.domain_name
}

# ---------------------------
# ROUTE53 A RECORD (Alias)
# ---------------------------
resource "aws_route53_record" "root_domain" {
  zone_id = aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_s3_bucket_website_configuration.website_config.website_domain
    zone_id                = aws_s3_bucket.website_bucket.hosted_zone_id
    evaluate_target_health = false
  }
}

# ---------------------------
# OUTPUT
# ---------------------------
output "website_url" {
  value = "http://${var.domain_name}"
}
