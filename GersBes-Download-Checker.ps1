Clear-Host
$Banner = @"

==========================================================================

 ██████╗ ███████╗██████╗ ███████╗██████╗ ███████╗███████╗
██╔════╝ ██╔════╝██╔══██╗██╔════╝██╔══██╗██╔════╝██╔════╝
██║  ███╗█████╗  ██████╔╝███████╗██████╔╝█████╗  ███████╗
██║   ██║██╔══╝  ██╔══██╗╚════██║██╔══██╗██╔══╝  ╚════██║
╚██████╔╝███████╗██║  ██║███████║██████╔╝███████╗███████║
 ╚═════╝ ╚══════╝╚═╝  ╚═╝╚══════╝╚═════╝ ╚══════╝╚══════╝

██████╗  ██████╗ ██╗    ██╗███╗    ██╗██╗      ██████╗  █████╗ ██████╗
██╔══██╗██╔═══██╗██║    ██║████╗   ██║██║     ██╔═══██╗██╔══██╗██╔══██╗
██║  ██║██║   ██║██║ █╗ ██║██╔██╗ ██║██║     ██║   ██║███████║██║  ██║
██║  ██║██║   ██║██║███╗██║██║╚██╗██║██║     ██║   ██║██╔══██║██║  ██║
██████╔╝╚██████╔╝╚███╔███╔╝██║ ╚████║███████╗╚██████╔╝██║  ██║██████╔╝
╚═════╝  ╚═════╝ ╚══╝╚══╝ ╚═╝  ╚═══╝╚══════╝ ╚═════╝ ╚═╝  ╚═╝╚═════╝

 ██████╗██╗  ██╗███████╗ ██████╗██╗  ██╗███████╗██████╗
██╔════╝██║  ██║██╔════╝██╔════╝██║ ██╔╝██╔════╝██╔══██╗
██║     ███████║█████╗  ██║     █████╔╝ █████╗  ██████╔╝
██║     ██╔══██║██╔══╝  ██║     ██╔═██╗ ██╔══╝  ██╔══██╗
╚██████╗██║  ██║███████╗╚██████╗██║  ██╗███████╗██║  ██║
 ╚═════╝╚═╝  ╚═╝╚══════╝ ╚═════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝

==========================================================================
                    GersBes's Download Checker v1.1
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

function Format-SourceUrl {
    param([string]$Url)

    if ($Url -match "cdn\.discordapp\.com/attachments/(\d+)/(\d+)") {
        $ChannelId = $Matches[1]
        return "Discord Server/DM (ID: $ChannelId) -> $Url"
    }
    if ($Url -match "media\.discordapp\.net/attachments/(\d+)/(\d+)") {
        $ChannelId = $Matches[1]
        return "Discord Server/DM (ID: $ChannelId) -> $Url"
    }

    return $Url
}

$AppMap = Get-InstalledAppMap
$LauncherMap = Get-LauncherMap

$RemovableDrives = @{}
Get-CimInstance Win32_LogicalDisk -Filter "DriveType=2" -ErrorAction SilentlyContinue | ForEach-Object {
    $Label = if ($_.VolumeName) { $_.VolumeName } else { $_.DeviceID }
    $RemovableDrives[$_.DeviceID] = $Label
}

function Check-ImportParent {
    param([string]$File)
    
    $Directory = Split-Path -Parent $File
    $ImportArchives = Get-ChildItem -Path $Directory -Include "*.zip", "*.mrpack", "*.curseforge", "*.rar", "*.7z", "*.exe" -File -ErrorAction SilentlyContinue
    
    foreach ($Archive in $ImportArchives) {
        $ArchiveData = Get-FileOriginInternal -File $Archive.FullName
        if ($ArchiveData.Origin -ne "Unknown") {
            return [PSCustomObject]@{
                ArchiveName = $Archive.Name
                ArchiveOrigin = $ArchiveData.Origin
            }
        }
    }
    return $null
}

function Get-FileOriginInternal {
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
        if ($HostUrl) { return @{ Type="Web"; Origin=(Format-SourceUrl -Url $HostUrl) } }
        if ($RefUrl)  { return @{ Type="Web"; Origin=(Format-SourceUrl -Url $RefUrl) } }
    }

    $FileName = Split-Path -Leaf $File
    $BrowserUrl = Get-BrowserDownloadUrl -FileName $FileName
    if ($BrowserUrl) { return @{ Type="Web"; Origin=(Format-SourceUrl -Url $BrowserUrl) } }

    $DriveRoot = (Get-Item -LiteralPath $File).PSDrive.Root
    $DriveLetter = ($DriveRoot -replace '\\$','')
    if ($RemovableDrives.ContainsKey($DriveLetter)) {
        return @{ Type="USB"; Origin="usb:$($RemovableDrives[$DriveLetter])" }
    }

    $FullPath = (Get-Item -LiteralPath $File).FullName

    foreach ($Loc in $LauncherMap.Keys) {
        if ($FullPath.StartsWith($Loc, [System.StringComparison]::OrdinalIgnoreCase)) {
            return @{ Type="App"; Origin=$LauncherMap[$Loc] }
        }
    }

    foreach ($Loc in $AppMap.Keys) {
        if ($FullPath.StartsWith($Loc, [System.StringComparison]::OrdinalIgnoreCase)) {
            return @{ Type="App"; Origin=$AppMap[$Loc] }
        }
    }

    if ($FullPath -match "OneDrive") { return @{ Type="Sync"; Origin="OneDrive Sync" } }
    if ($FullPath -match "Dropbox")  { return @{ Type="Sync"; Origin="Dropbox Sync" } }
    if ($FullPath -match "^\\\\")    { return @{ Type="Network"; Origin="Network Share" } }

    return @{ Type="Unknown"; Origin="Unknown" }
}

function Get-FileOrigin {
    param([string]$File)

    $DirectOrigin = Get-FileOriginInternal -File $File
    
    if ($DirectOrigin.Type -eq "Web") {
        return @{ Type = "Web"; Origin = $DirectOrigin.Origin; Name = (Split-Path -Leaf $File) }
    }

    $ImportInfo = Check-ImportParent -File $File
    if ($ImportInfo) {
        return @{
            Type = "Imported"
            Origin = $ImportInfo.ArchiveOrigin
            Importer = $ImportInfo.ArchiveName
            Name = (Split-Path -Leaf $File)
        }
    }

    return @{ Type = $DirectOrigin.Type; Origin = $DirectOrigin.Origin; Name = (Split-Path -Leaf $File) }
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

$Results_Web = @()
$Results_Imported = @()
$Results_App = @()
$Results_Unknown = @()

foreach ($Path in $Paths) {
    Get-ChildItem $Path -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
        $Result = Get-FileOrigin $_.FullName
        
        if ($Result.Type -eq "Web") { $Results_Web += $Result }
        elseif ($Result.Type -eq "Imported") { $Results_Imported += $Result }
        elseif ($Result.Type -eq "App") { $Results_App += $Result }
        else { $Results_Unknown += $Result }
    }
}

if ($Results_Web.Count -gt 0) {
    Write-Host "=========================================" -ForegroundColor Cyan
    Write-Host "       KNOWN WEBSITES / DIRECT WEB       " -ForegroundColor Cyan
    Write-Host "=========================================" -ForegroundColor Cyan
    foreach ($r in $Results_Web) {
        Write-Host "$($r.Name): " -NoNewline -ForegroundColor White
        Write-Host "$($r.Origin)" -ForegroundColor Green
    }
    Write-Host ""
}

if ($Results_Imported.Count -gt 0) {
    Write-Host "=========================================" -ForegroundColor Yellow
    Write-Host "    IMPORTED / INJECTED (VIA EXE/ZIP)    " -ForegroundColor Yellow
    Write-Host "=========================================" -ForegroundColor Yellow
    foreach ($r in $Results_Imported) {
        Write-Host "$($r.Name):" -ForegroundColor White
        Write-Host " + $($r.Importer): " -NoNewline -ForegroundColor Yellow
        Write-Host "$($r.Origin)" -ForegroundColor Green
    }
    Write-Host ""
}

if ($Results_App.Count -gt 0) {
    Write-Host "=========================================" -ForegroundColor Magenta
    Write-Host "        DOWNLOADED VIA KNOWN APP         " -ForegroundColor Magenta
    Write-Host "=========================================" -ForegroundColor Magenta
    foreach ($r in $Results_App) {
        Write-Host "$($r.Name): " -NoNewline -ForegroundColor White
        Write-Host "$($r.Origin)" -ForegroundColor Magenta
    }
    Write-Host ""
}

if ($Results_Unknown.Count -gt 0) {
    Write-Host "=========================================" -ForegroundColor DarkGray
    Write-Host "          UNKNOWN / LOCAL FILES          " -ForegroundColor DarkGray
    Write-Host "=========================================" -ForegroundColor DarkGray
    foreach ($r in $Results_Unknown) {
        Write-Host "$($r.Name): " -NoNewline -ForegroundColor White
        Write-Host "$($r.Origin)" -ForegroundColor DarkGray
    }
    Write-Host ""
}

$TotalCount = $Results_Web.Count + $Results_Imported.Count + $Results_App.Count + $Results_Unknown.Count
if ($TotalCount -gt 0) {
    $Pct = [math]::Round(($Results_Unknown.Count / $TotalCount) * 100, 2)
    Write-Host "Scan Complete. $TotalCount files scanned." -ForegroundColor Green
    Write-Host "$($Results_Unknown.Count) files lacked trace metadata ($Pct%)." -ForegroundColor Green
} else {
    Write-Host "Scan Complete. No files found." -ForegroundColor Green
}
