#!/usr/bin/env bash
# Copies the Terraform outputs into GitHub Actions repository variables.
# These are IDs and ARNs, not secrets, so they are stored as variables.
# Needs: terraform (initialised in ./terraform), the GitHub CLI (gh) signed in.
#
# Usage: ./scripts/set-github-vars.sh [owner/repo] [state-bucket]
set -euo pipefail

REPO="${1:-hammond-0023/hammond-website-portfolio}"
STATE_BUCKET="${2:-hammondmutambara-tfstate}"
TF_DIR="$(cd "$(dirname "$0")/../terraform" && pwd)"

out() { terraform -chdir="${TF_DIR}" output -raw "$1"; }

set_var() {
  printf 'Setting %s\n' "$1"
  gh variable set "$1" --repo "${REPO}" --body "$2"
}

set_var AWS_REGION                 "${AWS_REGION:-eu-central-1}"
set_var S3_BUCKET_NAME             "$(out bucket_name)"
set_var CLOUDFRONT_DISTRIBUTION_ID "$(out cloudfront_distribution_id)"
set_var AWS_DEPLOY_ROLE_ARN        "$(out deploy_role_arn)"
set_var AWS_PLAN_ROLE_ARN          "$(out plan_role_arn)"
set_var TF_STATE_BUCKET            "${STATE_BUCKET}"

echo "Done. You can now delete the old AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY secrets."
