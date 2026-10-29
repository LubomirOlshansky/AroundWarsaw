@tool
extends EditorPlugin
## The Android export's one change to Godot's manifest (the Vulkan follow-up to the first
## Android build, 2026-10-29): Godot writes `android.hardware.vulkan.level` and
## `android.hardware.vulkan.version` as `android:required="false"`, so Google Play would offer
## the game to OpenGL-only phones, where the Mobile renderer can't start (`fallback_to_opengl3`
## is off on purpose). This makes both required. Editor-only: it runs during an export, never in
## the game (and the presets exclude it from the exported files).

var _export: AndroidVulkanRequired


func _enter_tree() -> void:
	_export = AndroidVulkanRequired.new()
	add_export_plugin(_export)


func _exit_tree() -> void:
	remove_export_plugin(_export)
	_export = null


## Writes a variant manifest, `android/build/src/standard<Debug|Release>/AndroidManifest.xml`,
## into the Gradle project at the start of every Android export. Gradle's manifest merger ranks a
## build variant's manifest above the build type's (`src/release/`, the one Godot writes), so
## its `tools:node="replace"` elements win. Why not the other ways: Godot rewrites `src/release/`
## after `_export_begin` (an edit there is lost), and a second `uses-feature` with the same name
## from `_get_android_manifest_element_contents()` would be a duplicate element in Godot's own
## manifest. The file lives in the gitignored build template, but this plugin is tracked and
## rewrites it every export, so a fresh `--install-android-build-template` keeps the rule.
## `tools/export_android.sh` checks the merged manifest: both required, and VERSION equal to
## the Vulkan version Godot asks for (Godot 4.7: level 1, 0x401000 = Vulkan 1.1.0).
class AndroidVulkanRequired extends EditorExportPlugin:
	const LEVEL := "1"
	const VERSION := "0x401000"

	func _get_name() -> String:
		return "NocnaWarszawaAndroidVulkanRequired"

	func _supports_platform(platform: EditorExportPlatform) -> bool:
		return platform is EditorExportPlatformAndroid

	func _export_begin(features: PackedStringArray, is_debug: bool, _path: String, _flags: int) -> void:
		if not features.has("android"):
			return
		if not bool(get_option("gradle_build/use_gradle_build")):
			push_error("android vulkan: the Gradle build is off, so the Vulkan features stay optional")
			return
		var dir := str(get_option("gradle_build/gradle_build_directory"))
		if dir.is_empty():
			dir = "res://android/build"
		var variant := "standardDebug" if is_debug else "standardRelease"
		var folder := "%s/src/%s" % [dir, variant]
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
		var f := FileAccess.open(folder + "/AndroidManifest.xml", FileAccess.WRITE)
		if f == null:
			push_error("android vulkan: can't write %s/AndroidManifest.xml (the Vulkan features stay optional)" % folder)
			return
		f.store_string("\n".join([
			'<?xml version="1.0" encoding="utf-8"?>',
			"<!-- Written by addons/nw_android_export on every Android export; don't edit. -->",
			'<manifest xmlns:android="http://schemas.android.com/apk/res/android"',
			'    xmlns:tools="http://schemas.android.com/tools">',
			'    <uses-feature tools:node="replace" android:name="android.hardware.vulkan.level" android:required="true" android:version="%s" />' % LEVEL,
			'    <uses-feature tools:node="replace" android:name="android.hardware.vulkan.version" android:required="true" android:version="%s" />' % VERSION,
			"</manifest>",
			"",
		]))
		f.close()
		print("android vulkan: level %s and version %s required (src/%s/AndroidManifest.xml)" % [LEVEL, VERSION, variant])
