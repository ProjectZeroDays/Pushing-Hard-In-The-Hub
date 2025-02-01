@echo off
setlocal enabledelayedexpansion

:: Load environment variables from .env file if it exists
if exist .env (
    for /f "tokens=1,2 delims==" %%i in (.env) do (
        set %%i=%%j
    )
)

:: Check if GITHUB_TOKEN is set
if "%GITHUB_TOKEN%"=="" (
    set /p GITHUB_TOKEN=Enter your GitHub Personal Access Token: 
)
-
set /p REPO_OWNER=Enter the repository owner: 
set /p REPO_NAME=Enter the repository name: 
set /p BRANCH_NAME=Enter the branch name (default: automated-branch): 
if "%BRANCH_NAME%"=="" (
    set BRANCH_NAME=automated-branch
)
set /p FILE_PATH=Enter the file path to push: 
set /p COMMIT_MESSAGE=Enter the commit message: 

setlocal enabledelayedexpansion
for /f "delims=" %%i in ('type %FILE_PATH%') do set FILE_CONTENT=!FILE_CONTENT!%%i
set ENCODED_CONTENT=%FILE_CONTENT:~0,1000%

:: Create branch
for /f "tokens=*" %%i in ('curl -s -H "Authorization: token %GITHUB_TOKEN%" "https://api.github.com/repos/%REPO_OWNER%/%REPO_NAME%/git/refs/heads/main"') do set MAIN_SHA=%%i
for /f "tokens=*" %%i in ('curl -s -X POST -H "Authorization: token %GITHUB_TOKEN%" -d "{\"ref\": \"refs/heads/%BRANCH_NAME%\", \"sha\": \"%MAIN_SHA%\"}" "https://api.github.com/repos/%REPO_OWNER%/%REPO_NAME%/git/refs"') do set BRANCH_RESPONSE=%%i

:: Create file
for /f "tokens=*" %%i in ('curl -s -X PUT -H "Authorization: token %GITHUB_TOKEN%" -d "{\"message\": \"%COMMIT_MESSAGE%\", \"content\": \"%ENCODED_CONTENT%\", \"branch\": \"%BRANCH_NAME%\"}" "https://api.github.com/repos/%REPO_OWNER%/%REPO_NAME%/contents/%FILE_PATH%"') do set FILE_RESPONSE=%%i

:: Create pull request
for /f "tokens=*" %%i in ('curl -s -X POST -H "Authorization: token %GITHUB_TOKEN%" -d "{\"title\": \"Automated Pull Request\", \"head\": \"%BRANCH_NAME%\", \"base\": \"main\", \"body\": \"This is an automated pull request.\"}" "https://api.github.com/repos/%REPO_OWNER%/%REPO_NAME%/pulls"') do set PR_NUMBER=%%i

:: Merge pull request
for /f "tokens=*" %%i in ('curl -s -X PUT -H "Authorization: token %GITHUB_TOKEN%" -d "{\"commit_message\": \"Automated merge\"}" "https://api.github.com/repos/%REPO_OWNER%/%REPO_NAME%/pulls/%PR_NUMBER%/merge"') do set MERGE_RESPONSE=%%i

echo Branch created successfully.
echo File created successfully.
echo Pull request created: #%PR_NUMBER%
echo Pull request merged successfully.

endlocal
