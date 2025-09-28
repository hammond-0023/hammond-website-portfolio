variable "hosted_zone_id" {
  description = "The ID of the Route53 hosted zone"
  type        = string
  default     = "Z0747781L61EH83OK957"
}

variable "aws_s3_bucket_name" {
  description = "The name of the S3 bucket"
  type        = string
  default     = "hammondmutambara.com"
}