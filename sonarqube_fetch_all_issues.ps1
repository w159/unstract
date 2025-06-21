# SonarQube Issues Fetcher with Proper Pagination
# This script fetches ALL issues from SonarQube by handling pagination correctly

# Initialize session with cookies
$session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
$session.UserAgent = "Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Mobile Safari/537.36 Edg/137.0.0.0"

# Add cookies to session
$cookies = @{
    "__stripe_mid" = "df18cc72-7d2c-4482-8832-07b88c9ac8b9ed162b"
    "_BEAMER_USER_ID_brLvVEua59285" = "73dcb132-7f00-4afb-afec-3a8e6dd20751"
    "_BEAMER_FIRST_VISIT_brLvVEua59285" = "2025-06-21T03:04:06.702Z"
    "_BEAMER_FILTER_BY_URL_brLvVEua59285" = "false"
    "__stripe_sid" = "55133424-6166-4bb9-a0fd-ac1c4ff92877d50045"
    "XSRF-TOKEN" = "guej7f9q13f6ra54of84q6f9ve"
    "JWT-SESSION" = "eyJhbGciOiJIUzI1NiJ9.eyJsYXN0UmVmcmVzaFRpbWUiOjE3NTA0ODM1ODAwMTUsInhzcmZUb2tlbiI6Imd1ZWo3ZjlxMTNmNnJhNTRvZjg0cTZmOXZlIiwianRpIjoiQVplUTY1Qm9kcGNZMUdSNTVQRlkiLCJzdWIiOiJBWmVRY1hYNmRwY1kxR1I1NU9qUiIsImlhdCI6MTc1MDQ4MzA0NiwiZXhwIjoxNzUwNTY5OTgwfQ.UORRtdCrVAGV5y7BZRIRZIiTZG5azXKKvnGaEWaaIRk"
}

foreach ($cookieName in $cookies.Keys) {
    $session.Cookies.Add((New-Object System.Net.Cookie($cookieName, $cookies[$cookieName], "/", ".sonarcloud.io")))
}

# Common headers for all requests
$headers = @{
    "authority"="sonarcloud.io"
    "method"="GET"
    "scheme"="https"
    "accept"="application/json"
    "accept-encoding"="gzip, deflate, br, zstd"
    "accept-language"="en-US,en;q=0.9,de-CH;q=0.8,de;q=0.7"
    "dnt"="1"
    "priority"="u=1, i"
    "referer"="https://sonarcloud.io/project/issues?issueStatuses=OPEN%2CCONFIRMED&id=w159_unstract"
    "sec-ch-ua"="`"Microsoft Edge`";v=`"137`", `"Chromium`";v=`"137`", `"Not/A)Brand`";v=`"24`""
    "sec-ch-ua-mobile"="?1"
    "sec-ch-ua-platform"="`"Android`""
    "sec-fetch-dest"="empty"
    "sec-fetch-mode"="cors"
    "sec-fetch-site"="same-origin"
    "sec-gpc"="1"
    "x-xsrf-token"="guej7f9q13f6ra54of84q6f9ve"
}

# Initialize array to store all issues
$allIssues = @()

# Base URL for API calls
$baseUrl = "https://sonarcloud.io/api/issues/search"
$params = @{
    "s" = "FILE_LINE"
    "issueStatuses" = "OPEN,CONFIRMED"
    "ps" = "100"  # Page size (max 100)
    "componentKeys" = "w159_unstract"
    "organization" = "w159"
    "additionalFields" = "_all"
}

# Start with page 1
$currentPage = 1
$totalPages = 1  # Will be updated after first request

Write-Host "Starting to fetch SonarQube issues..." -ForegroundColor Cyan

do {
    # Build URL with current page
    $url = $baseUrl + "?"
    $paramString = @()
    foreach ($key in $params.Keys) {
        $paramString += "$key=$($params[$key])"
    }
    $paramString += "p=$currentPage"
    $url += ($paramString -join "&")
    
    Write-Host "Fetching page $currentPage..." -ForegroundColor Yellow
    
    try {
        # Make the API request
        $response = Invoke-WebRequest -UseBasicParsing -Uri $url -WebSession $session -Headers $headers
        $data = $response.Content | ConvertFrom-Json
        
        # On first request, calculate total pages
        if ($currentPage -eq 1) {
            $totalIssues = $data.paging.total
            $pageSize = $data.paging.pageSize
            $totalPages = [Math]::Ceiling($totalIssues / $pageSize)
            Write-Host "Total issues found: $totalIssues" -ForegroundColor Green
            Write-Host "Total pages to fetch: $totalPages" -ForegroundColor Green
        }
        
        # Add issues from current page to collection
        $pageIssues = $data.issues | ForEach-Object {
            [PSCustomObject]@{
                Key = $_.key
                Rule = $_.rule
                Severity = $_.severity
                Component = $_.component
                Project = $_.project
                Status = $_.status
                Message = $_.message
                Line = $_.line
                TextRange = if ($_.textRange) { "$($_.textRange.startLine):$($_.textRange.startOffset)-$($_.textRange.endLine):$($_.textRange.endOffset)" } else { "" }
                Type = $_.type
                Effort = $_.effort
                CreationDate = $_.creationDate
                UpdateDate = $_.updateDate
                Tags = ($_.tags -join ", ")
                URL = "https://sonarcloud.io/project/issues?id=w159_unstract&open=" + $_.key
            }
        }
        
        $allIssues += $pageIssues
        Write-Host "  Added $($pageIssues.Count) issues from page $currentPage (Total so far: $($allIssues.Count))" -ForegroundColor Gray
        
        $currentPage++
        
        # Add a small delay to avoid rate limiting
        Start-Sleep -Milliseconds 500
        
    } catch {
        Write-Host "Error fetching page $currentPage : $_" -ForegroundColor Red
        break
    }
    
} while ($currentPage -le $totalPages)

Write-Host "`nFetch complete! Total issues collected: $($allIssues.Count)" -ForegroundColor Green

# Export to CSV
$csvPath = "sonarqube_all_issues_$(Get-Date -Format 'yyyy-MM-dd_HHmmss').csv"
$allIssues | Export-Csv -Path $csvPath -NoTypeInformation

Write-Host "Issues exported to: $csvPath" -ForegroundColor Cyan

# Display summary by severity
Write-Host "`nSummary by Severity:" -ForegroundColor Yellow
$allIssues | Group-Object Severity | Select-Object Name, Count | Format-Table -AutoSize

# Display summary by rule
Write-Host "`nTop 10 Rules by Count:" -ForegroundColor Yellow
$allIssues | Group-Object Rule | Sort-Object Count -Descending | Select-Object -First 10 | Select-Object @{Name="Rule";Expression={$_.Name}}, Count | Format-Table -AutoSize

# Optional: Display first few issues as preview
Write-Host "`nPreview of issues (first 5):" -ForegroundColor Yellow
$allIssues | Select-Object -First 5 | Select-Object Severity, Component, Message, URL | Format-Table -AutoSize -Wrap