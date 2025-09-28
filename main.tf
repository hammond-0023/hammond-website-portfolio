terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.14.1"
    }
  }
}


data "aws_s3_bucket" "website" {
  bucket = var.aws_s3_bucket_name
}

data "aws_route53_zone" "main" {
  name         = "hammondmutambara.com."
  zone_id      = var.hosted_zone_id
  private_zone = false
  tags = {
    Name = "main route"
  }
}


