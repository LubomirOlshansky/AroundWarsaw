extends Node
## Loop 3g-2 (police, part two; docs/design/police.md sections 5.6, 11.1): one city guard on foot
## (Straż Miejska), a fixed person in the pedestrians' MultiMesh (pedestrians.gd set_fixed: +0
## draw calls), and its beehave tree. guards.gd staffs the posts near the player, decides what each
## guard does (the role on the blackboard: whistled at a car, the clamp, a talk) and ticks the
## trees of the six nearest at 5 Hz; a tree only moves its guard (a target and a pace that
## guards.gd walks every frame). Guards never call the police and never chase.
##
##   SelectorReactive
##   ├ SequenceReactive  Clamp: IsRole(clamp) → walk_to_car (to the parked car's side)
##   ├ SequenceReactive  Run  : IsRole(run)   → run_after (5 m/s after the car, 3 s)
##   ├ SequenceReactive  Talk : IsRole(talk)  → face_player
##   └ stand_or_stroll (back to the post at a walk, then standing, facing the street)

const PoliceTree := preload("res://scripts/police/police_tree.gd")
const SelectorReactive := preload("res://addons/beehave/nodes/composites/selector_reactive.gd")
const SequenceReactive := preload("res://addons/beehave/nodes/composites/sequence_reactive.gd")
const IsRole := preload("res://scripts/police/bt/is_role.gd")
const UnitAction := preload("res://scripts/police/bt/unit_action.gd")

## Paces (m/s): running after a car (police.md 5.6), walking.
const RUN := 5.0
const WALK := 1.4
## How close it comes to the parked car (m from its centre).
const CLAMP_SIDE := 2.6

## The post's id and its line tag ("oldtown" on the Market Square and the lanes, "" elsewhere).
var post := ""
var tag := ""
## Where it stands and the way it faces there (radians, like a car's yaw).
var home := Vector2.ZERO
var face := 0.0
## Where it is now, the way it faces, and where its tree sends it at what pace.
var pos := Vector2.ZERO
var yaw := 0.0
var target := Vector2.INF
var pace := 0.0
## Its fixed slot in the pedestrians' MultiMesh (-1 while not shown).
var slot := -1
## Metres to the player's car (guards.gd, 5 Hz) and seconds before it may talk again.
var dist := INF
var talk_wait := 0.0
## guards.gd: the player's car (2D), for the run and the clamp.
var car_at := Vector2.ZERO
var tree: Node


func _init(id: String, line_tag: String, at: Vector2, facing: float) -> void:
	post = id
	tag = line_tag
	home = at
	face = facing
	pos = at
	yaw = facing
	name = "Guard_" + id


## Builds the tree once.
func build() -> void:
	tree = PoliceTree.new()
	tree.process_thread = BeehaveTree.ProcessThread.MANUAL
	tree.actor = self
	var top := SelectorReactive.new()
	top.name = "Selector"
	tree.add_child(top)
	top.add_child(_branch("Clamp", "clamp", "walk_to_car"))
	top.add_child(_branch("Run", "run", "run_after"))
	top.add_child(_branch("Talk", "talk", "face_player"))
	var post_leaf := UnitAction.new()
	post_leaf.behaviour = "stand_or_stroll"
	post_leaf.name = "stand_or_stroll"
	top.add_child(post_leaf)
	add_child(tree)
	set_role("post")


func _branch(label: String, r: String, behaviour: String) -> Node:
	var seq := SequenceReactive.new()
	seq.name = label
	var c := IsRole.new()
	c.role = r
	c.name = "Is_" + r
	seq.add_child(c)
	var a := UnitAction.new()
	a.behaviour = behaviour
	a.name = behaviour
	seq.add_child(a)
	return seq


func role() -> String:
	return tree.blackboard.get_value("role", "")


func set_role(r: String) -> void:
	tree.blackboard.set_value("role", r)


func tick() -> void:
	tree.tick()


## guards.gd, every frame: walks towards the target at its pace.
func step(dt: float) -> void:
	if target == Vector2.INF or pace <= 0.0:
		return
	var to := target - pos
	var d := to.length()
	if d < 0.05:
		return
	var move := minf(d, pace * dt)
	pos += to / d * move
	yaw = atan2(-to.x, -to.y)


# --- behaviours (the tree's actions) --------------------------------------------------------

## After the car at a run (guards.gd ends the run after 3 s and has it give up).
func run_after() -> int:
	target = car_at
	pace = RUN
	return BeehaveNode.RUNNING


## Over to the parked car's side at a walk, to write the clamp's countdown.
func walk_to_car() -> int:
	var away := pos - car_at
	target = car_at + (away.normalized() if away.length() > 0.1 else Vector2.RIGHT) * CLAMP_SIDE
	pace = WALK
	if pos.distance_to(target) < 0.3:
		var to := car_at - pos
		yaw = atan2(-to.x, -to.y)
	return BeehaveNode.RUNNING


## Talking with the stopped car: stands where it is, facing it.
func face_player() -> int:
	target = Vector2.INF
	pace = 0.0
	var to := car_at - pos
	if to.length() > 0.1:
		yaw = atan2(-to.x, -to.y)
	return BeehaveNode.RUNNING


## Back to the post at a walk, then standing there facing the street.
func stand_or_stroll() -> int:
	if pos.distance_to(home) > 0.3:
		target = home
		pace = WALK
	else:
		target = Vector2.INF
		pace = 0.0
		yaw = face
	return BeehaveNode.RUNNING
