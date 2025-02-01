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

:: Save settings profile
:save_settings_profile
set /p PROFILE_NAME=Enter Profile Name: 
echo REPO_OWNER=%REPO_OWNER%>profiles\%PROFILE_NAME%.env
echo REPO_NAME=%REPO_NAME%>>profiles\%PROFILE_NAME%.env
echo BRANCH_NAME=%BRANCH_NAME%>>profiles\%PROFILE_NAME%.env
echo FILE_PATH=%FILE_PATH%>>profiles\%PROFILE_NAME%.env
echo COMMIT_MESSAGE=%COMMIT_MESSAGE%>>profiles\%PROFILE_NAME%.env
echo Settings profile saved as %PROFILE_NAME%.env

:: Load settings profile
:load_settings_profile
set /p PROFILE_NAME=Enter Profile Name: 
if exist profiles\%PROFILE_NAME%.env (
    for /f "tokens=1,2 delims==" %%i in (profiles\%PROFILE_NAME%.env) do (
        set %%i=%%j
    )
    echo Settings profile %PROFILE_NAME%.env loaded.
) else (
    echo Settings profile %PROFILE_NAME%.env does not exist.
)

:: Show help
:show_help
echo Available Commands:
echo 1. Create Branch
echo 2. Create File
echo 3. Create Pull Request
echo 4. Merge Pull Request
echo 5. Save Settings Profile
echo 6. Load Settings Profile
echo 7. Show Help

:: Main menu
:main_menu
echo Select an option:
echo 1. Create Branch
echo 2. Create File
echo 3. Create Pull Request
echo 4. Merge Pull Request
echo 5. Save Settings Profile
echo 6. Load Settings Profile
echo 7. Show Help
set /p OPTION=Enter your choice: 
if "%OPTION%"=="1" (
    call :create_branch
) else if "%OPTION%"=="2" (
    call :create_file
) else if "%OPTION%"=="3" (
    call :create_pull_request
) else if "%OPTION%"=="4" (
    set /p PR_NUMBER=Enter Pull Request Number: 
    call :merge_pull_request
) else if "%OPTION%"=="5" (
    call :save_settings_profile
) else if "%OPTION%"=="6" (
    call :load_settings_profile
) else if "%OPTION%"=="7" (
    call :show_help
) else (
    echo Invalid option. Please try again.
    goto main_menu
)

:exit
exit /b 0
