terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Provider pointé sur LocalStack : aucun compte AWS, aucun coût.
provider "aws" {
  region                      = "us-east-1"
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true

  endpoints {
    s3 = "http://localhost:4566"
  }
}

variable "bucket_name" {
  type    = string
  default = "elevvo-task08-secure-demo"
}

resource "aws_s3_bucket" "this" {
  bucket = var.bucket_name

  #checkov:skip=CKV_AWS_144:Replication inter-region inutile pour un bucket de démo
  #checkov:skip=CKV_AWS_145:Chiffrement SSE-S3 (AES256) suffisant pour la démo, KMS hors périmètre
  #checkov:skip=CKV_AWS_18:Access logging exige un second bucket, hors périmètre
  #checkov:skip=CKV2_AWS_62:Notifications d'événements non nécessaires pour la démo
  #checkov:skip=CKV2_AWS_61:Lifecycle non appliqué : LocalStack ne confirme pas la règle (timeout du provider)
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

output "bucket_name" {
  value = aws_s3_bucket.this.id
}

resource "aws_s3_bucket" "leaky" {
  bucket = "elevvo-task08-leaky"
  acl    = "public-read"
}
