---
name: warsaw-tone
description: The humour, parody and language rules for every word and joke in Around Warsaw (dialogue lines, radio host, signs, posters, billboards, job and mission cards, police lines, rival names, HUD labels), in Polish with English, and the format of game/data/dialogue.json. Use whenever writing or reviewing on-screen text, jokes, characters, parody brands or anything that names a real place, business or person.
---

# Warsaw tone

## The rules (hard)

1. **Original** writing only: no copied memes, songs, lyrics, slogans or catchphrases.
2. **Real places are welcome** (streets, squares, landmarks, districts, Mordor as the
   nickname for the Służewiec offices). **Real businesses, brands, stations, apps, sponsors
   and venues are not**, by name, logo or look. They appear only as **parodies** with
   invented names and marks: the frog-green 24h corner shop, the app-taxi that follows its
   GPS blindly, the square-backpack delivery riders, the dumped e-scooters. A parody must not
   be mistakable for the real one (name, logo shape, colours together).
3. **Affectionate**, about the city and its stereotypes (roadworks, Rondo Dmowskiego's jams,
   słoiki, Mordor commuters, pigeons, the Palm, kebab at 3 a.m., rents), never punching down,
   **never about real private people**; no politicians or public figures by name; no slurs,
   no jokes about religion, nationality or disability.
4. **Family-friendly**: police and city guards are human and funny, never violent; fines,
   chases you can escape, a funny line.
5. **Invented people only**: rival names are types ("Seba z Pragi", "Pani Halina",
   "Taksiarz Zbyszek"), customers and rescue callers get invented first names.
   Radio frequencies stay off real stations' frequencies.

## Language

- Every on-screen line exists in **Polish with English**. In the HUD and cards: Polish above,
  English below (smaller). In the world (signs, posters, billboards, neon): Polish only,
  UPPERCASE, in the 5×7 pixel font (`pixel_font.gd`); the English gloss lives in the data.
- Polish: spoken Warsaw register, short, punchline last ("Kompot. Był."). Correct diacritics
  always (ą ć ę ł ń ó ś ź ż); Polish quotes „…”. Numbers Polish style in Polish
  (87,3; 3999 zł), English style in English (87.3; 3,999 zł).
- English: a natural gloss that lands the joke, not a word-for-word translation; keep Polish
  words that are the joke (słoiki, Mordor, kebab) and gloss them once if needed.
- Lengths: a bubble line under ~70 characters; a column poster is at most **four lines of
  eight letters** (`{"poster": [...]}`); a neon or shop word fits the sign (generic words:
  KEBAB 24H, BAR MLECZNY, APTEKA, KWIATY, HOTEL, KANTOR).

## game/data/dialogue.json

Groups of lines, each `[Polish, English]` with an optional third element of notes:
`{"only": tag or [tags]}` limits a line to a situation (kebab orders: `powisle`, `praga`,
`office`; rescues: `roof`, `street`, `river`, `child`, `square`; słoiki: `all`, `some`),
`{"customer": name}`, `{"poster": [lines]}`. Read the file's `_about` and the group you are
adding to; match its voice; avoid repeating a joke already in the file (grep for the key word).

Examples of the voice (already in the game):
- "Mieszkam na Mokotowie, pracuję w Mordorze, a żyję w korku." / "I live in Mokotów, work in
  Mordor, and actually live in traffic."
- "REMONT MARSZAŁKOWSKIEJ · ETAP 47 Z 312" / "MARSZAŁKOWSKA ROADWORKS · PHASE 47 OF 312"

## Check before you hand it in

- [ ] No real brand, business, app, station or person; every parody clearly invented.
- [ ] Polish diacritics correct; English gloss present and natural.
- [ ] Fits its space (bubble, poster 4×8, sign) in the pixel font; checked in a screenshot
      when it is in the world.
- [ ] Not a repeat of a line already in `dialogue.json`.
- [ ] A Polish speaker would smile, not wince (when unsure, give the user two options).
