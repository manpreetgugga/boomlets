# Builds the play-reminders Android plugin (android/reminders_plugin, Java)
# into addons/boomlets_reminders/bin/boomlets_reminders.aar, which the game's
# Android export picks up. The .aar is kept in git, so this only needs running
# after the Java code changes.

$project = Split-Path -Parent $PSScriptRoot
$src = Join-Path $project 'android/reminders_plugin'
$out = Join-Path $project 'addons/boomlets_reminders/bin/boomlets_reminders.aar'

# Borrow Gradle from Godot's Android build template.
& (Join-Path $PSScriptRoot 'prepare_android_build.ps1')
if ($LASTEXITCODE) { exit 1 }

$env:JAVA_HOME = 'C:\Users\Manpreet\.jdks\jbr-21.0.11'
$env:ANDROID_HOME = Join-Path $env:LOCALAPPDATA 'Android\Sdk'

& (Join-Path $project 'android/build/gradlew.bat') -p $src assembleRelease --console=plain
if ($LASTEXITCODE) {
    Write-Host 'Plugin build failed - see the messages above.' -ForegroundColor Red
    exit 1
}
Copy-Item (Join-Path $src 'build/outputs/aar/boomlets_reminders-release.aar') $out -Force
Write-Host "Ready: $out" -ForegroundColor Green
