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
    $MainSha = (Invoke-RestMethod -Headers @{Authorization = "token $GitHubToken"} -Uri "https://api.github.com/repos/$RepoOwner/$RepoName/git/refs/heads/main" -UseBasicParsing).object.sha
    $Response = Invoke-RestMethod -Method Post -Headers @{Authorization = "token $GitHubToken"} -Uri "https://api.github.com/repos/$RepoOwner/$RepoName/git/refs" -Body (@{
        ref = "refs/heads/$BranchName"
        sha = $MainSha
    } | ConvertTo-Json) -UseBasicParsing
    return $Response
}

function Create-File {
    $Response = Invoke-RestMethod -Method Put -Headers @{Authorization = "token $GitHubToken"} -Uri "https://api.github.com/repos/$RepoOwner/$RepoName/contents/$FilePath" -Body (@{
        message = $CommitMessage
        content = $EncodedContent
        branch = $BranchName
    } | ConvertTo-Json) -UseBasicParsing
    return $Response
}

function Create-PullRequest {
    $Response = Invoke-RestMethod -Method Post -Headers @{Authorization = "token $GitHubToken"} -Uri "https://api.github.com/repos/$RepoOwner/$RepoName/pulls" -Body (@{
        title = "Automated Pull Request"
        head = $BranchName
        base = "main"
        body = "This is an automated pull request."
    } | ConvertTo-Json) -UseBasicParsing
    return $Response.number
}

function Merge-PullRequest {
    param ([int]$PrNumber)
    $Response = Invoke-RestMethod -Method Put -Headers @{Authorization = "token $GitHubToken"} -Uri "https://api.github.com/repos/$RepoOwner/$RepoName/pulls/$PrNumber/merge" -Body (@{
        commit_message = "Automated merge"
    } | ConvertTo-Json) -UseBasicParsing
    return $Response
}

try {
    Create-Branch | Out-Null
    Write-Output "Branch created successfully."
    Create-File | Out-Null
    Write-Output "File created successfully."
    $PrNumber = Create-PullRequest
    Write-Output "Pull request created: #$PrNumber"
    Merge-PullRequest -PrNumber $PrNumber | Out-Null
    Write-Output "Pull request merged successfully."
} catch {
    Write-Error $_.Exception.Message
}
