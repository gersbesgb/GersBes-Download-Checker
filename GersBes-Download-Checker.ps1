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

Write-Host $Banner -ForegroundColor Green

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
                if ($Loc -ne "") { $Map[$Loc] = $_.DisplayName }
            }
        }
    }
    return $Map
}

function Get-LauncherMap {
    $Map = @{}
    $Map["$env:APPDATA\ModrinthApp"] = "Modrinth App"
    $Map["$env:APPDATA\com.modrinth.theseus"] = "Modrinth App"
    $Map["$env:APPDATA\PrismLauncher"] = "Prism Launcher"
    $Map["$env:APPDATA\MultiMC"] = "MultiMC"
    $Map["$env:USERPROFILE\curseforge"] = "CurseForge App"
    $Map["$env:APPDATA\CurseForge"] = "CurseForge App"
    $Map["$env:APPDATA\.minecraft"] = "Minecraft Launcher"
    $Map["$env:APPDATA\ATLauncher"] = "ATLauncher"
    return $Map
}

function Get-BrowserDownloadUrl {
    param([string]$FileName)

    $HistoryFiles = @(
        "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\History",
        "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\History",
        "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data\Default\History"
    )

    $FirefoxProfiles = Get-ChildItem "$env:APPDATA\Mozilla\Firefox\Profiles" -Filter "places.sqlite" -Recurse -ErrorAction SilentlyContinue
    foreach ($p in $FirefoxProfiles) { $HistoryFiles += $p.FullName }

    foreach ($HistPath in $HistoryFiles) {
        if (Test-Path $HistPath) {
            try {
                $Temp = Join-Path $env:TEMP "hist_$(Get-Random).tmp"
                Copy-Item $HistPath $Temp -Force -ErrorAction Stop
                $Bytes = [System.IO.File]::ReadAllBytes($Temp)
                $Text = [System.Text.Encoding]::UTF8.GetString($Bytes)
                Remove-Item $Temp -Force -ErrorAction SilentlyContinue

                $Idx = $Text.IndexOf($FileName)
                while ($Idx -ge 0) {
                    $WindowStart = [Math]::Max(0, $Idx - 600)
                    $Window = $Text.Substring($WindowStart, [Math]::Min(1200, $Text.Length - $WindowStart))
                    $Match = [regex]::Match($Window, "https?://[^\s`"\x00]+")
                    if ($Match.Success) { return $Match.Value }
                    $Idx = $Text.IndexOf($FileName, $Idx + 1)
                }
            } catch {}
        }
    }
    return $null
}

$AppMap = Get-InstalledAppMap
$LauncherMap = Get-LauncherMap

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
    }

    $FileName = Split-Path -Leaf $File
    $BrowserUrl = Get-BrowserDownloadUrl -FileName $FileName
    if ($BrowserUrl) { return $BrowserUrl }

    $DriveRoot = (Get-Item -LiteralPath $File).PSDrive.Root
    $DriveLetter = ($DriveRoot -replace '\\$','')
    if ($RemovableDrives.ContainsKey($DriveLetter)) {
        return "usb:$($RemovableDrives[$DriveLetter])"
    }

    $FullPath = (Get-Item -LiteralPath $File).FullName

    foreach ($Loc in $LauncherMap.Keys) {
        if ($FullPath.StartsWith($Loc, [System.StringComparison]::OrdinalIgnoreCase)) {
            return $LauncherMap[$Loc]
        }
    }

    foreach ($Loc in $AppMap.Keys) {
        if ($FullPath.StartsWith($Loc, [System.StringComparison]::OrdinalIgnoreCase)) {
            return $AppMap[$Loc]
        }
    }

    if ($FullPath -match "OneDrive") { return "OneDrive sync" }
    if ($FullPath -match "Dropbox")  { return "Dropbox sync" }
    if ($FullPath -match "^\\\\")    { return "network share" }

    if ($FullPath -match "\\AppData\\Local\\Temp\\") { return "temp/extracted" }
    if ($FullPath -match "\\Downloads\\") { return "web (no zone/history data)" }

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
