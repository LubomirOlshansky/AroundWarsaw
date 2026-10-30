extends Node
## The web loop 2 (2026-10-30): on the web the sector scenes are not in the game's pack (they were
## 96 of its 140 MB). Each is a small pack of its own beside the page, sectors/<name>.<hash>.pck
## (tools/export_web.sh, game/tools/pack_sectors.gd), downloaded when the streamer wants the sector
## (nearest first, a few at a time; the browser caches them for a year) and mounted with
## ProjectSettings.load_resource_pack. The sectors round the start come first, while the title
## shows. res://map/web_sectors.json lists them; without it (every other build) none of this runs.

const MapBuilder := preload("res://scripts/map_builder.gd")

const MANIFEST := "res://map/web_sectors.json"
## Downloads at once.
const AT_ONCE := 3
## Where the downloaded packs go (the browser's memory file system, not user://, which is
## copied to IndexedDB).
const DIR := "/tmp/sectors"

## A sector's pack mounted (it was downloaded and ProjectSettings took it).
signal fetched(key: Vector2i)

var _packs := {}         # "s_i_j" -> path beside the page
var _spawn := Vector3.ZERO
var _base := ""
var _mounted := {}       # key -> true
var _waiting: Array = [] # [key, file] downloaded, not mounted yet
var _wanted := {}        # key -> priority (smaller first), asked for this frame
var _busy := {}          # HTTPRequest -> key
var _idle: Array[HTTPRequest] = []
var _failed := {}        # key -> failures
var bytes := 0


## Whether this build streams its sectors from the web (a web build with the manifest in its
## pack; a game run on the Mac may find the export's manifest on disk and ignores it).
static func active() -> bool:
	return OS.has_feature("web") and FileAccess.file_exists(MANIFEST)


func _ready() -> void:
	var m: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	if m is Dictionary:
		_packs = m.get("packs", {})
		var s: Dictionary = m.get("spawn", {})
		_spawn = Vector3(float(s.get("x", 0.0)), 0.0, float(s.get("z", 0.0)))
	if OS.has_feature("web"):
		_base = str(JavaScriptBridge.eval("location.href.replace(/[?#].*$/, '').replace(/[^\\/]*$/, '')"))
	DirAccess.make_dir_recursive_absolute(DIR)
	for i in AT_ONCE:
		var req := HTTPRequest.new()
		# A pack (~1 MB) in one read: the web client hands over at most this much a frame, and
		# the default 64 KB made the start's nine packs take most of a minute.
		req.download_chunk_size = 1 << 22
		req.request_completed.connect(_on_done.bind(req))
		add_child(req)
		_idle.append(req)


func is_ready(key: Vector2i) -> bool:
	return _mounted.has(key)


## Asks for a sector's pack this frame; the smallest priority (distance) downloads first. Asks
## that aren't repeated the next frame are dropped (the sector isn't wanted any more).
func want(key: Vector2i, priority: float) -> void:
	if _mounted.has(key) or _busy.values().has(key) or int(_failed.get(key, 0)) >= 3 \
			or not _packs.has(MapBuilder.sector_name(key)):
		return
	_wanted[key] = minf(priority, float(_wanted.get(key, INF)))


## A sector's scene is loaded: its pack's file is deleted (the browser keeps its memory file
## system in RAM, and an iPhone's Safari closes a page that holds too much); wanted again after an
## unload, it is fetched again, from the browser's cache.
func release(key: Vector2i) -> void:
	if _mounted.erase(key):
		DirAccess.remove_absolute("%s/%s.pck" % [DIR, MapBuilder.sector_name(key)])


## Mounts what was downloaded (the streamer calls this when its worker isn't loading: mounting
## changes the file table the worker reads).
func mount_waiting() -> void:
	for w: Array in _waiting:
		var path: String = w[1]
		if ProjectSettings.load_resource_pack(path):
			_mounted[w[0]] = true
			fetched.emit(w[0])
		else:
			push_error("sector packs: can't mount %s" % path)
			_failed[w[0]] = int(_failed.get(w[0], 0)) + 1
	_waiting.clear()


## The sectors within `reach` of the start (`at`, or the map's spawn), downloaded and mounted
## before the city is built.
func fetch_start(at: Vector3, reach: float, sector: float) -> void:
	if at == Vector3.INF:
		at = _spawn
	var keys: Array[Vector2i] = []
	for n: String in _packs:
		var p := n.split("_")
		var key := Vector2i(int(p[1]), int(p[2]))
		var x0 := key.x * sector
		var z0 := key.y * sector
		if at.x + reach > x0 and at.x - reach < x0 + sector and at.z + reach > z0 and at.z - reach < z0 + sector:
			keys.append(key)
	var t0 := Time.get_ticks_msec()
	while true:
		mount_waiting()
		var left := 0
		for key in keys:
			if not _mounted.has(key) and int(_failed.get(key, 0)) < 3:
				want(key, 0.0)
				left += 1
		if left == 0:
			break
		await get_tree().process_frame
	print("sector packs: %d at the start, %.1f MB in %d ms" % [keys.size(), bytes / 1e6, Time.get_ticks_msec() - t0])


func _process(_delta: float) -> void:
	while not _idle.is_empty() and not _wanted.is_empty():
		var best := Vector2i.ZERO
		var best_p := INF
		for key: Vector2i in _wanted:
			if _wanted[key] <= best_p:
				best_p = _wanted[key]
				best = key
		_wanted.erase(best)
		var req: HTTPRequest = _idle.pop_back()
		_busy[req] = best
		if req.request(_base + str(_packs[MapBuilder.sector_name(best)])) != OK:
			_busy.erase(req)
			_idle.append(req)
			_failed[best] = int(_failed.get(best, 0)) + 1
	_wanted.clear()


func _on_done(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray, req: HTTPRequest) -> void:
	var key: Vector2i = _busy[req]
	_busy.erase(req)
	_idle.append(req)
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		push_warning("sector packs: %s failed (result %d, HTTP %d)" % [MapBuilder.sector_name(key), result, code])
		_failed[key] = int(_failed.get(key, 0)) + 1
		return
	bytes += body.size()
	var path := "%s/%s.pck" % [DIR, MapBuilder.sector_name(key)]
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("sector packs: can't write %s" % path)
		return
	f.store_buffer(body)
	f.close()
	_waiting.append([key, path])

