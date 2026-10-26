#!/usr/bin/env bash
# Manual deploy from your machine: the same steps as the GitHub Actions workflow.
# Use it for an emergency fix or the very first upload before CI is set up.
# Needs the AWS CLI signed in to the account, and terraform initialised in ./terraform.
#
# Usage: ./scripts/deploy-site.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUCKET="$(terraform -chdir="${ROOT}/terraform" output -raw bucket_name)"
DIST_ID="$(terraform -chdir="${ROOT}/terraform" output -raw cloudfront_distribution_id)"

echo "Uploading site/ to s3://${BUCKET}"
aws s3 sync "${ROOT}/site/" "s3://${BUCKET}" \
  --delete \
  --exclude ".DS_Store" \
  --cache-control "public, max-age=300"

echo "Clearing the CloudFront cache (${DIST_ID})"
aws cloudfront create-invalidation --distribution-id "${DIST_ID}" --paths "/*" \
  --query 'Invalidation.Id' --output text

echo "Done. Changes show up within a minute or two."
