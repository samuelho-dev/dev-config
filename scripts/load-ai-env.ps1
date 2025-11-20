# Load AI credentials from cache and set as User environment variables
# Pattern: Matches Unix LaunchAgent/systemd approach for Windows
$SecretsDir = "$env:USERPROFILE\.config\dev-config\secrets"

# Ensure directory exists
if (-not (Test-Path $SecretsDir)) {
    Write-Host "ERROR: Secrets directory not found: $SecretsDir" -ForegroundColor Red
    exit 1
}

$Keys = @("ANTHROPIC_API_KEY", "OPENAI_API_KEY", "LITELLM_MASTER_KEY")
$LoadedCount = 0

foreach ($Key in $Keys) {
    $SecretFile = Join-Path $SecretsDir $Key

    if (Test-Path $SecretFile) {
        try {
            $Value = Get-Content $SecretFile -Raw
            $Value = $Value.Trim()  # Remove whitespace

            # Set as User environment variable (persists across sessions)
            [Environment]::SetEnvironmentVariable($Key, $Value, "User")

            # Also set for current session
            Set-Item -Path "env:$Key" -Value $Value

            Write-Host "✓ Loaded $Key" -ForegroundColor Green
            $LoadedCount++
        }
        catch {
            Write-Host "✗ Failed to load $Key : $_" -ForegroundColor Red
        }
    }
    else {
        Write-Host "⚠ File not found: $SecretFile" -ForegroundColor Yellow
    }
}

Write-Host "`n$LoadedCount / $($Keys.Count) AI environment variables loaded" -ForegroundColor Cyan

# Log timestamp
$LogFile = "$env:TEMP\ai-env-load.log"
Add-Content -Path $LogFile -Value "$(Get-Date): Loaded $LoadedCount environment variables"
