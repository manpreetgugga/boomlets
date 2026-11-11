# Sends Godot's native debug symbols for the Android release template to
# Firebase Crashlytics, so engine crashes (libgodot_android.so) show function
# names instead of "Missing BuildId".
#
# Needed once per Godot version, not per game release: every Boomlets build
# made with the same Godot version carries the same engine library. Run it on
# Wi-Fi: the download is about 780 MB (it resumes if the connection drops).
#
#   powershell -ExecutionPolicy Bypass -File tools\upload_crash_symbols.ps1

$godotVersion = '4.7.1.stable'
$tag = '4.7.1-stable'
$project = Split-Path -Parent $PSScriptRoot
$dir = Join-Path $env:APPDATA "Godot/export_templates/$godotVersion/native_debug_symbols"
$name = "Godot_native_debug_symbols.$godotVersion.template_release.android.zip"
$zip = Join-Path $dir $name
$unpacked = Join-Path $dir 'unpacked'

New-Item -ItemType Directory -Force $dir | Out-Null
if (-not (Test-Path $unpacked)) {
    Write-Host "Downloading $name (about 780 MB)..."
    & curl.exe -L -C - --retry 20 --retry-delay 5 --retry-all-errors -o $zip "https://github.com/godotengine/godot-builds/releases/download/$tag/$name"
    if ($LASTEXITCODE) {
        Write-Host 'Download did not finish. Run the script again to carry on from where it stopped.' -ForegroundColor Red
        exit 1
    }
    Write-Host 'Unpacking...'
    $tmp = "$unpacked.tmp"
    Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
    Expand-Archive -Path $zip -DestinationPath $tmp -Force
    Move-Item $tmp $unpacked
    Remove-Item $zip
}

# The build template reads the symbols folder when it is configured.
& (Join-Path $PSScriptRoot 'prepare_android_build.ps1')
if ($LASTEXITCODE) { exit 1 }

# Godot's own Java and Android SDK settings.
$settings = Get-ChildItem (Join-Path $env:APPDATA 'Godot') -Filter 'editor_settings-*.tres' | Sort-Object LastWriteTime | Select-Object -Last 1
$text = Get-Content $settings.FullName -Raw
if ($text -match 'export/android/java_sdk_path = "([^"]+)"') { $env:JAVA_HOME = $Matches[1] }
if ($text -match 'export/android/android_sdk_path = "([^"]+)"') { $env:ANDROID_HOME = $Matches[1] -replace '\\\\', '\' }

$presets = Get-Content (Join-Path $project 'export_presets.cfg') -Raw
$code = if ($presets -match 'version/code=(\d+)') { $Matches[1] } else { '1' }
$ver = if ($presets -match 'version/name="([^"]+)"') { $Matches[1] } else { '1.0' }

Push-Location (Join-Path $project 'android/build')
try {
    & .\gradlew.bat uploadCrashlyticsSymbolFileStandardRelease `
        "-Pexport_package_name=com.manpreetgugga.boomlets" `
        "-Pexport_version_code=$code" "-Pexport_version_name=$ver" `
        "-Pexport_enabled_abis=arm64-v8a" "-Pexport_edition=standard" "-Pexport_build_type=release"
    $ok = ($LASTEXITCODE -eq 0)
}
finally { Pop-Location }

if ($ok) {
    Write-Host 'Symbols sent to Crashlytics. New crash reports will show function names.' -ForegroundColor Green
} else {
    Write-Host 'Upload failed - see the messages above.' -ForegroundColor Red
    exit 1
}
