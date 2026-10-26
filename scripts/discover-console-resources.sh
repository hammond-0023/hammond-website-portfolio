#!/usr/bin/env bash
# Read-only inventory of what already exists in your AWS account, so you can decide
# what to destroy, keep or import before the first terraform apply.
# Needs the AWS CLI signed in to the right account. It changes nothing.
#
# Usage: ./scripts/discover-console-resources.sh [domain] [region]
set -uo pipefail

DOMAIN="${1:-hammondmutambara.com}"
REGION="${2:-eu-central-1}"

section() { printf '\n== %s ==\n' "$1"; }

section "Account"
aws sts get-caller-identity --query '[Account,Arn]' --output text

section "S3 buckets"
aws s3api list-buckets --query 'Buckets[].Name' --output text | tr '\t' '\n'

section "CloudFront distributions (id, domain, aliases, comment)"
aws cloudfront list-distributions \
  --query 'DistributionList.Items[].[Id,DomainName,join(`,`,Aliases.Items||`[]`),Comment]' \
  --output text

section "Route 53 hosted zones"
aws route53 list-hosted-zones \
  --query 'HostedZones[].[Id,Name,Config.PrivateZone]' --output text

ZONE_ID="$(aws route53 list-hosted-zones-by-name --dns-name "${DOMAIN}." \
  --query 'HostedZones[0].Id' --output text 2>/dev/null | sed 's|/hostedzone/||')"
if [ -n "${ZONE_ID}" ] && [ "${ZONE_ID}" != "None" ]; then
  section "Records in zone ${ZONE_ID}"
  aws route53 list-resource-record-sets --hosted-zone-id "${ZONE_ID}" \
    --query 'ResourceRecordSets[].[Name,Type]' --output text
fi

section "ACM certificates in us-east-1 (used by CloudFront)"
aws acm list-certificates --region us-east-1 \
  --query 'CertificateSummaryList[].[DomainName,CertificateArn,Status]' --output text

section "ACM certificates in ${REGION}"
aws acm list-certificates --region "${REGION}" \
  --query 'CertificateSummaryList[].[DomainName,CertificateArn,Status]' --output text

section "IAM OIDC providers"
aws iam list-open-id-connect-providers --query 'OpenIDConnectProviderList[].Arn' --output text

section "IAM roles that look related"
aws iam list-roles \
  --query 'Roles[?contains(RoleName,`github`)||contains(RoleName,`portfolio`)].RoleName' \
  --output text

section "IAM users and their access keys (old CI keys to delete later)"
aws iam list-users --query 'Users[].UserName' --output text | tr '\t' '\n' | while read -r user; do
  [ -z "${user}" ] && continue
  echo "-- ${user}"
  aws iam list-access-keys --user-name "${user}" \
    --query 'AccessKeyMetadata[].[AccessKeyId,Status,CreateDate]' --output text
done

echo
echo "Done. Nothing was changed."
