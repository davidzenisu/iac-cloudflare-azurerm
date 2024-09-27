# iac-cloudflare
Repository to manage DNS entries in Cloudflare using IaC

## Getting started

To get started, [fork this repository](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/working-with-forks/fork-a-repo).
Then, depending on your preferred setup, the following configuration has to be set:

### GitHub Secrets (GitHub Action workflows)

If you are using the provided GitHub Actions, make sure the following variables are set as secrets:

- *CLOUDFLARE_API_TOKEN*: Token to authenticate with the Cloudflare API. Should be considered highly sensitive. For more details see [here](https://developers.cloudflare.com/fundamentals/api/get-started/create-token/).
- *DNS_ZONE_NAME*: Name of the configured DNS domain. Will be treated as sensitive input variable.

### Environment variables (local development)

Deploying through GitHub Actions does not require setting environment variables (this is done as part of the workflow).
*If this is the case, the next section can be skipped!*

Ensure the following environment variables are set.
If you are running deployments in an non-interactive scenario, consider using the configuration tools provided by your CI/CD platform (e.g. [Github secrets](https://docs.github.com/en/actions/security-for-github-actions/security-guides/using-secrets-in-github-actions))

- *CLOUDFLARE_API_TOKEN*: Token to authenticate with the Cloudflare API. Should be considered highly sensitive. For more details see [here](https://developers.cloudflare.com/fundamentals/api/get-started/create-token/).
- *TF_VAR_zone_name* (_optional, recommended_): Name of the configured DNS domain. Will be treated as sensitive input variable.

### tfvars

Finally, create a `variables.tfvars` file when working locally or bring in external configuration dynamically as part of your CD to securly configure the different DNS records.
