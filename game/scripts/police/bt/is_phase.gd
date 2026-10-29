extends ConditionLeaf
## Loop 3g-1: SUCCESS when the chase's phase on the blackboard ("calm", "lizak", "chase",
## "search", "pullover"; police.gd writes it) is `phase`.

var phase := ""


func tick(_actor: Node, blackboard: Blackboard) -> int:
	return SUCCESS if blackboard.get_value("phase", "calm") == phase else FAILURE
