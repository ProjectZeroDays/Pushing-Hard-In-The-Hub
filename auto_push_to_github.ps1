param (
    [string]$RepoOwner,
    [string]$RepoName,
    [string]$BranchName = "automated-branch",
    [string]$FilePath,
    [string]$CommitMessage
)

# Load environment variables from .env file if it exists
if (Test-Path .env) {
    Get-Content .env | ForEach-Object {
        if ($_ -match "^(.*?)=(.*)$") {
            [System.Environment]::SetEnvironmentVariable($matches[1], $matches[2])
        }
    }
}

# Check if GITHUB_TOKEN is set
$GitHubToken = $env:GITHUB_TOKEN
if (-not $GitHubToken) {
    $GitHubToken = Read-Host -Prompt "Enter your GitHub Personal Access Token"
}

$FileContent = Get-Content -Raw -Path $FilePath
$EncodedContent = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($FileContent))

function Create-Branch {
    try {
        $MainSha = (Invoke-RestMethod -Headers @{Authorization = "token $GitHubToken"} -Uri "https://api.github.com/repos/$RepoOwner/$RepoName/git/refs/heads/main" -UseBasicParsing).object.sha
        $Response = Invoke-RestMethod -Method Post -Headers @{Authorization = "token $GitHubToken"} -Uri "https://api.github.com/repos/$RepoOwner/$RepoName/git/refs" -Body (@{
            ref = "refs/heads/$BranchName"
            sha = $MainSha
        } | ConvertTo-Json) -UseBasicParsing
        Write-Output "Branch created successfully."
        return $Response
    } catch {
        Write-Error "Failed to create branch: $_"
    }
}

function Create-File {
    try {
        $Response = Invoke-RestMethod -Method Put -Headers @{Authorization = "token $GitHubToken"} -Uri "https://api.github.com/repos/$RepoOwner/$RepoName/contents/$FilePath" -Body (@{
            message = $CommitMessage
            content = $EncodedContent
            branch = $BranchName
        } | ConvertTo-Json) -UseBasicParsing
        Write-Output "File created successfully."
        return $Response
    } catch {
        Write-Error "Failed to create file: $_"
    }
}

function Create-PullRequest {
    try {
        $Response = Invoke-RestMethod -Method Post -Headers @{Authorization = "token $GitHubToken"} -Uri "https://api.github.com/repos/$RepoOwner/$RepoName/pulls" -Body (@{
            title = "Automated Pull Request"
            head = $BranchName
            base = "main"
            body = "This is an automated pull request."
        } | ConvertTo-Json) -UseBasicParsing
        Write-Output "Pull request created successfully."
        return $Response.number
    } catch {
        Write-Error "Failed to create pull request: $_"
    }
}

function Merge-PullRequest {
    param ([int]$PrNumber)
    try {
        $Response = Invoke-RestMethod -Method Put -Headers @{Authorization = "token $GitHubToken"} -Uri "https://api.github.com/repos/$RepoOwner/$RepoName/pulls/$PrNumber/merge" -Body (@{
            commit_message = "Automated merge"
        } | ConvertTo-Json) -UseBasicParsing
        Write-Output "Pull request merged successfully."
        return $Response
    } catch {
        Write-Error "Failed to merge pull request: $_"
    }
}

function Save-SettingsProfile {
    param ($ProfileName)
    $ProfileContent = @{
        RepoOwner = $RepoOwner
        RepoName = $RepoName
        BranchName = $BranchName
        FilePath = $FilePath
        CommitMessage = $CommitMessage
    }
    $ProfileContent | ConvertTo-Json | Set-Content -Path ".\profiles\$ProfileName.json"
    Write-Output "Settings profile saved as $ProfileName.json"
}

function Load-SettingsProfile {
    param ($ProfileName)
    if (Test-Path ".\profiles\$ProfileName.json") {
        $ProfileContent = Get-Content -Path ".\profiles\$ProfileName.json" | ConvertFrom-Json
        $global:RepoOwner = $ProfileContent.RepoOwner
        $global:RepoName = $ProfileContent.RepoName
        $global:BranchName = $ProfileContent.BranchName
        $global:FilePath = $ProfileContent.FilePath
        $global:CommitMessage = $ProfileContent.CommitMessage
        Write-Output "Settings profile $ProfileName.json loaded."
    } else {
        Write-Output "Settings profile $ProfileName.json does not exist."
    }
}

function Show-Help {
    Write-Output "Available Commands:"
    Write-Output "1. Create-Branch"
    Write-Output "2. Create-File"
    Write-Output "3. Create-PullRequest"
    Write-Output "4. Merge-PullRequest"
    Write-Output "5. Save-SettingsProfile"
    Write-Output "6. Load-SettingsProfile"
    Write-Output "7. Show-Help"
}

function Main-Menu {
    Write-Output "Select an option:"
    Write-Output "1. Create Branch"
    Write-Output "2. Create File"
    Write-Output "3. Create Pull Request"
    Write-Output "4. Merge Pull Request"
    Write-Output "5. Save Settings Profile"
    Write-Output "6. Load Settings Profile"
    Write-Output "7. Show Help"
    $Option = Read-Host -Prompt "Enter your choice"
    switch ($Option) {
        1 { Create-Branch }
        2 { Create-File }
        3 { Create-PullRequest }
        4 { $PrNumber = Read-Host -Prompt "Enter Pull Request Number"; Merge-PullRequest -PrNumber $PrNumber }
        5 { $ProfileName = Read-Host -Prompt "Enter Profile Name"; Save-SettingsProfile -ProfileName $ProfileName }
        6 { $ProfileName = Read-Host -Prompt "Enter Profile Name"; Load-SettingsProfile -ProfileName $ProfileName }
        7 { Show-Help }
        default { Write-Output "Invalid option. Please try again." }
    }
}

Main-Menu
