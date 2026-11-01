# Packs: running clubs, cycling packs, coffee raves, big guys with tiny dogs

F's ask (2026-11-01): running clubs jogging through the streets in big groups, cycling clubs riding
round in packs with meme lines about their gear (Canyon, Cervélo, Garmin, Strava: as parodies),
coffee raves outside some cafés with people dancing, and dog walkers like big guys with tiny dogs,
all with jokes. Built in `game/scripts/packs.gd` (new) and `city_life.gd` (the dogs); checked by
`game/tools/check_packs.gd` (verify step `packs`, CI too).

## What the player sees

| Who | Where | When (game clock) | How many |
| --- | --- | --- | --- |
| **TEMPO NA KAWĘ** (Pace for Coffee), coral kit | Plac Zbawiciela → Plac Trzech Krzyży → Nowy Świat, out and back on the pavements (6.9 km) | Mon-Fri 06:30-09:30, 17:30-21:00; Sat-Sun 08:00-11:00 | 24 |
| **KILOMETRY I KRUASANY** (Kilometres and Croissants), lilac | the boulevards, Kopernik → Podzamcze fountains (5.2 km) | daily 07:00-10:00, 12:00-14:30, 18:00-21:00 | 20 |
| **NOGI Z MORDORU** (Legs from Mordor), electric blue | Plac Defilad → Ogród Saski → Krakowskie Przedmieście (4.4 km) | Mon-Fri 12:00-14:30 (the lunch run), 17:00-20:30; Sat 09:00-11:00 | 28 |
| **KARBONOWE KOLANA** (Carbon Knees), road riders | the boulevards' cycle path, Most Poniatowskiego → Most Śląsko-Dąbrowski (4.4 km) | Mon-Fri 13:00-16:00, 17:30-20:00; Sat-Sun 07:00-11:00 | 12 |
| **WATY I LATTE** (Watts and Lattes), road riders | Rondo ONZ → Plac Zbawiciela on the Marszałkowska cycle paths (5.8 km) | daily 11:00-16:00; Sat-Sun 08:00-11:00 too | 10 |
| **Coffee raves** (KAWOWY RAVE) | outside a COFFEECHAIR café: one a weekday, two at a weekend, rotating over the five | Mon-Fri 08:00-15:00 (14 dancers), Sat-Sun 09:00-15:00 (24) | DJ Espresso + dancers |
| **Big guys with tiny dogs** | a third of the dog walkers, wherever dogs are walked | the dogs' hours, now with a lunchtime walk 12:30-14:30 | ~35 % of walkers |

KOLKA (Wednesdays 19:00 on the boulevards, city_life.gd) stays the boulevards' own running club.
The fixed Day look (Friday 14:00) has two running clubs, both cycling packs and one rave out, so a
plain run of the game meets them; the Night look has none of them (the night belongs to the clubs).

- **Runners** run three abreast in rows 1.15 m apart, mostly in the club's colour, with a running
  stride and a little bounce, ~3 m/s. **Riders** ride two abreast 2 m apart on our own carbon road
  bike shapes (a drop-bar bike with a round helmet, a time-trial bike with a disc wheel and an aero
  helmet), ~7 m/s, on the cycle paths (the footways cost 2.5× a metre, used only where the cycle
  paths don't join up: 58 % and 92 % cycle path).
- **A rave**: a trestle table with two decks and a laptop, two speakers, a lit KAWOWY RAVE board on
  two posts and a string of party lights, on the pavement by the café's wall facing the street;
  DJ Espresso behind it, dancers round it bouncing on the beat (120 bpm) and swaying.
- **A big guy**: broader and taller (1.32 × 1.1), a dark tracksuit; his dog the fluffy shape at
  0.42 of the walkers' dogs, in a pale coat.

## The jokes (data/dialogue.json)

- `run_club` (16): Szpan ("If it's not on Szpan, the run never happened"), the Garnek watch, the
  group photo before the run, carbon-plate shoes, run club as a dating app, Mordor till five.
  `car` lines when the car is close behind the pack.
- `peleton` (18): the Wąwóz that weighs 6.8 kg, the Cegła Aero that slices the wind like a brick,
  the carbon loan, the coffee stop as training, Szpan segments, the Specjał a granny on a Rowerilo
  overtook. `car` lines when the car drafts them.
- `coffee_rave` (17): oat milk at 128 bpm and zero hangover, a barista instead of a bouncer, prams
  with ear defenders; DJ Espresso's `dj` lines to a slow car ("Honking in time? I'll sample you!").
- `dog_walkers` `tiny` (7): "This isn't my dog. I'm his bodyguard", Titan who weighs two kilos.
- A toast the first time the car meets a club ("Klub biegowy TEMPO NA KAWĘ / Running club: PACE
  FOR COFFEE") or a rave.

**Parody names** (warsaw-tone: never the real brand): **WĄWÓZ** (a gorge, for Canyon), **CEGŁA**
(a brick, for Cervélo: F's "cegera"), **SPECJAŁ** (a delicacy, for Specialized), the **GARNEK**
watch (a pot, for Garmin), the **SZPAN** app (showing off, for Strava). The real names are in
`brand_denylist.json`, so the checks fail if one slips into a line.

## How it works (packs.gd)

- Routes: for each club, A* over the map's footways and crossings (riders: cycle paths, footways
  dearer) between its `via` points, then the same way back, so a pack loops without turning in
  place. The map's footways often meet a crossing mid-segment, so any two corners of different
  paths within 4 m are joined (7 m when a leg isn't found), and a leg's ends are picked on one
  connected part. Found once in a worker thread at setup (~1.2 s of work for the five).
- A pack's head runs along the loop by the clock; each member is a fixed distance behind and to
  the side. Nothing is simulated far away: a pack within 420 m of the view is drawn and moved at
  15 Hz, a rave at 10 Hz; otherwise only the 2 Hz tick runs.
- Drawing: the runners one MultiMesh (the pedestrians' person mesh, a faster leg swing), the riders
  one (the roadie family, 168 triangles), the dancers one, one booth mesh per rave shown only near
  it: +1 to +3 draw calls near a pack or rave, +0 elsewhere. No shadows, no collisions (like the
  dawn crowd; packs stay on the pavements and cycle paths).
- Flags: `--packs=0` (none; `--crowd=0` too), `--packs-now` (every club and every café's rave on
  whatever the clock says, the packs whose loop passes within 300 m of the car timed to stream
  past it a few seconds in: for shots), `--packs-log`.

## Open (parked defaults)

- Packs don't react to the car (no swerving, no bump): the dawn crowd's rule. A collision or a
  "make way" behaviour is a follow-up if F wants it.
- No music at the raves yet (a thump from the booth through sfx.gd's positional voices would
  fit), no notebook card or egg for them, no radio mention.
- Rave days rotate over the five cafés by weekday; real coffee raves are mostly Sunday mornings.
- Only the phone can show whether the packs read at the default zoom and the cost on the device.
