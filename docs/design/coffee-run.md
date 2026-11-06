# Kawowy rajd · the coffee run (F, 2026-11-06)

F's ask: your bestie calls and invites you on a coffee run; you go to a few places in a set time,
collect stamps (pieczątki) and buy overpriced coffee, with jokes about filter coffee, overpriced
coffee and the third wave; new niche specialty cafés (like Dot) under parody names, close together;
the whole run on a bike, in Powiśle, starting by taking a city bike (F: "you coming to the Veturilo,
grabbing one, then going Dot, STOR coffee").

Code: `game/scripts/coffee_run.gd` (data and arithmetic), `trend_job.gd` order kind `kawa` (the
flow), `car.gd` model `bike` and `models.gd` `player_bike_meshes` (the bike). Check:
`game/tools/check_coffee_run.gd` (verify step `coffeerun`); the whole run with the autopilot is the
verify step `coffee` (`--trend-job=8 --autopilot`).

## The flow

1. **The call.** 8:00-19:00, after 7 minutes of play and then every 25 minutes, within 1.8 km of
   the dock, when nothing else is on: "📞 ZUZIA DZWONI", Zuzia being your psiapsi. JADĘ / NIE TERAZ.
   Test flag `--trend-job=8` puts the car by the dock and rings at once.
2. **The ROWERILO dock** by Elektrownia Powiśle (a real `bicycle_rental` point; ROWERILO is the
   game's Veturilo parody, city_life.gd). Drive there and stop: the car stays parked at the dock
   (a still copy) and you ride a cream ROWERILO bike with a paper cup in the basket (car.gd model
   `bike`: 8.5 m/s top, gentler pull, no NITRO, the car's collision box; the rider's shirt is the
   car's paint, the helmet its stripes, drawn at 1.6x, and the follow camera closes in to 0.55 of its view while you ride: the first Autopilot playtest found the bike too small at the car's view).
3. **Four cafés, 5:00 on the clock** from the dock, about 1.2 km of loop. At each door stop 1.5 s
   for the stamp; the wallet pays the coffee (if it can't, "na koszt Zuzi"). While you ride, Zuzia's
   third-wave lines take the status bar's hint every 22 s.
4. **Back to the dock**, no clock: the bike goes back, the car is yours again, and the card:
   on time Zuzia BLIKs back what you paid plus 40 zł, +20 respect ("Pełny paszport! Dziesiąta kawa
   gratis… w dni robocze 6:00-6:05"); late, half back and no respect ("Twoja kawa wystygła, to ją
   wypiłam"). Flying, or cancelling, ends the run and gives the car back.

## The cafés (parodies; the real names are in brand_denylist.json)

| # | In game | Behind it (real, 2025-26) | Door | Coffee, price | Joke |
| --- | --- | --- | --- | --- | --- |
| 1 | KROPKA. | a Ukrainian coffee & matcha bar chain's first Polish café, Leszczyńska 1A (Elektrownia Powiśle) | address door | matcha latte z kropką, 29 zł | the dot on the bill |
| 2 | GLON NA POWIŚLU | the game's own matcha place on Dobra (places.json `glon_dobra`) | its notebook place | ceremonialna matcha, 31 zł | a six-minute ceremony, you have three |
| 3 | STORCZYK | the filter-coffee café on Tamka 33 | address door | przelew V60 z Etiopii, 27 zł | jasmine and bergamot, tastes like tea |
| 4 | MANTRA | the matcha / cloud-coffee bar by the metro, Elektryczna 2 | address door | kawa z chmurką, 34 zł | paying for the weather |

Sources for the real places (checked 2026-11-06): specialtyatlas.com Warsaw list, Warsaw Foodie and
coffeespots.pl "new cafés" posts, propertynews.pl on the chain's first Warsaw café.

## Open (BACKLOG "Coffee run")

- Phone check: the bike's readability at the 80 m view, the 5:00 clock on a thumb, the hint lines.
- No café signs or shop fronts yet: the four doors are beacons only (signs need existing shells or
  photos; storefronts.gd already has GLON's).
- Zuzia is a voice on the phone and in the hint only: no figure rides with you.
- A bell sound and pedalling instead of the engine on the bike.
- A free-roam ROWERILO (take a bike at any dock outside the run).
