# Runbook

Everyday tasks, in the order you are most likely to need them.

## Update information on the site

Edit `site/index.html`. Common edits:

| I want to change | Where in `index.html` |
|---|---|
| Hero headline and intro | The `<h1>` and `.hero-sub` paragraph near the top |
| What I do | The `#offer` section, one `<article class="offer">` per item |
| Results and numbers | The `#results` section, one `<article class="result">` per figure |
| A project or its description | The `#proof` section, one `<details class="proj">` per project |
| Project, demo, Docker or certificate links | The `LINKS` block in the `<script>` at the bottom |
| Jobs and education | The `#background` section |
| Email, phone, social links | The `#contact` section and the hero button |

**Add a link to a project:** put the URL between the quotes in the `LINKS` block, for example `urlShortener: 'https://github.com/hammond-0023/your-repo'`. Buttons with an empty value stay hidden.

**Add a new project:** copy a whole `<details class="proj">` block, change the text, and add a `data-link` key to its links with a matching entry in `LINKS`.

**Add a photo:** save it as `site/chel.jpg`. Without it the page shows an "HM" badge.

### Preview before publishing

```bash
python3 -m http.server 8000 --directory site
```

Open <http://localhost:8000>. Check it on a phone-sized window as well.

### Publish

```bash
git checkout -b update-projects
# edit site/index.html
git add site
git commit -m "Update projects"
git push -u origin update-projects
```

Open a pull request and merge it. Pushing to `main` starts **Deploy site**, which uploads `site/` and clears the cache. The change is usually live within a minute or two. Check the **Actions** tab if it is not.

You can also push straight to `main` for small edits.

## Change the infrastructure

1. Branch, edit files in `terraform/`, push, and open a pull request.
2. Read the **Terraform plan** summary on the pull request. Look for anything marked `destroy` or `replace`.
3. Merge, then apply locally:

```bash
cd terraform
terraform init -backend-config=backend.hcl
terraform plan
terraform apply
```

Format your files before pushing: `terraform fmt -recursive`. The plan workflow fails on unformatted code.

## Roll back a bad site deploy

The quickest route is Git:

```bash
git revert <bad-commit>
git push
```

That redeploys the previous version. If GitHub Actions is down, restore an earlier file version from S3:

```bash
aws s3api list-object-versions --bucket <bucket> --prefix index.html
aws s3api copy-object --bucket <bucket> --key index.html \
  --copy-source "<bucket>/index.html?versionId=<old-version-id>"
aws cloudfront create-invalidation --distribution-id <id> --paths "/*"
```

Old versions are kept for 30 days.

## Deploy by hand

```bash
./scripts/deploy-site.sh
```

Use this for an emergency fix when CI is unavailable.

## Common problems

| Symptom | Likely cause |
|---|---|
| The page still shows old content | The cache. Check the deploy workflow cleared it, or wait a minute. Hard refresh the browser. |
| Deploy fails with "Not authorized to perform sts:AssumeRoleWithWebIdentity" | The `AWS_DEPLOY_ROLE_ARN` variable is wrong, the workflow did not run from `main`, or `github_repo` in `terraform/variables.tf` does not match the real repository name. |
| Deploy fails with "variable is empty" or an empty bucket name | A GitHub Actions variable is missing. Run `scripts/set-github-vars.sh`. |
| Plan workflow fails at `fmt` | Run `terraform fmt -recursive` and commit. |
| `terraform apply` fails on the certificate | DNS validation takes a few minutes. Run apply again. Confirm the domain's nameservers at the registrar match `terraform output name_servers`. |
| The site shows a 403 or an XML error | A file is missing from the bucket, or the bucket policy no longer matches the distribution. Run `terraform plan` and look for drift. |

## Secrets and credentials

- No AWS keys are stored in GitHub. The workflows use OIDC.
- GitHub Actions **variables** (not secrets) hold IDs and ARNs: `AWS_REGION`, `S3_BUCKET_NAME`, `CLOUDFRONT_DISTRIBUTION_ID`, `AWS_DEPLOY_ROLE_ARN`, `AWS_PLAN_ROLE_ARN`, `TF_STATE_BUCKET`.
- Never commit `*.tfstate`, `backend.hcl` or any `.tfvars` with real values. `.gitignore` already excludes them.
