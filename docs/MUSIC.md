# Music: Suno prompts

Prompts for the radio stations and the game's own music, made with Suno (or any song tool).
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
Kebab FM! Osiemdziesiąt siedem przecinek trzy!
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
