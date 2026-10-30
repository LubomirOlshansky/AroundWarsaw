# Store screenshots

Seven in-game screenshots with the HUD on, for the App Store and Google Play beta listings.
Rendered from the runtime city on 2026-10-30, saved as JPEG (quality 90, sRGB, no alpha).

| Folder | Size | For |
| --- | --- | --- |
| `appstore-iphone-6.9/` | 2868 × 1320 | App Store, iPhone 6.9" |
| `appstore-ipad-13/` | 2752 × 2064 | App Store, iPad 13" |
| `play-phone/` | 1920 × 1080 | Google Play, phone |

## How they were made

Every shot is one run of the game from `game/`, with each screen size passed as its own
`--resolution` so the HUD lays out for that screen:

```zsh
godot --path . --resolution WxH --fixed-fps 60 --quit-after <F+660> \
  -- --nosave --free --notitle --traffic=busy --shots=F --out=DIR <flags below>
```

The iPad set was rendered at 2440 × 1830 (4:3; a taller window doesn't fit this Mac's
screen) and scaled up to 2752 × 2064 (Lanczos). Night runs sometimes quit without saving
the shot, so a run was retried until it saved (see BACKLOG).

| # | File | Frame `F` | Flags | What it shows |
| --- | --- | --- | --- | --- |
| 01 | `01-palace-dusk.jpg` | 600 (Play: 690) | `--at=-1410,159 --yaw=90 --size=150 --time=dusk` (iPad: `--size=200`, frame 690) | Driving past the floodlit Palace of Culture at dusk, a driver shouting in a speech bubble |
| 02 | `02-rotunda-rain-night.jpg` | 420 | `--at=-837,427 --yaw=0 --size=85 --time=night --weather=rain` | Rondo Dmowskiego in the rain at night: the glowing Rotunda and the KEBAB 24H neon |
| 03 | `03-heli-vistula.jpg` | 600 | `--heli --at=1000,-180 --yaw=20 --size=70 --time=day` | The helicopter over the Vistula by Most Poniatowskiego, with its altitude and up/down controls |
| 04 | `04-kebab-job.jpg` | 900 | `--kebab=3 --autopilot --time=night --size=90` | A night kebab delivery under way: the order card with its heat bar, distance and the orange beacon |
| 05 | `05-police-talk.jpg` (iPhone, Play) | 720 | `--pullover=routine --pullover-frame=600 --time=day --size=60` | A routine police pull-over by day, the sergeant's line in Polish and English |
| 05 | `05-ride-day.jpg` (iPad) | 600 | `--ride=1 --autopilot --time=day --size=80` | A Podwózka ride by day: the passenger gets in and the ride card shows the rating and the distance |
| 06 | `06-narodowy-night.jpg` | 600 | `--at=1249,-568 --yaw=300 --size=260 --time=night` | Stadion Narodowy lit red and white at night, a taxi driver's quip from the road below |
| 07 | `07-varso-dusk.jpg` | 600 | `--at=-1501,649 --yaw=270 --size=160 --time=dusk` | Varso Tower and the towers by Aleje Jerozolimskie glowing red at sunset |

The iPad's fifth shot is the Podwózka ride, because the police pull-over's dialogue panel
doesn't appear at a 4:3 screen (see BACKLOG). The traffic speech bubbles are random,
so each screen size shows a different line.
