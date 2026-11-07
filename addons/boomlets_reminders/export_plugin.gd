@tool
extends EditorPlugin
## Puts the play reminders plugin (built from android/reminders_plugin by
## tools/build_reminders_plugin.ps1) into Android exports. The game reaches
## it as the "BoomletsReminders" singleton (core/Reminders.gd).

var _export: AndroidExport


func _enter_tree() -> void:
	_export = AndroidExport.new()
	add_export_plugin(_export)


func _exit_tree() -> void:
	remove_export_plugin(_export)
	_export = null


class AndroidExport extends EditorExportPlugin:
	const AAR: String = "boomlets_reminders/bin/boomlets_reminders.aar"

	func _get_name() -> String:
		return "BoomletsReminders"

	func _supports_platform(platform: EditorExportPlatform) -> bool:
		return platform is EditorExportPlatformAndroid

	func _get_android_libraries(_platform: EditorExportPlatform, _debug: bool) -> PackedStringArray:
		if not FileAccess.file_exists("res://addons/" + AAR):
			push_error("[Reminders] Missing res://addons/%s - run tools/build_reminders_plugin.ps1" % AAR)
			return PackedStringArray()
		return PackedStringArray([AAR])
