"""Build the website's pages: the landing in English and Polish, the privacy and support pages.

Usage: python3 -I tools/site_build.py

Writes site/public/index.html (English, the default) and site/public/pl/index.html from the
template site/src/index.html and the copy in site/src/strings.json ({{key}} placeholders;
the screenshot reel, the list of things to do and the form's topics are built here), and
site/public/privacy/index.html from docs/privacy.md, so the policy the stores link to
(https://aroundwarsaw.app/privacy/) always says what that file says, and
site/public/support/index.html from docs/support.md (the stores' support URL), and
site/public/progress/index.html, the day-by-day changelog (tools/changelog.py: docs/CHANGELOG.md and
ROADMAP's progress log). The Markdown
converter knows only what those files use: #/## headings, paragraphs, "- " lists, **bold**,
[links](url), "---".
"""

import html
import importlib.util
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SITE = ROOT / "site"
# Copy that carries its own markup (links, separators); everything else is escaped.
RAW_KEYS = {"f_legal", "radio_lines"}  # the author paragraphs are raw too (a link)

PAGE = """<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{title} · Around Warsaw</title>
<meta name="description" content="{description}">
<link rel="icon" href="/favicon.svg" type="image/svg+xml">
<link rel="stylesheet" href="/styles.css">
</head>
<body class="doc">
<header class="bar"><div class="bar-in"><a class="brand" href="/"><img src="/favicon.svg" alt="" width="28" height="28">Around Warsaw</a></div></header>
<main class="prose">
{body}
{extra}<p><a href="https://github.com/LubomirOlshansky/AroundWarsaw/issues">GitHub issues</a> · <a href="/">← aroundwarsaw.app</a></p>
</main>
</body>
</html>
"""

# The privacy page's part about the site itself (docs/privacy.md is about the game).
PRIVACY_SITE = """<h2>This website · Ta strona</h2>
<p>aroundwarsaw.app sets no cookies and runs no analytics or trackers. It is served by
Cloudflare, which handles ordinary request data (such as IP addresses) only to deliver and
protect the site. The beta and feedback form sends what you type (your email, phone type and
message) through Formspree to the developer's inbox. The email is used only to send a beta
invite or to reply, and is deleted on request (write on Telegram, @olshansky93, or through the
same form).</p>
<p>aroundwarsaw.app nie używa ciasteczek, analityki ani śledzenia. Stronę serwuje Cloudflare,
który przetwarza zwykłe dane żądań (np. adresy IP) wyłącznie po to, by ją dostarczyć i chronić.
Formularz bety i opinii wysyła to, co wpiszesz (e-mail, rodzaj telefonu, wiadomość), przez
Formspree do skrzynki autora. E-mail służy tylko do wysłania zaproszenia do bety albo
odpowiedzi i zostanie usunięty na prośbę (napisz na Telegramie, @olshansky93, albo przez ten
sam formularz).</p>
"""


def inline(text: str) -> str:
    """Escapes text and turns **bold** into <strong> and [text](url) into a link."""
    text = html.escape(text, quote=False)
    text = re.sub(r"\[(.+?)\]\((\S+?)\)", r'<a href="\2">\1</a>', text)
    return re.sub(r"\*\*(.+?)\*\*", r"<strong>\1</strong>", text)


def convert(md: str) -> str:
    """Converts the small Markdown subset docs/privacy.md and docs/support.md use into HTML."""
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


def fill(template: str, values: dict[str, str]) -> str:
    """Replaces every {{key}}; a key with no value is an error, so no placeholder ships."""

    def one(m: re.Match[str]) -> str:
        key = m.group(1)
        if key not in values:
            raise KeyError(f"site/src/index.html uses {{{{{key}}}}} but strings.json has no value")
        return values[key]

    return re.sub(r"\{\{(\w+)\}\}", one, template)


def landing(strings: dict, lang: str) -> str:
    """The landing page in one language."""
    values = {k: (v if k in RAW_KEYS else html.escape(v)) for k, v in strings[lang].items()}
    values["hero"] = strings["hero"]
    def pic(name: str, w: int, h: int, alt: str) -> str:
        return (f'<picture><source media="(max-width: 700px)" srcset="/img/game/{name}-960.webp">'
                f'<img src="/img/game/{name}.webp" alt="{alt}" width="{w}" height="{h}" loading="lazy" decoding="async"></picture>')

    # The city: a mosaic; each shot's "span" (wide, half, lead) sets its place in the grid.
    figs = []
    for shot in strings["reel"]:
        title, line, alt = (html.escape(t) for t in shot[lang])
        figs.append(
            f'    <figure class="tile tile-{shot.get("span", "half")}">\n'
            f'      {pic(shot["img"], shot["w"], shot["h"], alt)}\n'
            f"      <figcaption><h3>{title}</h3><p>{line}</p></figcaption>\n"
            f"    </figure>")
    values["reel"] = "\n".join(figs)
    # Missions: three short tiles (shot, title, one line).
    values["missions"] = "\n".join(
        f'    <figure class="tile">\n      {pic(m["img"], 1920, 887, html.escape(m[lang][2]))}\n'
        f"      <figcaption><h3>{html.escape(m[lang][0])}</h3><p>{html.escape(m[lang][1])}</p></figcaption>\n    </figure>"
        for m in strings["missions"])
    values["small"] = "\n".join(
        f'    <figure class="tile">\n      {pic(m["img"], m["w"], m["h"], html.escape(m[lang][2]))}\n'
        f"      <figcaption><h3>{html.escape(m[lang][0])}</h3><p>{html.escape(m[lang][1])}</p></figcaption>\n    </figure>"
        for m in strings["small"])
    values["timeline"] = "\n".join(
        f"      <li><time>{html.escape(d.replace("Oct", "paź") if lang == "pl" else d)}</time><p>{html.escape(txt[lang])}</p></li>" for d, txt in strings["timeline"])
    values["author_body"] = "\n".join(f"      <p>{p}</p>" for p in strings["author"][lang])
    values["topics"] = "\n".join(
        f'        <label><input type="radio" name="topic" value="{html.escape(v)}"{" checked" if i == 0 else ""}>'
        f"<span>{html.escape(t)}</span></label>"
        for i, (v, t) in enumerate(strings["topics"][lang]))
    return fill((SITE / "src" / "index.html").read_text(encoding="utf-8"), values)


def changelog():
    """tools/changelog.py (imported by path: `python3 -I` leaves the tools folder off sys.path)."""
    spec = importlib.util.spec_from_file_location("changelog", ROOT / "tools" / "changelog.py")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def progress_page() -> str:
    """/progress/: what was added or improved each day, from docs/CHANGELOG.md and ROADMAP's log."""
    cl = changelog()
    intro = (
        "<h1>Progress · Postępy</h1>\n"
        "<p>What was added or improved in Around Warsaw, day by day, newest first. "
        "Co dodano albo poprawiono, dzień po dniu.</p>\n"
        f'<p class="links"><a href="{cl.BACKLOG_URL}">The backlog: known issues and what\'s next</a> '
        f'<a href="{cl.ROADMAP_URL}">The full progress log</a></p>\n')
    return PAGE.format(title="Progress · Postępy", extra="",
                       description="What's new in Around Warsaw, day by day: what was added or improved, and the backlog.",
                       body=intro + cl.html_days())


def main() -> int:
    strings = json.loads((SITE / "src" / "strings.json").read_text(encoding="utf-8"))
    pages = {
        SITE / "public" / "index.html": landing(strings, "en"),
        SITE / "public" / "pl" / "index.html": landing(strings, "pl"),
        SITE / "public" / "privacy" / "index.html": PAGE.format(
            title="Privacy", extra=PRIVACY_SITE,
            description="Around Warsaw collects no personal data. Privacy policy for the game and this website.",
            body=convert((ROOT / "docs" / "privacy.md").read_text(encoding="utf-8"))),
        SITE / "public" / "support" / "index.html": PAGE.format(
            title="Support · Pomoc", extra="",
            description="Help with Around Warsaw and its beta: contact, TestFlight and Google Play testing, common questions.",
            body=convert((ROOT / "docs" / "support.md").read_text(encoding="utf-8"))),
        SITE / "public" / "progress" / "index.html": progress_page(),
    }
    for path, text in pages.items():
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text, encoding="utf-8")
        print(f"site_build: wrote {path.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
