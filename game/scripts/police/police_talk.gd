extends RefCounted
## Loop 3g-1 (police.md section 7.2): the state a pull-over conversation reads (Dialogue
## Manager's `extra_game_states`, as `talk`). The flow lives in game/dialogue/police.dialogue,
## every word in game/data/dialogue.json: `say(group, tag)` picks a line through dialogue.gd
## `line()` (prefer the tagged one, except the caution's "police", where the untagged lines fit
## too), keeps its English for the balloon and returns the Polish.

## Who says the trap opener (police.md section 6): the young constable reads the radar.
const KACPER := "Posterunkowy Kacper"

var dialogue: Node
## The opener's tag: "routine" (first contact), "kebab" / "sloik" (a job running), "trap", or
## "" (the generic opener).
var opener := ""
## "police", or "fifth" for the day's fifth caution.
var caution_tag := "police"
## The scripted first contact: the opener and the roosters line, no caution.
var first_contact := false
## The opener's tag has its own reply button ("trap", "kebab").
var has_reply := false
## Part two (the city guards' stop): the zone's tag.
var zone := ""
## Set by say() for a line someone else speaks; the balloon reads it (and clears it).
var speaker_override := ""
## Called by the conversation's mutations.
var on_caution: Callable
var on_routine: Callable
## Every line said: [group, tag, Polish], for the log and the checks.
var said: Array = []
var _english := {}


func say(group: String, tag: String) -> String:
	var l: Array = dialogue.line(group, tag, tag != "" and tag != "police")
	if l.is_empty():
		return ""
	if group == "police_stop" and tag == "trap":
		speaker_override = KACPER
	_english[l[0]] = l[1]
	said.append([group, tag, l[0]])
	return l[0]


## The English of a line say() returned ("" for anything else).
func english_of(polish: String) -> String:
	return _english.get(polish, "")


func done_caution() -> void:
	if on_caution.is_valid():
		on_caution.call()


func done_routine() -> void:
	if on_routine.is_valid():
		on_routine.call()
