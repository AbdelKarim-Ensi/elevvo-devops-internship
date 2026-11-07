# VOLONTAIREMENT MAUVAIS : sert uniquement à prouver que Checkov bloque.
# Ne jamais appliquer ce dossier.
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

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

resource "aws_s3_bucket" "bad" {
  bucket = "elevvo-task08-insecure-demo"
  acl    = "public-read" # public + pas de chiffrement + pas de versioning
}
