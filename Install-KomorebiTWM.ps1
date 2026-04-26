<#
.SYNOPSIS
    Installs or uninstalls Komorebi TWM and whkd on Windows.

.PARAMETER InstallMethod
    The tool to use for installation/uninstallation (winget or scoop).

.PARAMETER ConfigPath
    Optional path for the whkd configuration file. Defaults to $HOME\.config\whkdrc.

.PARAMETER DryRun
    If set, only shows what actions would be performed.

.PARAMETER Uninstall
    If set, uninstalls the components instead of installing them.
#>
param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("winget", "scoop")]
    [string]$InstallMethod = "winget",

    [Parameter(Mandatory=$false)]
    [string]$ConfigPath = "$HOME\.config\whkdrc",

    [Switch]$DryRun,

    [Switch]$Uninstall
)

$global:stepCounter = 1

function Check-AdminPrivileges {
    if ($DryRun) { return }

    if ($IsWindows) {
        $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
        if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
            Write-Warning "Skript ei jookse administraatorina. Mõned toimingud võivad ebaõnnestuda."
        }
    }
}

function Install-Winget {
    if ($DryRun) {
        Write-Host "  [$global:stepCounter] Meetodi paigaldamine: winget       Meetod: PowerShell"
        $global:stepCounter++
    } else {
        Write-Host "[+] Paigaldan winget-it..."
        Invoke-WebRequest https://raw.githubusercontent.com/asheroto/winget-installer/master/winget-install.ps1 -UseBasicParsing | iex
    }
}

function Install-Scoop {
    if ($DryRun) {
        Write-Host "  [$global:stepCounter] Meetodi paigaldamine: scoop       Meetod: PowerShell"
        $global:stepCounter++
    } else {
        Write-Host "[+] Paigaldan scoop-it..."
        Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
        Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
    }
}

function Check-InstallMethodAvailable {
    param([string]$Method)

    if (-not (Get-Command $Method -ErrorAction SilentlyContinue)) {
        if ($DryRun) {
            Write-Host "  [$global:stepCounter] Meetod '$Method' puudub, küsitaks paigaldamist."
            $global:stepCounter++
            return
        }

        Write-Host "VIGA: Paigaldusmeetod '$Method' ei ole kättesaadav." -ForegroundColor Yellow
        $choice = Read-Host "Kas soovid, et skript paigaldaks '$Method' automaatselt? (J/E)"
        if ($choice -eq 'J' -or $choice -eq 'j') {
            if ($Method -eq "winget") { Install-Winget } else { Install-Scoop }

            # Refresh path for current session if possible, though some tools require restart
            if (-not (Get-Command $Method -ErrorAction SilentlyContinue)) {
                Write-Warning "Paigaldus lõpetatud, kuid '$Method' pole veel PATH-is. Võib olla vajalik skripti uuesti käivitamine uues aknas."
            }
        } else {
            Write-Error "VIGA: Paigaldusmeetod '$Method' on vajalik jätkamiseks."
            exit 1
        }
    }
}

function Install-Komorebi {
    param([string]$Method)
    $pkg = if ($Method -eq "winget") { "LGUG2Z.komorebi" } else { "komorebi" }
    $cmd = "$Method install $pkg"

    if ($DryRun) {
        Write-Host "  [$global:stepCounter] Installimine: $cmd       Meetod: $Method"
        $global:stepCounter++
    } else {
        if (Get-Command "komorebic" -ErrorAction SilentlyContinue) {
            Write-Host "[-] komorebi on juba installeeritud, jäta vahele."
        } else {
            Write-Host "[+] Toiming: Installimine ($cmd)..."
            Invoke-Expression $cmd
        }
    }
}

function Uninstall-Komorebi {
    param([string]$Method)
    $pkg = if ($Method -eq "winget") { "LGUG2Z.komorebi" } else { "komorebi" }
    $cmd = "$Method uninstall $pkg"

    if ($DryRun) {
        Write-Host "  [$global:stepCounter] Eemaldamine: $cmd       Meetod: $Method"
        $global:stepCounter++
    } else {
        if (-not (Get-Command "komorebic" -ErrorAction SilentlyContinue)) {
            Write-Host "[-] komorebi pole installeeritud, jäta vahele."
        } else {
            Write-Host "[+] Toiming: Eemaldamine ($cmd)..."
            Invoke-Expression $cmd
        }
    }
}

function Install-Whkd {
    param([string]$Method)
    $pkg = if ($Method -eq "winget") { "LGUG2Z.whkd" } else { "whkd" }
    $cmd = "$Method install $pkg"

    if ($DryRun) {
        Write-Host "  [$global:stepCounter] Installimine: $cmd       Meetod: $Method"
        $global:stepCounter++
    } else {
        if (Get-Command "whkd" -ErrorAction SilentlyContinue) {
            Write-Host "[-] whkd on juba installeeritud, jäta vahele."
        } else {
            Write-Host "[+] Toiming: Installimine ($cmd)..."
            Invoke-Expression $cmd
        }
    }
}

function Uninstall-Whkd {
    param([string]$Method)
    $pkg = if ($Method -eq "winget") { "LGUG2Z.whkd" } else { "whkd" }
    $cmd = "$Method uninstall $pkg"

    if ($DryRun) {
        Write-Host "  [$global:stepCounter] Eemaldamine: $cmd       Meetod: $Method"
        $global:stepCounter++
    } else {
        if (-not (Get-Command "whkd" -ErrorAction SilentlyContinue)) {
            Write-Host "[-] whkd pole installeeritud, jäta vahele."
        } else {
            Write-Host "[+] Toiming: Eemaldamine ($cmd)..."
            Invoke-Expression $cmd
        }
    }
}

function Initialize-KomorebiConfig {
    $configFiles = "$HOME\komorebi.json, $HOME\applications.json"
    $cmd = "komorebic quickstart"

    if ($DryRun) {
        Write-Host "  [$global:stepCounter] Konfiguratsiooni loomine: $cmd       Meetod: komorebic"
        Write-Host "       Loob failid: $configFiles"
        $global:stepCounter++
    } else {
        Write-Host "[+] Toiming: Konfiguratsiooni loomine ($cmd)..."
        Invoke-Expression $cmd
    }
}

function Remove-KomorebiConfig {
    $configFiles = "$HOME\komorebi.json", "$HOME\applications.json"

    if ($DryRun) {
        Write-Host "  [$global:stepCounter] Konfiguratsiooni eemaldamine       Meetod: PowerShell"
        Write-Host "       Eemaldatavad failid: $($configFiles -join ', ')"
        $global:stepCounter++
    } else {
        Write-Host "[+] Toiming: Konfiguratsiooni eemaldamine..."
        foreach ($file in $configFiles) {
            if (Test-Path $file) {
                Remove-Item -Path $file -Force
                Write-Host "  [-] Eemaldatud: $file"
            }
        }
    }
}

function Set-KeybindConfiguration {
    param([string]$Path)
    $content = @"
alt + h  : komorebic focus left
alt + l  : komorebic focus right
alt + k  : komorebic focus up
alt + j  : komorebic focus down
"@

    if ($DryRun) {
        Write-Host "  [$global:stepCounter] Keybindi konfiguratsioon kirjutataks faili: $Path"
        Write-Host "       Sisu (esimesed read):"
        $content.Split("`n") | Select-Object -First 4 | ForEach-Object { Write-Host "         $_" }
        $global:stepCounter++
    } else {
        Write-Host "[+] Kirjutan keybindid faili: $Path"
        $dir = Split-Path $Path
        if ($dir -and -not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
        $content | Out-File -FilePath $Path -Encoding utf8
    }
}

function Remove-KeybindConfiguration {
    param([string]$Path)

    if ($DryRun) {
        Write-Host "  [$global:stepCounter] Keybindi konfiguratsiooni eemaldamine: $Path       Meetod: PowerShell"
        $global:stepCounter++
    } else {
        if (Test-Path $Path) {
            Write-Host "[+] Toiming: Keybindi konfiguratsiooni eemaldamine ($Path)..."
            Remove-Item -Path $Path -Force
        }
    }
}

# Execution logic
Check-AdminPrivileges

if ($DryRun) {
    Write-Host "[DRY-RUN] Järgmised toimingud TEHTAKS (midagi pole muudetud):"
    Write-Host ""
}

Check-InstallMethodAvailable -Method $InstallMethod

if ($Uninstall) {
    Uninstall-Komorebi -Method $InstallMethod
    Uninstall-Whkd -Method $InstallMethod
    Remove-KomorebiConfig
    Remove-KeybindConfiguration -Path $ConfigPath
} else {
    Install-Komorebi -Method $InstallMethod
    Install-Whkd -Method $InstallMethod
    Initialize-KomorebiConfig
    Set-KeybindConfiguration -Path $ConfigPath
}

if ($DryRun) {
    Write-Host ""
    Write-Host "[DRY-RUN] Lõpp. Kasuta ilma -DryRun lülitita tegelikuks toiminguks."
}
