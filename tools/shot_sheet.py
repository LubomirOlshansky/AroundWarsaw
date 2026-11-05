"""Before/after review sheet: every shot of two screenshot folders side by side in one page.

Usage: python3 -I tools/shot_sheet.py BEFORE_DIR AFTER_DIR [--out sheet.html] [--title TEXT]

The workflow (docs/WORKFLOW.md "Review sheet"): a look change takes the same fixed cameras
before and after, with tools/shots.sh (same --set, same --size, `--tag=before` / `--tag=after`,
or two --out folders), then this script lines the shots up by name. The PR shows ONE sheet, and
F picks from it instead of asking for single shots. Shots are matched by file name without the
`_before` / `_after` tag; a shot that exists in one folder only is listed as missing on the other
side. The page references the PNGs by path (it is written next to the AFTER folder by default,
so open it from there); nothing is copied. Standard library only.
"""
import html
import os
import re
import sys


def key(name):
    return re.sub(r'[_-](before|after)(?=\.)', '', name)


def pngs(d):
    return {key(f): f for f in sorted(os.listdir(d)) if f.lower().endswith('.png')}


def main(argv):
    args = [a for a in argv if not a.startswith('--')]
    opts = {}
    for i, a in enumerate(argv):
        if a in ('--out', '--title') and i + 1 < len(argv):
            opts[a] = argv[i + 1]
            args = [x for x in args if x != argv[i + 1]]
    if len(args) != 2:
        print(__doc__)
        return 2
    before, after = (os.path.abspath(a) for a in args)
    out = os.path.abspath(opts.get('--out') or os.path.join(after, 'sheet.html'))
    base = os.path.dirname(out)
    b, a = pngs(before), pngs(after)
    cells = []
    for k in sorted(set(b) | set(a)):
        def cell(d, m):
            if k not in m:
                return '<div class="miss">missing</div>'
            return '<a href="%s"><img loading="lazy" src="%s"></a>' % (
                html.escape(os.path.relpath(os.path.join(d, m[k]), base)),
                html.escape(os.path.relpath(os.path.join(d, m[k]), base)))
        cells.append('<h3>%s</h3><div class="pair"><figure>%s<figcaption>before</figcaption></figure>'
                     '<figure>%s<figcaption>after</figcaption></figure></div>' % (html.escape(k), cell(before, b), cell(after, a)))
    title = html.escape(opts.get('--title') or 'Before / after')
    page = ('<!doctype html><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">'
            '<title>%s</title><style>body{font:14px system-ui;margin:16px;background:#14171c;color:#e8eaee}'
            '.pair{display:grid;grid-template-columns:1fr 1fr;gap:8px}img{width:100%%;display:block}'
            'figcaption{color:#8f97a3;font-size:12px}.miss{padding:40px;border:1px dashed #555;text-align:center}'
            'figure{margin:0}h3{margin:20px 0 6px}@media(max-width:700px){.pair{grid-template-columns:1fr}}</style>'
            '<h1>%s</h1>%s' % (title, title, ''.join(cells)))
    with open(out, 'w', encoding='utf-8') as f:
        f.write(page)
    print('shot_sheet: %d shots (%d before, %d after) -> %s' % (len(set(b) | set(a)), len(b), len(a), out))
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
