<#
.SYNOPSIS
    Puzzak Multi-Platform Automated Build & Release Script.
    Builds Android APK, Android App Bundle (AAB), and Windows x64 Desktop binaries,
    stages the Windows folder for Inno Setup installer compilation, compiles the installer
    if Inno Setup (ISCC) is available, generates SHA256 checksums, and optionally publishes
    to GitHub Releases and Google Play.

.DESCRIPTION
    Based on PAIOS/geminilocal build_releases.ps1 and GGScanus Inno Setup conventions,
    modernized for full multi-platform release automation.
    Extracts version and build number from pubspec.yaml following the X.Y.Z+YYMMDDNN convention.
    Adapts flexibly to projects with or without Windows desktop support, and supports custom Inno Setup scripts.
    Outputs organized, named binaries into dist/v<VersionName>/.

.PARAMETER SkipTests
    Skips running 'flutter test' before building binaries.

.PARAMETER Platform
    Target platform: 'All' (default), 'Android', 'Windows', 'Apk', or 'Aab'.

.PARAMETER PublishGitHub
    If specified and GitHub CLI ('gh') is installed and authenticated, automatically creates
    a GitHub release draft or published release with artifacts and checksums attached.

.PARAMETER PublishPlayStore
    If specified, provides Google Play Console upload instructions or triggers automated upload.

.PARAMETER AppName
    Custom name for artifact filenames. Defaults to capitalized 'name' in pubspec.yaml (or 'App').

.PARAMETER InnoSetupScript
    Path to a custom Inno Setup (.iss) script. If omitted, checks for installer.iss,
    windows/installer.iss, or scripts/installer.iss; if none found, generates a tailored .iss on the fly.

.PARAMETER ZipWindows
    Optional switch to also create a portable .zip archive of the Windows release folder.

.PARAMETER Draft
    When publishing to GitHub, creates a draft release instead of publishing immediately.

.PARAMETER Prerelease
    When publishing to GitHub, marks the release as a pre-release.

.EXAMPLE
    .\scripts\build_releases.ps1
    .\scripts\build_releases.ps1 -SkipTests
    .\scripts\build_releases.ps1 -Platform Android
    .\scripts\build_releases.ps1 -Platform Windows -InnoSetupScript custom.iss
    .\scripts\build_releases.ps1 -PublishGitHub
#>

[CmdletBinding()]
param(
    [switch]$SkipTests,
    [ValidateSet('All', 'Android', 'Windows', 'Apk', 'Aab')]
    [string]$Platform = 'All',
    [switch]$PublishGitHub,
    [switch]$PublishPlayStore,
    [string]$AppName = '',
    [string]$InnoSetupScript = '',
    [switch]$ZipWindows,
    [switch]$Draft,
    [switch]$Prerelease
)

$ErrorActionPreference = 'Stop'

function Write-Header {
    param([string]$Text)
    Write-Host ""
    Write-Host "=======================================================================" -ForegroundColor Cyan
    Write-Host "  $Text" -ForegroundColor Cyan
    Write-Host "=======================================================================" -ForegroundColor Cyan
}

function Write-Step {
    param([string]$Step, [string]$Text)
    Write-Host ""
    Write-Host "[$Step] $Text" -ForegroundColor Yellow
}

function Write-Success {
    param([string]$Text)
    Write-Host "[SUCCESS] $Text" -ForegroundColor Green
}

function Write-Failure {
    param([string]$Text)
    Write-Host "[ERROR] $Text" -ForegroundColor Red
}

function Write-Info {
    param([string]$Text)
    Write-Host "[INFO] $Text" -ForegroundColor Gray
}

# -----------------------------------------------------------------------------
# 1. Pre-flight Checks & Working Directory Verification
# -----------------------------------------------------------------------------
Write-Header "Puzzak Multi-Platform Build & Release Pipeline"

# Locate repo root (ensure pubspec.yaml is present)
if (-not (Test-Path "pubspec.yaml")) {
    if (Test-Path "$PSScriptRoot\..\pubspec.yaml") {
        Set-Location "$PSScriptRoot\.."
        Write-Info "Switched working directory to repo root: $PWD"
    } else {
        Write-Failure "pubspec.yaml not found in current directory ($PWD) or parent. Run from project root."
        exit 1
    }
}

# Ensure Flutter is in PATH or look in standard installation paths
if (-not (Get-Command "flutter" -ErrorAction SilentlyContinue)) {
    $CommonFlutterPaths = @(
        "C:\Programs\Android\flutter\bin",
        "C:\flutter\bin",
        "C:\src\flutter\bin",
        "$env:LOCALAPPDATA\flutter\bin"
    )
    foreach ($Candidate in $CommonFlutterPaths) {
        if (Test-Path "$Candidate\flutter.bat") {
            $env:PATH = "$Candidate;" + $env:PATH
            Write-Info "Added Flutter to current session PATH: $Candidate"
            break
        }
    }
}

if (-not (Get-Command "flutter" -ErrorAction SilentlyContinue)) {
    Write-Failure "Flutter CLI could not be found. Please ensure Flutter is installed and added to PATH."
    exit 1
}

# Ensure Git is in PATH if available
if (-not (Get-Command "git" -ErrorAction SilentlyContinue)) {
    $CommonGitPaths = @(
        "C:\Program Files\Git\cmd",
        "C:\Program Files\Git\bin",
        "$env:LOCALAPPDATA\Programs\Git\cmd"
    )
    foreach ($Candidate in $CommonGitPaths) {
        if (Test-Path "$Candidate\git.exe") {
            $env:PATH = "$Candidate;" + $env:PATH
            Write-Info "Added Git to current session PATH: $Candidate"
            break
        }
    }
}

# Display Flutter version
$FlutterVer = (flutter --version 2>&1 | Select-Object -First 1)
Write-Info "Using: $FlutterVer"

# -----------------------------------------------------------------------------
# 2. Parse pubspec.yaml for AppName, VersionName, and VersionCode
# -----------------------------------------------------------------------------
Write-Step "1/5" "Parsing version and configuration from pubspec.yaml..."

$PubspecContent = Get-Content "pubspec.yaml" -Raw

# Parse version: X.Y.Z+YYMMDDNN
$VersionName = ""
$VersionCode = ""
if ($PubspecContent -match 'version:\s*([0-9\.]+)\+([0-9]+)') {
    $VersionName = $Matches[1].Trim()
    $VersionCode = $Matches[2].Trim()
} else {
    Write-Failure "Could not parse version: X.Y.Z+YYMMDDNN from pubspec.yaml."
    exit 1
}

# Parse or infer AppName
if (-not $AppName) {
    if ($PubspecContent -match 'name:\s*([a-zA-Z0-9_\-]+)') {
        $RawName = $Matches[1].Trim()
        $AppName = (Get-Culture).TextInfo.ToTitleCase($RawName)
    } else {
        $AppName = "App"
    }
}

# Detect Windows executable binary name from windows/CMakeLists.txt if available
$DetectedExeName = "$($AppName.ToLower()).exe"
if (Test-Path "windows\CMakeLists.txt") {
    $CmakeContent = Get-Content "windows\CMakeLists.txt" -Raw
    if ($CmakeContent -match 'set\(BINARY_NAME\s+"([^"]+)"\)') {
        $DetectedExeName = "$($Matches[1].Trim()).exe"
    }
}

$HasWindowsSupport = Test-Path "windows"

Write-Host "  App Name:        " -NoNewline -ForegroundColor White
Write-Host "$AppName" -ForegroundColor Cyan
Write-Host "  Version Name:    " -NoNewline -ForegroundColor White
Write-Host "v$VersionName" -ForegroundColor Cyan
Write-Host "  Build Number:    " -NoNewline -ForegroundColor White
Write-Host "$VersionCode" -ForegroundColor Cyan
Write-Host "  Target(s):       " -NoNewline -ForegroundColor White
Write-Host "$Platform" -ForegroundColor Cyan
Write-Host "  Windows Project: " -NoNewline -ForegroundColor White
Write-Host $(if ($HasWindowsSupport) { "Yes (Executable: $DetectedExeName)" } else { "No (Android/Cross-platform only)" }) -ForegroundColor $(if ($HasWindowsSupport) { "Green" } else { "Gray" })

# -----------------------------------------------------------------------------
# 3. Run Automated Tests
# -----------------------------------------------------------------------------
if ($SkipTests) {
    Write-Step "2/5" "Skipping tests (-SkipTests specified)."
} else {
    Write-Step "2/5" "Running Flutter test suite..."
    & flutter test
    if ($LASTEXITCODE -ne 0) {
        Write-Failure "Flutter test suite failed (exit code $LASTEXITCODE). Release build cancelled."
        exit $LASTEXITCODE
    }
    Write-Success "All tests passed successfully!"
}

# -----------------------------------------------------------------------------
# 4. Prepare Dist Directory
# -----------------------------------------------------------------------------
$DistDir = "dist\v$VersionName"
if (-not (Test-Path $DistDir)) {
    New-Item -ItemType Directory -Path $DistDir -Force | Out-Null
}
$DistDirFullPath = (Resolve-Path $DistDir).Path
Write-Info "Output directory: $DistDirFullPath"

$GeneratedArtifacts = @()

# -----------------------------------------------------------------------------
# 5. Build Artifacts
# -----------------------------------------------------------------------------
Write-Step "3/5" "Building production release binaries..."

# --- Build Android APK ---
if ($Platform -in @('All', 'Android', 'Apk')) {
    Write-Host ""
    Write-Host ">>> Building Android Release APK..." -ForegroundColor Magenta
    $ApkBuildName = "$VersionName-GitHub"
    
    & flutter build apk --release --build-name $ApkBuildName --build-number $VersionCode
    if ($LASTEXITCODE -ne 0) {
        Write-Failure "Android APK build failed with exit code $LASTEXITCODE."
        exit $LASTEXITCODE
    }

    $SourceApk = "build\app\outputs\flutter-apk\app-release.apk"
    if (Test-Path $SourceApk) {
        # Primary file: App_vX.Y.Z_GitHub.apk
        $StandardApk = "$DistDir\App_v${VersionName}_GitHub.apk"
        Copy-Item -Path $SourceApk -Destination $StandardApk -Force
        $GeneratedArtifacts += $StandardApk
        Write-Success "Created: $StandardApk"

        # Named file if custom app name: <AppName>_vX.Y.Z_GitHub.apk
        if ($AppName -and $AppName -ne "App") {
            $NamedApk = "$DistDir\${AppName}_v${VersionName}_GitHub.apk"
            Copy-Item -Path $SourceApk -Destination $NamedApk -Force
            $GeneratedArtifacts += $NamedApk
            Write-Success "Created: $NamedApk"
        }
    } else {
        Write-Failure "Expected APK not found at $SourceApk"
        exit 1
    }
}

# --- Build Android App Bundle (AAB for Google Play) ---
if ($Platform -in @('All', 'Android', 'Aab')) {
    Write-Host ""
    Write-Host ">>> Building Android App Bundle (AAB for Google Play)..." -ForegroundColor Magenta
    $AabBuildName = "$VersionName-PlayStore"

    & flutter build appbundle --release --build-name $AabBuildName --build-number $VersionCode
    if ($LASTEXITCODE -ne 0) {
        Write-Failure "Android AAB build failed with exit code $LASTEXITCODE."
        exit $LASTEXITCODE
    }

    $SourceAab = "build\app\outputs\bundle\release\app-release.aab"
    if (Test-Path $SourceAab) {
        # Primary file: App_vX.Y.Z_PlayStore.aab
        $StandardAab = "$DistDir\App_v${VersionName}_PlayStore.aab"
        Copy-Item -Path $SourceAab -Destination $StandardAab -Force
        $GeneratedArtifacts += $StandardAab
        Write-Success "Created: $StandardAab"

        # Named file if custom app name: <AppName>_vX.Y.Z_PlayStore.aab
        if ($AppName -and $AppName -ne "App") {
            $NamedAab = "$DistDir\${AppName}_v${VersionName}_PlayStore.aab"
            Copy-Item -Path $SourceAab -Destination $NamedAab -Force
            $GeneratedArtifacts += $NamedAab
            Write-Success "Created: $NamedAab"
        }
    } else {
        Write-Failure "Expected AAB not found at $SourceAab"
        exit 1
    }
}

# --- Build Windows Desktop & Prepare Inno Setup Installer ---
if ($Platform -in @('All', 'Windows')) {
    if ($HasWindowsSupport) {
        Write-Host ""
        Write-Host ">>> Building Windows x64 Desktop Release..." -ForegroundColor Magenta

        & flutter build windows --release
        if ($LASTEXITCODE -ne 0) {
            Write-Failure "Windows build failed with exit code $LASTEXITCODE."
            exit $LASTEXITCODE
        }

        # Locate Windows release bundle directory
        $WinCandidates = @(
            "build\windows\x64\runner\Release",
            "build\windows\runner\Release"
        )
        $WinSourceDir = ""
        foreach ($Candidate in $WinCandidates) {
            if (Test-Path $Candidate) {
                $WinSourceDir = $Candidate
                break
            }
        }

        if ($WinSourceDir) {
            # 1. Stage Windows release binaries into dedicated folder for installer
            $WinStagingDir = "$DistDir\windows_x64"
            if (Test-Path $WinStagingDir) {
                Remove-Item -Path $WinStagingDir -Recurse -Force
            }
            New-Item -ItemType Directory -Path $WinStagingDir -Force | Out-Null

            Write-Info "Staging Windows release files into: $WinStagingDir"
            Copy-Item -Path "$WinSourceDir\*" -Destination $WinStagingDir -Recurse -Force
            Write-Success "Staged Windows binaries folder: $WinStagingDir"

            # Check if actual executable exists in staging
            $FoundExes = Get-ChildItem -Path $WinStagingDir -Filter "*.exe"
            if ($FoundExes.Count -gt 0) {
                $DetectedExeName = $FoundExes[0].Name
                Write-Info "Found executable: $DetectedExeName"
            }

            # Optional ZIP archive if requested
            if ($ZipWindows) {
                $StandardZip = "$DistDir\App_v${VersionName}_Windows_x64.zip"
                Write-Info "Creating optional portable ZIP archive: $StandardZip"
                Compress-Archive -Path "$WinStagingDir\*" -DestinationPath $StandardZip -Force
                $GeneratedArtifacts += $StandardZip
                Write-Success "Created: $StandardZip"
            }

            # 2. Inno Setup Installer Wiring & Execution
            Write-Host ""
            Write-Host ">>> Configuring Windows Installer (Inno Setup)..." -ForegroundColor Cyan

            # Check for custom .iss script
            $ResolvedIssScript = ""
            if ($InnoSetupScript -and (Test-Path $InnoSetupScript)) {
                $ResolvedIssScript = (Resolve-Path $InnoSetupScript).Path
                Write-Info "Using user-specified Inno Setup script: $ResolvedIssScript"
            } else {
                $CandidateIssPaths = @(
                    "installer.iss",
                    "windows\installer.iss",
                    "scripts\installer.iss"
                )
                foreach ($Cand in $CandidateIssPaths) {
                    if (Test-Path $Cand) {
                        $ResolvedIssScript = (Resolve-Path $Cand).Path
                        Write-Info "Found project-specific Inno Setup script: $ResolvedIssScript"
                        break
                    }
                }
            }

            # If no custom .iss exists, generate a smart, tailored .iss script matching Puzzak's GGScanus conventions
            if (-not $ResolvedIssScript) {
                $GeneratedIssPath = "$DistDir\installer.iss"
                $StagingAbsolute = (Resolve-Path $WinStagingDir).Path

                $IssContent = @"
; Script generated by Puzzak Build System based on GGScanus Inno Setup conventions.
; SEE THE DOCUMENTATION FOR DETAILS ON CREATING INNO SETUP SCRIPT FILES!

#ifndef MyAppName
#define MyAppName "$AppName"
#endif

#ifndef MyAppVersion
#define MyAppVersion "$VersionName"
#endif

#ifndef MyAppPublisher
#define MyAppPublisher "Puzzak"
#endif

#ifndef MyAppURL
#define MyAppURL "https://puzzak.page"
#endif

#ifndef MyAppExeName
#define MyAppExeName "$DetectedExeName"
#endif

#ifndef MyAppSourceDir
#define MyAppSourceDir "$StagingAbsolute"
#endif

[Setup]
AppId={{PUZZAK-$AppName-SETUP}}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName=C:/Programs/{#MyAppName}
UninstallDisplayIcon={app}\{#MyAppExeName}
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=commandline
SolidCompression=yes
WizardStyle=modern

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "ukrainian"; MessagesFile: "compiler:Languages\Ukrainian.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "{#MyAppSourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent
"@
                $IssContent | Set-Content -Path $GeneratedIssPath -Encoding utf8
                $ResolvedIssScript = (Resolve-Path $GeneratedIssPath).Path
                Write-Info "Generated tailored Inno Setup script: $GeneratedIssPath"
            }

            # Locate Inno Setup Compiler (iscc.exe)
            $IsccCmd = $null
            if (Get-Command "iscc" -ErrorAction SilentlyContinue) {
                $IsccCmd = (Get-Command "iscc").Source
            } else {
                $CandidateIsccPaths = @(
                    "C:\Programs\InnoSetup\ISCC.exe",
                    "C:\Program Files (x86)\Inno Setup 6\ISCC.exe",
                    "C:\Program Files\Inno Setup 6\ISCC.exe",
                    "C:\Program Files (x86)\Inno Setup 5\ISCC.exe",
                    "C:\Program Files\Inno Setup 5\ISCC.exe",
                    "$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe"
                )
                foreach ($Cand in $CandidateIsccPaths) {
                    if (Test-Path $Cand) {
                        $IsccCmd = $Cand
                        break
                    }
                }
            }

            if ($IsccCmd) {
                Write-Host ">>> Compiling Windows Installer executable using Inno Setup..." -ForegroundColor Green
                Write-Info "ISCC Path: $IsccCmd"

                $OutputExeBase = "${AppName}_setup_v${VersionName}"
                $StagingAbsolute = (Resolve-Path $WinStagingDir).Path

                $IsccArgs = @(
                    "/O`"$DistDirFullPath`"",
                    "/F`"$OutputExeBase`"",
                    "/DMyAppName=$AppName",
                    "/DMyAppVersion=$VersionName",
                    "/DMyAppExeName=$DetectedExeName",
                    "/DMyAppSourceDir=$StagingAbsolute",
                    "`"$ResolvedIssScript`""
                )

                Write-Info "Running: & `"$IsccCmd`" $($IsccArgs -join ' ')"
                & $IsccCmd @IsccArgs

                if ($LASTEXITCODE -eq 0) {
                    $InstallerExe = "$DistDir\$OutputExeBase.exe"
                    if (Test-Path $InstallerExe) {
                        $GeneratedArtifacts += $InstallerExe
                        Write-Success "Created Windows Installer: $InstallerExe"

                        # Provide App_setup_vX.Y.Z.exe alias if custom AppName
                        if ($AppName -and $AppName -ne "App") {
                            $GenericInstaller = "$DistDir\App_setup_v${VersionName}.exe"
                            Copy-Item -Path $InstallerExe -Destination $GenericInstaller -Force
                            $GeneratedArtifacts += $GenericInstaller
                            Write-Success "Created Windows Installer alias: $GenericInstaller"
                        }
                    } else {
                        # Check if ISCC placed output with default name
                        $AnySetupExe = Get-ChildItem -Path $DistDir -Filter "*setup*.exe" | Select-Object -First 1
                        if ($AnySetupExe) {
                            $GeneratedArtifacts += $AnySetupExe.FullName
                            Write-Success "Created Windows Installer: $($AnySetupExe.FullName)"
                        }
                    }
                } else {
                    Write-Failure "Inno Setup compilation failed with exit code $LASTEXITCODE."
                }
            } else {
                Write-Info "Inno Setup compiler (ISCC.exe) not found on this system."
                Write-Info "Windows release files are safely staged in: $WinStagingDir"
                Write-Info "To build the installer, install Inno Setup (winget install JRSoftware.InnoSetup)"
                Write-Info "and run: iscc `"$ResolvedIssScript`""
            }
        } else {
            Write-Failure "Windows release directory not found in build\windows\"
            exit 1
        }
    } else {
        if ($Platform -eq 'Windows') {
            Write-Failure "Platform 'Windows' was explicitly requested, but this project has no windows/ directory."
            exit 1
        } else {
            Write-Info "Skipping Windows build (windows/ directory not present in project; Android/mobile project)."
        }
    }
}

# Deduplicate artifact array
$GeneratedArtifacts = $GeneratedArtifacts | Select-Object -Unique

# -----------------------------------------------------------------------------
# 6. Checksum Generation & Summary Table
# -----------------------------------------------------------------------------
Write-Step "4/5" "Generating SHA256 checksums..."

$ChecksumFile = "$DistDir\SHA256SUMS.txt"
$ChecksumLines = @()
$SummaryTable = @()

foreach ($Artifact in $GeneratedArtifacts) {
    if (Test-Path $Artifact) {
        $Item = Get-Item $Artifact
        $HashInfo = Get-FileHash -Path $Artifact -Algorithm SHA256
        $SizeMB = [Math]::Round($Item.Length / 1MB, 2)
        $SizeStr = "$SizeMB MB"
        if ($SizeMB -lt 1.0) {
            $SizeKB = [Math]::Round($Item.Length / 1KB, 1)
            $SizeStr = "$SizeKB KB"
        }

        $ChecksumLines += "$($HashInfo.Hash)  $($Item.Name)"
        $SummaryTable += [PSCustomObject]@{
            "File Name" = $Item.Name
            "Size"      = $SizeStr
            "SHA256"    = $HashInfo.Hash
        }
    }
}

if ($ChecksumLines.Count -gt 0) {
    $ChecksumLines | Set-Content -Path $ChecksumFile -Encoding utf8
    Write-Success "Saved checksums to: $ChecksumFile"
}

Write-Host ""
Write-Host "Generated Release Artifacts (dist/v$VersionName/):" -ForegroundColor Green
if ($SummaryTable.Count -gt 0) {
    $SummaryTable | Format-Table -AutoSize | Out-String | Write-Host -ForegroundColor White
} else {
    Write-Info "No standalone binary files generated (files may be staged in $DistDir\windows_x64)."
}

if (Test-Path "$DistDir\windows_x64") {
    Write-Info "Windows staging directory ready at: $DistDir\windows_x64"
}

# -----------------------------------------------------------------------------
# 7. Publishing & Deployment (GitHub / Play Store)
# -----------------------------------------------------------------------------
Write-Step "5/5" "Post-build publishing checks..."

# GitHub Publishing
if ($PublishGitHub) {
    Write-Host ">>> Publishing to GitHub Releases..." -ForegroundColor Cyan

    $GhCmd = Get-Command "gh" -ErrorAction SilentlyContinue
    if (-not $GhCmd) {
        $GhCandidate = "C:\Program Files\GitHub CLI\gh.exe"
        if (Test-Path $GhCandidate) {
            $GhCmd = $GhCandidate
        }
    }

    if ($GhCmd) {
        # Check authentication
        $AuthCheck = & $GhCmd auth status 2>&1
        if ($LASTEXITCODE -eq 0) {
            $TagName = "v$VersionName"
            $ReleaseTitle = "Release v$VersionName"
            $AllDistFiles = Get-ChildItem -Path $DistDir -File | Select-Object -ExpandProperty FullName

            $GhArgs = @("release", "create", $TagName)
            $GhArgs += $AllDistFiles
            $GhArgs += @("--title", $ReleaseTitle, "--generate-notes")
            if ($Draft) { $GhArgs += "--draft" }
            if ($Prerelease) { $GhArgs += "--prerelease" }

            Write-Info "Running: gh $($GhArgs -join ' ')"
            & $GhCmd @GhArgs

            if ($LASTEXITCODE -eq 0) {
                Write-Success "GitHub release '$TagName' created successfully!"
            } else {
                Write-Failure "GitHub CLI release command failed with exit code $LASTEXITCODE."
            }
        } else {
            Write-Failure "GitHub CLI is installed but not authenticated. Run 'gh auth login' to connect your GitHub account."
        }
    } else {
        Write-Failure "GitHub CLI ('gh') is not installed or not in PATH."
        Write-Info "Install it using: winget install --id GitHub.cli"
        Write-Info "Or manually upload artifacts from $DistDir to your GitHub repository releases page."
    }
} else {
    Write-Info "GitHub release publishing skipped (use -PublishGitHub switch to publish automatically)."
}

# Play Store Instructions
if ($PublishPlayStore) {
    Write-Host ""
    Write-Host "=======================================================================" -ForegroundColor Magenta
    Write-Host "  Google Play Store Upload Guide" -ForegroundColor Magenta
    Write-Host "=======================================================================" -ForegroundColor Magenta
    Write-Host "1. Locate your signed release bundle:"
    Write-Host "   $DistDir\App_v${VersionName}_PlayStore.aab" -ForegroundColor Yellow
    Write-Host "2. Open Google Play Console: https://play.google.com/console"
    Write-Host "3. Navigate to: Your App -> Release -> Production (or Internal / Closed testing)"
    Write-Host "4. Click 'Create new release' and drag & drop the .aab file."
    Write-Host "5. Enter release notes, review, and roll out to users!"
    Write-Host "=======================================================================" -ForegroundColor Magenta
}

Write-Header "Build Complete for v$VersionName ($VersionCode)! Output located in $DistDir"
