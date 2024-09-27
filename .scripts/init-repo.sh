SECRET_KEY=CLOUDFLARE_API_TOKEN

echo Logging into GitHub...

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

read -p "Enter Cloudflare API key: " INPUT

read -p "Are you want to set the secret '$SECRET_KEY' for your current repo? (yes/no) " yn

case $yn in 
	yes ) echo Ok, setting secret...;;
	no ) echo exiting...;
        cancel=1;;
	* ) echo invalid response;
        echo exiting...;
        cancel=1;;
esac

if [ -z "$cancel" ]
then
gh secret set $SECRET_KEY --body "$INPUT"
fi

export GITHUB_TOKEN=$GITHUB_TOKEN_CACHE