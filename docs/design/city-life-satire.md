# City-life satire ideas (F, 2026-11-02)

Twelve ideas F sent in one message (mostly Ukrainian). Each has a short plan, a size, a model
and what already exists. Built in the first thread: #11 and #12 (marked). House rules for all of
them: affectionate humour, never about real private people, no real brand names or logos (parody
names only; the denylist is `data/brand_denylist.json`), on-screen text in Polish with English,
pixel font has no "&". Add-ons check (Beehave / Dialogue Manager): not used for any of these
except where a plan says otherwise, because they are crowd spots and single lines.

| # | Idea | State | Plan in one line | Model |
| --- | --- | --- | --- | --- |
| 1 | Loud cars | BUILT (#345) | Sports-car meet at Browary Warszawskie, revving cars on the streets | Opus |
| 2 | Sound healing | BUILT (#343, docs/design/wellness.md) | Gongs and bowls session, satire; shares the wellness crowd spot with 3, 4, 8 | Sonnet |
| 3 | Techno-yoga | BUILT (#343) | Yoga mats with techno and hamsters running; part of the same spot family | Sonnet |
| 4 | Women's club 40+ | BUILT (#343) | Circle "waking the little girl inside"; circle crowd spot | Sonnet |
| 5 | Huge queues | extend | Queues exist (KUKŁA, ZAKWAS, PIURE, clubs); add more venues, not a new system | Sonnet |
| 6 | Pizzeria KRINGULA | BUILT (#331) | A brick pizzeria beside Cringulo's van lore; joke still to refine | Sonnet |
| 7 | Legia fans | BUILT (#336) | Friendly scarf-and-song fans near Stadion Leguminy, harmless red smoke | Opus |
| 8 | Park activities | BUILT (#343) | Yoga and kung-fu practice on park lawns (Łazienki, Pole Mokotowskie, Skaryszak) | Sonnet |
| 9 | Bike paths | BUILT (bike markings, #341) | Compare our cycleways with Warsaw's real network and fill the gaps | Opus |
| 10 | Map edges: roadworks | DONE | PR #309 closed all 393 road ends (`edge_roadworks.gd`) | - |
| 11 | Kebab "mieszane-mieszane" | BUILT | A neon kebab shop beside the Zagłębie | Sonnet |
| 12 | The Nose Agency | BUILT | A big crown sign on the Skyliner at Rondo Daszyńskiego | Sonnet |

## 1 Loud cars (Opus, own thread)
Browary Warszawskie (Haffnera, Grzybowska at Wronia): a row of generic sports cars (low wide coupe
shapes in loud colours, no marques, no badges) parked at the kerb with a crowd of phone-holders, and
two or three revving cars in traffic: a louder engine layer and a short horn-and-rev joke when one
passes, KEBAB FM news line "Sąsiedzi znów liczą obroty". Needs a car body variant in traffic (draw
calls: share the existing car MultiMesh), a sound layer on the spawn, bench before and after.

## 2-4 and 8 The wellness family (Sonnet, one thread, shares one crowd spot kind)
One new crowd spot kind `circle` (people sitting or standing on a mat in a ring, a leader in
front), reused for:
- **Sound healing**: a ring on mats with gongs and singing bowls; a soft gong sound when the car
  passes nearby; label "DŹWIĘKOTERAPIA, wejście 80 zł"; the joke is the price and the gong.
- **Techno yoga**: mats in a row facing a small speaker, a thumping beat on proximity, and hamsters
  in running balls rolling between the mats; label "TECHNO JOGA + CHOMIKI".
- **Women's club 40+**: a circle under a tree, a banner "KLUB PEŁNI. Budzimy małą dziewczynkę w
  środku", balloons and a hula hoop; warm, never mean.
- **Park activities** (#8): the same spot kind in Łazienki Królewskie, Pole Mokotowskie and Skaryszak
  (outside the demo box, only if it is in the box): yoga mats at sunrise, a kung-fu group in a row
  doing one slow move, a master in front. Daytime and warm weather only.
Where: Park Świętokrzyski (Rondo Daszyńskiego side), Pole Mokotowskie edge, Skwer Kościuszki.

## 5 Huge queues (extend, Sonnet)
The queue system is `crowds.gd` (kind `queue`/`trend`): KUKŁA, ZAKWAS I ROŻEN, HOTEL PIURE,
KROWA 2.0, DALEJ DALLA GELATO, the clubs. Add: a queue at the new KRINGULA pizzeria (#6), at the
MIESZANE-MIESZANE window in the evening (#11), and a "kolejka w kolejce" joke where the queue is
for the queue's start sign. No new system.

## 6 Pizzeria KRINGULA (extend, Sonnet)
Cringulo (the blogger) and his "TŁUSTA PEPA" pizza already exist (food-hype lane). The new piece
is a brick-and-mortar place, KRINGULA PIZZA, sign and a very long queue of delighted fans with
"MLASK" bubbles, a "stage" pose for a photo. F said the exact joke still needs work: build the sign
and the queue first, keep the joke text in dialogue.json for F to rewrite. Never a real person's
name. Park the joke in docs/QUESTIONS.md.

## 7 Legia fans (Opus: map and crowd; keep it light)
Stadion Leguminy is already modelled (`legia`). Add match-day-looking groups on Łazienkowska and
the bridge approach: fans in red-white-green scarves, a drum, hand-held harmless "red smoke" flares
(pink-red sparkle, no fire, no weapons), chanting bubbles that are funny and not about opposing
fans ("Eee, gdzie jest mój bilet?"), a kid with a giant foam finger. No violence, no hooligans,
no club crest or real chants naming a club, colours only. Only on "match" evenings; the police car
nearby just drinks a coffee. Crowd cost: share the existing pedestrian rig.

## 9 Bike paths (Opus)
`tools/cycleways.py` already smooths our network (BACKLOG "Bike paths"). Next: compare with the
real map of Warsaw's cycle network (OSM `highway=cycleway`, `cycleway=*` tags and the city's
"Mapa tras rowerowych"), list the missing links in the centre, fix by data (not by hand), then
put a rider density on the main ones (Wisłostrada, Marszałkowska, Świętokrzyska).

## 10 Map edges (DONE)
PR #309 `edge_roadworks.gd`: 237 closures with "ROBOTY DROGOWE" and "OBJAZD". Nothing to build.
Left from F's note: add an English "UNDER CONSTRUCTION" line on the boards when the language is
English (BACKLOG, small).

## 11 Kebab "mieszane-mieszane" (BUILT)
"Mieszane" is what a Pole says when the kebab man asks about the meat and then the sauce:
"mieszane" and "mieszane". A neon sign MIESZANE / MIESZANE on a small shop beside the Zagłębie
Kebabowe, in the venue table `Storefronts.HYPE` (`kebab_mieszane`). It is not on the Szlak Szpili
trail (the trail stays at five shops). Also built (crowds.gd `MIESZANE`): a short queue at the window, 18:00-04:00 and fullest 02:00-04:00
(tag `mieszane`, five bubbles in dialogue.json `viral`), and a vendor line "Mięso? Mieszane. Sos?
Mieszane." in `kebab_vendor`. Add-ons: not used, because it is a queue spot and single lines.

## 12 The Nose Agency (BUILT)
A crown sign NOSE AGENCY on the Skyliner (195 m, Rondo Daszyńskiego) on its two long faces, warm
white like the other towers' crown names (`"sign"` in the Skyliner's landmark spec, word in
`neon_signs.gd` LANDMARK_WORDS). Mac look check parked.
