# deploy.ps1
# Local developer deployment script.
# Concatenates all SQL files into a single temp file and runs them in
# one snow sql call — one connection, one authentication roundtrip.
#
# Usage:
#   .\scripts\deploy.ps1 -Env dev
#   .\scripts\deploy.ps1 -Env prod
#
# Prerequisites:
#   - Snowflake CLI installed  (pip install snowflake-cli-labs)
#   - snow connection configured (snow connection add)
#   - SNOWFLAKE_RSA_PUBLIC_KEY env var set (for step 07)

param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('dev', 'prod')]
    [string]$Env,

    [string]$Connection = 'default'
)

$ErrorActionPreference = 'Stop'
$SqlDir    = Join-Path $PSScriptRoot '..\sql'
$TempFile  = [System.IO.Path]::GetTempFileName() -replace '\.tmp$', '.sql'
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)  # BOM-free UTF-8

try {
    # Collect RSA public key from env var — never hard-code it
    $RsaPublicKey = $env:SNOWFLAKE_RSA_PUBLIC_KEY
    if (-not $RsaPublicKey) {
        Write-Warning "SNOWFLAKE_RSA_PUBLIC_KEY is not set. Step 07 (RSA key) will be skipped."
    }

    # Gather main SQL files in numbered order, then table definition files
    $mainFiles  = Get-ChildItem -Path $SqlDir -Filter '0*.sql' | Sort-Object Name
    $tableFiles = Get-ChildItem -Path (Join-Path $SqlDir 'tables') -Filter '*.sql' `
                    -ErrorAction SilentlyContinue | Sort-Object Name

    $files = @($mainFiles) + @($tableFiles)

    if (-not $RsaPublicKey) {
        $files = $files | Where-Object { $_.Name -ne '07_rsa_key.sql' }
    }

    Write-Host "Concatenating $($files.Count) SQL file(s) into a single batch..." -ForegroundColor Cyan
    $files | ForEach-Object {
        Write-Host "  + $($_.Name)"
        $content = Get-Content $_.FullName -Raw

        # Substitute Jinja2 placeholders in PowerShell — avoids dependency on
        # the snow CLI's templating engine version.
        $content = $content -replace '\{\{\s*env\s*\|\s*upper\s*\}\}', $Env.ToUpper()
        $content = $content -replace '\{\{\s*env\s*\}\}',               $Env.ToLower()
        if ($RsaPublicKey) {
            $content = $content -replace '\{\{\s*rsa_public_key\s*\}\}', $RsaPublicKey
        }

        $content + "`n" | ForEach-Object {
            [System.IO.File]::AppendAllText($TempFile, $_, $Utf8NoBom)
        }
    }

    Write-Host "`nExecuting batch [env=$($Env.ToUpper())]..." -ForegroundColor Cyan
    # PYTHONUTF8=1 forces the Snowflake CLI (Python) to read the temp file
    # as UTF-8 rather than the Windows default charmap (cp1252).
    $env:PYTHONUTF8 = '1'
    snow sql -f $TempFile --connection $Connection

    if ($LASTEXITCODE -ne 0) {
        throw "Deployment failed. Check snow output above."
    }

    Write-Host "`nDeployment complete for environment: $($Env.ToUpper())" -ForegroundColor Green
}
finally {
    Remove-Item -Path $TempFile -ErrorAction SilentlyContinue
}
