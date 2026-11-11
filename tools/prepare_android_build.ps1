# Sets up android/build (Godot's Gradle build template) for Firebase and AdMob.
# The template is about 200 MB, so it is not in git: this script unpacks it from
# the installed Godot export templates when it is missing, then patches
# build.gradle for the google-services and Crashlytics plugins. Safe to run again.

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
# Crashlytics: its Gradle plugin stamps each build with the ID the SDK needs at
# start-up, and the NDK library also catches native (engine and driver) crashes.
if ($text -notmatch 'firebase-crashlytics-gradle') {
    $text = $text -replace "(classpath 'com\.google\.gms:google-services:[^']+')", "`$1`n        classpath 'com.google.firebase:firebase-crashlytics-gradle:3.0.6'"
    $changed = $true
}
if ($text -notmatch "apply plugin: 'com\.google\.firebase\.crashlytics'") {
    $text = $text.TrimEnd() + "`n`napply plugin: 'com.google.firebase.crashlytics'`n"
    $changed = $true
}
if ($text -notmatch 'firebase-crashlytics-ndk') {
    $text = $text.TrimEnd() + "`n`ndependencies {`n    implementation 'com.google.firebase:firebase-crashlytics-ndk:20.1.0'`n}`n"
    $changed = $true
}
# Native crash symbols: when Godot's own debug symbols for the release template
# are unpacked on this PC (tools/upload_crash_symbols.ps1 fetches them), let
# the Crashlytics plugin read them, so engine crashes show function names.
if ($text -notmatch 'boomletsSymbols') {
    $text = $text.TrimEnd() + @"


// Boomlets: Godot's native debug symbols for Crashlytics (see tools/upload_crash_symbols.ps1).
def boomletsSymbols = new File(System.getenv('APPDATA') ?: '', 'Godot/export_templates/$godotVersion/native_debug_symbols/unpacked')
if (boomletsSymbols.isDirectory()) {
    android.buildTypes.release.firebaseCrashlytics {
        nativeSymbolUploadEnabled true
        unstrippedNativeLibsDir boomletsSymbols
    }
}

"@
    $changed = $true
}
if ($changed) {
    [IO.File]::WriteAllText($gradle, $text)
    Write-Host 'Patched android/build/build.gradle for Firebase.'
}

# Safe mode and clean exit, patched into the game's Android activity. The block
# sits between two marker lines, so a newer version of it replaces an older one.
#  - Renderer: Qualcomm phones whose Vulkan driver is older than 1.3 start on
#    OpenGL from the first launch (Crashlytics: "Vulkan device was lost" on
#    Adreno 618/619 with driver 1.1.128). Any other phone moves to OpenGL
#    after one start that died while the game was on screen (core/SafeBoot.gd).
#  - Exit: when Android destroys the activity the process ends at once, without
#    the engine's own shutdown (Crashlytics: "pthread_mutex_lock called on a
#    destroyed mutex" in that shutdown). Nothing is lost: the game saves as it
#    goes and Godot on Android cannot reuse the process anyway.
$app = Join-Path $buildDir 'src/main/java/com/godot/game/GodotApp.java'
$java = [IO.File]::ReadAllText($app) -replace "`r`n", "`n"
$block = @'
	// BOOMLETS-BEGIN 2 (tools/prepare_android_build.ps1)
	private static Boolean useOpenGl = null;

	// Qualcomm chip with a Vulkan driver older than 1.3: these drivers lose
	// the device under the game, which the engine cannot survive.
	private boolean boomletsWeakVulkan() {
		String chip = (android.os.Build.HARDWARE + " " + android.os.Build.BOARD).toLowerCase(java.util.Locale.ROOT);
		if (android.os.Build.VERSION.SDK_INT >= 31) {
			chip += " " + android.os.Build.SOC_MANUFACTURER.toLowerCase(java.util.Locale.ROOT);
		}
		boolean qualcomm = chip.contains("qcom") || chip.contains("qualcomm") || chip.contains("qti");
		boolean vulkan13 = getPackageManager().hasSystemFeature(
				android.content.pm.PackageManager.FEATURE_VULKAN_HARDWARE_VERSION, 0x403000);
		return qualcomm && !vulkan13;
	}

	// Decided once per process. See core/SafeBoot.gd for the marker files.
	@Override
	public java.util.List<String> getCommandLine() {
		java.util.List<String> args = new java.util.ArrayList<>(super.getCommandLine());
		if (useOpenGl == null) {
			java.io.File dir = getFilesDir();
			java.io.File gl = new java.io.File(dir, "use_gl");
			if (!gl.exists() && new java.io.File(dir, "boot_pending").exists()) {
				try {
					gl.createNewFile();
				} catch (java.io.IOException e) {
					Log.e("GODOT", "Boomlets: could not save the OpenGL fallback flag");
				}
				useOpenGl = true;
			} else {
				useOpenGl = gl.exists();
			}
			if (!useOpenGl) {
				try {
					useOpenGl = boomletsWeakVulkan();
				} catch (RuntimeException e) {
					Log.e("GODOT", "Boomlets: could not read the Vulkan version", e);
				}
			}
			if (useOpenGl) {
				Log.w("GODOT", "Boomlets: starting on OpenGL (safe mode)");
			}
		}
		if (useOpenGl && !args.contains("--rendering-driver")) {
			args.add("--rendering-driver");
			args.add("opengl3");
			args.add("--rendering-method");
			args.add("gl_compatibility");
		}
		return args;
	}

	// The activity is going away: end the process here, before the engine's
	// own shutdown runs on the render thread.
	@Override
	public void onDestroy() {
		if (!BuildConfig.FLAVOR.equals("instrumented")) {
			Log.i("GODOT", "Boomlets: activity destroyed, ending the process");
			android.os.Process.killProcess(android.os.Process.myPid());
		}
		super.onDestroy();
	}
	// BOOMLETS-END

'@ -replace "`r`n", "`n"
$anchor = "	@Override`n	protected boolean isPiPEnabled() {"
# Take out an older copy of the block (the first version had no marker lines).
if ($java.Contains('BOOMLETS-BEGIN')) {
    $java = [regex]::Replace($java, '(?s)(\t// BOOMLETS-BEGIN[^\n]*\n)+.*?// BOOMLETS-END\n+', '')
} else {
    $java = [regex]::Replace($java, '(?s)\tprivate static Boolean useOpenGl = null;.*?(?=\t@Override\n\tprotected boolean isPiPEnabled\(\) \{)', '')
}
if (-not $java.Contains($anchor)) {
    Write-Host 'GodotApp.java does not look as expected: safe mode was not patched in.' -ForegroundColor Red
    exit 1
}
$java = $java.Replace($anchor, $block + "`n" + $anchor)
if ($java -ne ([IO.File]::ReadAllText($app) -replace "`r`n", "`n")) {
    [IO.File]::WriteAllText($app, $java)
    Write-Host 'Patched GodotApp.java for safe mode and clean exit.'
}
exit 0
