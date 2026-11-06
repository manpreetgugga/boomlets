# Builds the signed release APK (export/Boomlets.apk, for GitHub Releases)
# and app bundle (export/Boomlets.aab, for Google Play).
# Asks for the keystore password once and passes it to Godot only for this run.
# Pass -ApkOnly or -AabOnly to build just one of them.

$godot = 'C:\Users\Manpreet\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe'
$project = Split-Path -Parent $PSScriptRoot
$builds = @(
    @{ Preset = 'Android Release'; File = 'export/Boomlets.apk' },
    @{ Preset = 'Android Play'; File = 'export/Boomlets.aab' }
)
if ($args -contains '-ApkOnly') { $builds = @($builds[0]) }
if ($args -contains '-AabOnly') { $builds = @($builds[1]) }

# Firebase and AdMob need Godot's Gradle build template in android/build.
& (Join-Path $PSScriptRoot 'prepare_android_build.ps1')
if ($LASTEXITCODE) { exit 1 }

# A Windows pop-up asks for the password (typing and pasting both work there,
# unlike some embedded terminals). Pass -Console to be asked in the terminal.
if ($args -contains '-Console') {
    $secure = Read-Host -AsSecureString 'Keystore password'
} else {
    $cred = Get-Credential -UserName 'boomlets' -Message 'Boomlets release keystore password'
    $secure = if ($cred) { $cred.Password } else { New-Object System.Security.SecureString }
}
if ($secure.Length -eq 0) {
    Write-Host 'No password typed - nothing was built. Run the script again.' -ForegroundColor Red
    exit 1
}

# Remove previous builds so an old file is never mistaken for a new one.
New-Item -ItemType Directory -Force (Join-Path $project 'export') | Out-Null
foreach ($b in $builds) {
    $out = Join-Path $project $b.File
    Remove-Item $out, "$out.idsig" -ErrorAction SilentlyContinue
}

$bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
try {
    $env:GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
    foreach ($b in $builds) {
        Write-Host ''
        Write-Host "Building $($b.File)..." -ForegroundColor Cyan
        & $godot --headless --path $project --export-release $b.Preset $b.File
    }
}
finally {
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    Remove-Item Env:GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD -ErrorAction SilentlyContinue
}

Write-Host ''
foreach ($b in $builds) {
    if (Test-Path (Join-Path $project $b.File)) {
        Write-Host "Ready: $($b.File)" -ForegroundColor Green
    } else {
        Write-Host "Failed: $($b.File) - see the messages above." -ForegroundColor Red
    }
}
