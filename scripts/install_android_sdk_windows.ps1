<#
Semi-automated installer for Android SDK Command-line Tools on Windows

What it does:
- Verifies Java (JDK) is available (sdkmanager requires Java)
- Downloads Android command-line tools (if not present)
- Extracts them to `C:\Android\sdk` (default path; configurable)
- Adds `ANDROID_SDK_ROOT` and updates User PATH with platform-tools, emulator and cmdline-tools
- Runs `sdkmanager` to install common packages: platform-tools, build-tools, platforms, emulator, system-image
- Attempts to accept licenses automatically

Notes / preconditions:
- Requires internet connection
- Requires a JDK (OpenJDK or Oracle JDK) accessible in PATH as `java` and `javac`.
  If not installed, install manually (AdoptOpenJDK / Temurin recommended) or via choco: `choco install temurinjdk` (requires Chocolatey).
- Installing system images and emulator may require additional disk space.
- This script makes user-level PATH changes (no admin required). You may need to restart your shell after running.

Usage (PowerShell Admin recommended):
  Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
  .\install_android_sdk_windows.ps1

#>

param(
  [string]$SdkRoot = "C:\Android\sdk",
  [string]$CmdlineToolsUrl = "https://dl.google.com/android/repository/commandlinetools-win-latest.zip",
  [string[]]$Packages = @(
    'platform-tools',
    'platforms;android-33',
    'build-tools;33.0.0',
    'emulator',
    'system-images;android-33;google_apis;x86_64'
  )
)

function Write-Log([string]$msg) { Write-Host "[android-sdk] $msg" }

try {
  Write-Log "Starting Android SDK command-line tools installation"

  # Check Java
  $java = Get-Command java -ErrorAction SilentlyContinue
  $javac = Get-Command javac -ErrorAction SilentlyContinue
  if (-not $java -or -not $javac) {
    Write-Host "";
    Write-Host "WARNING: Java (JDK) not found in PATH. sdkmanager requires Java."
    Write-Host "Please install a JDK (Temurin/AdoptOpenJDK) before proceeding."
    Write-Host "Example: choco install temurinjdk -y (requires Chocolatey) or install from https://adoptium.net/"
    Write-Host ""
    $proceed = Read-Host "Continue anyway? (y/N)"
    if ($proceed -ne 'y' -and $proceed -ne 'Y') { Write-Log "Aborting due to missing Java"; exit 1 }
  } else {
    Write-Log "Java found: $($java.Source)"
  }

  # Prepare directories
  if (-not (Test-Path $SdkRoot)) { New-Item -ItemType Directory -Path $SdkRoot -Force | Out-Null }
  $cmdlineDest = Join-Path $SdkRoot 'cmdline-tools\latest'

  # Download command-line tools if not present
  $sdkmanagerPath = Join-Path $cmdlineDest 'bin\sdkmanager.bat'
  if (-not (Test-Path $sdkmanagerPath)) {
    Write-Log "Downloading command-line tools from $CmdlineToolsUrl"
    $tmpZip = Join-Path $env:TEMP "cmdline-tools.zip"
    try {
      Invoke-WebRequest -Uri $CmdlineToolsUrl -OutFile $tmpZip -UseBasicParsing -ErrorAction Stop
      Write-Log "Download complete. Extracting..."
    } catch {
      Write-Log "Automatic download failed: $($_.Exception.Message)"
      Write-Host ""
      Write-Host "Please manually download the Android command-line tools ZIP from:"
      Write-Host "  https://developer.android.com/studio#command-tools"
      Write-Host "Then place the downloaded zip file at a local path (for example: C:\temp\cmdline-tools.zip)"
      Write-Host "Or provide an alternate direct download URL now."
      $userInput = Read-Host "Enter local zip path or alternate URL (leave empty to abort)"
      if ([string]::IsNullOrWhiteSpace($userInput)) {
        throw "Command-line tools download failed and no alternative provided. Aborting."
      }

      if (Test-Path $userInput) {
        Copy-Item -Path $userInput -Destination $tmpZip -Force
      } else {
        try {
          Invoke-WebRequest -Uri $userInput -OutFile $tmpZip -UseBasicParsing -ErrorAction Stop
        } catch {
          throw "Fallback download also failed: $($_.Exception.Message)"
        }
      }
      Write-Log "Download (fallback) complete. Extracting..."
    }

    # Extract archive
    $tmpExtract = Join-Path $env:TEMP "cmdline-tools-extract"
    if (Test-Path $tmpExtract) { Remove-Item -Recurse -Force $tmpExtract -ErrorAction SilentlyContinue }
    New-Item -ItemType Directory -Path $tmpExtract | Out-Null
    Expand-Archive -Path $tmpZip -DestinationPath $tmpExtract -Force
    Remove-Item $tmpZip -Force -ErrorAction SilentlyContinue

    # The zip usually extracts a folder; move the first directory under tmpExtract to cmdline-tools/latest
    $extractedRoot = Get-ChildItem -Path $tmpExtract | Where-Object { $_.PSIsContainer } | Select-Object -First 1
    if ($null -eq $extractedRoot) { throw "Extraction failed or unexpected archive structure" }

    $sourcePath = $extractedRoot.FullName
    if (Test-Path $cmdlineDest) { Remove-Item -Recurse -Force $cmdlineDest -ErrorAction SilentlyContinue }
    New-Item -ItemType Directory -Path (Split-Path $cmdlineDest -Parent) -Force | Out-Null
    Move-Item -Path $sourcePath -Destination $cmdlineDest -Force
    Remove-Item $tmpExtract -Recurse -Force -ErrorAction SilentlyContinue

    Write-Log "Command-line tools installed to $cmdlineDest"
  } else {
    Write-Log "sdkmanager already present at $sdkmanagerPath"
  }

  # Set ANDROID_SDK_ROOT and update PATH (user scope)
  [Environment]::SetEnvironmentVariable('ANDROID_SDK_ROOT', $SdkRoot, 'User')
  $userPath = [Environment]::GetEnvironmentVariable('Path','User')
  $addPaths = @(
    (Join-Path $SdkRoot 'platform-tools'),
    (Join-Path $SdkRoot 'emulator'),
    (Join-Path $cmdlineDest 'bin')
  )
  foreach ($p in $addPaths) {
    if ($userPath -notlike "*${p}*") {
      if ([string]::IsNullOrEmpty($userPath)) { $userPath = $p } else { $userPath = "$userPath;$p" }
    }
  }
  [Environment]::SetEnvironmentVariable('Path',$userPath,'User')

  # Update current session PATH
  $env:Path = "$env:Path;$(Join-Path $SdkRoot 'platform-tools');$(Join-Path $SdkRoot 'emulator');$(Join-Path $cmdlineDest 'bin')"

  # Ensure sdkmanager path for execution
  $sdkmanagerExe = Join-Path $cmdlineDest 'bin\sdkmanager.bat'
  if (-not (Test-Path $sdkmanagerExe)) {
    throw "sdkmanager not found at $sdkmanagerExe"
  }

  Write-Log "Installing Android SDK packages: $($Packages -join ', ')"
  # Build sdkmanager command
  $quotedPackages = $Packages | ForEach-Object { '"' + $_ + '"' }
  $cmd = "`"$sdkmanagerExe`" $($quotedPackages -join ' ')"
  Write-Log "Running: $cmd"
  & cmd /c $cmd

  # Accept licenses
  Write-Log "Accepting SDK licenses"
  $acceptCmd = "cmd /c echo y ^| `"$sdkmanagerExe`" --licenses"
  Invoke-Expression $acceptCmd

  Write-Log "Installation complete. Recommended next steps:"
  Write-Log " - Open Android Studio, SDK Manager -> ensure platforms & tools installed"
  Write-Log " - Create an AVD via AVD Manager (Android Studio)"
  Write-Log " - Restart your terminal or sign out/in so PATH & ANDROID_SDK_ROOT are applied"

} catch {
  Write-Error "ERROR: $_"
  exit 1
}
