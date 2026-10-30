# Store screenshots

Seven in-game screenshots with the HUD on, for the App Store and Google Play beta listings.
Rendered on 2026-10-30 with the radio station named KEBAB FM, saved as JPEG (quality 90,
sRGB, no alpha).

| Folder | Size | For |
| --- | --- | --- |
| `appstore-iphone-6.9/` | 2868 × 1320 | App Store, iPhone 6.9" |
| `appstore-ipad-13/` | 2752 × 2064 | App Store, iPad 13" |
| `play-phone/` | 1920 × 1080 | Google Play, phone |

## How they were made

Every shot is one run of the game from `game/`, with each screen size passed as its own
`--resolution` so the HUD lays out for that screen:

```zsh
godot --path . --resolution WxH --fixed-fps 60 --quit-after <last frame + 660> \
  -- --nosave --free --notitle --traffic=busy --shots=F1,F2,F3 --out=DIR <flags below>
```

Each run saved three frames, and the cleanest one was kept (the car moving where it could,
speech bubbles fully typed). The iPad set was rendered at 2440 × 1830 (4:3; a taller window
doesn't fit the Mac's screen) and scaled up to 2752 × 2064 (Lanczos).

**Which city:** shots 01–06 come from `main` (commit 5137c54, the runtime city). Shot 07
comes from the bigger demo map (loop 3d-1's 18.6 km² box, not yet on `main`): on `main`'s
map Varso Tower stands about 140 m from the west edge, so any framing that fits its crown
shows the edge of the map. That copy of the game had only the KEBAB FM name applied.

| # | File | Frame kept (iPhone / iPad / Play) | Flags | What it shows |
| --- | --- | --- | --- | --- |
| 01 | `01-palace-dusk.jpg` | 480 / 480 / 480 | `--at=-1384,250 --heading=0 --demo --yaw=90 --size=180 --time=dusk` | Driving up Marszałkowska at 43 km/h past the floodlit Palace of Culture at dusk |
| 02 | `02-rotunda-rain-night.jpg` | 300 / 300 / 300 | `--at=-837,427 --heading=90 --demo --yaw=0 --size=85 --time=night --weather=rain` | Rondo Dmowskiego in the rain at night: the glowing Rotunda, the KEBAB 24H sign, a driver's quip |
| 03 | `03-heli-vistula.jpg` | 600 / 600 / 600 | `--heli --at=1000,-180 --yaw=20 --size=70 --time=day` | The helicopter hovering over the Vistula by Most Poniatowskiego, with its altitude and up/down controls |
| 04 | `04-kebab-job.jpg` | 840 / 840 / 840 | `--kebab=3 --autopilot --time=night --size=90` | A night kebab delivery under way: the order card with its heat bar, distance and the orange beacon |
| 05 | `05-police-talk.jpg` (iPhone, Play) | 720 / – / 720 | `--pullover=routine --pullover-frame=600 --time=day --size=60` | A routine police pull-over by day, the sergeant's line in Polish and English |
| 05 | `05-ride-day.jpg` (iPad) | – / 600 / – | `--ride=1 --autopilot --time=day --size=80` | A Podwózka ride under way at 30 km/h: the ride card with the rating, the distance and the teal beacon |
| 06 | `06-narodowy-night.jpg` | 300 / 330 / 300 | `--at=1249,-568 --heading=0 --demo --yaw=300 --size=260 --time=night` | Driving along Wybrzeże Szczecińskie past Stadion Narodowy, lit red and white at night |
| 07 | `07-varso-dusk.jpg` | 360 / 360 / 360 | `--at=-1501,649 --yaw=270 --size=380 --time=dusk` (bigger map) | Varso Tower, crown in frame, with Złote Tarasy and Aleje Jerozolimskie at sunset |

The iPad's fifth shot is the Podwózka ride, because the police pull-over's dialogue panel
doesn't appear at a 4:3 screen (see BACKLOG). The car stands still in 03 (the helicopter
hovers), 05-police-talk (pulled over) and 07 (every moving take of Varso lost the crown or
the framing). Traffic speech bubbles are random, so each size shows a different line.
