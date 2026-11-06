# Builds the signed release APK (export/Boomlets.apk).
# Asks for the keystore password and passes it to Godot only for this run.

$godot = 'C:\Users\Manpreet\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe'
$project = Split-Path -Parent $PSScriptRoot
$apk = Join-Path $project 'export/Boomlets.apk'

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

# Remove the previous APK so an old file is never mistaken for a new build.
New-Item -ItemType Directory -Force (Join-Path $project 'export') | Out-Null
Remove-Item $apk, "$apk.idsig" -ErrorAction SilentlyContinue

$bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
try {
    $env:GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
    & $godot --headless --path $project --export-release 'Android Release' 'export/Boomlets.apk'
}
finally {
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    Remove-Item Env:GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD -ErrorAction SilentlyContinue
}

if (Test-Path $apk) {
    Write-Host ''
    Write-Host 'Release APK ready: export/Boomlets.apk' -ForegroundColor Green
} else {
    Write-Host ''
    Write-Host 'Export failed - see the messages above. No APK was made.' -ForegroundColor Red
}
