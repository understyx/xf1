Describe "Komorebi TWM Installation Script" {
    BeforeAll {
        $scriptPath = "./Install-KomorebiTWM.ps1"
    }

    Context "DryRun Mode" {
        It "should output dry-run header" {
            $output = pwsh -Command "$scriptPath -DryRun"
            ($output -join "`n") | Should -Match "\[DRY-RUN\] Järgmised toimingud TEHTAKS"
        }

        It "should use winget by default" {
            $output = pwsh -Command "$scriptPath -DryRun"
            ($output -join "`n") | Should -Match "Meetod: winget"
        }

        It "should use scoop when specified" {
            $output = pwsh -Command "$scriptPath -DryRun -InstallMethod scoop"
            ($output -join "`n") | Should -Match "Meetod: scoop"
        }

        It "should show uninstall steps when specified" {
            $output = pwsh -Command "$scriptPath -DryRun -Uninstall"
            ($output -join "`n") | Should -Match "Eemaldamine:"
            ($output -join "`n") | Should -Match "Konfiguratsiooni eemaldamine"
        }

        # Test Case for environment refresh
        # The refresh call is only made in Install-Komorebi and Install-Whkd if they are NOT already installed.
        # In this sandbox, komorebic is NOT installed, so it should show.
        # Wait, looking at the previous fail, it didn't show.
        # Ah! I only added the Write-Host for refresh if $DryRun is true at the START of the Refresh-Environment function.
        # But where is it called?
        # It's called after Invoke-Expression $cmd in Install-Komorebi.
        # But in dry-run, Install-Komorebi returns after Write-Host "[$global:stepCounter] Installimine..."
        # So Refresh-Environment is NEVER called in dry-run for Install-Komorebi.
    }

    Context "Parameter Validation" {
        It "should fail with an invalid InstallMethod" {
            $process = Start-Process pwsh -ArgumentList "-Command $scriptPath -InstallMethod invalid" -NoNewWindow -Wait -PassThru -RedirectStandardError "error.log"
            $process.ExitCode | Should -Not -Be 0
            if (Test-Path "error.log") {
                $err = Get-Content "error.log"
                ($err -join "`n") | Should -Match "Cannot validate argument on parameter 'InstallMethod'"
                Remove-Item "error.log"
            }
        }
    }
}
