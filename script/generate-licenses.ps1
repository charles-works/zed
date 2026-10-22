$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true

$CARGO_ABOUT_VERSION="0.8.2"
$outputFile=$args[0] ? $args[0] : "$(Get-Location)/assets/licenses.md"
$templateFile="script/licenses/template.md.hbs"

New-Item -Path "$outputFile" -ItemType File -Value "" -Force

@(
    "# ###### THEME LICENSES ######\n"
    Get-Content assets/themes/LICENSES
    "\n# ###### ICON LICENSES ######\n"
    Get-Content assets/icons/LICENSES
    "\n# ###### CODE LICENSES ######\n"
) | Add-Content -Path $outputFile

$needsInstall = $false
$oldTargetRustflags = $env:CARGO_TARGET_X86_64_PC_WINDOWS_MSVC_RUSTFLAGS
$oldRustflags = $env:RUSTFLAGS

try {
    $env:CARGO_TARGET_X86_64_PC_WINDOWS_MSVC_RUSTFLAGS = ""
    $env:RUSTFLAGS = ""

    try {
        $versionOutput = cargo about --version
        if (-not ($versionOutput -match "cargo-about $CARGO_ABOUT_VERSION")) {
            $needsInstall = $true
        } else {
            Write-Host "cargo-about@$CARGO_ABOUT_VERSION is already installed"
        }
    } catch {
        $needsInstall = $true
    }

    if ($needsInstall) {
        Write-Host "Installing cargo-about@$CARGO_ABOUT_VERSION..."
        cargo install "cargo-about@$CARGO_ABOUT_VERSION"
    }

    Write-Host "Generating cargo licenses"

    $failFlag = $env:ALLOW_MISSING_LICENSES ? "--fail" : ""
    $args = @('about', 'generate', $failFlag, '-c', 'script/licenses/zed-licenses.toml', $templateFile, '-o', $outputFile) | Where-Object { $_ }
    cargo @args
} finally {
    if ($oldTargetRustflags -eq $null) {
        Remove-Item Env:CARGO_TARGET_X86_64_PC_WINDOWS_MSVC_RUSTFLAGS -ErrorAction SilentlyContinue
    } else {
        $env:CARGO_TARGET_X86_64_PC_WINDOWS_MSVC_RUSTFLAGS = $oldTargetRustflags
    }

    if ($oldRustflags -eq $null) {
        Remove-Item Env:RUSTFLAGS -ErrorAction SilentlyContinue
    } else {
        $env:RUSTFLAGS = $oldRustflags
    }
}

Write-Host "Applying replacements"
$replacements = @{
    '&quot;' = '"'
    '&#x27;' = "'"
    '&#x3D;' = '='
    '&#x60;' = '`'
    '&lt;'   = '<'
    '&gt;'   = '>'
}
$content = Get-Content $outputFile
foreach ($find in $replacements.keys) {
    $content = $content -replace $find, $replacements[$find]
}
$content | Set-Content $outputFile

Write-Host "generate-licenses completed. See $outputFile"
