extends RefCounted
## The web loop (2026-10-30): sends a MultiMesh's whole buffer (12 transform floats and 4 custom
## floats an instance) so it draws the same on every renderer. The Compatibility renderer (the
## web build's WebGL 2; Godot 4.7.2's gles3 scene.glsl) multiplies an instanced mesh's vertex
## COLOR by the instance colour even when the MultiMesh has no colours, and multimesh_set_buffer
## then leaves the custom data's raw bits in that slot: traffic and pedestrians came out green.
## There the MultiMeshes these feed carry colours too (all white), and each buffer is widened to
## 20 floats an instance on the way out. Mobile and Forward+ (the phone) pass straight through.

## True on the Compatibility renderer: prepare() adds colours and send() widens.
static var widen := RenderingServer.get_current_rendering_method() == "gl_compatibility"
static var _wide := PackedFloat32Array()


## Before `instance_count` is set (a MultiMesh with custom data and no colours).
static func prepare(mm: MultiMesh) -> void:
	if widen:
		mm.use_colors = true


## After `instance_count` is set, for a MultiMesh written instance by instance
## (set_instance_custom_data): its colour slots start unset, so they are made white.
static func whiten(mm: MultiMesh) -> void:
	if widen:
		for i in mm.instance_count:
			mm.set_instance_color(i, Color.WHITE)


## The whole buffer, 16 floats an instance, as the scripts write it.
static func send(rid: RID, buf: PackedFloat32Array) -> void:
	if not widen:
		RenderingServer.multimesh_set_buffer(rid, buf)
		return
	var n := buf.size() / 16
	if _wide.size() < n * 20:
		_wide.resize(n * 20)
		_wide.fill(1.0)  # the colour slots stay white
	elif _wide.size() > n * 20:
		_wide.resize(n * 20)
	for i in n:
		var a := i * 16
		var b := i * 20
		for k in 12:
			_wide[b + k] = buf[a + k]
		_wide[b + 16] = buf[a + 12]
		_wide[b + 17] = buf[a + 13]
		_wide[b + 18] = buf[a + 14]
		_wide[b + 19] = buf[a + 15]
	RenderingServer.multimesh_set_buffer(rid, _wide)
