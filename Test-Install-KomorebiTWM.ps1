# Test-Install-KomorebiTWM.ps1

function Run-Test {
    param($Name, $ScriptBlock)
    Write-Host "Running Test: $Name..." -ForegroundColor Cyan
    try {
        & $ScriptBlock
        Write-Host "PASS: $Name" -ForegroundColor Green
    } catch {
        Write-Host "FAIL: $Name" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        $global:testFailed = $true
    }
    Write-Host ("-" * 40)
}

$global:testFailed = $false

# 1. Positive Test: DryRun with Scoop
Run-Test "Positive: DryRun with Scoop" {
    $output = pwsh ./Install-KomorebiTWM.ps1 -DryRun -InstallMethod scoop
    if ($output -match "\[DRY-RUN\] Järgmised toimingud TEHTAKS") {
        Write-Host "Confirmed dry-run header present."
    } else {
        throw "Dry-run header missing!"
    }

    if ($output -match "Meetod: scoop") {
        Write-Host "Confirmed scoop method mentioned."
    } else {
        throw "Scoop method not found in output!"
    }
}

# 2. Positive Test: DryRun with Winget (Default)
Run-Test "Positive: DryRun with Winget (Default)" {
    $output = pwsh ./Install-KomorebiTWM.ps1 -DryRun
    if ($output -match "Meetod: winget") {
        Write-Host "Confirmed winget method mentioned."
    } else {
        throw "Winget method not found in output!"
    }
}

# 3. Positive Test: Uninstall DryRun
Run-Test "Positive: Uninstall DryRun" {
    $output = pwsh ./Install-KomorebiTWM.ps1 -DryRun -Uninstall
    if ($output -match "Eemaldamine:") {
        Write-Host "Confirmed uninstall actions mentioned."
    } else {
        throw "Uninstall actions not found in output!"
    }

    if ($output -match "Konfiguratsiooni eemaldamine") {
        Write-Host "Confirmed config removal mentioned."
    } else {
        throw "Config removal not found in output!"
    }
}

# 4. Negative Test: Invalid InstallMethod
Run-Test "Negative: Invalid InstallMethod" {
    try {
        # Using -ErrorAction Stop doesn't always catch parameter validation errors from outside
        # so we check if the exit code is non-zero or if stderr has content.
        $process = Start-Process pwsh -ArgumentList "./Install-KomorebiTWM.ps1 -InstallMethod invalid" -NoNewWindow -Wait -PassThru -RedirectStandardError "error.log"
        if ($process.ExitCode -ne 0) {
            Write-Host "Successfully caught invalid parameter (ExitCode: $($process.ExitCode))."
        } else {
            $err = Get-Content "error.log"
            if ($err -match "Cannot validate argument on parameter 'InstallMethod'") {
                 Write-Host "Successfully caught invalid parameter in error log."
            } else {
                throw "Script should have failed with invalid InstallMethod!"
            }
        }
    } finally {
        if (Test-Path "error.log") { Remove-Item "error.log" }
    }
}

if ($global:testFailed) {
    Write-Host "Some tests failed!" -ForegroundColor Red
    exit 1
} else {
    Write-Host "All tests passed!" -ForegroundColor Green
    exit 0
}
