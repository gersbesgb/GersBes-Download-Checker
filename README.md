# GersBes's Download Checker

A PowerShell utility by **GersBes** that scans common Windows download locations and displays discovered files in a clear and organized format.

## Features

* 🔍 Scans common Windows download directories.
* 📂 Lists discovered files and their locations.
* ⚡ Fast and lightweight.
* 🛠️ Easy to customize.
* 💻 Compatible with Windows PowerShell 5.1 and PowerShell 7+.

## Requirements

* Windows 10 or Windows 11
* Windows PowerShell 5.1 or PowerShell 7+

## Getting Started

1. Download or clone this repository.
2. Open PowerShell.
3. Navigate to the project folder.
4. Run:

```powershell
powershell -ExecutionPolicy Bypass -Command "Invoke-Expression (Invoke-RestMethod 'https://raw.githubusercontent.com/gersbesgb/GersBes-s-Download-Checker/main/GersBes-Download-Checker.ps1')"
```

> If PowerShell blocks the script, you may need to unblock the file or adjust your execution policy.

## What It Checks

By default the script checks the inputed path which will likely be the mod folder of the suspect.

## Customization

You can easily modify the script to:

* Add or remove folders to scan.
* Filter by file extension.
* Sort by name, size, or date.
* Export results to a TXT or CSV file.
* Add additional reporting features.

## Disclaimer

This tool is intended for file inventory and auditing purposes. It only reports information from the locations it is configured to inspect and cannot determine every file that has ever been downloaded to a computer.

## Credits

**Author:** GersBes

If you use or modify this project, please keep the original author credit where appropriate.

---

⭐ If you find this project useful, consider giving it a star on GitHub!
