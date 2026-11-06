# Sets up android/build (Godot's Gradle build template) for Firebase and AdMob.
# The template is about 200 MB, so it is not in git: this script unpacks it from
# the installed Godot export templates when it is missing, then patches
# build.gradle for the google-services plugin. Safe to run again.

$project = Split-Path -Parent $PSScriptRoot
$godotVersion = '4.7.1.stable'
$zip = Join-Path $env:APPDATA "Godot/export_templates/$godotVersion/android_source.zip"
$buildDir = Join-Path $project 'android/build'
$gradle = Join-Path $buildDir 'build.gradle'

if (-not (Test-Path $gradle)) {
    if (-not (Test-Path $zip)) {
        Write-Host "Android build template not found at $zip. Install the Godot $godotVersion export templates first." -ForegroundColor Red
        exit 1
    }
    Write-Host 'Unpacking the Android build template...'
    New-Item -ItemType Directory -Force $buildDir | Out-Null
    Expand-Archive -Path $zip -DestinationPath $buildDir -Force
    Set-Content -Path (Join-Path $project 'android/.build_version') -Value $godotVersion -NoNewline
    New-Item -ItemType File -Force (Join-Path $buildDir '.gdignore') | Out-Null
}

$text = [IO.File]::ReadAllText($gradle)
$changed = $false
if ($text -notmatch 'com\.google\.gms:google-services') {
    $head = "buildscript {`n    repositories {`n        google()`n        mavenCentral()`n    }`n    dependencies {`n        classpath 'com.google.gms:google-services:4.4.4'`n    }`n}`n`n"
    $text = $head + $text
    $changed = $true
}
if ($text -notmatch "apply plugin: 'com\.google\.gms\.google-services'") {
    $text = $text.TrimEnd() + "`n`napply plugin: 'com.google.gms.google-services'`n"
    $changed = $true
}
if ($changed) {
    [IO.File]::WriteAllText($gradle, $text)
    Write-Host 'Patched android/build/build.gradle for Firebase.'
}
exit 0
