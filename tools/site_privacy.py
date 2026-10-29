"""Build the website's privacy page from docs/privacy.md.

Usage: python3 -I tools/site_privacy.py

Writes site/public/privacy/index.html, so the policy the stores link to
(https://aroundwarsaw.app/privacy/) always says what docs/privacy.md says. The converter
knows only what that file uses: #/## headings, paragraphs, "- " lists, **bold**, "---".
"""

import html
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "docs" / "privacy.md"
OUT = ROOT / "site" / "public" / "privacy" / "index.html"

PAGE = """<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Privacy · Nocna Warszawa</title>
<meta name="description" content="Nocna Warszawa collects no personal data. Privacy policy for the game and this website.">
<link rel="icon" href="/favicon.svg" type="image/svg+xml">
<link rel="stylesheet" href="/styles.css">
</head>
<body class="doc">
<header class="bar"><a class="brand" href="/"><img src="/favicon.svg" alt="" width="28" height="28">Nocna Warszawa</a></header>
<main class="prose">
{body}
<h2>This website · Ta strona</h2>
<p>aroundwarsaw.app sets no cookies and runs no analytics or trackers. It is served by
Cloudflare, which handles ordinary request data (such as IP addresses) only to deliver and
protect the site.</p>
<p>aroundwarsaw.app nie używa ciasteczek, analityki ani śledzenia. Stronę serwuje Cloudflare,
który przetwarza zwykłe dane żądań (np. adresy IP) wyłącznie po to, by ją dostarczyć i chronić.</p>
<p><a href="https://github.com/LubomirOlshansky/AroundWarsaw/issues">GitHub issues</a> · <a href="/">← aroundwarsaw.app</a></p>
</main>
</body>
</html>
"""


def inline(text: str) -> str:
    """Escapes text and turns **bold** into <strong>."""
    text = html.escape(text, quote=False)
    return re.sub(r"\*\*(.+?)\*\*", r"<strong>\1</strong>", text)


def convert(md: str) -> str:
    """Converts the small Markdown subset docs/privacy.md uses into HTML."""
    out: list[str] = []
    para: list[str] = []
    items: list[str] = []

    def flush() -> None:
        if para:
            out.append("<p>" + inline(" ".join(para)) + "</p>")
            para.clear()
        if items:
            out.append("<ul>" + "".join("<li>" + inline(i) + "</li>" for i in items) + "</ul>")
            items.clear()

    for raw in md.splitlines():
        line = raw.strip()
        if not line:
            flush()
        elif line == "---":
            flush()
            out.append("<hr>")
        elif line.startswith("#"):
            flush()
            level = len(line) - len(line.lstrip("#"))
            title = line[level:].strip()
            out.append(f"<h{level}>{inline(title)}</h{level}>")
        elif line.startswith("- "):
            if para:
                flush()
            items.append(line[2:])
        elif items and raw.startswith("  "):
            items[-1] += " " + line
        else:
            para.append(line)
    flush()
    return "\n".join(out)


def main() -> int:
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(PAGE.format(body=convert(SRC.read_text(encoding="utf-8"))), encoding="utf-8")
    print(f"site_privacy: wrote {OUT.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
