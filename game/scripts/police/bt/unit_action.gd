extends ActionLeaf
## Loop 3g-1: an action leaf that moves its unit by one of its behaviours (police_unit.gd:
## drive_as_traffic, pursue, search_area, hold_still, stay_parked, hold_or_leave). Each sets the
## unit's traffic driver up through the traffic API (race_to, stop_racing, park, held, lights)
## and returns RUNNING while it goes on; the driving itself happens in traffic.gd every frame.

var behaviour := ""


func tick(actor: Node, _blackboard: Blackboard) -> int:
	return actor.call(behaviour)
