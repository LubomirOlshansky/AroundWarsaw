extends RefCounted
## Accessibility and comfort options (loop v1.0 "Accessibility", 2026-11-01), the one place the
## game reads them: settings.gd keeps them in the file, main.gd calls `apply` after loading and
## after each change, and the rest of the game only reads the statics here. Settings → ŁATWOŚĆ
## (settings_panel.gd) is where the player changes them.
##   text_scale     1.0, or LARGE_TEXT: the HUD's text (hud.gd `_label`) one step bigger; read
##                  when the HUD is built, so a change shows after the next launch.
##   calm           true: no flashing or shaking: the patrol cars' lights burn steady instead of
##                  alternating, the VHS pulse and the headlight flash stay off, and anything
##                  that shakes the screen asks `shake()`, which is 0 then.
##   color_safe     true: markers that told green from amber or red from blue by hue alone get
##                  a second cue (the drop-off beacon turns blue, the patrol lights white/blue).
##   vibration      false: `buzz` does nothing. THE hook for the phone's haptics: every
##                  Input.vibrate_handheld call goes through it, on to haptics.gd (the floor a
##                  hand feels, the iOS engine kept warm; car.gd's knock calls haptics.gd directly).
##   stop_assist    false: the quest stop assist (stop_assist.gd) leaves the car alone.

const LARGE_TEXT := 1.25

static var text_scale := 1.0
static var calm := false
static var color_safe := false
static var vibration := true
static var stop_assist := true


## Take the values from the saved settings (settings.gd).
static func apply(s: RefCounted) -> void:
	text_scale = LARGE_TEXT if s.text_large else 1.0
	calm = s.calm
	color_safe = s.color_safe
	vibration = s.vibration
	stop_assist = s.stop_assist


## A buzz on the phone (milliseconds, strength 0..1) unless vibration is off; haptics.gd raises
## it to a strength the hand feels and keeps iOS's haptic engine warm (v1.0 juice).
static func buzz(ms: int, strength: float) -> void:
	if vibration:
		load("res://scripts/haptics.gd").buzz(ms, strength)


## 1 for a normal run, 0 with `calm`: multiply any screen shake by it.
static func shake() -> float:
	return 0.0 if calm else 1.0
