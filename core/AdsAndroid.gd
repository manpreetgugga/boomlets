extends Node
## The Android side of [code]Services[/code]: Google's consent form (UMP), then
## the AdMob SDK, a rewarded ad (an extra life) and an interstitial (between
## levels), each loaded ahead of time. Loaded by Services only on Android,
## so the AdMob classes are never touched on desktop or in test runs.

## The consent check is done. [param ads_ok]: ads may be requested.
## [param stats_ok]: the player agreed to analytics (or no consent is needed
## where they are).
signal consent_done(ads_ok: bool, stats_ok: bool)
signal rewarded_changed

const APP_UNITS := {
	"rewarded": "ca-app-pub-6111568882988372/7230598573",
	"interstitial": "ca-app-pub-6111568882988372/4604435236",
}
## Google's sample units: debug builds always use these, never the real ones.
const TEST_UNITS := {
	"rewarded": "ca-app-pub-3940256099942544/5224354917",
	"interstitial": "ca-app-pub-3940256099942544/1033173712",
}
const RETRY_SECONDS: Array[float] = [10.0, 30.0, 60.0, 120.0]

var ads_ok: bool = false
var _started: bool = false
var _rewarded: RewardedAd = null
var _interstitial: InterstitialAd = null
var _loading: Dictionary = {}
var _fails: Dictionary = {"rewarded": 0, "interstitial": 0}


func start() -> void:
	var params := ConsentRequestParameters.new()
	params.tag_for_under_age_of_consent = false
	UserMessagingPlatform.consent_information.update(params, _on_consent_info, _on_consent_info_failed)


func _on_consent_info() -> void:
	var info := UserMessagingPlatform.consent_information
	if info.get_is_consent_form_available() and info.get_consent_status() == ConsentInformation.ConsentStatus.REQUIRED:
		UserMessagingPlatform.load_consent_form(
			func(form: ConsentForm) -> void:
				form.show(func(_err: FormError) -> void: _finish_consent()),
			func(_err: FormError) -> void: _finish_consent())
	else:
		_finish_consent()


func _on_consent_info_failed(_err: FormError) -> void:
	# Offline or no message set up: go on with what was agreed last time.
	_finish_consent()


func _finish_consent() -> void:
	var status: int = UserMessagingPlatform.consent_information.get_consent_status()
	ads_ok = status != ConsentInformation.ConsentStatus.REQUIRED
	var stats_ok: bool = status == ConsentInformation.ConsentStatus.NOT_REQUIRED or _tcf_allows_analytics()
	consent_done.emit(ads_ok, stats_ok)
	if ads_ok and not _started:
		_started = true
		var config := RequestConfiguration.new()
		config.max_ad_content_rating = RequestConfiguration.MAX_AD_CONTENT_RATING_PG
		MobileAds.set_request_configuration(config)
		MobileAds.initialize()
		_load("rewarded")
		_load("interstitial")


## In regions that need consent, the form saves the player's choices as an
## IAB TCF string in the app's default preferences. Purpose 1 (store info on
## the device) and purpose 8 (measure content) both cover analytics.
func _tcf_allows_analytics() -> bool:
	if not Engine.has_singleton("AndroidRuntime"):
		return false
	var ctx: Variant = Engine.get_singleton("AndroidRuntime").getApplicationContext()
	if ctx == null:
		return false
	var pm: Variant = JavaClassWrapper.wrap("android.preference.PreferenceManager")
	if pm == null:
		return false
	var prefs: Variant = pm.getDefaultSharedPreferences(ctx)
	if prefs == null:
		return false
	var purposes: Variant = prefs.getString("IABTCF_PurposeConsents", "")
	if typeof(purposes) != TYPE_STRING:
		return false
	var p: String = purposes
	return p.length() >= 8 and p[0] == "1" and p[7] == "1"


## Whether the privacy-options button is needed (only where consent applies).
func privacy_options_required() -> bool:
	return UserMessagingPlatform.consent_information.get_privacy_options_requirement_status() \
		== ConsentInformation.PrivacyOptionsRequirementStatus.REQUIRED


func show_privacy_options() -> void:
	UserMessagingPlatform.show_privacy_options_form(func(_err: FormError) -> void: _finish_consent())


func _unit(kind: String) -> String:
	return TEST_UNITS[kind] if OS.is_debug_build() else APP_UNITS[kind]


func _load(kind: String) -> void:
	if not ads_ok or _loading.get(kind, false):
		return
	_loading[kind] = true
	if kind == "rewarded":
		var cb := RewardedAdLoadCallback.new()
		cb.on_ad_loaded = func(ad: RewardedAd) -> void:
			_loading[kind] = false
			_fails[kind] = 0
			_rewarded = ad
			rewarded_changed.emit()
		cb.on_ad_failed_to_load = func(_err: LoadAdError) -> void: _load_failed(kind)
		RewardedAdLoader.new().load(_unit(kind), AdRequest.new(), cb)
	else:
		var cb := InterstitialAdLoadCallback.new()
		cb.on_ad_loaded = func(ad: InterstitialAd) -> void:
			_loading[kind] = false
			_fails[kind] = 0
			_interstitial = ad
		cb.on_ad_failed_to_load = func(_err: LoadAdError) -> void: _load_failed(kind)
		InterstitialAdLoader.new().load(_unit(kind), AdRequest.new(), cb)


func _load_failed(kind: String) -> void:
	_loading[kind] = false
	var n: int = _fails[kind]
	_fails[kind] = n + 1
	var wait: float = RETRY_SECONDS[mini(n, RETRY_SECONDS.size() - 1)]
	get_tree().create_timer(wait, true, false, true).timeout.connect(_load.bind(kind))


func has_rewarded() -> bool:
	return _rewarded != null


func has_interstitial() -> bool:
	return _interstitial != null


## Shows the rewarded ad. [param done] gets true when the reward was earned.
func show_rewarded(done: Callable) -> void:
	var ad: RewardedAd = _rewarded
	if ad == null:
		done.call(false)
		return
	_rewarded = null
	rewarded_changed.emit()
	var earned: Array[bool] = [false]
	var closed: Array[bool] = [false]
	var finish := func() -> void:
		if closed[0]:
			return
		closed[0] = true
		ad.destroy()
		done.call(earned[0])
		_load("rewarded")
	ad.full_screen_content_callback.on_ad_dismissed_full_screen_content = finish
	ad.full_screen_content_callback.on_ad_failed_to_show_full_screen_content = func(_err: AdError) -> void: finish.call()
	var listener := OnUserEarnedRewardListener.new()
	listener.on_user_earned_reward = func(_item: RewardedItem) -> void: earned[0] = true
	ad.show(listener)


## Shows the interstitial; [param done] runs once it is closed (or failed).
func show_interstitial(done: Callable) -> void:
	var ad: InterstitialAd = _interstitial
	if ad == null:
		done.call()
		return
	_interstitial = null
	var closed: Array[bool] = [false]
	var finish := func() -> void:
		if closed[0]:
			return
		closed[0] = true
		ad.destroy()
		done.call()
		_load("interstitial")
	ad.full_screen_content_callback.on_ad_dismissed_full_screen_content = finish
	ad.full_screen_content_callback.on_ad_failed_to_show_full_screen_content = func(_err: AdError) -> void: finish.call()
	ad.show()
