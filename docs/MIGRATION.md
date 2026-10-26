# Moving from the console to Terraform

This guide takes you from the current state (some resources created by hand in the AWS console, some by earlier Terraform) to a stack where Terraform owns everything for the portfolio site.

There are two routes. **Rebuild** is simpler and is what this repository assumes. **Import** keeps existing resources but needs more care.

| | Rebuild (recommended) | Import |
|---|---|---|
| Idea | Delete the old site resources, let Terraform create new ones | Tell Terraform about the existing resources and adjust code until the plan shows no changes |
| Downtime | A few minutes while CloudFront and the certificate are created | None if done correctly |
| Risk | Low. The hosted zone is kept, so DNS and nameservers do not change | Higher. Each resource must match exactly or Terraform will try to change or replace it |
| Good for | A small static site | Anything with data or customers you cannot rebuild |

The steps below use the rebuild route. The import route is at the end.

## 0. Prerequisites

- Terraform 1.10+, AWS CLI, GitHub CLI installed
- AWS CLI signed in to the account that owns `hammondmutambara.com`
- Admin-level access for the first apply (you will create IAM roles)
- The repository cloned locally

## 1. Take inventory

```bash
./scripts/discover-console-resources.sh hammondmutambara.com eu-central-1
```

Read the output and write down:

- the S3 buckets used by the old site, for example `hammond-portfolio101` and the bucket behind `hammondmutambara.com`
- the CloudFront distribution that serves the domain, and its ID
- the ACM certificate in `us-east-1`
- the Route 53 hosted zone ID, and any records you created by hand
- whether a GitHub OIDC provider already exists (if it does, copy its ARN)
- old IAM users with access keys used by CI

Back up anything you cannot recreate: download the files from the old bucket (`aws s3 sync s3://<old-bucket> ./backup`) and note any custom DNS records such as MX or TXT records for email.

> Do not delete the Route 53 **hosted zone**, and do not delete records that are not about the website (MX, TXT, CNAME for email or verification). If the zone is deleted, the nameservers change and the domain goes offline until you update the registrar.

## 2. Create the state bucket

```bash
cd bootstrap
terraform init
terraform apply
terraform output -raw backend_config
```

If the default bucket name `hammondmutambara-tfstate` is taken, change `state_bucket_name` in `bootstrap/main.tf` first. Bootstrap uses local state on purpose. Keep the small `terraform.tfstate` it creates somewhere safe, or re-import the bucket later with `terraform import aws_s3_bucket.state <bucket-name>`.

## 3. Point the main stack at that bucket

```bash
cd ../terraform
cp backend.hcl.example backend.hcl
# edit backend.hcl if you changed the bucket name
terraform init -backend-config=backend.hcl
```

## 4. Remove the old site resources

Only do this once you have the backup from step 1.

**Resources made by earlier Terraform** (the old `hammond-portfolio101` stack). From the folder that holds its state file:

```bash
aws s3 rm s3://hammond-portfolio101 --recursive
terraform destroy
```

**Resources made by hand.** In the console, in this order:

1. CloudFront: select the distribution, **Disable**, wait until the status is *Deployed*, then **Delete**.
2. Route 53: delete only the A/alias records that pointed at the old CloudFront distribution or bucket (`hammondmutambara.com`, `www`). Keep everything else.
3. ACM (us-east-1): delete the old certificate after the distribution is gone. A certificate that is still attached cannot be deleted.
4. S3: empty and delete the old site bucket.

If `terraform plan` later complains that a record already exists, it is a leftover from this list. Delete it and run plan again.

## 5. Create everything with Terraform

```bash
cd terraform
terraform plan
terraform apply
```

If your account already has a GitHub OIDC provider, apply fails with *EntityAlreadyExists*. Set its ARN and run again:

```bash
terraform apply -var 'github_oidc_provider_arn=arn:aws:iam::<account-id>:oidc-provider/token.actions.githubusercontent.com'
```

Create a file `terraform/terraform.tfvars` with that value if you want it to stick. `.gitignore` excludes it.

Certificate validation and CloudFront creation take about 5 to 15 minutes.

## 6. Connect GitHub

```bash
./scripts/set-github-vars.sh hammond-0023/hammond-website-portfolio hammondmutambara-tfstate
```

This stores the bucket name, distribution ID, role ARNs and state bucket as GitHub Actions variables.

Then delete the old secrets in the repository settings (**Settings → Secrets and variables → Actions**): `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, and the old `AWS_DEPLOY_ROLE_ARN`, `S3_BUCKET_NAME`, `CLOUDFRONT_DISTRIBUTION_ID` secrets if they exist. A variable and a secret with the same name can conflict, so remove the secret versions.

## 7. First deploy

Either push a change under `site/` to `main`, run the **Deploy site** workflow from the Actions tab, or upload once by hand:

```bash
./scripts/deploy-site.sh
```

Open <https://hammondmutambara.com> and <https://www.hammondmutambara.com>. If the page does not load, check `terraform output name_servers` against the nameservers at the registrar.

## 8. Clean up

- Delete the old CI IAM user's access keys, then the user: `aws iam delete-access-key` and `aws iam delete-user`.
- Delete the old workflow files in the repository (the ones that use `AWS_ACCESS_KEY_ID`, and the duplicate "List S3 Bucket Objects" workflow).
- Delete the committed `terraform.tfstate` and `terraform.tfstate.backup` from the old repository if they were pushed. State files can contain account IDs and resource details. They are in `.gitignore` here, but older commits still hold them: if the repository is public, consider the history exposed and remove it from history or rotate anything sensitive.
- Check the AWS bill the next day for resources you forgot to delete.

---

## Import route (keep existing resources)

Use this only if you cannot afford any downtime. Terraform 1.5+ can adopt resources with `import` blocks.

1. Find the IDs with `scripts/discover-console-resources.sh`.
2. Add an `imports.tf` in `terraform/` for each resource, for example:

```hcl
import {
  to = aws_s3_bucket.site
  id = "hammondmutambara-com-site"
}

import {
  to = aws_cloudfront_distribution.site
  id = "E1234567890ABC"
}

import {
  to = aws_acm_certificate.site
  id = "arn:aws:acm:us-east-1:111111111111:certificate/xxxxxxxx"
}
```

3. Run `terraform plan`. The goal is a plan with **no changes**. Wherever it wants to change or replace something, edit the Terraform code to match what actually exists (or decide to accept the change).
4. Never apply a plan that shows `must be replaced` on the distribution, certificate or bucket until you understand why.
5. After a clean apply, delete `imports.tf`.

You can also let Terraform draft the code for you: `terraform plan -generate-config-out=generated.tf` writes resource blocks for imported objects. Treat the output as a starting point and tidy it before committing.

### Adopting the hosted zone

If you also want the zone in Terraform, replace the `data "aws_route53_zone" "main"` block in `terraform/main.tf` with a managed resource and import it:

```hcl
resource "aws_route53_zone" "main" {
  name = var.domain_name

  lifecycle {
    prevent_destroy = true
  }
}

import {
  to = aws_route53_zone.main
  id = "Z0123456789ABCDEFGHIJ" # your hosted zone ID
}
```

Then change every `data.aws_route53_zone.main.zone_id` to `aws_route53_zone.main.zone_id`, and the `name_servers` output to `aws_route53_zone.main.name_servers`. Every record in the zone that Terraform does not manage (MX, TXT and so on) stays untouched, but it is worth adding them to Terraform as well so the zone is fully described in code.

---

## Your other projects

The URL shortener, ECS Fargate app, data pipeline and PowerofMath were built separately. Each lives in its own repository and should follow the same pattern: infrastructure in Terraform, state in S3, deploys through GitHub Actions with OIDC, and a README that says how to build, deploy and tear it down. Use the inventory script to see what exists in the console for each, then apply the rebuild or import route above per project.
