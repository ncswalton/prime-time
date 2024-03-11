provider "aws" {
  region = "us-east-2"
}

resource "aws_s3_bucket" "bucket" {
  bucket = var.bucket_name
}

resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.bucket.id
  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_public_access_block" "access_block" {
  bucket = aws_s3_bucket.bucket.id
  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}

resource "aws_s3_object" "object" {
  bucket = var.bucket_name
  key    = "index.html"
  source = "../frontend/index.html"
  content_type = "text/html"
}

data "aws_iam_policy_document" "bucket_policy" {
  statement {
    sid       = "IPAllow"
    effect    = "Allow"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::${var.bucket_name}/*"]

    condition {
      test     = "IpAddress"
      variable = "aws:SourceIp"
      values   = [var.ip_address]
    }
  }
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.bucket.id
  policy = data.aws_iam_policy_document.bucket_policy.json
}
output "bucket_name" {
  value = aws_s3_bucket.bucket.bucket
}