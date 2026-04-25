<#
.SYNOPSIS
    Installs Komorebi TWM and whkd on Windows.

.PARAMETER InstallMethod
    The tool to use for installation (winget or scoop).

.PARAMETER ConfigPath
    Optional path for the whkd configuration file. Defaults to $HOME\.config\whkdrc.

.PARAMETER DryRun
    If set, only shows what actions would be performed.
#>
param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("winget", "scoop")]
    [string]$InstallMethod = "winget",

    [Parameter(Mandatory=$false)]
    [string]$ConfigPath = "$HOME\.config\whkdrc",

    [Switch]$DryRun
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

function Check-InstallMethodAvailable {
    param([string]$Method)
    if ($DryRun) { return }

    if (-not (Get-Command $Method -ErrorAction SilentlyContinue)) {
        Write-Error "VIGA: Paigaldusmeetod '$Method' ei ole kättesaadav. Palun installi see kõigepealt."
        exit 1
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

# Execution
Check-AdminPrivileges
Check-InstallMethodAvailable -Method $InstallMethod

if ($DryRun) {
    Write-Host "[DRY-RUN] Järgmised toimingud TEHTAKS (midagi pole muudetud):"
    Write-Host ""
}

Install-Komorebi -Method $InstallMethod
Install-Whkd -Method $InstallMethod
Initialize-KomorebiConfig
Set-KeybindConfiguration -Path $ConfigPath

if ($DryRun) {
    Write-Host ""
    Write-Host "[DRY-RUN] Lõpp. Kasuta ilma -DryRun lülitita tegelikuks installimiseks."
}
