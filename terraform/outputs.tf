output "site_url" {
  value = "https://${var.domain_name}"
}

output "bucket_name" {
  value = aws_s3_bucket.site.bucket
}

output "cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.site.id
}

output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.site.domain_name
}

output "deploy_role_arn" {
  description = "Set as the AWS_DEPLOY_ROLE_ARN variable in GitHub"
  value       = aws_iam_role.github_deploy.arn
}

output "plan_role_arn" {
  description = "Set as the AWS_PLAN_ROLE_ARN variable in GitHub"
  value       = aws_iam_role.github_plan.arn
}

output "name_servers" {
  description = "Nameservers of the hosted zone. These must match the registrar."
  value       = data.aws_route53_zone.main.name_servers
}
