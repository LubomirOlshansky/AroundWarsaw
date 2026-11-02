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
##      "Adding music"), not a failure. The total radio size is printed;
##   5. loop MW-5, PÓŁNOC FM (_check_polnoc): its 7 tracks (titles as vision.md 4.6, 90-120 s,
##      no jump or gap across each one's loop point), the hours rule on synthetic times (and the
##      looks' clock), reruns at 70 % and the host silent by day, the host every 60-120 s at
##      night (the ident first), the radio following the clock until the player picks, the
##      unlock order (chapters in order, an egg's track skipped, nothing past track 7) and its
##      save, locked tracks never chosen, the unlock toast ≤ 70 characters.
## The last line is "radio: OK (counts and size)" or "radio: PROBLEM"; a WARN line comes before it
## (tools/verify.sh turns a "radio: WARN" line into a WARN row).
##   godot --headless --path game --script res://tools/check_radio.gd

const Radio := preload("res://scripts/radio.gd")
const Dialogue := preload("res://scripts/dialogue.gd")
const Wallet := preload("res://scripts/wallet.gd")
const TimeOfDay := preload("res://scripts/time_of_day.gd")
## Loop MW-5: PÓŁNOC FM's tracks, exactly as vision.md 4.6's briefs.
const POLNOC_TITLES := ["Sód", "Wiadukt", "Nocna przesiadka", "Szkło na Woli", "Bulwar, 23:40",
		"Mgła nad Pałacem", "Świt na Smolnej"]
const SCRATCH_SAVE := "user://check_radio_save.cfg"
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
	await _check_polnoc(problems)
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
		# Loop MW-5: a station with locked tracks plays only its unlocked ones (here, with no
		# save, PÓŁNOC FM's two free tracks).
		var n: int = radio.unlocked_count(i)
		var label := String(info["name"])
		if radio.label() != label:
			problems.append("%s: label() says '%s'" % [label, radio.label()])
		var order := radio.playlist()
		print("    %s: %d track(s) playing of %d, today's order %s" % [label, n, info["tracks"].size(), order])
		var sorted := order.duplicate()
		sorted.sort()
		var want: Array[int] = []
		for k in info["tracks"].size():
			if radio.is_unlocked(i, k):
				want.append(k)
		if sorted != want:
			problems.append("%s: the playlist %s is not a permutation of its %d unlocked tracks" % [label, order, n])
		var again: Array[int] = []
		for k: int in radio._shuffled(info["tracks"].size(), i):
			if radio.is_unlocked(i, k):
				again.append(k)
		if again != order:
			problems.append("%s: the same day shuffled twice gave two orders (%s, %s)" % [label, order, again])
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


# --- loop MW-5: PÓŁNOC FM ---------------------------------------------------------------------

func _check_polnoc(problems: Array[String]) -> void:
	var radio := Radio.new()
	root.add_child(radio)
	await process_frame
	var si := radio.polnoc_index()
	if si < 0:
		problems.append("PÓŁNOC FM: no station '%s' in radio.json" % Radio.POLNOC)
		radio.queue_free()
		return
	var st: Dictionary = radio.stations[si]
	# 1. the data: the station, its 7 tracks as the briefs, their lengths and loop seams
	if st["name"] != "PÓŁNOC FM" or st["freq"] != "86,0" or int(st["free"]) != 2:
		problems.append("PÓŁNOC FM: name '%s', freq '%s', free %d (expected PÓŁNOC FM, 86,0, 2)" % [st["name"], st["freq"], st["free"]])
	var titles: Array = []
	for t: Dictionary in st["tracks"]:
		titles.append(t["title"])
	if titles != POLNOC_TITLES:
		problems.append("PÓŁNOC FM: tracks %s, the briefs say %s" % [titles, POLNOC_TITLES])
	for t: Dictionary in st["tracks"]:
		var length: float = (load(t["file"]) as AudioStream).get_length()
		if length < 90.0 or length > 120.5:
			problems.append("PÓŁNOC FM: %s is %.1f s (the briefs: 90-120 s loops)" % [t["title"], length])
		_check_seam(t, "PÓŁNOC FM / %s" % t["title"], problems)
	# 2. the hours rule on synthetic times, and the fixed looks' clock (time_of_day.gd)
	var cases := [["Day", 14.0, false], ["Dusk", 19.5, false], ["Night", 1.5, true], ["Night", 14.0, true],
			["Dawn", 5.75, true], ["Live", 21.99, false], ["Live", 22.0, true], ["Live", 0.0, true],
			["Live", 3.5, true], ["Live", 5.99, true], ["Live", 6.0, false], ["Live", 12.0, false]]
	for c: Array in cases:
		if Radio.on_air_at(c[0], c[1]) != c[2]:
			problems.append("PÓŁNOC FM: on air at %s %.2f should be %s" % [c[0], c[1], c[2]])
	var clocks := [["Day", 0.0, 14.0, 5], ["Dusk", 0.0, 19.5, 5], ["Night", 0.0, 1.5, 6], ["Dusk", 5.0, 0.5, 6],
			["Night", 1.0, 2.5, 6], ["Day", 10.5, 0.5, 6]]
	for c: Array in clocks:
		var lc := TimeOfDay.look_clock(c[0], c[1])
		if absf(float(lc["hour"]) - float(c[2])) > 0.001 or int(lc["weekday"]) != int(c[3]):
			problems.append("look_clock(%s, +%.1f h) = %s (expected %.2f, weekday %d)" % [c[0], c[1], lc, c[2], c[3]])
	# 3. reruns by day at 70 %, the host silent; on air at night, the host's group (the clock
	# lambda holds this array, so the cases change its contents)
	var look := ["Day", 14.0]
	radio.clock = func() -> Array: return look
	radio.picked = true
	radio.tune(si, true)
	radio.check_air(true)
	if not radio.is_rerun() or absf(radio.level_db() - (Radio.VOLUME_DB + Radio.RERUN_DB)) > 0.01 or radio.host_group() != "":
		problems.append("PÓŁNOC FM by day: rerun %s, level %.1f dB (want %.1f), host '%s' (want silent)" % [
				radio.is_rerun(), radio.level_db(), Radio.VOLUME_DB + Radio.RERUN_DB, radio.host_group()])
	if not radio.caption().contains("powtórka") or radio.caption_sub() != "":
		problems.append("PÓŁNOC FM by day: the caption '%s' / '%s' doesn't say rerun" % [radio.caption(), radio.caption_sub()])
	look.assign(["Night", 1.5])
	radio.check_air()
	if radio.is_rerun() or absf(radio.level_db() - Radio.VOLUME_DB) > 0.01 or radio.host_group() != "radio_polnoc":
		problems.append("PÓŁNOC FM at night: rerun %s, level %.1f dB, host '%s' (want radio_polnoc)" % [
				radio.is_rerun(), radio.level_db(), radio.host_group()])
	radio.tune(radio.station_index(Radio.DAY_DEFAULT), true)
	if radio.host_group() != "radio_host":
		problems.append("KEBAB FM's host group is '%s' (want radio_host)" % radio.host_group())
	# 4. following the clock until the player picks a station
	radio.picked = false
	radio.check_air(true)
	var night_station := radio.station
	look.assign(["Live", 14.0])
	radio.check_air()
	var day_station := radio.station
	radio.next()
	var after_pick := radio.station
	look.assign(["Live", 23.0])
	radio.check_air()
	if night_station != si or day_station != radio.station_index(Radio.DAY_DEFAULT) or radio.station != after_pick or not radio.picked:
		problems.append("following the clock: night %d (want %d), day %d (want %d), after a pick %d stayed %d" % [
				night_station, si, day_station, radio.station_index(Radio.DAY_DEFAULT), after_pick, radio.station])
	# 5. the host through dialogue.gd: at night every 60-120 s (the ident first), by day never
	var heard := _host_run(radio, si, ["Night", 1.5], 900.0)
	var gaps: Array = []
	for k in range(1, heard.size()):
		gaps.append(snappedf(float(heard[k][0]) - float(heard[k - 1][0]), 0.1))
	print("    PÓŁNOC FM host at night: %d lines in 900 s, gaps %s s" % [heard.size(), gaps])
	if heard.size() < 7 or not String(heard[0][1]).contains("86,0"):
		problems.append("PÓŁNOC FM at night: %d host lines in 900 s (want ≥ 7, the ident first: '%s')" % [heard.size(), heard[0][1] if not heard.is_empty() else ""])
	for g: float in gaps:
		if g < 59.9 or g > 120.6:
			problems.append("PÓŁNOC FM at night: a host gap of %.1f s (want 60-120)" % g)
	var by_day := _host_run(radio, si, ["Day", 14.0], 600.0)
	print("    PÓŁNOC FM host by day: %d lines in 600 s" % by_day.size())
	if not by_day.is_empty():
		problems.append("PÓŁNOC FM by day: the host spoke %d times (want silent)" % by_day.size())
	# 6. the unlocks: chapters in order, saved; an egg's track is skipped by the chapters
	var opened: Array = []
	radio.track_unlocked.connect(func(n: int, _t: Dictionary, _why: String) -> void: opened.append(n))
	var w := _wallet()
	w.path = SCRATCH_SAVE
	w.persistent = true
	radio.wallet = w
	var steps: Array = []
	w.chapters_done["noc"] = 1
	steps.append(radio.sync_chapters())
	for id: String in ["bary", "schodki", "trendy", "metro"]:
		w.chapters_done[id] = 1
	steps.append(radio.sync_chapters())
	for id: String in ["jedzenie", "codziennie", "retro", "kiedys"]:
		w.chapters_done[id] = 1
	steps.append(radio.sync_chapters())
	steps.append(radio.sync_chapters())
	if str(steps) != str([[3], [4, 5, 6, 7], [], []]) or w.track_chapters != 9 or str(opened) != str([3, 4, 5, 6, 7]):
		problems.append("unlocks by chapter: %s (want [[3], [4, 5, 6, 7], [], []]), %d chapters counted, signals %s" % [steps, w.track_chapters, opened])
	var back := _wallet()
	back.path = SCRATCH_SAVE
	back.persistent = true
	back.load_save()
	var keys: Array = back.tracks.keys()
	keys.sort()
	if str(keys) != str([3, 4, 5, 6, 7]) or back.track_chapters != 9:
		problems.append("the unlocks' save read back as %s, %d chapters (want [3..7], 9)" % [keys, back.track_chapters])
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SCRATCH_SAVE))
	var egg := _wallet()
	radio.wallet = egg
	var e1 := radio.unlock_track(5, "egg")
	var e2 := radio.unlock_track(5, "egg")
	var e3 := radio.unlock_track(1, "egg")
	for id: String in ["noc", "bary", "schodki", "trendy", "metro"]:
		egg.chapters_done[id] = 1
	var after_egg := radio.sync_chapters()
	if not e1 or e2 or e3 or str(after_egg) != str([3, 4, 6, 7]):
		problems.append("an egg's track: first %s, again %s, a free one %s, then 5 chapters opened %s (want [3, 4, 6, 7])" % [e1, e2, e3, after_egg])
	# 7. locked tracks never play
	var fresh := _wallet()
	radio.wallet = fresh
	radio.picked = true
	radio.tune(si, true)
	var played := {}
	for k in 40:
		played[radio.track_number()] = true
		if radio.current_track().is_empty():
			problems.append("PÓŁNOC FM with 2 open tracks: no current track after %d skips" % k)
			break
		radio.next_track()
	var nums: Array = played.keys()
	nums.sort()
	if str(nums) != str([1, 2]) or radio.playlist().size() != 2:
		problems.append("PÓŁNOC FM with only the free tracks played %s, playlist %s (want [1, 2])" % [nums, radio.playlist()])
	radio.unlock_track(3, "check")
	played.clear()
	for k in 6:
		radio.next_track()
		played[radio.track_number()] = true
	if not played.has(3):
		problems.append("PÓŁNOC FM: track 3 opened but never played in 6 skips (%s)" % [played.keys()])
	radio.unlock_all = true
	if radio.playlist().size() != 7:
		problems.append("--unlock=all: the playlist has %d tracks" % radio.playlist().size())
	radio.unlock_all = false
	# 8. the toast
	for t: String in POLNOC_TITLES:
		for l: String in Radio.unlock_toast(t):
			if l.length() > 70:
				problems.append("the unlock toast is %d characters: '%s'" % [l.length(), l])
	print("    PÓŁNOC FM: %d tracks, free %d, unlocks by chapter %s, after an egg's 5: %s" % [titles.size(), st["free"], steps, after_egg])
	for n in [w, back, egg, fresh]:
		n.queue_free()
	radio.queue_free()


## A wallet that never reads or writes the player's save.
func _wallet() -> Node:
	var w := Wallet.new()
	w.persistent = false
	root.add_child(w)
	return w


## dialogue.gd's host on `radio` tuned to station `si` at `look` for `seconds` of play (2 Hz
## steps, a fixed seed): [[time, Polish line]] of what he said.
func _host_run(radio: Node, si: int, look: Array, seconds: float) -> Array:
	radio.clock = func() -> Array: return look
	radio.picked = true
	radio.tune(si, true)
	radio.check_air(true)
	var d := Dialogue.new()
	root.add_child(d)
	d._rng.seed = 5
	d._host_next = d._rng.randf_range(Dialogue.HOST_GAP.x, Dialogue.HOST_GAP.y)
	d.radio = radio
	var heard: Array = []
	var now := [0.0]
	var take := func(text: String, _c: Color, _s: String) -> void:
		heard.append([now[0], text.get_slice(":  ", 1)])
	radio.ticker.connect(take)
	d.on_station_changed(si, radio.stations[si])
	var t := 0.0
	while t < seconds:
		t += 0.5
		now[0] = t
		d._frame(0.5)
	radio.ticker.disconnect(take)
	d.free()
	return heard
