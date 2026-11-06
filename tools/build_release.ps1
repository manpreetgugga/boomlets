# Builds the signed release APK (export/Boomlets.apk).
# Asks for the keystore password and passes it to Godot only for this run.

$godot = 'C:\Users\Manpreet\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe'
$project = Split-Path -Parent $PSScriptRoot

$secure = Read-Host -AsSecureString 'Keystore password'
$bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
try {
    $env:GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
    New-Item -ItemType Directory -Force (Join-Path $project 'export') | Out-Null
    & $godot --headless --path $project --export-release 'Android Release' 'export/Boomlets.apk'
}
finally {
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    Remove-Item Env:GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD -ErrorAction SilentlyContinue
}

if (Test-Path (Join-Path $project 'export/Boomlets.apk')) {
    Write-Host ''
    Write-Host 'Release APK ready: export/Boomlets.apk' -ForegroundColor Green
} else {
    Write-Host 'Export failed - see the messages above.' -ForegroundColor Red
}
