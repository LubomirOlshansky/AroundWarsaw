extends Node
## Loop 3g-1 (police, part one; docs/design/police.md section 11.1): one police unit, a POLICE
## car in traffic (traffic.gd's Driver) and its beehave tree. police.gd keeps a pool of eight
## (the POLICE kind's pool), binds one to each police car that comes into the band or that it
## places (a speed trap's car, a blocker, the roadblock), writes the blackboard (`role`,
## `phase`, `pullover`) at 5 Hz right after its perception pass, and ticks the trees there.
## Escalation is not in the trees: police.gd's state machine decides; a tree only moves its
## unit, through the traffic API (race_to, stop_racing, park, unpark, held, the light bar).
##
##   SelectorReactive
##   ├ SequenceReactive  PullOver : IsPullOver → hold_still (stopped behind the player, lights on)
##   ├ SequenceReactive  Roadblock: IsRole(roadblock) → hold_or_leave (parked; 10 s, then goes)
##   ├ SequenceReactive  Blocker  : IsRole(blocker) → hold_or_leave
##   ├ SequenceReactive  Search   : IsRole(chaser), IsPhase(search) → search_area
##   ├ SequenceReactive  Chase    : IsRole(chaser) → pursue (re-planned 1 Hz by police.gd)
##   ├ SequenceReactive  Trap     : IsRole(trap) → stay_parked
##   └ drive_as_traffic
##
## The escort (rescues) and the city guards' car come in part two (loop 3g-2): a branch each.

const PoliceTree := preload("res://scripts/police/police_tree.gd")
const SelectorReactive := preload("res://addons/beehave/nodes/composites/selector_reactive.gd")
const SequenceReactive := preload("res://addons/beehave/nodes/composites/sequence_reactive.gd")
const IsRole := preload("res://scripts/police/bt/is_role.gd")
const IsPhase := preload("res://scripts/police/bt/is_phase.gd")
const IsPullOver := preload("res://scripts/police/bt/is_pull_over.gd")
const UnitAction := preload("res://scripts/police/bt/unit_action.gd")

## Chasers: the player's top speed (30 m/s) x 0.92, traffic's acceleration x 1.2, and the gap
## they keep behind the player's car (they never ram; police.md section 4).
const CHASE_TOP := 27.6
const CHASE_ACCEL := 1.2
const CHASE_GAP := 10.0
## Searching: to the last-seen point, then round it within SEARCH_REACH at 30 km/h.
const SEARCH_SPEED := 8.3
const SEARCH_REACH := 150.0
## A blocker or the roadblock the chase has gone past (or away from) leaves after this.
const HOLD_LEAVE := 10.0

## Its number in the log ("unit 2").
var number := 0
var police: Node
var traffic: Node3D
## The traffic Driver it drives (null while unbound).
var driver = null
var tree: Node
## police.gd's perception (5 Hz): metres to the player and whether it sees the player now.
var dist := INF
var sees := false
## It has come near the player (police.gd paces the patrol cars by it).
var met := false
## Seconds before its megaphone may speak again, and before it warns again.
var line_wait := 0.0
var warn_wait := 0.0
## Blocker and roadblock: seconds the chase has been away from it, the player's closest pass.
var away := 0.0
var closest := INF
var _mode := ""


func _init(n: int) -> void:
	number = n
	name = "PoliceUnit%d" % n


## Builds the tree once (the pool's units keep theirs).
func build() -> void:
	tree = PoliceTree.new()
	tree.process_thread = BeehaveTree.ProcessThread.MANUAL
	tree.actor = self
	var top := SelectorReactive.new()
	top.name = "Selector"
	tree.add_child(top)
	top.add_child(_branch("PullOver", [IsPullOver.new()], "hold_still"))
	top.add_child(_branch("Roadblock", [_role("roadblock")], "hold_or_leave"))
	top.add_child(_branch("Blocker", [_role("blocker")], "hold_or_leave"))
	var in_search := IsPhase.new()
	in_search.phase = "search"
	top.add_child(_branch("Search", [_role("chaser"), in_search], "search_area"))
	top.add_child(_branch("Chase", [_role("chaser")], "pursue"))
	top.add_child(_branch("Trap", [_role("trap")], "stay_parked"))
	top.add_child(_action("drive_as_traffic"))
	add_child(tree)


func _branch(label: String, conditions: Array, behaviour: String) -> Node:
	var seq := SequenceReactive.new()
	seq.name = label
	for c: Node in conditions:
		seq.add_child(c)
	seq.add_child(_action(behaviour))
	return seq


func _role(r: String) -> Node:
	var c := IsRole.new()
	c.role = r
	c.name = "Is_" + r
	return c


func _action(behaviour: String) -> Node:
	var a := UnitAction.new()
	a.behaviour = behaviour
	a.name = behaviour
	return a


func role() -> String:
	return tree.blackboard.get_value("role", "")


func set_role(r: String) -> void:
	tree.blackboard.set_value("role", r)


func bind(d, r: String) -> void:
	driver = d
	_mode = ""
	dist = INF
	sees = false
	met = false
	line_wait = 0.0
	warn_wait = 0.0
	away = 0.0
	tree.blackboard.set_value("pullover", false)
	tree.blackboard.set_value("phase", "calm")
	set_role(r)


func unbind() -> void:
	if tree.status == BeehaveTree.RUNNING:
		tree.interrupt()
	tree.status = -1
	driver = null
	set_role("")
	_mode = ""


## police.gd, 5 times a second.
func tick() -> void:
	if driver != null and driver.active:
		tree.tick()


# --- behaviours (the trees' actions) --------------------------------------------------------

## A patrol in traffic: obeys the lights, at 0.95 of the road's speed, lights off.
func drive_as_traffic() -> int:
	if _mode != "traffic":
		_mode = "traffic"
		var d = driver
		traffic.set_lights(d, false)
		d.chase = false
		d.v_cap = 0.0
		d.keep_gap = 2.4
		d.goal = Vector2.INF
		d.accel_factor = 1.0
		d.held = false
		if not d.route.is_empty():
			traffic.stop_racing(d)
		# Back to the band's rules: it may leave when out of sight.
		d.persistent = false
	return BeehaveNode.RUNNING


## The chaser: lights on, after the player on the lane graph (police.gd re-plans the route once
## a second, one unit a frame), never closer than CHASE_GAP behind, slow through reds.
func pursue() -> int:
	if _mode != "chase":
		_mode = "chase"
		var d = driver
		if d.parked:
			police.pull_out(self)
		traffic.set_lights(d, true)
		d.chase = true
		d.held = false
		d.persistent = true
		d.v_cap = CHASE_TOP
		d.accel_factor = CHASE_ACCEL
		d.keep_gap = CHASE_GAP
		police.request_replan(self)
	return BeehaveNode.RUNNING


## Searching: to where it last saw the player, then round there at 30 km/h (police.gd picks the
## spots; lights stay on, no siren).
func search_area() -> int:
	var d = driver
	if _mode != "search":
		_mode = "search"
		if d.parked:
			police.pull_out(self)
		traffic.set_lights(d, true)
		d.chase = false
		d.held = false
		d.persistent = true
		d.v_cap = SEARCH_SPEED
		d.keep_gap = CHASE_GAP
		police.request_replan(self)
	elif d.arrived or d.route.is_empty():
		police.request_replan(self)
	return BeehaveNode.RUNNING


## Pulled over with the player: stopped where it is (a few metres behind), lights on.
func hold_still() -> int:
	if _mode != "hold":
		_mode = "hold"
		traffic.set_lights(driver, true)
		driver.held = true
	return BeehaveNode.RUNNING


## A speed trap's car: parked on the shoulder, lights off (the officer does the waving).
func stay_parked() -> int:
	if _mode != "parked":
		_mode = "parked"
		traffic.set_lights(driver, false)
	return BeehaveNode.RUNNING


## A blocker or the roadblock: parked at its junction with the lights on; once the chase has
## been away from it HOLD_LEAVE seconds (gone past, turned off, over), it goes (police.gd).
func hold_or_leave() -> int:
	if _mode != "block":
		_mode = "block"
		traffic.set_lights(driver, true)
		away = 0.0
		closest = INF
	# Waiting while the player comes nearer; gone past or turned off: going away from it.
	if not police.chasing() or dist > closest + 40.0:
		away += police.TICK
	else:
		away = 0.0
	closest = minf(closest, dist)
	if away >= HOLD_LEAVE:
		police.dismiss(self)
	return BeehaveNode.RUNNING
