extends SceneTree
## The radio's data and playlists (loop radio-playlists; it replaced check_radio_loops.gd, which
## checked the old WAV loops):
##   1. data/radio.json parses; every station has an id, name, frequency and colour; every track
##      has its fields, its file exists, is Ogg Vorbis (the "OggS" header, imported as
##      AudioStreamOggVorbis) and is as long as `seconds` says;
##   2. the radio itself (scripts/radio.gd): tunes through every station and Off, each playlist is
##      a permutation of its tracks and the same on a second radio, a skip walks the playlist in
##      its order and wraps, a station with one track loops and one with several does not, the
##      caption reads "freq NAME · title (artist)";
##   3. a single-track station's loop has no jump or gap across its loop point (decoded);
##   4. a track whose licence is "unknown" is a WARN line (check them before a release, README
##      "Adding music"), not a failure. The total radio size is printed.
## The last line is "radio: OK (counts and size)" or "radio: PROBLEM"; a WARN line comes before it
## (tools/verify.sh turns a "radio: WARN" line into a WARN row).
##   godot --headless --path game --script res://tools/check_radio.gd

const Radio := preload("res://scripts/radio.gd")
const FIELDS := ["file", "title", "artist", "seconds", "gain_db", "licence", "source"]


func _initialize() -> void:
	var problems: Array[String] = []
	var unknown: Array[String] = []
	var total_bytes := 0
	var tracks := 0
	var data: Variant = null
	if FileAccess.file_exists(Radio.PATH):
		data = JSON.parse_string(FileAccess.get_file_as_string(Radio.PATH))
	if not (data is Dictionary) or not (data.get("stations") is Array) or (data["stations"] as Array).is_empty():
		print("radio: PROBLEM")
		print("    %s is missing, unreadable or has no stations" % Radio.PATH)
		quit(1)
		return
	var ids := {}
	for s: Dictionary in data["stations"]:
		var id := String(s.get("id", ""))
		if id == "" or ids.has(id):
			problems.append("station '%s': missing or repeated id" % s.get("name", "?"))
		ids[id] = true
		for key: String in ["name", "freq", "colour"]:
			if String(s.get(key, "")) == "":
				problems.append("station %s: no %s" % [id, key])
		if not Color.html_is_valid(String(s.get("colour", ""))):
			problems.append("station %s: colour '%s' is not a colour" % [id, s.get("colour", "")])
		if not (s.get("tracks") is Array):
			problems.append("station %s: no tracks list" % id)
			continue
		for t: Dictionary in s["tracks"]:
			tracks += 1
			var name := "%s / %s" % [id, t.get("title", "?")]
			for f: String in FIELDS:
				if not t.has(f):
					problems.append("%s: no '%s'" % [name, f])
			if String(t.get("title", "")) == "":
				problems.append("%s: empty title" % name)
			var file := String(t.get("file", ""))
			if not file.begins_with("res://audio/radio/%s/" % id) or not file.ends_with(".ogg"):
				problems.append("%s: file %s is not res://audio/radio/%s/*.ogg" % [name, file, id])
			if not FileAccess.file_exists(file):
				problems.append("%s: file %s does not exist" % [name, file])
				continue
			var f := FileAccess.open(file, FileAccess.READ)
			var head := f.get_buffer(4).get_string_from_ascii()
			total_bytes += f.get_length()
			f.close()
			if head != "OggS":
				problems.append("%s: %s is not an Ogg file (starts '%s')" % [name, file, head])
				continue
			var stream: Variant = load(file)
			if not (stream is AudioStreamOggVorbis):
				problems.append("%s: %s did not import as AudioStreamOggVorbis" % [name, file])
				continue
			var length: float = (stream as AudioStreamOggVorbis).get_length()
			if absf(length - float(t.get("seconds", -1.0))) > 0.15:
				problems.append("%s: seconds says %.2f, the file is %.2f s" % [name, float(t.get("seconds", -1.0)), length])
			if String(t.get("licence", "unknown")).strip_edges().to_lower() == "unknown":
				unknown.append("%s (%s)" % [t.get("title", "?"), id])

	await _check_radio(problems)
	var summary := "%d stations, %d tracks, %.2f MB of Ogg in game/audio/radio" % [
			(data["stations"] as Array).size(), tracks, total_bytes / 1048576.0]
	print("radio: ", summary)
	if not unknown.is_empty():
		print("radio: WARN licence unknown on %d track(s), check before a release: %s" % [unknown.size(), ", ".join(unknown)])
	for p in problems:
		print("    PROBLEM: ", p)
	print("radio: ", ("OK (%s)" % summary) if problems.is_empty() else "PROBLEM")
	quit(0 if problems.is_empty() else 1)


## The Radio node on its own: playlists, skipping, looping, the caption, the loop seam.
func _check_radio(problems: Array[String]) -> void:
	var radio := Radio.new()
	root.add_child(radio)
	# The root is not ready inside _initialize: one frame, then the radio has run _ready.
	await process_frame
	var changed: Array = []
	radio.track_changed.connect(func(_i: Dictionary, track: Dictionary, natural: bool) -> void: changed.append([track["title"], natural]))
	if radio.stations.is_empty():
		problems.append("radio.gd read no stations from radio.json")
	# A fixture station with three tracks (the first real track under three titles, one with an
	# artist), so the playlist rules run even while every real station holds a single track.
	for st: Dictionary in radio.stations.duplicate():
		if not st["tracks"].is_empty():
			var tracks: Array = []
			for title: String in ["Fixture A", "Fixture B", "Fixture C"]:
				var t: Dictionary = (st["tracks"][0] as Dictionary).duplicate()
				t["title"] = title
				t["artist"] = "Artist" if title == "Fixture B" else ""
				tracks.append(t)
			radio.stations.append({"id": "fixture", "name": "FIXTURE FM", "freq": "99,9", "colour": Color.WHITE, "tracks": tracks})
			radio._orders.append(radio._shuffled(3, radio.stations.size() - 1))
			radio._pos.append(0)
			break
	# Tune through every station and Off, the way the RADIO button does.
	radio.tune(-1, true)
	for i in radio.stations.size():
		radio.next()
		if radio.station != i:
			problems.append("next() from station %d went to %d" % [i - 1, radio.station])
			break
		var info: Dictionary = radio.stations[i]
		var n: int = info["tracks"].size()
		var label := String(info["name"])
		if radio.label() != label:
			problems.append("%s: label() says '%s'" % [label, radio.label()])
		var order := radio.playlist()
		print("    %s: %d track(s), today's order %s" % [label, n, order])
		var sorted := order.duplicate()
		sorted.sort()
		var want: Array[int] = []
		for k in n:
			want.append(k)
		if sorted != want:
			problems.append("%s: the playlist %s is not a permutation of its %d tracks" % [label, order, n])
		if radio._shuffled(n, i) != order:
			problems.append("%s: the same day shuffled twice gave two orders (%s, %s)" % [label, order, radio._shuffled(n, i)])
		if n == 0:
			if not radio.current_track().is_empty():
				problems.append("%s: no tracks but a current track" % label)
			continue
		# The caption: station, title, the artist when given.
		var first: Dictionary = radio.current_track()
		var cap := radio.caption()
		var expect := "%s %s  ·  %s" % [info["freq"], info["name"], first["title"]]
		if String(first["artist"]) != "":
			expect += " (%s)" % first["artist"]
		if cap != expect:
			problems.append("%s: caption '%s' (expected '%s')" % [label, cap, expect])
		# Looping: one track loops, a playlist does not.
		var stream: Variant = radio._stream_of(first)
		if stream is AudioStreamOggVorbis and (stream as AudioStreamOggVorbis).loop != (n == 1):
			problems.append("%s: loop is %s with %d track(s)" % [label, (stream as AudioStreamOggVorbis).loop, n])
		# A skip walks the playlist in its order, and wraps after n.
		changed.clear()
		var seen: Array = []
		for k in n + 1:
			radio.next_track()
			seen.append(radio.current_track()["title"])
		var titles: Array = []
		for k in n:
			titles.append(info["tracks"][order[(k + 1) % n]]["title"])
		titles.append(info["tracks"][order[(n + 1) % n]]["title"])
		if seen != titles:
			problems.append("%s: skipping gave %s, the playlist says %s" % [label, seen, titles])
		if changed.size() != n + 1:
			problems.append("%s: %d skips made %d track_changed signals" % [label, n + 1, changed.size()])
		if n == 1:
			_check_seam(radio.current_track(), label, problems)
	radio.next()
	if radio.station != -1 or radio.label() != "OFF" or radio.caption() != "":
		problems.append("after the last station next() did not turn the radio off")
	radio.queue_free()


## Decodes a second either side of a single track's loop point: no step bigger than the
## music's own, no run of silence (the old WAV loops' check, on the Ogg).
func _check_seam(track: Dictionary, label: String, problems: Array[String]) -> void:
	var s: AudioStreamOggVorbis = load(track["file"])
	s.loop = true
	var pb: AudioStreamPlayback = s.instantiate_playback()
	if not pb.has_method("mix_audio"):
		print("    %s: (no mix_audio in this build; loop seam skipped)" % label)
		return
	var rate := 44100.0
	pb.start(maxf(s.get_length() - 1.0, 0.0))
	var buf: PackedVector2Array = pb.call("mix_audio", 1.0, int(rate * 2.0))
	var steps := PackedFloat32Array()
	for i in range(1, buf.size()):
		steps.append((buf[i] - buf[i - 1]).length())
	var sorted := steps.duplicate()
	sorted.sort()
	var p99: float = sorted[int(sorted.size() * 0.999)]
	var near := 0.0
	for i in range(int(rate) - 64, int(rate) + 64):
		if i > 0 and i < buf.size():
			near = maxf(near, (buf[i] - buf[i - 1]).length())
	var silent := 0
	var run := 0
	for v in buf:
		run = run + 1 if v.length() < 0.0005 else 0
		silent = maxi(silent, run)
	print("    %s loop seam: max step %.4f at the seam, 99.9th pct %.4f elsewhere, longest near-silent run %d samples, loops %d" % [
			label, near, p99, silent, pb.get_loop_count()])
	if near > p99 * 1.5 + 0.01 or silent > 64:
		problems.append("%s: the loop point jumps or has a gap" % label)
