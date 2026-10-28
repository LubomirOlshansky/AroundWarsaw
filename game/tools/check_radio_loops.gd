extends SceneTree
## Checks that the radio loops are imported as seamless Forward loops: loop points
## at 0 and the full length, and no jump in the decoded audio across the loop point
## (compares the step at the seam with the typical step elsewhere).
##   godot --headless --path game --script res://tools/check_radio_loops.gd

func _initialize() -> void:
	var ok := true
	for path in ["res://audio/radio/palma_de_gaulle.wav", "res://audio/radio/rondo_3am.wav", "res://audio/radio/mordor_mall.wav"]:
		var s: AudioStreamWAV = load(path)
		var frames := int(round(s.get_length() * s.mix_rate))
		var line := "%s: format %d, %d Hz, stereo %s, loop mode %d, begin %d, end %d (%d frames, %.2f s)" % [
				path.get_file(), s.format, s.mix_rate, s.stereo, s.loop_mode, s.loop_begin, s.loop_end, frames, s.get_length()]
		if s.loop_mode != AudioStreamWAV.LOOP_FORWARD or s.loop_begin != 0 or s.loop_end != frames:
			ok = false
			line += "  <-- NOT a full forward loop"
		var pb: AudioStreamPlayback = s.instantiate_playback()
		if pb.has_method("mix_audio"):
			# Decode the last second, the seam and the first second after it.
			pb.start(maxf(s.get_length() - 1.0, 0.0))
			var buf: PackedVector2Array = pb.call("mix_audio", 1.0, int(s.mix_rate * 2.0))
			var steps := PackedFloat32Array()
			var seam_i := -1
			var worst := 0.0
			var worst_i := 0
			for i in range(1, buf.size()):
				var d := (buf[i] - buf[i - 1]).length()
				steps.append(d)
				if d > worst:
					worst = d
					worst_i = i
			var sorted := steps.duplicate()
			sorted.sort()
			var p99 := sorted[int(sorted.size() * 0.999)]
			# The seam sits about mix_rate samples in.
			var near := 0.0
			for i in range(int(s.mix_rate) - 64, int(s.mix_rate) + 64):
				if i > 0 and i < buf.size():
					near = maxf(near, (buf[i] - buf[i - 1]).length())
			var silent := 0
			var run := 0
			for v in buf:
				run = run + 1 if v.length() < 0.0005 else 0
				silent = maxi(silent, run)
			line += "\n    seam window max step %.4f, 99.9th pct step %.4f, worst %.4f at %d, longest near-silent run %d samples, loops %d" % [
					near, p99, worst, worst_i, silent, pb.get_loop_count()]
			if near > p99 * 1.5 + 0.01 or silent > 64:
				ok = false
				line += "  <-- seam jump or gap"
		else:
			line += "\n    (no mix_audio in this build; decode check skipped)"
		print(line)
	print("radio loops: ", "OK" if ok else "PROBLEM")
	quit(0 if ok else 1)
