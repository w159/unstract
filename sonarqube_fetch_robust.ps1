# Robust SonarQube Issues Fetcher with Token Management
# This script fetches ALL issues from SonarQube with proper error handling and token management

param(
    [string]$OutputPath = "sonarqube_issues_$(Get-Date -Format 'yyyy-MM-dd_HHmmss').csv",
    [string]$Organization = "w159",
    [string]$ProjectKey = "w159_unstract",
    [int]$PageSize = 100,
    [switch]$IncludeClosed = $false
)

# Function to create web session with cookies
function New-SonarSession {
    param(
        [string]$JwtToken,
        [string]$XsrfToken
    )
    
    $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
    $session.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    
    # Add essential cookies
    $cookies = @{
        "XSRF-TOKEN" = $XsrfToken
        "JWT-SESSION" = $JwtToken
    }
    
    foreach ($cookieName in $cookies.Keys) {
        if ($cookies[$cookieName]) {
            $session.Cookies.Add((New-Object System.Net.Cookie($cookieName, $cookies[$cookieName], "/", ".sonarcloud.io")))
        }
    }
    
    return $session
}

# Function to fetch issues from a single page
function Get-SonarIssuesPage {
    param(
        [Microsoft.PowerShell.Commands.WebRequestSession]$Session,
        [string]$BaseUrl,
        [hashtable]$Parameters,
        [int]$Page,
        [string]$XsrfToken
    )
    
    # Build query string
    $queryParams = @()
    foreach ($key in $Parameters.Keys) {
        $queryParams += "$key=$([System.Web.HttpUtility]::UrlEncode($Parameters[$key]))"
    }
    $queryParams += "p=$Page"
    $url = "$BaseUrl?" + ($queryParams -join "&")
    
    $headers = @{
        "Accept" = "application/json"
        "Accept-Language" = "en-US,en;q=0.9"
        "Referer" = "https://sonarcloud.io/project/issues?id=$($Parameters.componentKeys)"
        "X-XSRF-TOKEN" = $XsrfToken
    }
    
    try {
        $response = Invoke-WebRequest -Uri $url -WebSession $Session -Headers $headers -Method Get -UseBasicParsing
        return ($response.Content | ConvertFrom-Json)
    } catch {
        throw "Failed to fetch page $Page : $_"
    }
}

# Main script
Write-Host "SonarQube Issues Fetcher" -ForegroundColor Cyan
Write-Host "========================" -ForegroundColor Cyan
Write-Host "Organization: $Organization" -ForegroundColor Gray
Write-Host "Project: $ProjectKey" -ForegroundColor Gray
Write-Host "Output: $OutputPath" -ForegroundColor Gray
Write-Host ""

# Prompt for authentication if needed
Write-Host "Authentication Required" -ForegroundColor Yellow
Write-Host "Please provide your SonarCloud session tokens." -ForegroundColor Gray
Write-Host "You can find these in your browser's Developer Tools > Application > Cookies" -ForegroundColor Gray
Write-Host ""

$jwtToken = Read-Host -Prompt "Enter JWT-SESSION token"
$xsrfToken = Read-Host -Prompt "Enter XSRF-TOKEN"

if (-not $jwtToken -or -not $xsrfToken) {
    Write-Host "Error: Both JWT-SESSION and XSRF-TOKEN are required" -ForegroundColor Red
    exit 1
}

# Create session
$session = New-SonarSession -JwtToken $jwtToken -XsrfToken $xsrfToken

# API endpoint and parameters
$apiUrl = "https://sonarcloud.io/api/issues/search"
$issueStatuses = if ($IncludeClosed) { "OPEN,CONFIRMED,REOPENED,RESOLVED,CLOSED" } else { "OPEN,CONFIRMED,REOPENED" }

$parameters = @{
    "s" = "FILE_LINE"
    "issueStatuses" = $issueStatuses
    "ps" = $PageSize
    "componentKeys" = $ProjectKey
    "organization" = $Organization
    "additionalFields" = "_all"
}

# Initialize collection
$allIssues = New-Object System.Collections.ArrayList
$currentPage = 1
$totalPages = 1
$retryCount = 0
$maxRetries = 3

Write-Host "Fetching issues..." -ForegroundColor Cyan

# Fetch all pages
do {
    try {
        Write-Host "Fetching page $currentPage/$totalPages..." -NoNewline
        
        $pageData = Get-SonarIssuesPage -Session $session -BaseUrl $apiUrl -Parameters $parameters -Page $currentPage -XsrfToken $xsrfToken
        
        # Update total pages on first request
        if ($currentPage -eq 1) {
            $totalIssues = $pageData.paging.total
            $totalPages = [Math]::Ceiling($totalIssues / $PageSize)
            Write-Host " (Total issues: $totalIssues, Pages: $totalPages)" -ForegroundColor Green
        } else {
            Write-Host " Done" -ForegroundColor Green
        }
        
        # Process issues
        foreach ($issue in $pageData.issues) {
            $processedIssue = [PSCustomObject]@{
                Key = $issue.key
                Type = $issue.type
                Rule = $issue.rule
                Severity = $issue.severity
                Component = $issue.component
                Project = $issue.project
                Status = $issue.status
                Resolution = $issue.resolution
                Message = $issue.message
                Effort = $issue.effort
                Debt = $issue.debt
                Author = $issue.author
                Tags = ($issue.tags -join "; ")
                CreationDate = $issue.creationDate
                UpdateDate = $issue.updateDate
                CloseDate = $issue.closeDate
                Line = $issue.line
                TextRange = if ($issue.textRange) { 
                    "L$($issue.textRange.startLine):$($issue.textRange.startOffset)-L$($issue.textRange.endLine):$($issue.textRange.endOffset)" 
                } else { "" }
                Hash = $issue.hash
                URL = "https://sonarcloud.io/project/issues?id=$ProjectKey&open=$($issue.key)"
                Assignee = $issue.assignee
                Comments = $issue.comments.Count
                Attributes = ($issue.attributes.PSObject.Properties | ForEach-Object { "$($_.Name)=$($_.Value)" }) -join "; "
            }
            
            [void]$allIssues.Add($processedIssue)
        }
        
        $currentPage++
        $retryCount = 0
        
        # Small delay to avoid rate limiting
        if ($currentPage -le $totalPages) {
            Start-Sleep -Milliseconds 300
        }
        
    } catch {
        $retryCount++
        if ($retryCount -le $maxRetries) {
            Write-Host " Retry $retryCount/$maxRetries" -ForegroundColor Yellow
            Start-Sleep -Seconds 2
        } else {
            Write-Host " Failed" -ForegroundColor Red
            Write-Host "Error: $_" -ForegroundColor Red
            break
        }
    }
} while ($currentPage -le $totalPages)

Write-Host ""
Write-Host "Fetch complete! Total issues collected: $($allIssues.Count)" -ForegroundColor Green

# Export to CSV
try {
    $allIssues | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
    Write-Host "Issues exported to: $OutputPath" -ForegroundColor Cyan
} catch {
    Write-Host "Error exporting to CSV: $_" -ForegroundColor Red
    exit 1
}

# Display summary
Write-Host ""
Write-Host "Summary Report" -ForegroundColor Cyan
Write-Host "==============" -ForegroundColor Cyan

# Summary by severity
Write-Host ""
Write-Host "Issues by Severity:" -ForegroundColor Yellow
$severitySummary = $allIssues | Group-Object Severity | Sort-Object Name
foreach ($group in $severitySummary) {
    $percentage = [Math]::Round(($group.Count / $allIssues.Count) * 100, 1)
    Write-Host "  $($group.Name): $($group.Count) ($percentage%)"
}

# Summary by type
Write-Host ""
Write-Host "Issues by Type:" -ForegroundColor Yellow
$typeSummary = $allIssues | Group-Object Type | Sort-Object Count -Descending
foreach ($group in $typeSummary) {
    $percentage = [Math]::Round(($group.Count / $allIssues.Count) * 100, 1)
    Write-Host "  $($group.Name): $($group.Count) ($percentage%)"
}

# Top rules
Write-Host ""
Write-Host "Top 10 Rules:" -ForegroundColor Yellow
$ruleSummary = $allIssues | Group-Object Rule | Sort-Object Count -Descending | Select-Object -First 10
foreach ($group in $ruleSummary) {
    Write-Host "  $($group.Name): $($group.Count)"
}

# Components with most issues
Write-Host ""
Write-Host "Top 10 Components with Issues:" -ForegroundColor Yellow
$componentSummary = $allIssues | Group-Object { Split-Path $_.Component -Leaf } | Sort-Object Count -Descending | Select-Object -First 10
foreach ($group in $componentSummary) {
    Write-Host "  $($group.Name): $($group.Count)"
}

Write-Host ""
Write-Host "Script completed successfully!" -ForegroundColor Green