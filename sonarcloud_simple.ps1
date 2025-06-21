# Simple SonarCloud Issues Fetcher
# Works reliably on all platforms

param(
    [string]$Token = "",
    [string]$Organization = "w159",
    [string]$ProjectKey = "w159_unstract",
    [string]$OutputFile = "sonarcloud_issues_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv",
    [switch]$SaveToken
)

# Simple token file management
$tokenFile = Join-Path $HOME ".sonarcloud_token"

# Get token
if (-not $Token) {
    # Check environment variable
    if ($env:SONARCLOUD_TOKEN) {
        $Token = $env:SONARCLOUD_TOKEN
        Write-Host "Using token from environment variable" -ForegroundColor Green
    }
    # Check saved token
    elseif (Test-Path $tokenFile) {
        $Token = Get-Content $tokenFile -Raw
        $Token = $Token.Trim()  # Remove any whitespace/newlines
        Write-Host "Using saved token" -ForegroundColor Green
    }
    # Prompt for token
    else {
        Write-Host "SonarCloud API Token Required" -ForegroundColor Yellow
        Write-Host "Generate a token at: https://sonarcloud.io/account/security" -ForegroundColor Gray
        $Token = Read-Host "Enter your SonarCloud API token"
        
        if ($SaveToken) {
            $Token | Out-File $tokenFile -NoNewline
            if ($IsMacOS -or $IsLinux) {
                chmod 600 $tokenFile
            }
            Write-Host "Token saved to: $tokenFile" -ForegroundColor Green
        }
    }
}

# Validate token
Write-Host "`nValidating API token..." -NoNewline
$headers = @{
    "Authorization" = "Bearer $Token"
}

try {
    $testUrl = "https://sonarcloud.io/api/authentication/validate"
    $null = Invoke-RestMethod -Uri $testUrl -Headers $headers -Method Get
    Write-Host " Valid!" -ForegroundColor Green
} catch {
    Write-Host " Failed!" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    
    # If saved token failed, remove it
    if (Test-Path $tokenFile) {
        Remove-Item $tokenFile
        Write-Host "Removed invalid saved token" -ForegroundColor Yellow
    }
    exit 1
}

# Fetch issues
Write-Host "`nFetching issues from project: $ProjectKey"
Write-Host "Organization: $Organization`n"

$allIssues = @()
$page = 1
$pageSize = 500

do {
    Write-Host "Fetching page $page..." -NoNewline
    
    $url = "https://sonarcloud.io/api/issues/search?" +
           "componentKeys=$ProjectKey&" +
           "organization=$Organization&" +
           "statuses=OPEN,CONFIRMED,REOPENED&" +
           "ps=$pageSize&" +
           "p=$page&" +
           "s=FILE_LINE&" +
           "additionalFields=_all"
    
    try {
        $response = Invoke-RestMethod -Uri $url -Headers $headers -Method Get
        
        if ($page -eq 1) {
            $totalIssues = $response.total
            Write-Host " Total issues: $totalIssues" -ForegroundColor Green
        } else {
            Write-Host " Done" -ForegroundColor Green
        }
        
        # Process issues
        foreach ($issue in $response.issues) {
            $allIssues += [PSCustomObject]@{
                Key = $issue.key
                Type = $issue.type
                Rule = $issue.rule
                Severity = $issue.severity
                Status = $issue.status
                Component = $issue.component -replace "^${ProjectKey}:", ""
                Message = $issue.message
                Line = $issue.line
                Author = $issue.author
                CreationDate = $issue.creationDate
                UpdateDate = $issue.updateDate
                Tags = ($issue.tags -join ";")
                URL = "https://sonarcloud.io/project/issues?id=${ProjectKey}&open=$($issue.key)"
            }
        }
        
        if ($response.issues.Count -lt $pageSize) {
            break
        }
        $page++
        
    } catch {
        Write-Host " Failed!" -ForegroundColor Red
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        break
    }
} while ($true)

# Export to CSV
Write-Host "`nTotal issues collected: $($allIssues.Count)"
$allIssues | Export-Csv -Path $OutputFile -NoTypeInformation
Write-Host "Exported to: $OutputFile" -ForegroundColor Cyan

# Summary
Write-Host "`nSummary by Severity:"
$allIssues | Group-Object Severity | Sort-Object Name | Format-Table Name, Count -AutoSize

Write-Host "Top 5 Rules:"
$allIssues | Group-Object Rule | Sort-Object Count -Descending | Select-Object -First 5 | Format-Table Name, Count -AutoSize