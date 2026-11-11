extends Node
## Privacy consent, Firebase Analytics and AdMob ads, behind one small API.
## Everything is live only in the Android build with the plugins present. On
## desktop and in test runs every call is a quiet no-op: there is never a
## rewarded ad to offer, and level breaks go straight on.
##
## Privacy: Firebase starts with collection off and every consent signal
## denied (set in the exported manifest). It is switched on only when the
## player is somewhere no consent is needed, or agreed in Google's consent
## form, and they have not turned "Share play stats" off in Privacy.
## Crash reports (Crashlytics) are on from the first launch, then follow the
## same consent once it is known, and have their own switch in Privacy.

const PRIVACY_URL: String = "https://manpreetgugga.github.io/boomlets/privacy.html"

## An interstitial plays at most after every this many finished levels...
const LEVELS_PER_BREAK: int = 3
## ...at least this many seconds after the last full-screen ad...
const BREAK_GAP_SECONDS: float = 150.0
## ...and only once the player has cleared this many levels in all.
const BREAK_AFTER_CLEARS: int = 4

signal rewarded_changed

## True while a full-screen ad covers the game.
var ad_showing: bool = false
## Test runs only (tools/play_shot.gd "fakead"): pretend a rewarded ad is
## loaded and always watched to the end.
var fake_rewarded: bool = false

var _ads: Node = null
var _analytics: Object = null
var _analytics_ready: bool = false
var _consent_stats: bool = false
var _crash: Object = null
var _crash_ready: bool = false
## False until Google's consent check has answered for this launch.
var _consent_known: bool = false
var _levels_since_break: int = 0
var _last_full_ad_ms: int = -1000000


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if OS.get_name() != "Android":
		return
	_start_firebase()
	if Engine.has_singleton("PoingGodotAdMob"):
		_ads = (load("res://core/AdsAndroid.gd") as GDScript).new()
		add_child(_ads)
		_ads.consent_done.connect(_on_consent_done)
		_ads.rewarded_changed.connect(func() -> void: rewarded_changed.emit())
		_ads.start()


# --- Analytics -------------------------------------------------------------

func _start_firebase() -> void:
	if not Engine.has_singleton("GodotxFirebaseCore") or not Engine.has_singleton("GodotxFirebaseAnalytics"):
		return
	var core: Object = Engine.get_singleton("GodotxFirebaseCore")
	_analytics = Engine.get_singleton("GodotxFirebaseAnalytics")
	_analytics.connect("analytics_initialized", func(ok: bool) -> void:
		_analytics_ready = ok
		_apply_stats())
	if Engine.has_singleton("GodotxFirebaseCrashlytics"):
		_crash = Engine.get_singleton("GodotxFirebaseCrashlytics")
		_crash.connect("crashlytics_initialized", func(ok: bool) -> void:
			_crash_ready = ok
			if ok:
				_tag_crash_reports()
			_apply_crash()
			_maybe_test_crash())
	core.connect("core_initialized", func(ok: bool) -> void:
		if ok:
			_analytics.initialize()
			if _crash != null:
				_crash.initialize())
	core.initialize()


func _on_consent_done(_ads_ok: bool, stats_ok: bool, known: bool) -> void:
	_consent_stats = stats_ok
	_consent_known = known
	_apply_stats()
	_apply_crash()


## Turns Firebase collection on or off to match consent and the player's
## own "Share play stats" switch.
func _apply_stats() -> void:
	if not _analytics_ready:
		return
	var on: bool = _consent_stats and Save.stats_on
	var state: String = "granted" if on else "denied"
	_analytics.set_consent({
		"analytics_storage": state,
		"ad_storage": state,
		"ad_user_data": state,
		"ad_personalization": state,
	})
	_analytics.set_analytics_collection_enabled(on)


func stats_allowed() -> bool:
	return _analytics_ready and _consent_stats and Save.stats_on


## Logs an analytics event. Values may be strings, ints or floats.
func event(name: String, params: Dictionary = {}) -> void:
	if stats_allowed():
		_analytics.log_event(name, params)


func set_stats_on(on: bool) -> void:
	Save.stats_on = on
	Save.write()
	_apply_stats()


# --- Crash reports -----------------------------------------------------------
# Crashlytics is on from the very first launch (nothing in the manifest holds
# it), so a crash at start-up, before any script runs, is still reported.
# Once Google's consent check answers, crash reports follow the same consent
# as play stats; the player's "Crash reports" switch can always turn them off.
# The SDK remembers the last setting, so a "no" also covers the next start-up.

func _apply_crash() -> void:
	if not _crash_ready:
		return
	_crash.set_crashlytics_collection_enabled(crash_reports_allowed())


func crash_reports_allowed() -> bool:
	return Save.crash_reports_on and (not _consent_known or _consent_stats)


func set_crash_reports_on(on: bool) -> void:
	Save.crash_reports_on = on
	Save.write()
	_apply_crash()


## Facts that help sort crashes by device: the GPU and its driver above all.
func _tag_crash_reports() -> void:
	var tags: Dictionary = {
		"gpu": RenderingServer.get_video_adapter_name(),
		"gpu_vendor": RenderingServer.get_video_adapter_vendor(),
		"gpu_api": RenderingServer.get_video_adapter_api_version(),
		"renderer": RenderingServer.get_current_rendering_method(),
		"safe_mode": str(SafeBoot.safe_mode),
		"game_version": str(ProjectSettings.get_setting("application/config/version", "")),
	}
	for k: String in tags:
		_crash.set_custom_value_string(k, str(tags[k]))


## Debug builds only: a native crash on purpose, to check that crash reports
## reach Firebase. Create the file with
## adb shell run-as com.manpreetgugga.boomlets touch files/crash_test
## then start the game; the report is sent on the next start. (The plugin's
## own crash() is no use here: Godot catches exceptions from plugin calls.)
## On an x86_64 emulator, test with an x86_64 build: under ARM translation
## the native crash is caught but its report is never written.
func _maybe_test_crash() -> void:
	const FLAG: String = "user://crash_test"
	if not OS.is_debug_build() or not FileAccess.file_exists(FLAG):
		return
	DirAccess.remove_absolute(FLAG)
	crash_note("test crash requested")
	await get_tree().create_timer(2.0).timeout
	OS.crash("Boomlets test crash (debug build)")


## A short trail of what the player did, attached to the next crash report.
func crash_note(text: String) -> void:
	if _crash_ready:
		_crash.log_message(text)


func level_started(world: int, level: int) -> void:
	crash_note("level_start %d-%d" % [world, level])
	event("level_start", {"level_name": "%d-%d" % [world, level], "world": world, "level": level})


func level_won(world: int, level: int, stars: int, seconds: float, deaths: int) -> void:
	event("level_end", {"level_name": "%d-%d" % [world, level], "success": "true",
		"world": world, "level": level, "stars": stars, "seconds": int(seconds), "deaths": deaths})
	_levels_since_break += 1


func level_lost(world: int, level: int, reason: String, seconds: float) -> void:
	event("level_end", {"level_name": "%d-%d" % [world, level], "success": "false",
		"world": world, "level": level, "reason": reason, "seconds": int(seconds)})
	_levels_since_break += 1


# --- Ads ---------------------------------------------------------------------

func has_rewarded() -> bool:
	return fake_rewarded or (_ads != null and _ads.has_rewarded())


## Plays a rewarded ad; [param done] gets true if the player earned the reward.
func show_rewarded(placement: String, done: Callable) -> void:
	if fake_rewarded:
		done.call(true)
		return
	if not has_rewarded():
		done.call(false)
		return
	_cover(true)
	event("ad_rewarded_offer_taken", {"placement": placement})
	_ads.show_rewarded(func(earned: bool) -> void:
		_cover(false)
		_last_full_ad_ms = Time.get_ticks_msec()
		if earned:
			event("ad_rewarded_earned", {"placement": placement})
		done.call(earned))


## Call between levels with what to do next: plays an interstitial first when
## one is due (never in the first few levels, never often), then runs [param next].
func level_break(next: Callable) -> void:
	if ad_showing:
		return
	var due: bool = _ads != null and _ads.has_interstitial() \
		and _levels_since_break >= LEVELS_PER_BREAK \
		and Time.get_ticks_msec() - _last_full_ad_ms >= int(BREAK_GAP_SECONDS * 1000.0) \
		and Save.stars.size() >= BREAK_AFTER_CLEARS
	if not due:
		next.call()
		return
	_levels_since_break = 0
	_cover(true)
	_ads.show_interstitial(func() -> void:
		_cover(false)
		_last_full_ad_ms = Time.get_ticks_msec()
		next.call())


func _cover(on: bool) -> void:
	ad_showing = on
	AudioServer.set_bus_mute(0, on)


# --- Privacy -----------------------------------------------------------------

## Whether the player can (and must be able to) change their ad consent.
func privacy_options_required() -> bool:
	return _ads != null and _ads.privacy_options_required()


func show_privacy_options() -> void:
	if _ads != null:
		_ads.show_privacy_options()


func open_privacy_policy() -> void:
	OS.shell_open(PRIVACY_URL)
