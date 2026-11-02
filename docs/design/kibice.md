# Kibice by Stadion Leguminy

F's idea 7 (2026-11-02): "near the Legia stadium some football fans with flares, a parody of
Legia, but consider how to make it not harmful, just funny". Code: `game/scripts/fans.gd`; check:
`game/tools/check_fans.gd` (`tools/verify.sh --only=fans`, CI too). Plan line: docs/design/city-life-satire.md, 7.

## The rules of the joke

- Affection, not mockery: the fans are warm, a bit silly and proud. The jokes are about tickets,
  sausages, grandad's scarf, mum, singing for hours and the grass.
- Colours only (white, red, green). No crest, no club named (the stadium is the parody "Stadion
  Leguminy"), no real chant, nothing about other clubs or their fans, no fight words. The check
  fails on any club name, "kibol", "chuligan", "ustawka" and similar in the lines or banners.
- The "flares" are hand-held pink smoke sticks ("dymek z atestem"): pink puffs, no fire, no
  bangs. Nobody throws anything; the police officer drinks a coffee.

## What is in the game

| Part | How |
| --- | --- |
| When | Match evenings: Wed 17:00-21:30, Sat 15:00-21:30, Sun 14:00-20:30 (`MATCHES`). `--fans-now` any hour. |
| Where | Three groups (`GROUPS`): north gate and north-east corner on Łazienkowska, south side by the Trasa Łazienkowska approach; on the nearest long pavement stretch and the open ground on its roomier side, never on a road or in a building. |
| Who | 24, 18 and 16 fans (× `--crowd`), a drummer with a belly drum, two smoke holders, a kid with a giant green foam finger; Sierżant Bogdan (police_club's officer) by a patrol car at the gate. |
| Chant | Every 14-26 s for 7 s: everyone jumps on the beat and the scarves go up over the heads; between, scarves round the neck and a sway. The player's horn within 45 m starts one. |
| Banners | ZAWSZE WIERNI / CZASEM PUNKTUALNI · MAMO, JESTEM / W TELEWIZJI! · WYNIK NIEWAŻNY / KIEŁBASA WAŻNA (words on both faces). |
| Lines | `kibice` (chat, `chant`, `honk`, `car`, `kid`) and `police_kibice` in data/dialogue.json, Polish with English. A toast the first time: "Kibice pod Stadionem Leguminy". |
| Sound | `fan_chant` (tools/make_sfx.py): a belly drum "boom, boom, boom-boom-boom" and a wordless original crowd tune, 8 s loop, through city_sounds.gd's `chant` kind. |
| Match day | Kick-off 1.5 h into the evening (`phase_at`): in the 1.4 h before it fans walk in bunches of 1-4 (a kid with a foam finger in some) on four routes found once on the footways and zebras (AStar2D): from the two bus platforms by the Trasa Łazienkowska to the gate and to the corner, along Łazienkowska from the west to the gate, up Czerniakowska to the south group. 134 walkers (× `--crowd`), more as kick-off nears, the last 7 minutes a few running late (`late` lines). After kick-off nobody new sets off; whoever is still on the way runs the rest. From 1.9 h after kick-off, for 0.7 h, they stream home the other way. The result is rolled at full time: a win (65 %: the groups sing twice as often, scarves up on the way home, `win` lines, the toast "Koniec meczu: wygrana!") or a draw ("Następnym razem!", `draw` lines). Never a loss. `--fans-phase=arrive|match|leave`, `--fans-result=win|draw` for shots. |
| Cost | +4 draw calls (fans, props family, smoke puffs, one kit mesh for all three groups) plus the patrol car, only within 420 m of the stadium on a match evening, +1 while walkers are out (their own person mesh with walking legs; their scarves join the props); fans scripts 0.05 ms before the walkers, 0.09 ms with 134 walkers out (cloud lavapipe probe at `--at=1230,1360`, 125-126 draw calls both). Nothing elsewhere. |

Add-ons: Beehave / Dialogue Manager not used, because the fans are a standing crowd with timed
chants and ambient bubbles, no branching conversation.
