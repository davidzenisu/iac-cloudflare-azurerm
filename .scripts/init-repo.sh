CLOUDFLARE_SECRET_KEY=CLOUDFLARE_API_TOKEN
AZURE_TENANT_ID_KEY=AZURE_TENANT_ID
AZURE_SUBCRIPTION_ID_KEY=AZURE_SUBSCRIPTION_ID
AZURE_CLIENT_ID_KEY=AZURE_CLIENT_ID
AZURE_BACKEND_RG_KEY=AZURE_BACKEND_RG
AZURE_BACKEND_ST_KEY=AZURE_BACKEND_ST

#formatting
red='\033[0;31m'
green='\033[0;32m'
nc='\033[0m' # No Color

#cache github token!
GITHUB_TOKEN_CACHE=$GITHUB_TOKEN
export GITHUB_TOKEN=""

gh_logged_in=$(gh auth status)
if [ ! -z "$gh_logged_in" ]
then
    echo Already logged into GitHub CLI.
else
    echo Login into GitHub CLI required.
    echo Logging in...
    gh auth login
fi

gh_repo_name=$(gh repo view --json name -q ".name")
gh_owner_name=$(gh repo view --json owner -q ".owner.login")

az_logged_in=$(az account show)
if [ ! -z "$az_logged_in" ]
then
    echo Already logged into Azure CLI.
else
    echo Login into Azure CLI required.
    echo Logging in...
    az login --use-device-code
fi

read -p "Enter the name of your backend Azure Resource Group: " AZURE_BACKEND_RG_INPUT
read -p "Enter the name of your backend Azure Storage Account: " AZURE_BACKEND_ST_INPUT

echo Validating storage account...

storage_account=$(az storage account show -n $AZURE_BACKEND_ST_INPUT -g $AZURE_BACKEND_RG_INPUT 2>/dev/null)
if [ ! -z "$storage_account" ]
then
    echo -e "${green}✓${nc} Storage account validated!"
else
    echo -e "${red}Storage account does not exist! Please specify an existing storage account!${nc}"
    export GITHUB_TOKEN=$GITHUB_TOKEN_CACHE
    exit 1
fi

azure_backend_st_container_name="$gh_owner_name"
storage_container=$(az storage container exists \
    -n $azure_backend_st_container_name \
    --auth-mode login \
    --blob-endpoint $(echo $storage_account | jq -r '.primaryEndpoints.blob'))
if [ $(echo $storage_container | jq -r '.exists') = true ]
then
    echo -e "${green}✓${nc} Storage container validated!"
else
    echo -e "${red}Storage container $azure_backend_st_container_name does not exist! Please ensure a container with this name exists!${nc}"
    export GITHUB_TOKEN=$GITHUB_TOKEN_CACHE
    exit 1
fi

read -p "Enter your Cloudflare API key: " CLOUDFLARE_SECRET_INPUT

read -p "Are you want to set the secrets for Cloudflare and Azure for your current repo and allow GitHub access to Azure? (yes/no) " yn

case $yn in 
	yes ) echo Ok, setting secret...;;
	no ) echo exiting...;
        cancel=1;;
	* ) echo invalid response;
        echo exiting...;
        cancel=1;;
esac

if [ ! -z "$cancel" ]
then
    export GITHUB_TOKEN=$GITHUB_TOKEN_CACHE
    exit 1
fi

echo Checking managed identity...

az_id_name="id-gh-${gh_owner_name}-${gh_repo_name}"

az_managed_identity=$(az identity show -n $az_id_name -g $AZURE_BACKEND_RG_INPUT 2>/dev/null)
if [ ! -z "$az_managed_identity" ]
then
    echo Managed identity already exists.
else
    echo Managed identity has to be created.
    echo Creating managed identity...
    az_managed_identity=$(az identity create -n $az_id_name -g $AZURE_BACKEND_RG_INPUT)
fi

echo Setting storage account permissions...

role_assignment=$(az role assignment create \
    --role "Storage Blob Data Contributor" \
    --scope "$(echo $storage_account | jq -r '.id')" \
    --assignee-principal-type ServicePrincipal \
    --assignee-object-id $(echo $az_managed_identity | jq -r '.principalId'))
echo -e "${green}✓${nc} Set Storage account permissions for managed identity"

echo Setting Azure federated credentials...

credential_main=$(az identity federated-credential create \
    -g $AZURE_BACKEND_RG_INPUT \
    --identity-name $az_id_name \
    -n "gh-branch-main" \
    --subject "repo:${gh_owner_name}/${gh_repo_name}:ref:refs/heads/main" \
    --issuer "https://token.actions.githubusercontent.com" \
    --audiences "api://AzureADTokenExchange")
echo -e "${green}✓${nc} Set Federated credential for main branch"

credential_pr=$(az identity federated-credential create \
    -g $AZURE_BACKEND_RG_INPUT \
    --identity-name $az_id_name \
    -n "gh-pullrequest" \
    --subject "repo:${gh_owner_name}/${gh_repo_name}:pull_request" \
    --issuer "https://token.actions.githubusercontent.com" \
    --audiences "api://AzureADTokenExchange")
echo -e "${green}✓${nc} Set Federated credential for pull request"

echo Setting secrets...

gh secret set $CLOUDFLARE_SECRET_KEY --body "$CLOUDFLARE_SECRET_INPUT"
gh secret set $AZURE_TENANT_ID_KEY --body "$(az account show | jq -r '.tenantId')"
gh secret set $AZURE_SUBCRIPTION_ID_KEY --body "$(az account show | jq -r '.id')"
gh secret set $AZURE_CLIENT_ID_KEY --body "$(echo $az_managed_identity | jq -r '.clientId')"
gh secret set $AZURE_BACKEND_RG_KEY --body "$AZURE_BACKEND_RG_INPUT"
gh secret set $AZURE_BACKEND_ST_KEY --body "$AZURE_BACKEND_ST_INPUT"

export GITHUB_TOKEN=$GITHUB_TOKEN_CACHE

echo SETUP FINISHED SUCCESSFULLY!