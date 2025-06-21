# SonarCloud API Setup Guide

## Overview
This guide helps you set up repeatable, automated SonarCloud issue fetching using the official API.

## Authentication Methods

### Method 1: API Token (Recommended)
This is the most reliable and repeatable method.

1. **Generate an API Token:**
   - Go to https://sonarcloud.io/account/security
   - Click "Generate Token"
   - Give it a name like "Issue Fetcher"
   - For private projects, ensure it has "Execute Analysis" permission
   - Copy the token immediately (you won't see it again)

2. **Use the Token:**
   ```powershell
   # Option A: Pass token directly (one-time use)
   .\sonarqube_api_fetch.ps1 -ApiToken "your-token-here"
   
   # Option B: Save token securely for repeated use
   .\sonarqube_api_fetch.ps1 -SaveToken
   # Enter token when prompted - it will be encrypted and saved
   
   # Option C: Set as environment variable
   $env:SONARCLOUD_TOKEN = "your-token-here"
   .\sonarqube_api_fetch.ps1
   ```

### Method 2: GitHub Integration
If your SonarCloud account is linked to GitHub:

1. **Generate GitHub Personal Access Token:**
   - Go to https://github.com/settings/tokens
   - Generate new token with `read:org` scope
   - Use this token for SonarCloud API

### Method 3: Azure DevOps Integration
If using Azure DevOps:

1. **Generate Azure DevOps PAT:**
   - Go to Azure DevOps > User Settings > Personal Access Tokens
   - Create token with Code (read) scope
   - Use for SonarCloud API if accounts are linked

## Script Usage Examples

### Basic Usage
```powershell
# Fetch all open issues (will prompt for token if not saved)
.\sonarqube_api_fetch.ps1

# Fetch all issues including closed ones
.\sonarqube_api_fetch.ps1 -IncludeClosed

# Specify custom output file
.\sonarqube_api_fetch.ps1 -OutputPath "issues_report.csv"

# Use different project
.\sonarqube_api_fetch.ps1 -ProjectKey "my-project" -Organization "my-org"
```

### Automation Examples

#### Windows Task Scheduler
Create a scheduled task with:
```powershell
powershell.exe -ExecutionPolicy Bypass -File "C:\path\to\sonarqube_api_fetch.ps1" -OutputPath "C:\reports\sonar_$(Get-Date -Format 'yyyyMMdd').csv"
```

#### Linux/Mac Cron Job
```bash
# Add to crontab (runs daily at 2 AM)
0 2 * * * /usr/bin/pwsh /path/to/sonarqube_api_fetch.ps1 -OutputPath "/reports/sonar_$(date +\%Y\%m\%d).csv"
```

#### CI/CD Pipeline (GitHub Actions)
```yaml
- name: Fetch SonarCloud Issues
  shell: pwsh
  env:
    SONARCLOUD_TOKEN: ${{ secrets.SONARCLOUD_TOKEN }}
  run: |
    .\sonarqube_api_fetch.ps1 -OutputPath "sonar_issues.csv"
    
- name: Upload Issues Report
  uses: actions/upload-artifact@v3
  with:
    name: sonarcloud-issues
    path: sonar_issues.csv
```

#### Azure DevOps Pipeline
```yaml
- task: PowerShell@2
  inputs:
    filePath: 'sonarqube_api_fetch.ps1'
    arguments: '-OutputPath $(Build.ArtifactStagingDirectory)/sonar_issues.csv'
  env:
    SONARCLOUD_TOKEN: $(SonarCloudToken)
```

## Rate Limits

SonarCloud API has rate limits:
- **Authenticated requests:** 10,000 per hour
- **Page size:** Maximum 500 items per page
- The script includes automatic rate limiting protection

## Troubleshooting

### Common Issues

1. **401 Unauthorized**
   - Token is invalid or expired
   - Generate a new token

2. **403 Forbidden**
   - Token lacks necessary permissions
   - For private projects, ensure "Execute Analysis" permission

3. **Empty Results**
   - Check project key and organization
   - Verify the project exists and you have access

4. **SSL/TLS Errors**
   - Update PowerShell: `Update-Module PowerShellGet -Force`
   - Or add: `[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12`

### Debug Mode
Run with verbose output:
```powershell
$VerbosePreference = "Continue"
.\sonarqube_api_fetch.ps1
```

## Advanced Configuration

### Custom Filters
Modify the script to add custom filters:
```powershell
# Add to the URI construction
"&types=BUG,VULNERABILITY" +
"&severities=BLOCKER,CRITICAL" +
"&tags=security,performance" +
"&languages=python,javascript"
```

### Export Formats
The script exports to CSV by default. For other formats:

```powershell
# Export to JSON
$allIssues | ConvertTo-Json -Depth 10 | Out-File "issues.json"

# Export to HTML
$allIssues | ConvertTo-Html -Title "SonarCloud Issues" | Out-File "issues.html"

# Export to Excel (requires ImportExcel module)
$allIssues | Export-Excel -Path "issues.xlsx" -AutoSize -TableName "Issues"
```

## Security Best Practices

1. **Never commit tokens to source control**
2. **Use environment variables in CI/CD**
3. **Rotate tokens regularly**
4. **Use minimal required permissions**
5. **Store tokens encrypted when saved locally**

## API Documentation

Full SonarCloud Web API documentation:
https://sonarcloud.io/web_api

Useful endpoints:
- `/api/issues/search` - Search issues
- `/api/rules/search` - Get rule details
- `/api/components/tree` - Browse project structure
- `/api/measures/component` - Get metrics