# Od słoika do Złotej: the city economy (post-beta plan)

Written 2026-11-03 at F's request: research on arcade driving games and on city-economy and business
games, and a plan to add an economy layer after the beta. "You come to the city broke, start working,
make money, buy kebabs, matcha bars, restaurants, run running clubs… rent a kawalerka, and in the
endgame live in Złota 44… you open a Żabka but it works at a loss." Plan only: no game code changed.

The designer's summary with tables and sources is the artifact
[Drive and Hustle](https://claude.ai/artifact/NR9RQ95srALR6rZ8GSF49h). This file is the repo copy
that build threads work from. The driving fixes stay in `docs/GAMEPLAY_PLAN.md`; part 1 here adds only
what that plan doesn't cover.

## 1. Driving extras from the research (after GAMEPLAY_PLAN phase 3)

What the references teach that we don't have yet (the rest is built or planned):

| Id | Idea | From | Sketch |
| --- | --- | --- | --- |
| D-A | **Napiwek za styl** (style tips) | Crazy Taxi tips for weaving, jumps, drifts | On paid rides: near miss +2 zł, a clean 200 m +3 zł, combo ×2 within 4 s; a number pops above the passenger. The star cost for bumps stays; this adds a positive track. |
| D-B | **Reward, not penalty** | Crazy Taxi World Tour's director | Review every fine-like rule (passenger −½ ★ per bump, scrape costs) against a reward version. |
| D-C | **Wyzwania ze świateł** (traffic-light challenges) | Burnout Paradise: events start at any junction, no menus | 12 chosen junctions: stop at red, rev, a 60 s challenge starts with a HUD 3-2-1 (time to a landmark; a speed-camera dash). No card. |
| D-D | **Sport-only drift** | NFS Heat: brake-to-drift, feathered throttle holds the angle | Above 40 km/h, brake + full steer slides the rear; the gas holds the angle; full gas too long spins. Cruise never slides. |
| D-E | **Destination card** | Crazy Taxi: picture + district + distance, gone after 3 s | A small photo-card and district name at pickup. |
| D-F | **Comfort playtest** | Touchscreen design round-up: test at 15/30/60 min | A PLAYTEST row for F's phone: thumb fatigue, which control is held most. |
| D-G | **On the beat** | Crazy Taxi's director starts from the music | Nitro and challenge starts land on the radio's beat; countdowns duck the music. |

Priority after the gameplay plan: D-A and D-C (most feel per effort, reuse rides, rings and the HUD).

## 2. What the economy games teach

| Game | Take | Avoid |
| --- | --- | --- |
| Monopoly | street sets multiply income; visible levels (houses, hotel) | runaway snowball, losing everything at once |
| GTA Vice City / Vice City Stories | buy a place, finish its missions, then passive income; icons on the map; choose the business per site | unlimited cash with nothing to buy |
| GTA IV | ownership is what makes the city yours (it removed it on purpose) | money with no outlet |
| The Godfather (2006) | a chain to climb (businesses → rackets → warehouses → hubs), district control | violence and extortion: ours is satire and business |
| Yakuza 0, Real Estate Royale | managers, a collection beat, one rival boss per area | menus for everything |
| AdVenture Capitalist, Idle Bank Tycoon | rising costs (×1.07-1.15 each), managers, storage caps that bring you back | ads, timers, energy, daily-login pressure |
| Supermarket Simulator | the hands-on "my shop" fantasy | a whole shop sim in a car game |
| Taxi Life | a real city plus a fleet goal | reviewers: spending is all there is, no sense of progress |
| Faucets and sinks | every income needs a matching sink, or prices stop meaning anything | sinks that feel like fines |

## 3. The layer: Od słoika do Złotej

A **słoik** (a jar) is a newcomer to Warsaw who goes home for their mum's jars of food: the game
already has a słoiki job, so the fantasy is native. You arrive at Centralna with a backpack and
Mirek's borrowed hatchback; you end with a key card that opens only your floor of Złota 44.

### 3.1 The ladder

| Rung | Name | Play time | What you get |
| --- | --- | --- | --- |
| 1 | Słoik | 0-1 h | The main line as it is. A hostel bunk by Centralna. Jobs, rides, rescues, races. |
| 2 | Najemca | 1-3 h | A room on Hoża, then a rented studio in Powiśle: spawn point, save, garage slot, balcony view. Car rental by the day, leasing. |
| 3 | Pierwsza budka | 3-6 h | Kebab stand, matcha bar, running club. Tills, collection drives, managers, their own jobs. |
| 4 | Ulica | 6-12 h | Bistro, padel court, the corner-shop parody, car rental. Levels, street sets, the rival developer. |
| 5 | Złota 44 | 12-20 h | Buying homes; a flat in Złota 44 with a fly-up shot; the penthouse as the postgame. |

### 3.2 Rules that keep it an arcade game

1. **Active beats passive.** At every tier, all businesses together earn at most 40 % of an hour of
   jobs. A till holds 2 game days, so collecting is a reason to drive.
2. **Every economic action is a drive**: supply runs, collections, influencer rides, deliveries,
   takeovers. They reuse `jobs.gd`, `rides.gd`, `roundup_job.gd`, `ladder.gd`.
3. **Nothing is lost while away.** A game day is 20 minutes of play (the game has no day clock; this
   adds one, separate from the day/dusk/night looks). No real-time timers, no decay with the app
   closed, no ads, no purchases.
4. **One card, three numbers**: income, till, one action.
5. **You never lose what you own.** The rival only contests properties not yet bought.

### 3.3 Businesses (desk model; zł/min while playing; today's jobs pay ~15-40 zł/min)

| Business | Buy | Net zł/min (L1) | Twist | Its jobs |
| --- | ---: | ---: | --- | --- |
| Kebab stand by Centralna | 2,000 | +8 | steady, never loses | meat supply run before the night rush |
| Matcha bar on Chmielna | 8,000 | +10 to +40 | hype rises and decays over 5 days (vision.md 3.4 trend cycle) | drive the influencer: a 5★ ride tops hype up |
| Running club on the boulevards | 5,000 | +5 | pays mostly respect; runners wear your colour | escort the Sunday run, cone the route |
| Padel court at WTS DESKA | 15,000 | +30 | busy only in the evening | the "Czwarty" call: bring the fourth player |
| Bistro on Nowy Świat | 25,000 | +60 | the parody inspector's random visits | supply runs, a critic's ride, clean-up before the inspection |
| Ropucha 24/7 (corner-shop franchise parody, "toad") | 12,000 | −10 | the card shows "Obrót: 1,2 mln!" big and "Na czysto: minus" small | night deliveries are the only way into profit (~+6 zł/min while you do them) |
| Car rental at Mirek's | 40,000 | +45 | rents your old cars to other słoiki | fetch a car abandoned by a bar barge |

Levels 1-3: income ×1.6, price ×2.2 each; each level swaps the sign's texture (no new draw call). A
manager collects for a 15 % cut. Three businesses on one street: ×1.5 and the street in your colour
on the full map.

### 3.4 Homes and cars

| Step | Cost | Gives |
| --- | ---: | --- |
| Hostel bunk by Centralna | 60 / day | save point, the morning radio greeting |
| Room on Hoża | 150 / day | spawn point, a flatmate's side jobs |
| Studio in Powiśle, rented | 300 / day | garage slot, balcony shot, sleep sets the time of day |
| The same studio, bought | 60,000 | no rent; a "kredyt 2%" radio joke |
| Flat in a Muranów block | 150,000 | rent it out (+20 zł/min) or move in |
| Złota 44, two rooms | 1,000,000 | the endgame: fly-up shot to your floor, the pool, the floor-locked key card |
| Złota 44 penthouse | "on request" (50,000,000) | postgame: a whole floor, a rooftop Fotka spot |
| Cars: rent / lease / buy | 300 or 150 a day, or the price | try the Ołdi TT for a day; a lease becomes yours after 10 days |

Real anchors (Wikipedia, Złota 44): 52 floors, 192 m, a 25 m pool, floor-locked key cards; sales
resumed in 2015 at 24,000-40,000 zł/m²; one flat sold for 22.9 million zł in 2022. Game prices follow
play time, not the market.

### 3.5 Faucets and sinks

- **In:** jobs, rides, rescues, races (always the best per minute); tills; rent from owned flats;
  style tips; finds (districts, eggs, notebook).
- **Out:** rent and wages each game day; levels, cars, parts, paints, homes; repairs after big crashes
  (only above 30 km/h, never scrapes); the clamp and fines (exist); bids against the rival.

### 3.6 How it plugs in

| System | Use |
| --- | --- |
| `wallet.gd` (save v2) | save v3 adds `[property]` and `[ledger]`; unknown sections are already kept |
| `jobs.gd`, `rides.gd`, `roundup_job.gd` | supply runs, influencer rides, deliveries with a business as origin |
| `ladder.gd`, `rivals.gd` | takeovers: beat the developer's driver for a disputed property |
| `garage.gd`, `upgrades.gd` | rent, lease, buy; Mirek's rental becomes a business |
| `full_map.gd`, `map_icons.gd`, `districts.gd` | ownership icons, street colours, district sets |
| `storefronts.gd`, `neon_signs.gd` | level signs swap a texture on an existing sign |
| `radio.gd`, chatter budget | business news and ads on KEBAB FM; business toasts are class `quest` |
| `notebook.gd` | receipts, a ledger page |
| Performance | no new actors, materials or lights; logic at 1 Hz; bench before/after each phase |

## 4. Phases

| Phase | What | Check |
| --- | --- | --- |
| Now | Beta and GAMEPLAY_PLAN phases 0-3. No economy code. | |
| D1 | Driving extras D-A, D-C, D-D, D-F | `check_steering` drift cases, a tip case in `check_rides` |
| E1 | A roof over your head: game-day clock, save v3, bunk/room/studio, home spawn, car rental | new `check_economy.gd`: a simulated 20 h player hits each rung within ±15 % |
| E2 | First businesses: kebab stand, matcha bar, running club; tills, collections, managers, icons | `check_economy` + a collection-drive case |
| E3 | The street: levels with sign swaps, sets, bistro, padel, Ropucha 24/7, inspector and influencer events | bench before/after |
| E4 | The rival developer (the billboards exist): bids and race takeovers, one boss per district | `check_economy` rival case |
| E5 | Złota 44: homes, the fly-up shot, the roof end card, the penthouse, optional "Nowy słoik+" restart | F's phone run |

## 5. Open questions (defaults used above)

- Does the economy wrap the main line or come after it? **Wraps it**: rung 1 is the main line, unchanged.
- Is the start car still free? **Yes**, lent by Mirek; owning one is a rung-2 goal.
- Can you lose a business? **No.**
- The frog-branded corner-shop chain's parody name? **Ropucha 24/7**, green sign, never the real logo.
- Interiors? **No walk-ins**: a card with the window view and the camera flying up the façade.
- "gidphazer" in F's message read as **The Godfather** (2006); if F meant another game, add it to §2.

## Sources

Crazy Taxi developers (automaton-media.com), Crazy Taxi core loop (itch.io blog 530882), Burnout
Paradise (racinggames.gg), NFS Heat handling model (ea.com), Mario Kart World smart steering
(gamesradar.com), assist modes (gameaccessibilityguidelines.com), touchscreen controls
(gamedeveloper.com), The Godfather 2006 (Wikipedia), Real Estate Royale UX analysis (SUPERJUMP on
medium.com), GTA Vice City properties (gtabase.com), Vice City Stories property (sportskeeda.com), GTA
IV and economic opportunity (avclub.com), the math of idle games III (gamedeveloper.com), Idle Bank
Tycoon (pocketgamer.biz), sinks and faucets (1kx on medium.com), Supermarket Simulator mobile
(lancaric.substack.com), Taxi Life review (gamegrin.com), Złota 44 (Wikipedia), corner-shop franchise
earnings (money.pl). Full links in the artifact.
