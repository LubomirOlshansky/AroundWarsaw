# Music: Suno and ElevenLabs prompts

Prompts for the radio stations and the game's own music. **Start with "The beta radio"**; the sets after it are the first ideas for every station, made with Suno or ElevenLabs.
Each track has a **Title**, a **Style** field (at most 200 characters, checked), and **Lyrics**
(Polish where it fits, original, affectionate parody; no real artists, no brands). Paste Style into
"Style of Music", Lyrics into "Lyrics", and use "Instrumental" for the ones marked so.

Putting a song on the radio: save it as `data/raw/music/<station_id>/<name>.mp3` with a
`<name>.txt` sidecar (licence line, title, artist), then `python3 -I tools/add_music.py --station=<id>`
(see README "Adding music"). Aim for 1:30 to 3:00. Check the song tool's licence (a paid plan that
allows a published game) before a release. Stations: `nocna_fm` = KEBAB FM 87,3, `rondo_fm` = RONDO FM 86,6,
`mordor_fm` = MORDOR FM 108,8, `polnoc_fm` = PÓŁNOC FM 86,0.

Metatags in the lyrics (`[Verse]`, `[Chorus]`) are Suno syntax; keep them.

---

## The beta radio (F, 2026-11-02): KEBAB FM + MORDOR FM, instrumental only

The beta has two stations (`"lineup"` in `game/data/radio.json`; RONDO FM and PÓŁNOC FM are
hidden until it is removed): **KEBAB FM** plays vaporwave, **MORDOR FM** plays minimal techno.
**Music only, no words** (F, 2026-11-02): eight instrumental tracks each, no vocals, no
jingles, no voice clips. The vocal songs, idents and the announcer (`docs/design/sound.md`) wait
for later. Nothing names a station: the name is only on screen (the RADIO chip, the ticker).

**Tool.** ElevenLabs Creator (commercial licence; free plans are non-commercial and a free-plan
file stays that way after an upgrade). In Eleven Music paste the prompt as it is; each already
says "instrumental" and the length. Sidecar `.txt` licence line: `licence: ElevenLabs Creator,
commercial`.

**Adding them.** `data/raw/music/nocna_fm/` (KEBAB FM) or `data/raw/music/mordor_fm/` (MORDOR FM),
then `python3 -I tools/add_music.py --station=nocna_fm` (README "Adding music"). 64 kbps is
enough for both (about 0.5 MB a minute; set `"encode": {"kbps": 64}` on the station); on the Mac
`brew install vorbis-tools` first. Remove a station's old synth loop from radio.json once its
tracks are in.

### KEBAB FM 87,3: vaporwave (8 instrumentals)

Slowed 80s pop and mall funk, chopped textures, warm detuned synths, tape wobble, pink-and-cyan
Warsaw at sunset.

| # | Title | Eleven Music prompt |
| --- | --- | --- |
| KB1 | Palma de Gaulle'a | `Instrumental vaporwave, dreamy synth pop, slowed disco bassline, warm analog chords, sunset city, nostalgic, no vocals, 98 bpm, 2:15 long` |
| KB2 | Neon na Marszałkowskiej | `Instrumental future funk, filtered disco loop, slap bass, glossy synths, sidechained pads, neon night, no vocals, 112 bpm, 2:00 long` |
| KB3 | Pałac o zachodzie | `Instrumental vaporwave, slowed smooth jazz, lush reverb, soft saxophone, tape hiss, golden hour, dreamy, no vocals, 84 bpm, 2:00 long` |
| KB4 | Galeria 1995 | `Instrumental mallsoft, distant shopping mall ambience, muffled elevator music, fountain sounds, warm chords, nostalgic, no vocals, 78 bpm, 2:00 long` |
| KB5 | Sos czosnkowy | `Instrumental vaporwave, slowed and reverbed disco house, hazy brass stabs, handclaps, late night, cheeky groove, no vocals, 96 bpm, 2:00 long` |
| KB6 | Wisła w różu | `Instrumental chillwave, shimmering pads, gentle electric piano, slow drum machine, water reflections, pastel sunset, no vocals, 88 bpm, 2:00 long` |
| KB7 | Rondo w pamięci | `Instrumental vaporwave dream pop, chorus guitar, vintage drum machine, wistful summer night, washed-out synths, no vocals, 92 bpm, 2:15 long` |
| KB8 | 87,3 MHz | `Instrumental future funk, bright filtered disco loop, punchy kick, radio static effects, upbeat, no vocals, 118 bpm, 2:00 long` |

### MORDOR FM 108,8: minimal techno (8 instrumentals)

Dark, hypnotic minimal techno for the office towers at night: deep rolling kick, clicky hats,
metallic percussion, long filter sweeps. No artist names in prompts (the tools refuse them).

| # | Title | Eleven Music prompt |
| --- | --- | --- |
| MD1 | Open Space | `Instrumental minimal techno, hypnotic, deep rolling kick, clicky hi-hats, dark metallic percussion, slow filter sweep, no vocals, 128 bpm, 2:00 long` |
| MD2 | Spotkanie mogło być mailem | `Instrumental minimal techno, dark hypnotic groove, deep kick, glitchy percussion, office phone blips as texture, reverb, no vocals, 127 bpm, 2:00 long` |
| MD3 | Szklane biurowce | `Instrumental minimal techno, cold glassy synth stabs, sub bass, ticking hats, long reverb tails, night city towers, no vocals, 126 bpm, 2:00 long` |
| MD4 | Deadline | `Instrumental driving minimal techno, relentless kick, acid bassline slowly opening, tense, metallic clicks, no vocals, 130 bpm, 2:00 long` |
| MD5 | Winda na 30. piętro | `Instrumental minimal techno, hypnotic, elevator chime as texture, rolling bass, crisp percussion, no vocals, 125 bpm, 2:00 long` |
| MD6 | Służewiec 3:00 | `Instrumental deep minimal techno, dark, sparse, heavy sub kick, distant city texture, dub chords, hypnotic loop, no vocals, 124 bpm, 2:00 long` |
| MD7 | Arkusz | `Instrumental minimal techno, glitchy clicks like keyboard typing, tight groove, rubbery bass, dry percussion, playful, no vocals, 127 bpm, 2:00 long` |
| MD8 | Fajrant | `Instrumental melodic minimal techno, warm rising pads, rolling bassline, euphoric slow build and release, after work, no vocals, 126 bpm, 2:00 long` |

About 33 minutes in all, about 16 MB in the game at 64 kbps.

## KEBAB FM 87,3 (pink; vaporwave, Palm, kebab, summer in the city)

### K1 · Palma de Gaulle'a (full version)
**Style:** `vaporwave, dreamy synth pop, slowed disco bassline, female vocal, warm analog chords, sunset city, nostalgic, 98 bpm, polish`

```
[Verse]
Rondo, gorący beton, wieczór jak karmel,
palma na środku świata, plastikowy cud.
Kebab w papierze parzy mi palce,
a miasto mruga neonem: "jeszcze tu bądź".

[Chorus]
Palma de Gaulle'a, Palma de Gaulle'a,
nikt nie wie skąd, a każdy wie gdzie.
Palma de Gaulle'a, Palma de Gaulle'a,
zimą bez liści, latem w moim śnie.
```

### K2 · Sos czosnkowy
**Style:** `funky disco house, slap bass, handclaps, bright brass stabs, party vocal duet, cheeky, 118 bpm, polish`

```
[Verse]
Biała czy ostra? Pytanie jak życie,
pan za ladą kroi, ja stoję w kolejce.
Druga w nocy, a my świętujemy
mały cud: jedzenie na ulicy.

[Chorus]
Sos czosnkowy, sos czosnkowy,
zawsze za mało, nigdy dosyć!
Sos czosnkowy, sos czosnkowy,
jutro wszyscy będą się kłócić o to, kto prosił.
```

### K3 · Kebab o trzeciej (instrumental)
**Style:** `instrumental, lo-fi house, dusty drum machine, warm Rhodes, vinyl crackle, late night, mellow groove, 104 bpm`

Instrumental (no lyrics). Leave the Lyrics field empty or write `[Instrumental]`.

### K4 · Jingle KEBAB FM (10 to 15 s)
**Style:** `radio jingle, retro synth fanfare, bright vocal chop, fast, cheerful, short stinger, 120 bpm, polish`

```
[Intro]
Dzień dobry, Warszawo!
Pachnie całe miasto, gdy gramy my!
```

---

## RONDO FM 86,6 (cyan; the roundabout at 3 AM, cool synthwave)

### R1 · Rondo Dmowskiego 3 A.M. (full version)
**Style:** `synthwave, night drive, arpeggiated synths, gated reverb drums, cold neon mood, male whisper vocal, 100 bpm, polish`

```
[Verse]
Trzecia nad ranem, światła w kółko,
czterdzieści pasów, jedno marzenie.
Taksówka z pustym wnętrzem czeka,
na rondzie nikt nie wie, kto ma pierwszeństwo.

[Chorus]
Kręcę się wokół, wokół, wokół,
Rondo, Rondo, trzecia w nocy.
Wszystkie drogi wiodą tu,
nikt nie wie, w którą stronę wyjść.
```

### R2 · Zielone na skrzyżowaniu
**Style:** `dark synth pop, pulsing bass, crisp snare, airy female vocal, melancholic, urban, 112 bpm, polish`

```
[Verse]
Czerwone, żółte, zielone, znowu czerwone,
w oknie autobusu moja twarz.
Mijam ten sam billboard trzeci raz,
a miasto śpi, jak gdyby nic się nie stało.

[Chorus]
Zielone na skrzyżowaniu,
jedź, zanim zgaśnie.
Zielone na skrzyżowaniu,
ktoś na mnie czeka, a ja nie wiem kto.
```

### R3 · Nocny autobus (instrumental)
**Style:** `instrumental, chillwave, shimmering pads, soft side-chained bass, tape wobble, rainy window, dreamy, 90 bpm`

Instrumental.

---

## MORDOR FM 108,8 (violet; the office district, corporate muzak with a wink)

### M1 · Mordor Mall Muzak (full version)
**Style:** `elevator muzak, smooth jazz, soft saxophone, mellow electric piano, brushed drums, shopping mall, corporate chill, 84 bpm`

Instrumental, then a spoken announcement mid-song. Put it in the Lyrics field:

```
[Spoken, calm announcer voice]
Szanowni Państwo, na parterze trwa wyprzedaż. Przypominamy, że spotkanie o dziewiątej
mogło być mailem. Dziękujemy za wspólne synergie.
```

### M2 · Stand-up o ósmej
**Style:** `corporate pop rock, upbeat, clean guitar, cheerful claps, motivational chorus, ironic, 124 bpm, male and female vocal, polish`

```
[Verse]
Poniedziałek, ósma rano, kawa w kubku z logo,
nowy sprint, stary stres, tablica pełna karteczek.
Dzień dobry, jestem na mute, słychać mnie?
Ktoś udostępnia ekran, ale nie ten co trzeba.

[Chorus]
Stand-up o ósmej, stand-up o ósmej,
krótko, treściwie, ale trwa godzinę!
Stand-up o ósmej, stand-up o ósmej,
wrócę do tego w piątek, lub nie wrócę wcale.
```

### M3 · Open space blues
**Style:** `bluesy lounge, slow shuffle, warm hammond organ, brushed snare, tired baritone vocal, deadpan, 76 bpm, polish`

```
[Verse]
Trzydzieste piętro, widok na Mordor,
na biurku kaktus, który jeszcze żyje.
Klimatyzacja szumi jak morze,
a ja liczę godziny do piątku.

[Chorus]
Open space blues, open space blues,
dwa tysiące ludzi i nikt nie ma długopisu.
```

---

## PÓŁNOC FM 86,0 (amber; the night station, the Wisła and the dawn)

Seven tracks already ship (synthesised). These are vocal or fuller replacements for the same
titles; keep the file name if one is swapped in.

### P1 · Sód
**Style:** `ambient electronica, warm sodium-lamp mood, slow pulsing synth, soft glitch percussion, hushed female vocal, 80 bpm`

```
[Verse]
Latarnie zapalają się jedna po drugiej,
miasto zmienia kolor na bursztyn.
Idę po mokrym asfalcie, bez celu,
a każdy cień ma swój własny adres.
```

### P2 · Wiadukt
**Style:** `post-rock, slow build, reverb guitar, steady toms, train rumble, cinematic, night, instrumental, 92 bpm`

Instrumental.

### P3 · Nocna przesiadka
**Style:** `downtempo, deep house, rolling bassline, quiet claps, sleepy male vocal, empty tram stop, 106 bpm, polish`

```
[Verse]
Przesiadka o pierwszej, peron pusty,
tablica mówi: "tramwaj za dwie minuty",
od godziny. Zimny wiatr, ciepła herbata,
kto jedzie nocą, ten wie, co to ma znaczyć.
```

### P4 · Szkło na Woli
**Style:** `dream pop, glassy bells, shimmering guitar, soft four-on-the-floor, breathy vocal, skyscrapers at night, 110 bpm, polish`

```
[Verse]
Szkło na Woli odbija pół nieba,
każde okno to ktoś, kto jeszcze nie śpi.
Winda jedzie w górę po nic,
a światło liczy piętra za mnie.
```

### P5 · Bulwar 23:40
**Style:** `chillout, nu-jazz, upright bass, soft trumpet, river breeze, brushed drums, warm and slow, instrumental, 88 bpm`

Instrumental.

### P6 · Mgła nad Pałacem
**Style:** `ambient drone, deep pads, distant bell, slow swell, ethereal choir, fog, cinematic, instrumental, 60 bpm`

Instrumental.

### P7 · Świt na Smolnej
**Style:** `uplifting indie electronic, sunrise build, bright piano, soft kick, hopeful female vocal, first tram, 118 bpm, polish`

```
[Verse]
Pierwszy tramwaj dzwoni jak budzik,
niebo robi się różowo-szare.
Nie spałem całą noc, a mimo to
mam wrażenie, że wszystko się dopiero zaczyna.

[Chorus]
Świt na Smolnej, świt na Smolnej,
pachnie świeżą bułką i deszczem.
```

---

## The game's own music

### G1 · Title screen: Around Warsaw (full version)
**Style:** `vaporwave, retro synth pop, chrome pads, warm bass, dreamy female vocal, sunset skyline, hopeful, 100 bpm, english and polish`

```
[Verse]
Pałac na horyzoncie, neon na asfalcie,
gaz do dechy, miasto czeka.
Drive, fly and discover,
prawdziwa Warszawa, ta sama co zawsze.

[Chorus]
Around Warsaw, around Warsaw,
w kółko, dookoła, jeszcze raz.
Around Warsaw, around Warsaw,
nikt nie wraca taki sam.
```

### G2 · Police chase (instrumental, loops)
**Style:** `instrumental, driving electro rock, fast breakbeat, distorted bass, siren-like synth leads, playful tension, loopable, 150 bpm`

Instrumental, aim for a clean loop. The police are the gentle kind (warnings and jokes), so keep it playful, not grim.

### G3 · Helicopter ride (instrumental)
**Style:** `instrumental, cinematic orchestral electronic, soaring strings, steady pulse, aerial view, wonder, optimistic, 96 bpm`

### G4 · Race (instrumental, loops)
**Style:** `instrumental, high-energy drum and bass, rolling bass, tight snares, tense synth stabs, street race, loopable, 172 bpm`

### G5 · Delivery job (instrumental, loops)
**Style:** `instrumental, upbeat funk, wah guitar, bouncy bass, light percussion, busy city courier, playful, loopable, 112 bpm`

### G6 · Mission done sting (5 s)
**Style:** `instrumental, short victory sting, bright synth fanfare, playful, 5 seconds, resolves on a major chord`

---

## Notes

- Suno gives two versions per prompt: take both, keep the better one, and note the pick in the
  sidecar `.txt`.
- No real artists, no brands in prompts or lyrics (Bank Pekao is never named).
- Polish lyrics: check the stress and the diacritics after generation; regenerate a line if
  Suno mispronounces it.
