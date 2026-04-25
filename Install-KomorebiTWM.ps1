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

function Invoke-CommandSafe {
    param(
        [string]$Description,
        [string]$Command,
        [string]$Method,
        [string]$ExtraInfo = "",
        [string]$CheckCmd = ""
    )

    if ($DryRun) {
        Write-Host "  [$global:stepCounter] ${Description}: $Command       Meetod: $Method"
        if ($ExtraInfo) {
            Write-Host "       $ExtraInfo"
        }
        $global:stepCounter++
    } else {
        if ($CheckCmd -and (Get-Command $CheckCmd -ErrorAction SilentlyContinue)) {
            Write-Host "[-] $CheckCmd on juba installeeritud, jäta vahele."
        } else {
            Write-Host "[+] Toiming: $Description ($Command)..."
            try {
                Invoke-Expression $Command
            } catch {
                Write-Error "Viga toimingu sooritamisel: $_"
            }
        }
    }
}

# Admin check
if (-not $DryRun) {
    if ($IsWindows) {
        $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
        if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
            Write-Warning "Skript ei jookse administraatorina. Mõned toimingud võivad ebaõnnestuda."
        }
    }
}

# Check if InstallMethod is available
if (-not $DryRun) {
    if (-not (Get-Command $InstallMethod -ErrorAction SilentlyContinue)) {
        Write-Error "VIGA: Paigaldusmeetod '$InstallMethod' ei ole kättesaadav. Palun installi see kõigepealt."
        exit 1
    }
}

if ($DryRun) {
    Write-Host "[DRY-RUN] Järgmised toimingud TEHTAKS (midagi pole muudetud):"
    Write-Host ""
}

# 1. Install Komorebi
$komorebiPkg = if ($InstallMethod -eq "winget") { "LGUG2Z.komorebi" } else { "komorebi" }
$komorebiInstallCmd = "$InstallMethod install $komorebiPkg"
Invoke-CommandSafe -Description "Installimine" -Command $komorebiInstallCmd -Method $InstallMethod -CheckCmd "komorebic"

# 2. Install whkd
$whkdPkg = if ($InstallMethod -eq "winget") { "LGUG2Z.whkd" } else { "whkd" }
$whkdInstallCmd = "$InstallMethod install $whkdPkg"
Invoke-CommandSafe -Description "Installimine" -Command $whkdInstallCmd -Method $InstallMethod -CheckCmd "whkd"

# 3. Create Komorebi config
$configFiles = "$HOME\komorebi.json, $HOME\applications.json"
Invoke-CommandSafe -Description "Konfiguratsiooni loomine" -Command "komorebic quickstart" -Method "komorebic" -ExtraInfo "Loob failid: $configFiles"

# 4. Keybind configuration (whkdrc)
$whkdrcContent = @"
alt + h  : komorebic focus left
alt + l  : komorebic focus right
alt + k  : komorebic focus up
alt + j  : komorebic focus down
"@

if ($DryRun) {
    Write-Host "  [$global:stepCounter] Keybindi konfiguratsioon kirjutataks faili: $ConfigPath"
    Write-Host "       Sisu (esimesed read):"
    $whkdrcContent.Split("`n") | Select-Object -First 4 | ForEach-Object { Write-Host "         $_" }
} else {
    Write-Host "[+] Kirjutan keybindid faili: $ConfigPath"
    $configDir = Split-Path $ConfigPath
    if ($configDir -and -not (Test-Path $configDir)) {
        New-Item -ItemType Directory -Path $configDir -Force | Out-Null
    }
    $whkdrcContent | Out-File -FilePath $ConfigPath -Encoding utf8
}

if ($DryRun) {
    Write-Host ""
    Write-Host "[DRY-RUN] Lõpp. Kasuta ilma -DryRun lülitita tegelikuks installimiseks."
}
