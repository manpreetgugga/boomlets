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
	core.connect("core_initialized", func(ok: bool) -> void:
		if ok:
			_analytics.initialize())
	core.initialize()


func _on_consent_done(_ads_ok: bool, stats_ok: bool) -> void:
	_consent_stats = stats_ok
	_apply_stats()


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


func level_started(world: int, level: int) -> void:
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
