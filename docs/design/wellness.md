# Wellness circles: sound healing, techno yoga, the 40+ club, park kung-fu

F's ideas 2, 3, 4 and 8 (2026-11-02, plan in docs/design/city-life-satire.md): the city's wellbeing habits, played
gently. One crowd-spot family on lawns, built in `game/scripts/wellness.gd`, checked by
`game/tools/check_wellness.gd` (verify step `wellness`, CI quick job too). Affectionate, never about real private
people, no real brand, Polish with English (warsaw-tone). Add-ons check: Beehave / Dialogue Manager not used,
because these are crowd spots and single lines (the packs' rule).

## What the player sees

| Spot kind | The scene | The joke | Hours (game clock) |
| --- | --- | --- | --- |
| **Sound healing** (`sound`) | 8 people cross-legged on mats in a ring round a gong on a frame and three singing bowls; the practitioner in white sways at the gong; a chalkboard "DŹWIĘKOTERAPIA / WEJŚCIE 80 ZŁ" | the price of silence and the gong ("the gong is certified, I'm not"; "I feel the vibrations, or that's the tram") | Park Świętokrzyski Mon-Fri 12-15, Sat-Sun 10-17; Skwer Kościuszki Mon-Fri 17:30-19:30, Sat-Sun 10-18 |
| **Techno yoga** (`techno`) | two rows of four neon-shirted people on mats facing a speaker stack, the instructor in pink bouncing on the beat (130 bpm), a lit board "TECHNO JOGA / + CHOMIKI" with party lights, three hamsters in see-through balls rolling between the mats | "downward dog, hamster head in the wheel"; "the hamsters are certified, I'm not yet" | Rondo Daszyńskiego lawn Mon-Fri 12-14:30 (the office lunch), Sat-Sun 10-12; Browary Warszawskie Mon-Fri 17:30-19:30, Sat-Sun 10-15 |
| **Women's club 40+** (`club`) | a circle of nine in pastels holding hands round a real tree, slowly turning, bobbing; the leader in red outside it; a pink banner "KLUB PEŁNI 40+ / BUDZIMY MAŁĄ DZIEWCZYNKĘ", balloons, hula hoops, a thermos table | waking "the little girl inside": she wants coffee, ice cream and a nap; "no, it's not a cult, it's a club" | Ogród Saski Mon-Fri 13-15:30, Sat-Sun 11-15; Park Ujazdowski Mon-Fri 10-12:30, Sat-Sun 12-16 |
| **Kung-fu in the park** (`kungfu`) | a master in black facing nine students in white; all dip and turn together in one very slow move every 12 s; a banner "SZKOŁA ŻURAWIA" (Crane school), a pigeon among them | "be like water" (water has no back); "slower than you think"; the pigeon is a teacher | Ogród Krasińskich Mon-Fri 7-9 and 17:30-19:30, Sat-Sun 8:30-11; Park Ujazdowski Mon-Fri 7:30-9 and 18-19:30, Sat-Sun 9-11:30 |

Nothing before 07:00 or after 20:00, so the Night look (01:30) has none and the Day look (Friday 14:00) meets three
(Park Świętokrzyski, the Rondo lawn, Ogród Saski). The yoga class already in Ogród Saski, Ogród Krasińskich and
Park Ujazdowski (`park_details.gd`, static) stays; the kung-fu school is the new park activity.

## The lines (data/dialogue.json)

`sound_healing` (15), `techno_yoga` (15), `club_40` (15), `park_kungfu` (13): each has plain lines from a person,
`leader` lines from the practitioner ("Mistrzyni gongu", "Instruktor Bas", "Przewodniczka Pełni", "Mistrz Wolny")
and `car` lines for a slow car close by ("Quiet, please, this is a session!", "Drive carefully, there's a little
girl inside!", "Slower, don't disturb the qi"). A spot on screen near the view speaks every 22-40 s; the spot's
name is a toast the first time the car meets it ("Dźwiękoterapia w parku / Sound healing in the park").

## How it works

- Spots: `SPOTS` in wellness.gd, fixed lawn points read off centrum.json's grass and park areas with a search for
  4-6.5 m of open lawn (clear of buildings by R + 1.5 m, roads, water, pitches and trees; the 40+ circles stand
  round a real tree of the baked trees). `check_wellness` re-checks every spot against the map data.
- Drawing: the figures are one MultiMesh of the pedestrians' person mesh (standing or cross-legged), the hamster
  balls two more (a ring frame, the hamster), the mats, stands, signs and balloons one small mesh per spot shown
  only while the spot is on and within 260 m of the view: +1 to +3 draw calls near a spot, +0 elsewhere. No
  shadows, no collisions. The logic ticks at 2 Hz, the figures at 10 Hz for near spots only (a worst-case tick of
  all eight spots near takes ~0.4 ms in the cloud).
- Flags: `--wellness=0` (none, `--crowd=0` too), `--wellness-now` (every spot on whatever the clock says; for
  shots), `--wellness-log`.

## Open (parked defaults)

BACKLOG "Wellness circles": the gong and beat sound, the Mac look check (QUESTIONS), the phone's look and cost,
rain awareness, the groups ignoring the car. Łazienki, Pole Mokotowskie and Skaryszak lie outside the map.
