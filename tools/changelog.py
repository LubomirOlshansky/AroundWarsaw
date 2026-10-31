"""The day-by-day changelog: docs/CHANGELOG.md's short lines, plus ROADMAP's progress log.

Usage: python3 -I tools/changelog.py   (prints the days it finds; site_build.py and wiki_build.py import it)

Every day in ROADMAP.md's "Progress log" table becomes one entry, newest first. The entry shows the
short lines written for that day in docs/CHANGELOG.md (a "## YYYY-MM-DD" section with "- " lines).
A day in the log that CHANGELOG.md does not cover yet gets lines made from the log's own labels,
so a new day shows up before anyone writes it up. Each entry also counts the log's updates that day.
"""

import datetime
import html
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
BACKLOG_URL = "https://github.com/LubomirOlshansky/AroundWarsaw/blob/main/docs/BACKLOG.md"
ROADMAP_URL = "https://github.com/LubomirOlshansky/AroundWarsaw/blob/main/docs/ROADMAP.md#progress-log"


def log_rows() -> list[tuple[str, str]]:
    """(date, label) for each row of ROADMAP.md's progress log."""
    text = (ROOT / "docs" / "ROADMAP.md").read_text(encoding="utf-8")
    start = text.find("## Progress log")
    rows = []
    for ln in text[start:].splitlines():
        m = re.match(r"\|\s*(20\d\d-\d\d-\d\d)\s*\|\s*([^|]+?)\s*\|", ln)
        if m:
            rows.append((m.group(1), m.group(2)))
    return rows


def written() -> dict[str, list[str]]:
    """The short lines of docs/CHANGELOG.md by day."""
    days: dict[str, list[str]] = {}
    cur = None
    for ln in (ROOT / "docs" / "CHANGELOG.md").read_text(encoding="utf-8").splitlines():
        m = re.match(r"## (20\d\d-\d\d-\d\d)\s*$", ln)
        if m:
            cur = m.group(1)
            days[cur] = []
        elif cur and ln.startswith("- "):
            days[cur].append(ln[2:].strip())
        elif cur and ln.startswith("  ") and days[cur]:
            days[cur][-1] += " " + ln.strip()
    return days


def days() -> list[dict]:
    """Newest first: {date, label (e.g. "31 October 2026"), lines, written, updates}."""
    counts: dict[str, list[str]] = {}
    for d, label in log_rows():
        counts.setdefault(d, []).append(label)
    lines = written()
    out = []
    for d in sorted(set(counts) | set(lines), reverse=True):
        auto = [re.sub(r"^loop ", "", lab) for lab in counts.get(d, [])]
        out.append({
            "date": d,
            "label": datetime.date.fromisoformat(d).strftime("%-d %B %Y"),
            "lines": lines.get(d) or ["Updates: " + ", ".join(auto) + "."],
            "written": d in lines,
            "updates": len(counts.get(d, [])),
        })
    return out


def inline(text: str) -> str:
    t = html.escape(text)
    t = re.sub(r"\*\*(.+?)\*\*", r"<strong>\1</strong>", t)
    return re.sub(r"\[([^\]]+)\]\(([^)\s]+)\)", r'<a href="\2">\1</a>', t)


def html_days(heading: str = "h2") -> str:
    """The days as HTML: a heading, a count, the short lines."""
    out = []
    for day in days():
        n = day["updates"]
        count = f' <span class="day-count">{n} update{"s" if n != 1 else ""}</span>' if n else ""
        items = "".join(f"<li>{inline(x)}</li>" for x in day["lines"])
        out.append(f'<{heading} id="d{day["date"]}">{day["label"]}{count}</{heading}>\n<ul class="day">{items}</ul>')
    return "\n".join(out)


def main() -> int:
    for day in days():
        print(day["date"], day["updates"], "written" if day["written"] else "from the log", len(day["lines"]))
    return 0


if __name__ == "__main__":
    sys.exit(main())
