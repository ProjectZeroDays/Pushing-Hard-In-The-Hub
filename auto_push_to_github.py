import os
import base64
import requests
import json
import logging
from dotenv import load_dotenv

load_dotenv()

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

GITHUB_TOKEN = os.getenv('GITHUB_TOKEN')
if not GITHUB_TOKEN:
    GITHUB_TOKEN = input("Enter your GitHub Personal Access Token: ")

REPO_OWNER = input("Enter the repository owner: ")
REPO_NAME = input("Enter the repository name: ")
BRANCH_NAME = input("Enter the branch name (default: automated-branch): ") or "automated-branch"
FILE_PATHS = input("Enter the file paths to push (comma-separated): ").split(',')
COMMIT_MESSAGE = input("Enter the commit message: ")

def get_file_content(file_path):
    with open(file_path, "r") as file:
        content = file.read()
    return base64.b64encode(content.encode()).decode()

def create_branch():
    try:
        url = f"https://api.github.com/repos/{REPO_OWNER}/{REPO_NAME}/git/refs/heads/main"
        headers = {"Authorization": f"token {GITHUB_TOKEN}"}
        response = requests.get(url, headers=headers)
        response.raise_for_status()
        main_sha = response.json()["object"]["sha"]
        
        url = f"https://api.github.com/repos/{REPO_OWNER}/{REPO_NAME}/git/refs"
        data = {"ref": f"refs/heads/{BRANCH_NAME}", "sha": main_sha}
        response = requests.post(url, headers=headers, json=data)
        response.raise_for_status()
        logging.info("Branch created successfully.")
        return response.json()
    except requests.exceptions.RequestException as e:
        logging.error(f"Failed to create branch: {e}")
        return None

def create_file(file_path):
    try:
        url = f"https://api.github.com/repos/{REPO_OWNER}/{REPO_NAME}/contents/{file_path}"
        headers = {"Authorization": f"token {GITHUB_TOKEN}"}
        data = {
            "message": COMMIT_MESSAGE,
            "content": get_file_content(file_path),
            "branch": BRANCH_NAME
        }
        response = requests.put(url, headers=headers, json=data)
        response.raise_for_status()
        logging.info(f"File {file_path} created successfully.")
        return response.json()
    except requests.exceptions.RequestException as e:
        logging.error(f"Failed to create file {file_path}: {e}")
        return None

def create_pull_request():
    try:
        url = f"https://api.github.com/repos/{REPO_OWNER}/{REPO_NAME}/pulls"
        headers = {"Authorization": f"token {GITHUB_TOKEN}"}
        data = {
            "title": "Automated Pull Request",
            "head": BRANCH_NAME,
            "base": "main",
            "body": "This is an automated pull request."
        }
        response = requests.post(url, headers=headers, json=data)
        response.raise_for_status()
        logging.info("Pull request created successfully.")
        return response.json()["number"]
    except requests.exceptions.RequestException as e:
        logging.error(f"Failed to create pull request: {e}")
        return None

def merge_pull_request(pr_number):
    try:
        url = f"https://api.github.com/repos/{REPO_OWNER}/{REPO_NAME}/pulls/{pr_number}/merge"
        headers = {"Authorization": f"token {GITHUB_TOKEN}"}
        data = {"commit_message": "Automated merge"}
        response = requests.put(url, headers=headers, json(data))
        response.raise_for_status()
        logging.info("Pull request merged successfully.")
        return response.json()
    except requests.exceptions.RequestException as e:
        logging.error(f"Failed to merge pull request: {e}")
        return None

def save_settings_profile(profile_name):
    profile_content = {
        "RepoOwner": REPO_OWNER,
        "RepoName": REPO_NAME,
        "BranchName": BRANCH_NAME,
        "FilePaths": FILE_PATHS,
        "CommitMessage": COMMIT_MESSAGE
    }
    with open(f"profiles/{profile_name}.json", "w") as file:
        json.dump(profile_content, file)
    logging.info(f"Settings profile saved as {profile_name}.json")

def load_settings_profile(profile_name):
    if os.path.exists(f"profiles/{profile_name}.json"):
        with open(f"profiles/{profile_name}.json", "r") as file:
            profile_content = json.load(file)
        global REPO_OWNER, REPO_NAME, BRANCH_NAME, FILE_PATHS, COMMIT_MESSAGE
        REPO_OWNER = profile_content["RepoOwner"]
        REPO_NAME = profile_content["RepoName"]
        BRANCH_NAME = profile_content["BranchName"]
        FILE_PATHS = profile_content["FilePaths"]
        COMMIT_MESSAGE = profile_content["CommitMessage"]
        logging.info(f"Settings profile {profile_name}.json loaded.")
    else:
        logging.error(f"Settings profile {profile_name}.json does not exist.")

def show_help():
    print("Available Commands:")
    print("1. Create-Branch")
    print("2. Create-File")
    print("3. Create-PullRequest")
    print("4. Merge-PullRequest")
    print("5. Save-SettingsProfile")
    print("6. Load-SettingsProfile")
    print("7. Show-Help")

def main_menu():
    print("Select an option:")
    print("1. Create Branch")
    print("2. Create File")
    print("3. Create Pull Request")
    print("4. Merge Pull Request")
    print("5. Save Settings Profile")
    print("6. Load Settings Profile")
    print("7. Show Help")
    option = input("Enter your choice: ")
    if option == "1":
        create_branch()
    elif option == "2":
        for file_path in FILE_PATHS:
            create_file(file_path)
    elif option == "3":
        pr_number = create_pull_request()
        if pr_number:
            print(f"Pull request created: #{pr_number}")
    elif option == "4":
        pr_number = input("Enter Pull Request Number: ")
        merge_pull_request(pr_number)
    elif option == "5":
        profile_name = input("Enter Profile Name: ")
        save_settings_profile(profile_name)
    elif option == "6":
        profile_name = input("Enter Profile Name: ")
        load_settings_profile(profile_name)
    elif option == "7":
        show_help()
    else:
        print("Invalid option. Please try again.")
        main_menu()

main_menu()
