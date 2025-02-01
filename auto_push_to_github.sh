
#!/bin/bash

# Load environment variables from .env file if it exists
if [ -f .env ]; then
    export $(cat .env | xargs)
fi

# Check if GITHUB_TOKEN is set
if [ -z "$GITHUB_TOKEN" ]; then
    read -p "Enter your GitHub Personal Access Token: " GITHUB_TOKEN
fi

read -p "Enter the repository owner: " REPO_OWNER
read -p "Enter the repository name: " REPO_NAME
read -p "Enter the branch name (default: automated-branch): " BRANCH_NAME
BRANCH_NAME=${BRANCH_NAME:-automated-branch}
read -p "Enter the file path to push: " FILE_PATH
read -p "Enter the commit message: " COMMIT_MESSAGE

FILE_CONTENT=$(base64 -w 0 $FILE_PATH)

create_branch() {
    MAIN_SHA=$(curl -s -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/git/refs/heads/main | jq -r .object.sha)
    curl -s -X POST -H "Authorization: token $GITHUB_TOKEN" -d "{\"ref\": \"refs/heads/$BRANCH_NAME\", \"sha\": \"$MAIN_SHA\"}" https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/git/refs
}

create_file() {
    curl -s -X PUT -H "Authorization: token $GITHUB_TOKEN" -d "{\"message\": \"$COMMIT_MESSAGE\", \"content\": \"$FILE_CONTENT\", \"branch\": \"$BRANCH_NAME\"}" https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/contents/$FILE_PATH
}

create_pull_request() {
    PR_NUMBER=$(curl -s -X POST -H "Authorization: token $GITHUB_TOKEN" -d "{\"title\": \"Automated Pull Request\", \"head\": \"$BRANCH_NAME\", \"base\": \"main\", \"body\": \"This is an automated pull request.\"}" https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/pulls | jq -r .number)
    echo $PR_NUMBER
}

merge_pull_request() {
    PR_NUMBER=$1
    curl -s -X PUT -H "Authorization: token $GITHUB_TOKEN" -d "{\"commit_message\": \"Automated merge\"}" https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/pulls/$PR_NUMBER/merge
}

save_settings_profile() {
    PROFILE_NAME=$1
    mkdir -p profiles
    echo "REPO_OWNER=$REPO_OWNER" > profiles/$PROFILE_NAME.env
    echo "REPO_NAME=$REPO_NAME" >> profiles/$PROFILE_NAME.env
    echo "BRANCH_NAME=$BRANCH_NAME" >> profiles/$PROFILE_NAME.env
    echo "FILE_PATH=$FILE_PATH" >> profiles/$PROFILE_NAME.env
    echo "COMMIT_MESSAGE=$COMMIT_MESSAGE" >> profiles/$PROFILE_NAME.env
    echo "Settings profile saved as $PROFILE_NAME.env"
}

load_settings_profile() {
    PROFILE_NAME=$1
    if [ -f profiles/$PROFILE_NAME.env ]; then
        export $(cat profiles/$PROFILE_NAME.env | xargs)
        echo "Settings profile $PROFILE_NAME.env loaded."
    else
        echo "Settings profile $PROFILE_NAME.env does not exist."
    fi
}

show_help() {
    echo "Available Commands:"
    echo "1. create_branch"
    echo "2. create_file"
    echo "3. create_pull_request"
    echo "4. merge_pull_request"
    echo "5. save_settings_profile"
    echo "6. load_settings_profile"
    echo "7. show_help"
}

main_menu() {
    echo "Select an option:"
    echo "1. Create Branch"
    echo "2. Create File"
    echo "3. Create Pull Request"
    echo "4. Merge Pull Request"
    echo "5. Save Settings Profile"
    echo "6. Load Settings Profile"
    echo "7. Show Help"
    read -p "Enter your choice: " OPTION
    case $OPTION in
        1) create_branch ;;
        2) create_file ;;
        3) PR_NUMBER=$(create_pull_request); echo "Pull request created: #$PR_NUMBER" ;;
        4) read -p "Enter Pull Request Number: " PR_NUMBER; merge_pull_request $PR_NUMBER ;;
        5) read -p "Enter Profile Name: " PROFILE_NAME; save_settings_profile $PROFILE_NAME ;;
        6) read -p "Enter Profile Name: " PROFILE_NAME; load_settings_profile $PROFILE_NAME ;;
        7) show_help ;;
        *) echo "Invalid option. Please try again."; main_menu ;;
    esac
}

main_menu
