extends SceneTree
## Prints the Live mode's sun over Warsaw for a few Warsaw clock times (time_of_day.gd),
## to compare with a published table (e.g. 2026-10-28: sunrise ~06:30, noon elevation
## ~25 degrees at ~11:44, sunset ~16:20 CET).
##   godot --headless --path game --script res://tools/check_sun.gd

const TimeOfDay := preload("res://scripts/time_of_day.gd")


func _initialize() -> void:
	for date in [20261028, 20260621, 20261221]:
		for clock in ["06:30", "08:00", "11:44", "13:00", "16:20", "17:30", "22:00"]:
			var t := TimeOfDay.warsaw_to_utc(clock, date)
			var sp := TimeOfDay.sun_position(t)
			print("%d %s Warsaw (UTC+%d): elevation %6.2f, azimuth %6.2f" % [date, clock, TimeOfDay.warsaw_offset(t) / 3600, sp.x, sp.y])
	quit()
