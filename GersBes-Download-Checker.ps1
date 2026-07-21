Clear-Host
$Banner = @"

==========================================================================

 ██████╗ ███████╗██████╗ ███████╗██████╗ ███████╗███████╗
██╔════╝ ██╔════╝██╔══██╗██╔════╝██╔══██╗██╔════╝██╔════╝
██║  ███╗█████╗  ██████╔╝███████╗██████╔╝█████╗  ███████╗
██║   ██║██╔══╝  ██╔══██╗╚════██║██╔══██╗██╔══╝  ╚════██║
╚██████╔╝███████╗██║  ██║███████║██████╔╝███████╗███████║
 ╚═════╝ ╚══════╝╚═╝  ╚═╝╚══════╝╚═════╝ ╚══════╝╚══════╝

██████╗  ██████╗ ██╗    ██╗███╗   ██╗██╗      ██████╗  █████╗ ██████╗
██╔══██╗██╔═══██╗██║    ██║████╗  ██║██║     ██╔═══██╗██╔══██╗██╔══██╗
██║  ██║██║   ██║██║ █╗ ██║██╔██╗ ██║██║     ██║   ██║███████║██║  ██║
██║  ██║██║   ██║██║███╗██║██║╚██╗██║██║     ██║   ██║██╔══██║██║  ██║
██████╔╝╚██████╔╝╚███╔███╔╝██║ ╚████║███████╗╚██████╔╝██║  ██║██████╔╝
╚═════╝  ╚═════╝  ╚══╝╚══╝ ╚═╝  ╚═══╝╚══════╝ ╚═════╝ ╚═╝  ╚═╝╚═════╝

 ██████╗██╗  ██╗███████╗ ██████╗██╗  ██╗███████╗██████╗
██╔════╝██║  ██║██╔════╝██╔════╝██║ ██╔╝██╔════╝██╔══██╗
██║     ███████║█████╗  ██║     █████╔╝ █████╗  ██████╔╝
██║     ██╔══██║██╔══╝  ██║     ██╔═██╗ ██╔══╝  ██╔══██╗
╚██████╗██║  ██║███████╗╚██████╗██║  ██╗███████╗██║  ██║
 ╚═════╝╚═╝  ╚═╝╚══════╝ ╚═════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝

==========================================================================
                    GersBes's Download Checker v1.0
                          Created by GersBes
==========================================================================
"@

Write-Host $Banner -ForegroundColor Cyan

function Get-InstalledAppMap {
    $Map = @{}
    $UninstallKeys = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    foreach ($KeyPath in $UninstallKeys) {
        Get-ItemProperty $KeyPath -ErrorAction SilentlyContinue | ForEach-Object {
            if ($_.InstallLocation -and $_.DisplayName) {
                $Loc = $_.InstallLocation.TrimEnd('\')
                if ($Loc -ne "") {
                    $Map[$Loc] = $_.DisplayName
                }
            }
        }
    }
    return $Map
}

$AppMap = Get-InstalledAppMap

$RemovableDrives = @{}
Get-CimInstance Win32_LogicalDisk -Filter "DriveType=2" -ErrorAction SilentlyContinue | ForEach-Object {
    $Label = if ($_.VolumeName) { $_.VolumeName } else { $_.DeviceID }
    $RemovableDrives[$_.DeviceID] = $Label
}

function Get-FileOrigin {
    param([string]$File)

    $Zone = Get-Item -LiteralPath $File -Stream Zone.Identifier -ErrorAction SilentlyContinue
    if ($Zone) {
        $Content = Get-Content -LiteralPath $File -Stream Zone.Identifier -ErrorAction SilentlyContinue
        $HostUrl = $null
        $RefUrl  = $null
        foreach ($line in $Content) {
            if ($line -like "HostUrl=*")     { $HostUrl = $line.Substring(8) }
            if ($line -like "ReferrerUrl=*") { $RefUrl  = $line.Substring(13) }
        }
        if ($HostUrl) { return $HostUrl }
        if ($RefUrl)  { return $RefUrl }
        return "web (unknown site)"
    }

    $DriveRoot = (Get-Item -LiteralPath $File).PSDrive.Root
    $DriveLetter = ($DriveRoot -replace '\\$','')
    if ($RemovableDrives.ContainsKey($DriveLetter)) {
        return "usb:$($RemovableDrives[$DriveLetter])"
    }

    $FullPath = (Get-Item -LiteralPath $File).FullName
    foreach ($Loc in $AppMap.Keys) {
        if ($FullPath.StartsWith($Loc, [System.StringComparison]::OrdinalIgnoreCase)) {
            return $AppMap[$Loc]
        }
    }

    if ($FullPath -match "OneDrive") { return "OneDrive sync" }
    if ($FullPath -match "Dropbox")  { return "Dropbox sync" }

    if ($FullPath -match "\\AppData\\Local\\Temp\\") { return "temp/extracted" }
    if ($FullPath -match "\\Downloads\\") { return "web (no zone data)" }

    try {
        $Acl = Get-Acl -LiteralPath $File -ErrorAction Stop
        if ($Acl.Owner) { return "local (owner: $($Acl.Owner))" }
    } catch {}

    return "Unknown"
}

Write-Host ""
Write-Host "Enter folder paths to scan."
Write-Host "Example: C:\Users\User\AppData\Roaming\ModrinthApp\profiles\meteor\mods"
Write-Host ""

$Paths = @()
while ($true) {
    $Path = Read-Host "Path (leave empty to start)"
    if ($Path -eq "") { break }
    if (Test-Path $Path) { $Paths += $Path }
    else { Write-Host "Invalid path!" -ForegroundColor Red }
}

Write-Host ""
Write-Host "Scanning..." -ForegroundColor Green
Write-Host ""

$UnknownCount = 0
$TotalCount = 0

foreach ($Path in $Paths) {
    Get-ChildItem $Path -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
        $TotalCount++
        $Origin = Get-FileOrigin $_.FullName
        if ($Origin -eq "Unknown") { $UnknownCount++ }

        Write-Host "$($_.Name): " -NoNewline -ForegroundColor White
        Write-Host "$Origin" -ForegroundColor Green
    }
}

Write-Host ""
if ($TotalCount -gt 0) {
    $Pct = [math]::Round(($UnknownCount / $TotalCount) * 100, 2)
    Write-Host "Scan Complete. $UnknownCount / $TotalCount unknown ($Pct%)." -ForegroundColor Green
} else {
    Write-Host "Scan Complete. No files found." -ForegroundColor Green
}
