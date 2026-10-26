variable "region" {
  description = "Region for the site bucket"
  type        = string
  default     = "eu-central-1"
}

variable "domain_name" {
  description = "Root domain served by the site. Its Route 53 hosted zone must already exist."
  type        = string
  default     = "hammondmutambara.com"
}

variable "bucket_name" {
  description = "Private S3 bucket that holds the site files"
  type        = string
  default     = "hammondmutambara-com-site"
}

variable "github_repo" {
  description = "GitHub repository allowed to deploy, as owner/name"
  type        = string
  default     = "hammond-0023/hammond-website-portfolio"
}

variable "github_oidc_provider_arn" {
  description = "ARN of an existing GitHub OIDC provider in this account. Leave empty to create one."
  type        = string
  default     = "arn:aws:iam::724772057376:oidc-provider/token.actions.githubusercontent.com"
}

variable "hosted_zone_id" {
  description = "ID of the Route 53 hosted zone for the domain. Needed because the account has two zones with the same name."
  type        = string
  default     = "Z0747781L61EH83OK957"
}

variable "price_class" {
  description = "CloudFront price class. PriceClass_100 covers North America and Europe at the lowest cost."
  type        = string
  default     = "PriceClass_100"
}

variable "force_destroy" {
  description = "Allow terraform destroy to delete the site bucket even when it holds files"
  type        = bool
  default     = false
}
