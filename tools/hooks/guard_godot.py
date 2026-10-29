#!/usr/bin/env python3
"""A Claude Code PreToolUse hook for Bash: blocks Godot runs that break the project's rules.

- A game run (godot with --path and no --script / --export / --import / --version) must pass
  --nosave and something that ends it (--quit-after, --quit, --shots=, --bench, --probe,
  --sound-check), so a test never writes the player's save or hangs.
- tools/bake_city.gd must never run --headless (it would drop MultiMesh and texture data and
  write a broken game/map/city.scn).

Reads the hook's JSON on stdin; exits 2 with the reason on stderr to block, 0 otherwise
(also 0 on anything it can't parse, so it never gets in the way of other commands).
Enable it in .claude/settings.json:
  {"hooks": {"PreToolUse": [{"matcher": "Bash", "hooks": [{"type": "command",
    "command": "python3 -I \\"$CLAUDE_PROJECT_DIR\\"/tools/hooks/guard_godot.py"}]}]}}
"""
import json
import os
import shlex
import sys

SEPARATORS = {";", "&&", "||", "|", "&", "(", ")", "\n"}
# Words that may come before godot in one command: env assignments, timing and the
# `perl -e 'alarm shift; exec @ARGV' N` stand-in for timeout.
WRAPPERS = {"time", "exec", "nohup", "env", "perl", "-e", "command"}
NOT_A_GAME = {"--script", "-s", "--export-debug", "--export-release", "--export-pack", "--import",
              "--version", "--help", "-h", "--editor", "-e", "--check-only", "--doctool"}
ENDS_RUN = ("--quit-after", "--quit", "--shots=", "--bench", "--probe", "--sound-check")


def godot_commands(command: str):
    """Yield the argument list of every godot invocation at a command position."""
    lexer = shlex.shlex(command, posix=True, punctuation_chars=";&|()")
    lexer.whitespace_split = True
    segment: list[str] = []
    for token in list(lexer) + [";"]:
        if token in SEPARATORS or set(token) <= set(";&|()"):
            for i, word in enumerate(segment):
                if os.path.basename(word) in ("godot", "Godot"):
                    before = segment[:i]
                    if all(w in WRAPPERS or ("=" in w and not w.startswith("-")) or w.isdigit()
                           or "alarm" in w for w in before):
                        yield segment[i + 1:]
                    break
            segment = []
        else:
            segment.append(token)


def problem(args: list[str]) -> str:
    joined = " ".join(args)
    if "bake_city.gd" in joined and "--headless" in args:
        return ("bake_city.gd must run WITH a renderer (--headless drops MultiMesh and texture "
                "data): godot --path game --resolution 320x180 --script res://tools/bake_city.gd")
    if "--path" not in args and not any(a.startswith("--path=") for a in args):
        return ""
    if any(a in NOT_A_GAME for a in args):
        return ""
    user = args[args.index("--") + 1:] if "--" in args else []
    missing = []
    if "--nosave" not in user:
        missing.append("--nosave (after --)")
    if not any(a.startswith(ENDS_RUN) for a in args):
        missing.append("a way to quit (--quit-after N before --, or --shots= / --bench after it)")
    if missing:
        return "Around Warsaw test runs need " + " and ".join(missing) + " (CLAUDE.md, Hard rules)."
    return ""


def main() -> int:
    try:
        data = json.load(sys.stdin)
        command = data.get("tool_input", {}).get("command", "")
        for line in command.splitlines():
            try:
                found = list(godot_commands(line))
            except ValueError:  # a quote spanning lines: judge what can be read
                continue
            for args in found:
                reason = problem(args)
                if reason:
                    print(reason, file=sys.stderr)
                    return 2
    except Exception:  # never block on something this hook can't read
        return 0
    return 0


if __name__ == "__main__":
    sys.exit(main())
