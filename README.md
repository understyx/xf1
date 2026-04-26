# Komorebi TWM Windows Automation

See projekt pakub PowerShell skripti, mis automatiseerib Komorebi Tiling Window Manager-i (TWM) ja `whkd` hotkey daemon-i paigaldamist ja seadistamist Windows operatsioonisüsteemile.

## Funktsioonid

- **Automaatne paigaldus**: Toetab nii `winget` kui ka `scoop` paketihaldureid.
- **Tööriistade tuvastus**: Kui `winget` või `scoop` puudub, pakub skript võimalust need automaatselt paigaldada.
- **Konfiguratsioon**: Seadistab automaatselt Komorebi baaskonfiguratsiooni (`quickstart`) ja loob `whkdrc` faili standardsete klahvikombinatsioonidega.
- **Dry-Run režiim**: Võimalus näha kõiki planeeritud tegevusi ilma süsteemi muutmata.
- **Eemaldamine**: Täielik tugi komponentide ja konfiguratsioonifailide eemaldamiseks.
- **Keskkonna värskendamine**: Värskendab PATH muutuja automaatselt jooksvas sessioonis, et uued tööriistad oleksid kohe kättesaadavad.

## Kasutamine

### Paigaldamine

Vaikimisi paigaldus (`winget` abil):
```powershell
.\Install-KomorebiTWM.ps1
```

Paigaldus `scoop` abil:
```powershell
.\Install-KomorebiTWM.ps1 -InstallMethod scoop
```

### Dry-Run

Vaata tegevuste nimekirja ilma muudatusi tegemata:
```powershell
.\Install-KomorebiTWM.ps1 -DryRun
```

### Eemaldamine

Eemalda kõik paigaldatud komponendid ja seaded:
```powershell
.\Install-KomorebiTWM.ps1 -Uninstall
```

## Klahvikombinatsioonid

Skript seadistab järgmised vaikimisi klahvikombinatsioonid:

- `alt + h`: Fookus vasakule
- `alt + l`: Fookus paremale
- `alt + k`: Fookus üles
- `alt + j`: Fookus alla

## Nõuded

- Windows 10/11
- PowerShell 5.1 või PowerShell Core (pwsh)
- Internetiühendus (tööriistade allalaadimiseks)
- Administraatori õigused (soovituslik, et tagada sujuv paigaldus)

## Riskianalüüs

- **Puuduvad tööriistad**: Skript pakub lahendust `winget`/`scoop` puudumisel, kuid mõned keskkonnad võivad nõuda taaskäivitust.
- **Konfiguratsiooni ülekirjutamine**: Skript kirjutab üle olemasoleva `whkdrc` faili, kui see on juba olemas.
- **Õigused**: Mõned süsteemid võivad piirata skriptide käivitamist (vaja võib minna `Set-ExecutionPolicy`).
