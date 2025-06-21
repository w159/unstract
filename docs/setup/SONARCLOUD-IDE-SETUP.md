# SonarCloud IDE Integration Setup

This guide helps you set up SonarLint in your IDE to see SonarCloud issues directly in your code editor.

## Prerequisites

- VS Code or IntelliJ IDEA
- SonarLint extension/plugin installed
- SonarCloud account with access to the project

## VS Code Setup

### 1. Install SonarLint Extension

1. Open VS Code
2. Go to Extensions (Ctrl+Shift+X / Cmd+Shift+X)
3. Search for "SonarLint"
4. Install the official SonarLint extension by SonarSource

### 2. Get Your SonarCloud Token

1. Go to [SonarCloud](https://sonarcloud.io)
2. Click on your profile picture → **My Account**
3. Go to **Security** tab
4. Generate a new token:
   - Name: `vscode-unstract` (or any name you prefer)
   - Click **Generate**
   - Copy the token (you won't see it again!)

### 3. Configure SonarLint

1. Open VS Code settings (Cmd+, / Ctrl+,)
2. Search for "sonarlint"
3. Or edit `.vscode/settings.json` directly:

```json
{
  "sonarlint.connectedMode.connections.sonarcloud": [
    {
      "organizationKey": "w159",
      "connectionId": "w159",
      "token": "YOUR_TOKEN_HERE"  // Replace with your actual token
    }
  ]
}
```

### 4. Bind Project

The project binding is already configured in `.vscode/settings.json`:
```json
{
  "sonarlint.connectedMode.project": {
    "connectionId": "w159",
    "projectKey": "w159_unstract"
  }
}
```

### 5. Sync with SonarCloud

1. Open Command Palette (Cmd+Shift+P / Ctrl+Shift+P)
2. Run: `SonarLint: Update all project bindings to SonarCloud/SonarQube`
3. This will download all issues from SonarCloud

## IntelliJ IDEA Setup

### 1. Install SonarLint Plugin

1. Go to **Settings/Preferences** → **Plugins**
2. Search for "SonarLint"
3. Install and restart IDE

### 2. Configure SonarCloud Connection

1. Go to **Settings/Preferences** → **Tools** → **SonarLint**
2. Click **+** to add a new connection
3. Choose **SonarCloud**
4. Enter:
   - Connection name: `Unstract`
   - Token: Your SonarCloud token
   - Organization: `w159`

### 3. Bind Project

1. Right-click on project root
2. Select **SonarLint** → **Bind to SonarCloud...**
3. Select your connection
4. Choose project: `w159_unstract`

## Using SonarLint

### Viewing Issues

- **VS Code**: Issues appear in:
  - Problems panel (Ctrl+Shift+M / Cmd+Shift+M)
  - Inline in code as squiggly lines
  - Hover over code to see issue details
  
- **IntelliJ**: Issues appear in:
  - SonarLint tool window
  - Inline as code inspections
  - Alt+Enter for quick fixes

### Issue Details

When you hover over an issue, you'll see:
- Rule description
- Severity (Bug, Vulnerability, Code Smell)
- Why this is an issue
- How to fix it
- Examples of compliant code

### Quick Actions

- **VS Code**: Click the lightbulb icon or press Ctrl+. / Cmd+.
- **IntelliJ**: Press Alt+Enter

Some issues have automatic fixes available!

## Syncing with SonarCloud

### Manual Sync
- **VS Code**: Command Palette → "SonarLint: Update all project bindings"
- **IntelliJ**: SonarLint panel → Refresh button

### Automatic Sync
SonarLint automatically syncs when:
- You open the project
- Every hour while the IDE is open
- When you manually trigger analysis

## Rule Configuration

The `.vscode/settings.json` file includes rule configurations that match SonarCloud:

```json
{
  "sonarlint.rules": {
    "python:S3776": {
      "level": "on",
      "parameters": {
        "threshold": "15"  // Cognitive complexity threshold
      }
    }
  }
}
```

## Troubleshooting

### Issues Not Showing

1. Check SonarLint Output panel for errors
2. Verify token is valid
3. Try manual sync
4. Check internet connection

### Connection Failed

1. Verify organization key: `w159`
2. Verify project key: `w159_unstract`
3. Regenerate token if needed
4. Check proxy settings if behind firewall

### Different Issues than SonarCloud

This is normal! SonarLint shows:
- Issues in files you're currently editing
- Some rules that only run locally
- Real-time analysis results

SonarCloud shows:
- Issues from full project analysis
- Security hotspots
- Coverage and duplication metrics

## Best Practices

1. **Fix issues as you code** - Don't wait for CI/CD
2. **Understand the "why"** - Read rule descriptions
3. **Use quick fixes** - When available
4. **Mark false positives** - In SonarCloud web UI
5. **Keep rules in sync** - Update settings when project rules change

## Resources

- [SonarLint for VS Code](https://marketplace.visualstudio.com/items?itemName=SonarSource.sonarlint-vscode)
- [SonarLint for IntelliJ](https://plugins.jetbrains.com/plugin/7973-sonarlint)
- [SonarCloud Project](https://sonarcloud.io/project/overview?id=w159_unstract)
- [Rule Descriptions](https://rules.sonarsource.com/)

## Security Note

⚠️ **Never commit your SonarCloud token!**

The token in `.vscode/settings.json` is a placeholder. Each developer should:
1. Generate their own token
2. Keep it local
3. Not commit the settings file with real tokens

Consider using:
- VS Code workspace settings (not committed)
- Environment variables
- User-level settings