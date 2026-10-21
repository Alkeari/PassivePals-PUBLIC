<#
.SYNOPSIS
Stages Passive Pals for local testing under a separate Dev package identity.

.DESCRIPTION
Passive Pals is a UE4SS Lua mod: no build step, Info.json and Scripts/ ship exactly as committed, plus the
mod's update check, which Lua cannot do (no HTTP): Source\PassivePals builds into dlls\main.dll, staged
with a copy of Info.json beside it so the dll knows which mod and version it belongs to. Every
-Package and -Release builds it first (skip with -SkipBuild) and checks it against both UE4SS
builds' export lists.
This script never touches the released package; it only stages a second, disposable package
beside it and flips the loader's enable switch between the two.

  -Package   (default) Stages a DEV build under the workshop root at $LocalPackageId as its own
             package, "PassivePalsDev" ("Passive Pals (Dev)"), with "DebugMode": true so the
             loader reinstalls it on every launch. The released package (PackageName PassivePals,
             once it exists as a subscribed Workshop item) is never touched; instead the script
             flips the loader's enable switch in Mods\PalModSettings.ini so that ONLY the dev
             package is active. Safe to run with Palworld open; the game never loads from the
             staging folder directly.

  -Unstage   Removes the dev package (staging folder, installed copy, loader record) and gives
             the enable switch back to the released package name. Run it when a test session is
             over, or the next launch keeps running the dev build.

Pass either switch; passing none runs -Package only.
#>
[CmdletBinding()]
param(
    [switch]$Package,
    [switch]$Release,
    [switch]$Unstage,
    [string]$GameRoot = "D:\Steam\steamapps\common\Palworld",
    [string]$LocalPackageId = "9000000003",
    [switch]$SkipBuild,
    [string]$ToolchainRoot = "C:\Dev\RE-UE4SS",
    [string]$XmakeExe = "C:\Dev\xmake293\xmake.exe"
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$packageName = "PassivePals"
$devPackageName = "$($packageName)Dev"
$settingsIni = Join-Path $GameRoot "Mods\PalModSettings.ini"

if (-not $Package -and -not $Release -and -not $Unstage) { $Package = $true }

function Set-ActivePackage([string]$enable, [string]$disable) {
    $lines = Get-Content -LiteralPath $settingsIni
    $lines = @($lines | Where-Object { $_ -ne "ActiveModList=$disable" })
    if (-not ($lines -contains "ActiveModList=$enable")) {
        $index = [array]::FindLastIndex($lines, [Predicate[string]]{ param($l) $l -like "ActiveModList=*" })
        if ($index -lt 0) { $index = $lines.Count - 1 }
        $lines = $lines[0..$index] + @("ActiveModList=$enable") + $(if ($index + 1 -lt $lines.Count) { $lines[($index + 1)..($lines.Count - 1)] } else { @() })
    }
    Set-Content -LiteralPath $settingsIni -Value $lines -Encoding UTF8
    Write-Host "Loader enable switch: $enable on, $disable off"
}

function Get-WorkshopRoot {
    $match = Select-String -Path $settingsIni -Pattern "^WorkshopRootDir=(.+)$"
    if (-not $match) { throw "WorkshopRootDir not found in $settingsIni" }
    return $match.Matches[0].Groups[1].Value.Trim()
}

if ($Unstage) {
    $workshopRoot = Get-WorkshopRoot
    foreach ($p in (Join-Path $workshopRoot $LocalPackageId),
                   (Join-Path $GameRoot "Mods\NativeMods\UE4SS\Mods\$devPackageName"),
                   (Join-Path $GameRoot "Mods\ManagedMods\$devPackageName")) {
        if (Test-Path $p) { Remove-Item -LiteralPath $p -Recurse -Force; Write-Host "Removed $p" }
    }
    Set-ActivePackage -enable $packageName -disable $devPackageName
    Write-Host "Dev build unstaged. Next launch runs the released package (once published)."
    return
}

# The update check is the only compiled part. Its dll reads PackageName, ModName and Version from
# the Info.json beside it, always the released identity, so a Dev package still checks the real
# feed and logs under the mod's own tag.
function Build-Dlls([string]$destination) {
    if (-not $script:builtDll) {
        if (-not $SkipBuild) {
            $env:PATH = "$env:USERPROFILE\.rustup\toolchains\stable-x86_64-pc-windows-msvc\bin;$env:USERPROFILE\.cargo\bin;$env:PATH"
            & $XmakeExe build -P $ToolchainRoot $packageName
            if ($LASTEXITCODE -ne 0) { throw "Build failed with exit code $LASTEXITCODE." }
        }
        $built = Join-Path $ToolchainRoot "Binaries\Game__Shipping__Win64\$packageName\$packageName.dll"
        if (-not (Test-Path $built)) { throw "Built dll not found at $built" }
        $abiTool = Join-Path (Split-Path -Parent $repoRoot) ".Tooling\UE4SS-builds"
        $exportLists = Get-ChildItem -Path (Join-Path $abiTool "exports") -Filter "*.txt" | Select-Object -ExpandProperty FullName
        & python (Join-Path $abiTool "Check-Ue4ssAbi.py") $built @exportLists
        if ($LASTEXITCODE -ne 0) { throw "The update check imports UE4SS symbols that one supported UE4SS build does not export (see above)." }
        $script:builtDll = $built
    }
    $dlls = Join-Path $destination "dlls"
    if (Test-Path $dlls) { Remove-Item -LiteralPath $dlls -Recurse -Force }
    New-Item -ItemType Directory -Force -Path $dlls | Out-Null
    Copy-Item -LiteralPath $script:builtDll -Destination (Join-Path $dlls "main.dll") -Force
    Copy-Item -LiteralPath (Join-Path $repoRoot "Info.json") -Destination $dlls -Force
}

if ($Package) {
    $workshopRoot = Get-WorkshopRoot
    $staging = Join-Path $workshopRoot $LocalPackageId

    $info = Get-Content -LiteralPath (Join-Path $repoRoot "Info.json") -Raw | ConvertFrom-Json
    $info.PackageName = $devPackageName
    $info.ModName = "$($info.ModName) (Dev)"
    $info.DebugMode = $true
    New-Item -ItemType Directory -Force -Path $staging | Out-Null
    $info | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $staging "Info.json") -Encoding UTF8

    $stagedScripts = Join-Path $staging "Scripts"
    if (Test-Path $stagedScripts) { Remove-Item -LiteralPath $stagedScripts -Recurse -Force }
    Copy-Item -LiteralPath (Join-Path $repoRoot "Scripts") -Destination $staging -Recurse -Force
    Build-Dlls $staging
    Copy-Item -LiteralPath (Join-Path $repoRoot "LICENSE.md") -Destination $staging -Force

    Set-ActivePackage -enable $devPackageName -disable $packageName
    Write-Host "Dev package staged at $staging"
    Write-Host "Fully close and relaunch Palworld: DebugMode reinstalls from this staged copy on launch, and only a real relaunch proves it."
    Write-Host "When the test session is over: tools/deploy.ps1 -Unstage (re-enables the released package name)."
}

if ($Release) {
    # The ONLY identity that ever ships is the released one. Anything else in the committed
    # manifest (a dev name, debug mode, a stray suffix) stops the release here.
    $info = Get-Content -LiteralPath (Join-Path $repoRoot "Info.json") -Raw | ConvertFrom-Json
    if ($info.PackageName -ne $packageName) { throw "Info.json PackageName is '$($info.PackageName)'; a release must be exactly '$packageName'." }
    if ($info.ModName -ne "Passive Pals") { throw "Info.json ModName is '$($info.ModName)'; a release must be exactly 'Passive Pals'." }
    if ($info.DebugMode) { throw "Info.json has DebugMode true; a release package must ship with it false." }

    $outDir = Join-Path $repoRoot "out"
    $pkgDir = Join-Path $outDir $packageName
    if (Test-Path $pkgDir) { Remove-Item -Recurse -Force $pkgDir }
    New-Item -ItemType Directory -Force -Path $pkgDir | Out-Null
    Copy-Item -LiteralPath (Join-Path $repoRoot "Info.json") -Destination $pkgDir -Force
    Copy-Item -LiteralPath (Join-Path $repoRoot "LICENSE.md") -Destination $pkgDir -Force
    Copy-Item -LiteralPath (Join-Path $repoRoot "thumbnail.png") -Destination $pkgDir -Force
    Copy-Item -LiteralPath (Join-Path $repoRoot "PACKAGE_README.txt") -Destination (Join-Path $pkgDir "README.txt") -Force
    Copy-Item -LiteralPath (Join-Path $repoRoot "Scripts") -Destination $pkgDir -Recurse -Force
    Build-Dlls $pkgDir
    $zip = Join-Path $outDir "$packageName-$($info.Version).zip"
    if (Test-Path $zip) { Remove-Item -Force $zip }
    Compress-Archive -Path $pkgDir -DestinationPath $zip
    Write-Host "Steam Workshop package written to $pkgDir (zip: $zip)"

    # Nexus Mods package: the same Scripts as a plain UE4SS Lua mod. The zip carries the FULL
    # game path, Pal\Binaries\Win64\ue4ss\Mods\PassivePals\, because that is the one layout every
    # version of Vortex's Palworld extension auto-installs (see Palpedia Enhancer's deploy.ps1
    # for the history). Manual users extract into the Palworld install folder. No Info.json:
    # the Palworld loader is not involved.
    $nexusRoot = Join-Path $outDir "nexus"
    if (Test-Path $nexusRoot) { Remove-Item -Recurse -Force $nexusRoot }
    $nexusDir = Join-Path $nexusRoot "Pal\Binaries\Win64\ue4ss\Mods\$packageName"
    New-Item -ItemType Directory -Force -Path $nexusDir | Out-Null
    Copy-Item -LiteralPath (Join-Path $repoRoot "Scripts") -Destination $nexusDir -Recurse -Force
    Build-Dlls $nexusDir
    Copy-Item -LiteralPath (Join-Path $repoRoot "LICENSE.md") -Destination $nexusDir -Force
    Copy-Item -LiteralPath (Join-Path $repoRoot "PACKAGE_README_NEXUS.txt") -Destination (Join-Path $nexusDir "README.txt") -Force
    Set-Content -LiteralPath (Join-Path $nexusDir "enabled.txt") -Value "" -NoNewline
    $nexusZip = Join-Path $outDir "$packageName-$($info.Version)-nexus.zip"
    if (Test-Path $nexusZip) { Remove-Item -Force $nexusZip }
    Compress-Archive -Path (Join-Path $nexusRoot "Pal") -DestinationPath $nexusZip
    Write-Host "Nexus Mods package written to $nexusZip"
}
