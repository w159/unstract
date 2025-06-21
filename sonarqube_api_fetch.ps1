# SonarCloud API Issues Fetcher - Using Official API Authentication
# This script uses SonarCloud's official API with token authentication for repeatability

param(
    [Parameter(Mandatory=$false)]
    [string]$ApiToken = $env:SONARCLOUD_TOKEN,
    
    [Parameter(Mandatory=$false)]
    [string]$Organization = "w159",
    
    [Parameter(Mandatory=$false)]
    [string]$ProjectKey = "w159_unstract",
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = "sonarcloud_issues_$(Get-Date -Format 'yyyy-MM-dd_HHmmss').csv",
    
    [Parameter(Mandatory=$false)]
    [int]$PageSize = 500,  # API allows up to 500
    
    [Parameter(Mandatory=$false)]
    [switch]$IncludeClosed = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$SaveToken = $false
)

# Function to save token securely
function Save-TokenSecurely {
    param([string]$Token)
    
    # Check if we're on Windows
    $isWin = if ($PSVersionTable.PSVersion.Major -ge 6) { $IsWindows } else { $true }
    
    if ($isWin) {
        $secureToken = ConvertTo-SecureString $Token -AsPlainText -Force
        $encryptedToken = ConvertFrom-SecureString $secureToken
        $tokenPath = Join-Path $env:USERPROFILE ".sonarcloud_token"
        $encryptedToken | Out-File $tokenPath
        Write-Host "Token saved securely to: $tokenPath" -ForegroundColor Green
    } else {
        # For non-Windows, save to a file with restricted permissions
        $tokenPath = Join-Path $HOME ".sonarcloud_token"
        $Token | Out-File $tokenPath -NoNewline
        chmod 600 $tokenPath
        Write-Host "Token saved to: $tokenPath (permissions set to 600)" -ForegroundColor Green
    }
}

# Function to load saved token
function Get-SavedToken {
    # Check if we're on Windows
    $isWin = if ($PSVersionTable.PSVersion.Major -ge 6) { $IsWindows } else { $true }
    
    if ($isWin) {
        $tokenPath = Join-Path $env:USERPROFILE ".sonarcloud_token"
        if (Test-Path $tokenPath) {
            $encryptedToken = Get-Content $tokenPath
            $secureToken = ConvertTo-SecureString $encryptedToken
            $ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureToken)
            try {
                return [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)
            } finally {
                [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)
            }
        }
    } else {
        $tokenPath = Join-Path $HOME ".sonarcloud_token"
        if (Test-Path $tokenPath) {
            return Get-Content $tokenPath -Raw
        }
    }
    return $null
}

# Function to make authenticated API request
function Invoke-SonarCloudApi {
    param(
        [string]$Uri,
        [string]$Token,
        [string]$Method = "GET"
    )
    
    $headers = @{
        "Authorization" = "Bearer $Token"
        "Accept" = "application/json"
    }
    
    try {
        $response = Invoke-RestMethod -Uri $Uri -Headers $headers -Method $Method -ErrorAction Stop
        return $response
    } catch {
        if ($_.Exception.Response.StatusCode -eq 401) {
            throw "Authentication failed. Please check your API token."
        } elseif ($_.Exception.Response.StatusCode -eq 403) {
            throw "Access forbidden. Ensure your token has the necessary permissions."
        } else {
            throw "API request failed: $_"
        }
    }
}

# Main script
Write-Host "SonarCloud API Issues Fetcher" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan
Write-Host ""

# Token management
if (-not $ApiToken) {
    # Try to load saved token
    $ApiToken = Get-SavedToken
    
    if (-not $ApiToken) {
        Write-Host "API Token Required" -ForegroundColor Yellow
        Write-Host "You can generate a token at: https://sonarcloud.io/account/security" -ForegroundColor Gray
        Write-Host "The token needs 'Execute Analysis' permission for private projects" -ForegroundColor Gray
        Write-Host ""
        
        # Read token - for macOS/Linux, just read as plain text
        $ApiToken = Read-Host -Prompt "Enter your SonarCloud API token"
        
        if ($SaveToken) {
            Save-TokenSecurely -Token $ApiToken
        }
    } else {
        Write-Host "Using saved API token" -ForegroundColor Green
    }
}

# Validate token by making a test request
Write-Host "Validating API token..." -NoNewline
try {
    $testUri = "https://sonarcloud.io/api/organizations/search?organizations=$Organization"
    $testResponse = Invoke-SonarCloudApi -Uri $testUri -Token $ApiToken
    Write-Host " Valid!" -ForegroundColor Green
} catch {
    Write-Host " Failed!" -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
    exit 1
}

# Build API URL and parameters
$baseUri = "https://sonarcloud.io/api/issues/search"
$issueStatuses = if ($IncludeClosed) { 
    "OPEN,CONFIRMED,REOPENED,RESOLVED,CLOSED" 
} else { 
    "OPEN,CONFIRMED,REOPENED" 
}

# Initialize collection
$allIssues = New-Object System.Collections.ArrayList
$page = 1
$totalPages = 1

Write-Host ""
Write-Host "Fetching issues from project: $ProjectKey" -ForegroundColor Cyan
Write-Host "Organization: $Organization" -ForegroundColor Gray
Write-Host "Status filter: $issueStatuses" -ForegroundColor Gray
Write-Host ""

# Fetch all pages
do {
    $uri = "$baseUri" +
           "?componentKeys=$ProjectKey" +
           "&organization=$Organization" +
           "&statuses=$issueStatuses" +
           "&ps=$PageSize" +
           "&p=$page" +
           "&s=FILE_LINE" +
           "&additionalFields=_all"
    
    Write-Host "Fetching page $page/$totalPages..." -NoNewline
    
    try {
        $response = Invoke-SonarCloudApi -Uri $uri -Token $ApiToken
        
        # Update total pages on first request
        if ($page -eq 1) {
            $total = $response.total
            $totalPages = [Math]::Ceiling($total / $PageSize)
            Write-Host " (Total issues: $total)" -ForegroundColor Green
        } else {
            Write-Host " Done" -ForegroundColor Green
        }
        
        # Process issues
        foreach ($issue in $response.issues) {
            # Extract file path from component
            $filePath = $issue.component -replace "^$($ProjectKey):", ""
            
            $processedIssue = [PSCustomObject]@{
                Key = $issue.key
                Type = $issue.type
                Rule = $issue.rule
                Severity = $issue.severity
                Status = $issue.status
                Resolution = $issue.resolution
                FilePath = $filePath
                FileName = Split-Path $filePath -Leaf
                Directory = Split-Path $filePath -Parent
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
                CleanCodeAttribute = $issue.cleanCodeAttribute
                CleanCodeAttributeCategory = $issue.cleanCodeAttributeCategory
                Impacts = ($issue.impacts | ForEach-Object { "$($_.softwareQuality):$($_.severity)" }) -join "; "
                URL = "https://sonarcloud.io/project/issues?id=$($ProjectKey)&open=$($issue.key)"
                Assignee = $issue.assignee
                Comments = $issue.comments.Count
                QuickFixAvailable = $issue.quickFixAvailable
            }
            
            [void]$allIssues.Add($processedIssue)
        }
        
        $page++
        
        # Rate limiting protection
        if ($page -le $totalPages) {
            Start-Sleep -Milliseconds 200
        }
        
    } catch {
        Write-Host " Failed!" -ForegroundColor Red
        Write-Host "Error: $_" -ForegroundColor Red
        break
    }
} while ($page -le $totalPages)

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

# Generate summary report
Write-Host ""
Write-Host "Summary Report" -ForegroundColor Cyan
Write-Host "==============" -ForegroundColor Cyan

# By severity
Write-Host ""
Write-Host "Issues by Severity:" -ForegroundColor Yellow
$allIssues | Group-Object Severity | Sort-Object Name | ForEach-Object {
    $percentage = [Math]::Round(($_.Count / $allIssues.Count) * 100, 1)
    Write-Host ("  {0,-10} {1,5} ({2,4}%)" -f $_.Name, $_.Count, $percentage)
}

# By type
Write-Host ""
Write-Host "Issues by Type:" -ForegroundColor Yellow
$allIssues | Group-Object Type | Sort-Object Count -Descending | ForEach-Object {
    $percentage = [Math]::Round(($_.Count / $allIssues.Count) * 100, 1)
    Write-Host ("  {0,-20} {1,5} ({2,4}%)" -f $_.Name, $_.Count, $percentage)
}

# By clean code category
if ($allIssues[0].PSObject.Properties['CleanCodeAttributeCategory']) {
    Write-Host ""
    Write-Host "Issues by Clean Code Category:" -ForegroundColor Yellow
    $allIssues | Where-Object { $_.CleanCodeAttributeCategory } | Group-Object CleanCodeAttributeCategory | Sort-Object Count -Descending | ForEach-Object {
        Write-Host ("  {0,-20} {1,5}" -f $_.Name, $_.Count)
    }
}

# Top 10 rules
Write-Host ""
Write-Host "Top 10 Rules:" -ForegroundColor Yellow
$allIssues | Group-Object Rule | Sort-Object Count -Descending | Select-Object -First 10 | ForEach-Object {
    Write-Host ("  {0,-40} {1,5}" -f $_.Name, $_.Count)
}

# Top 10 files
Write-Host ""
Write-Host "Top 10 Files with Most Issues:" -ForegroundColor Yellow
$allIssues | Group-Object FileName | Sort-Object Count -Descending | Select-Object -First 10 | ForEach-Object {
    Write-Host ("  {0,-40} {1,5}" -f $_.Name, $_.Count)
}

# Quick fix available
$quickFixCount = ($allIssues | Where-Object { $_.QuickFixAvailable -eq $true }).Count
if ($quickFixCount -gt 0) {
    Write-Host ""
    Write-Host "Issues with Quick Fix available: $quickFixCount" -ForegroundColor Green
}

Write-Host ""
Write-Host "Script completed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "To run this script again without re-entering your token:" -ForegroundColor Gray
Write-Host "  .\$($MyInvocation.MyCommand.Name) -SaveToken" -ForegroundColor Gray
Write-Host "Or set the SONARCLOUD_TOKEN environment variable" -ForegroundColor Gray