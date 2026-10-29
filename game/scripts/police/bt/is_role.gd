extends ConditionLeaf
## Loop 3g-1: SUCCESS when the unit's role on the blackboard (police.gd writes it) is `role`.

var role := ""


func tick(_actor: Node, blackboard: Blackboard) -> int:
	return SUCCESS if blackboard.get_value("role", "") == role else FAILURE
