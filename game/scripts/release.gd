extends RefCounted
## The release build's rules (DEMO 3j "debug flags stripped"): a build exported with the release
## template (the TestFlight / App Store archive, the Play AAB) reads no command-line flags, so
## none of the testing flags (--at=, --shots=, --bench, --ghost-debug=, --debug-roads ...) can
## change what a player sees. The debug export (Xcode's Run, tools/device_run.sh) and the editor
## binary that runs the checks keep every flag.


## The game's own options: the user args after "--", or, when a launcher swallowed the "--"
## (devicectl on an iPhone, loop 2b), the engine's list; none in a release build.
static func game_args() -> PackedStringArray:
	return pick(OS.get_cmdline_user_args(), OS.get_cmdline_args(), OS.is_debug_build())


## The rule itself, apart from the OS (tools/check_credits.gd runs it both ways).
static func pick(user: PackedStringArray, all: PackedStringArray, debug: bool) -> PackedStringArray:
	if not debug:
		return PackedStringArray()
	return user if not user.is_empty() else all
