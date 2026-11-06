# Testing backlog

F's ask (2026-11-06): a separate backlog for testing, built from the comment history, worked
through until every test is done. This file is the queue; `docs/PLAYTEST.md` keeps the plan rows,
the case lists and the PT-n bug log. A run takes one line here: tick it, name the run, link the PT
ids. Bugs are reported, not fixed here; each one gets its own fix thread.

Each row is one Autopilot run of under 6 minutes on the Mac (`.claude/skills/autopilot-playtest`).
Order: fixes waiting for proof, then what F asked about, then the plan rows never run.

## 1. Fixes waiting for proof

- [ ] T1 PT-23 and PT-24 (#460): the offer over the ride app at `-735,1722`, backing off at `-680,725`
- [ ] T2 PT-25 crazy drivers' lines: with `--crazy-log`, why 5 cut-ins gave no line
- [ ] T3 PT-19: the map teleport hold at `-700,900` leaves the car in place
- [ ] T4 The P2 re-checks: PT-11 (first race), PT-15 (two offers at once), PT-16 (order result card)
- [ ] T5 PT-18 ramp stop on Solec and PT-20 toast, on the next P11 and P13 runs

## 2. What F asked for

- [ ] T6 Roadworks block every road end ("make sure there are the block roads on the end of the map", 11-05): P7, north, east and west closures, and traffic queued at them
- [ ] T7 Objects that are invisible but solid ("check for more objects with such bug", 11-05): log every stop with nothing on screen
- [ ] T8 Collisions with cars ("car stuck each time it collides", 10-29): ram traffic at 15, 40 and 80 km/h, time to drive off
- [ ] T9 Tiny objects on the road ("driving is heavy", 10-29): after smooth roads (#447), one steered street per run
- [ ] T10 Police and racers ("make them smarter, then test", 11-04): P10 and P17, can the chase be escaped by a fast agent
- [ ] T11 Radio ("make sure the new radio interface and songs are there", 11-05): station change, from the #454 branch
- [ ] T12 Złote Tarasy corner screen and Skwer Linearny (11-05): drive and look, from the #456 branch
- [ ] T13 Crazy drivers in thick traffic: Marszałkowska south, at speed, how close they come
- [ ] T14 Button driving, the default (#425): the on-screen GAS, BRAKE and slider, not keys
- [ ] T15 Patelnia from the west by Kokota, and the Rotunda stair once more after #452 merges
- [ ] T16 The look of the starting street shops and Świętokrzyska tents (#449): frames, day and night

## 3. Plan rows never run or left open

- [ ] T17 P1 the other start streets (only Marszałkowska driven)
- [ ] T18 P4 Krakowskie Przedmieście, Plac Zamkowy, Old Town
- [ ] T19 P5 bridges and ramps, W-Z tunnel, Wisłostrada
- [ ] T20 P6 Powiśle and the river edge, water tow
- [ ] T21 P8 helicopter landings, rescue roofs
- [ ] T22 P9 menus: pause card, map, garage, settings, POMOC DROGOWA
- [ ] T23 P11 the tunnels driven through (C11.1, C11.3, C11.4)
- [ ] T24 P14 narrow streets, steered
- [ ] T25 P15 the helicopter to Varso and the map edge
- [ ] T26 P16 Trzy mosty frames at race speed

## 4. Only the phone can show

Parked until F allows a device run: touch feel, frame time and heat, the button ranks' look (#460),
PT-27 on a real screen.
