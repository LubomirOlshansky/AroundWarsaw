extends ConditionLeaf
## Loop 3g-1: SUCCESS while this unit is the one the player pulled over for (`pullover`).


func tick(_actor: Node, blackboard: Blackboard) -> int:
	return SUCCESS if blackboard.get_value("pullover", false) else FAILURE
