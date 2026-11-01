extends Control
## The garage loop (2026-10-31): the paint card at Warsztat u Mirka (garage.gd). The game pauses
## under it (main.gd, like the settings card), so it runs with PROCESS_MODE_ALWAYS. In the HUD's
## card recipe (hud.gd `_panel_box`, `_chip`, the type scale): the title and the wallet, Mirek's
## line, the paints as swatches in two rows of five (each 44 pt or more: the colour, its Polish
## name, the price or "masz" / "na aucie"), then the action for the swatch picked (buy, switch,
## or why not) and WYJAZD · Drive off. Polish over English throughout. Built at the first open.

signal closed

const Gamepad := preload("res://scripts/gamepad.gd")  # the gamepad follow-ups

## The swatches' size in points (at least 44 tall: the touch rule).
const SWATCH := Vector2(114.0, 58.0)
const GAP := 6.0
## Swatches per row (loop 3h slice 2: ten paints in two rows of five).
const COLUMNS := 5

## garage.gd (the rules, the paints, Mirek's lines).
var garage: Node
## Pixels per point and the safe area (hud.gd's).
var pt := 1.0
var safe := Rect2()
## The swatch picked (a paint id).
var picked := ""

var _built := false
## The dim over the HUD and the city behind the card (drawn by this Control, `_draw`).
const DIM := Color(0, 0, 0, 0.4)
var _card: PanelContainer
var _title: Label
var _title_en: Label
var _money: Label
var _line: Label
var _line_en: Label
var _grid: GridContainer
var _swatches := {}
var _action: Button
var _leave: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false


func _hud() -> CanvasLayer:
	return garage.hud


func _build() -> void:
	_built = true
	var hud := _hud()
	_card = PanelContainer.new()
	_card.name = "card"
	_card.add_theme_stylebox_override("panel", hud._panel_box(12.0, 12.0))
	add_child(_card)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", roundi(6.0 * pt))
	_card.add_child(col)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", roundi(10.0 * pt))
	col.add_child(head)
	var names := VBoxContainer.new()
	names.add_theme_constant_override("separation", 0)
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(names)
	_title = hud._label(hud.T_TITLE, garage.GARAGE_COLOUR)
	_title.text = str(garage.NAME[0]).to_upper()
	names.add_child(_title)
	_title_en = hud._label(hud.T_LABEL, hud.SUB)
	_title_en.text = "%s · %s, Praga" % [garage.NAME[1], garage.STREET]
	names.add_child(_title_en)
	_money = hud._label(hud.T_BODY, hud.ACCENT)
	_money.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_money.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(_money)
	var width := SWATCH.x * COLUMNS + GAP * (COLUMNS - 1)
	_line = hud._label(hud.T_SUB, hud.INK)
	hud._wrap(_line, width)
	col.add_child(_line)
	_line_en = hud._label(hud.T_LABEL, hud.SUB)
	hud._wrap(_line_en, width)
	col.add_child(_line_en)
	_grid = GridContainer.new()
	_grid.columns = COLUMNS
	_grid.add_theme_constant_override("h_separation", roundi(GAP * pt))
	_grid.add_theme_constant_override("v_separation", roundi(GAP * pt))
	col.add_child(_grid)
	for p: Dictionary in garage.PAINTS:
		_swatches[str(p["id"])] = _swatch(p)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", roundi(GAP * pt))
	col.add_child(row)
	_action = hud._chip(row, "", "")
	_action.name = "action"
	_action.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_action.pressed.connect(_on_action)
	_leave = hud._chip(row, "WYJAZD", "Drive off")
	_leave.name = "leave"
	_leave.pressed.connect(func() -> void: closed.emit())


## One paint's button: its colour (with the stripe), the Polish name, the price or the state.
func _swatch(p: Dictionary) -> Button:
	var hud := _hud()
	var b := Button.new()
	b.name = "paint_%s" % p["id"]
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = SWATCH * pt
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.add_theme_constant_override("separation", roundi(2.0 * pt))
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(box)
	var chip := ColorRect.new()
	chip.color = p["paint"]
	chip.custom_minimum_size = Vector2(0.0, 14.0 * pt)
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(chip)
	var stripe := ColorRect.new()
	stripe.color = p["stripe"]
	stripe.custom_minimum_size = Vector2(0.0, 2.0 * pt)
	stripe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(stripe)
	var name_l: Label = hud._label(hud.T_LABEL, hud.INK)
	name_l.text = str(p["name"][0])
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_l.clip_text = true
	name_l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	box.add_child(name_l)
	var price: Label = hud._label(hud.T_LABEL, hud.SUB)
	price.name = "price"
	price.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price.clip_text = true
	box.add_child(price)
	b.pressed.connect(func() -> void: pick(str(p["id"])))
	_grid.add_child(b)
	return b


## Opens on the paint the car wears, with Mirek's hello.
func open() -> void:
	if not _built:
		_build()
	picked = garage.current()
	_say("hello")
	_refresh()
	visible = true
	_place.call_deferred()
	_place()
	if Gamepad.in_use():
		# The gamepad follow-ups: the swatches and the two chips take focus, on the paint worn.
		Gamepad.focus_all(_card, pt)
		(_swatches.get(picked, _leave) as Button).grab_focus()
	else:
		Gamepad.focus_none(_card)


func close() -> void:
	Gamepad.drop_focus(self)
	visible = false


func is_open() -> bool:
	return visible


## A swatch tapped: it is picked; a paint you can't have yet gets Mirek's reason.
func pick(id: String) -> void:
	picked = id
	match garage.rule_now(id):
		"short":
			_say("short")
		"locked":
			_say("locked")
	_refresh()


## The action button: buy or switch to the picked paint.
func _on_action() -> void:
	var first: bool = not garage.wallet.paints.has(picked)
	var r: String = garage.choose(picked)
	if r == "buy":
		_say(picked if picked in ["black", "green"] else "buy")
	elif r == "switch":
		# The gold paint, opened by the eggs, the first time: its own line.
		_say("gold" if picked == "gold" and first else "switch")
	_refresh()


func _say(tag: String) -> void:
	var l: Array = garage.line(tag)
	if str(l[0]) == "" and tag in ["black", "green"]:
		l = garage.line("buy")
	_line.text = str(l[0])
	_line_en.text = str(l[1])


func _refresh() -> void:
	var hud := _hud()
	var w: Node = garage.wallet
	_money.text = w.money(int(w.zl)) if w != null else ""
	var cur: String = garage.current()
	for id: String in _swatches:
		var b: Button = _swatches[id]
		var r: String = garage.rule_now(id)
		var p: Dictionary = garage.find(id)
		var price := b.find_child("price", true, false) as Label
		match r:
			"on":
				price.text = "na aucie · on"
			"switch":
				price.text = "masz · yours" if not (p.has("eggs") or p.has("syrenki")) or w.paints.has(id) else "gratis · free"
			"locked":
				if p.has("syrenki"):
					price.text = "%d/%d Syrenek" % [garage.syrenki_now(), int(p["syrenki"])]
				else:
					price.text = "%d/%d sekretów" % [garage.eggs_now(), int(p["eggs"])]
			_:
				price.text = w.money(int(p["price"]))
		var lit := id == picked
		var edge: Color = hud.ACCENT if lit else (garage.GARAGE_COLOUR if id == cur else Color(1, 1, 1, 0.22))
		var style: StyleBoxFlat = hud._box(hud.CARD_BG, edge, 2.0 if lit or id == cur else 1.0)
		for s in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
			b.add_theme_stylebox_override(s, style)
	var p2: Dictionary = garage.find(picked)
	var name_pl := str(p2["name"][0]) if not p2.is_empty() else ""
	var name_en := str(p2["name"][1]) if not p2.is_empty() else ""
	match garage.rule_now(picked):
		"on":
			hud._set_chip(_action, "NA AUCIE: %s" % name_pl.to_upper(), "%s is on the car" % name_en)
			_action.disabled = true
		"switch":
			hud._set_chip(_action, "LAKIERUJ: %s" % name_pl.to_upper(), "Paint it %s, free" % name_en.to_lower())
			_action.disabled = false
		"buy":
			hud._set_chip(_action, "KUP ZA %s" % w.money(int(p2["price"])).to_upper(), "Buy %s" % name_en.to_lower())
			_action.disabled = false
		"short":
			var miss := int(p2["price"]) - int(w.zl)
			hud._set_chip(_action, "BRAKUJE %s" % w.money(miss).to_upper(), "%s short" % _money_en(miss))
			_action.disabled = true
		"locked":
			if p2.has("syrenki"):
				hud._set_chip(_action, "ZA %d SYRENEK" % int(p2["syrenki"]), "Find %d Mermaids" % int(p2["syrenki"]))
			else:
				hud._set_chip(_action, "ZA %d SEKRETÓW" % int(p2["eggs"]), "Find %d easter eggs" % int(p2["eggs"]))
			_action.disabled = true
	_action.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_place()


static func _money_en(amount: int) -> String:
	var s := str(amount)
	if amount >= 1000:
		s = "%d,%03d" % [amount / 1000, amount % 1000]
	return s + " zł"


## The card in the middle of the safe area at its natural size.
func _place() -> void:
	if _card == null:
		return
	# This Control covers the screen (sized by hand: top-left anchors), dims it in `_draw` and
	# takes the touches that would reach the HUD under it.
	position = Vector2.ZERO
	size = get_viewport_rect().size
	queue_redraw()
	_card.reset_size()
	var s := _card.get_combined_minimum_size()
	_card.size = s
	var r := safe if safe.has_area() else get_viewport_rect()
	_card.position = (r.position + (r.size - s) * 0.5).round()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), DIM)


## For check_hud: the card and its buttons, in pixels.
func ui_rects() -> Dictionary:
	var out := {"card": _card.get_global_rect(), "action": _action.get_global_rect(), "leave": _leave.get_global_rect()}
	for id: String in _swatches:
		out["paint_" + id] = (_swatches[id] as Button).get_global_rect()
	return out


func card_rect() -> Rect2:
	return _card.get_global_rect()


func _unhandled_input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed("ui_cancel") or Gamepad.closes(event)):
		get_viewport().set_input_as_handled()
		closed.emit()
