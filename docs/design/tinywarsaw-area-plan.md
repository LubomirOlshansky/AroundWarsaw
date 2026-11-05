# The Tiny Warsaw list on our map: what we have, what is left, and the plan (2026-11-04)

F asked (2026-11-04) for the same list of buildings as Tiny Warsaw's gallery, but only in our area, with where each one is, plus
everything else in our backlog, as one plan. Method and the full tables are in
docs/inventory/tinywarsaw_area.md (regenerate with `python3 -I tools/tinywarsaw_area.py NAMES.txt OUT.md`). Names are only
facts about Warsaw; nothing of their models is used. A match is by name, or by the street number when our map holds that address.
"Where" is the district and the street nearest to the block.

## 1. The numbers

| | Names |
| --- | --- |
| Their list | 1,393 |
| In our box: named in our map | 288 |
| In our box: found by street number (our map has the block, unnamed) | 262 |
| Metro stations in our box (their entrances / ours) | 10 stations, 82 / 84 entrances |
| A street of ours in the name, number not on our map (check by hand) | 134 |
| Outside our box (airport, Filtry waterworks, Bemowo, Wilanów, other lines) | 345 |
| Unknown (no street or name match: renamed or off our names) | 282 |

Of the 550 in the box: **★ 32 photo builds, ◐ 42 models or outline builds, ○ 45 dressed or in the game, ✗ 430 plain blocks**.
The 430 are the work: 31 of them are ranked places in CITY_INVENTORY Part 1, 262 are address-only blocks (a number, no name
in OSM), the rest are named blocks nobody has dressed (hospital pavilions, Norblin, the Sejm complex, university faculties).

## 2. Where they are (in the box)

Śródmieście 116, Wola 121, Trakt Królewski 96, Śródmieście Południowe 77, Ujazdów i Łazienki 55, Muranów 38, Praga 25,
Powiśle 18, Stare Miasto 4 (the Old Town's houses are named by street fronts in our map, so they mostly match there and not by
name). The per-district tables list name, street, status and the inventory row.

## 3. The plan (order of work, one thread per item, photos first)

Rule from CITY_INVENTORY: tier S/A places start from photos on the Mac; cloud threads do text, kits and tools. Paused by F
(2026-11-03): no new backlog threads are handed out until F says resume; this plan is the order for when it does.

**P1. Finish what already has a row (31 ranked ✗ rows in the box).** Do them in the inventory's order, starting with the palaces on Senatorska and Aleje Ujazdowskie (#99, #112: Blanka, Prymasowski,
Branickich, Jabłonowskich, Pod Karczochem, Pod Gigantami), the Stary BUW (#108), Teatr Polski and Teatr Powszechny (#83), NBP
(#75) and Filharmonia (#77), Żyletkowiec (#127, modernism lane), Dworzec Gdańska composite (#72), the office towers Equator,
Intraco, North Gate, Babka, Prosta Office Center (#124-126), the residences Atelier, Foksal 5, Solec (#128), Muzeum Niepodległości
(#138), the three kamienice (#119, #120).

**P2. Photo re-pass of the 42 ◐ builds**, in the ranked order: Varso (#7), Złote Tarasy (#8), Pałac Prezydencki (#27), Zamek
Ujazdowski (#43), Barbakan (#23), the halls (#53, #54), Elektrownia Powiśle (#55), Warszawa Wschodnia (#73), Polonia (#89),
Metropolitan (#46). Already tracked: CITY_INVENTORY Part 3 item 9.

**P3. Dressed (○, 45) that deserve a model:** the Rondo ONZ towers by photo (#28: Q22, Rondo 1, Cosmopolitan, InterContinental,
WTT), the Rondo Daszyńskiego towers (#61: Atlas, Generation Park X, Pekao, The Bridge, Warsaw Towers), JM Tower, Ilmet, Central
Tower, Łucka City (#129), Błękitny Wieżowiec (#63).

**P4. Clusters of named plain blocks (one shared kit or pass each):**
- Szpital Dzieciątka Jezus (26 pavilions, Nowogrodzka/Oczki): hospital kit, brick, one pass.
- Fabryka Norblina (12 buildings) and Browary Warszawskie (8): industrial brick pass with the existing KRAJOBRAZ notes.
- Sejm and Senate complex (about 14 names on Wiejska/Górnośląska/Frascati): one government-stone pass.
- Ministerstwo Infrastruktury block (6, Chałubińskiego) and the other ministries: modernism lane M11 (#152).
- University and WUM campuses (Banacha, Pasteura, Żwirki i Wigury; many are outside the box edge, check each).
- Politechnika's gmachy, Koszykowa and Nowowiejska (about 12), Instytut Głuchoniemych (4).
- MDM Plac Konstytucji (7) and Plac Zbawiciela fronts: modernism lane (socrealism), shared kit.

**P5. Address-only blocks (262), street by street.** These are numbered houses on the streets in the Part 2 street passes
(Chmielna, Jerozolimskie, Chłodna, Grójecka, Hoża, Filtrowa, Krochmalna, Opaczewska, Solec, Puławska, Foksal). Fold them into
the street passes already planned (Tier C: Żurawia-Chmielna, Foksal next) and give each house a real name and colour from
street photos (docs/design/road-objects.md has the Mapillary/Panoramax tools). Names come free from the list.

**P6. Infrastructure tier (new, F's list shows them as findable places).** Tunnels under al. Niepodległości, Marszałkowska
and Rondo Jazdy Polskiej (Armii Ludowej), Tunel Średnicowy sections (9), Wisłostrada footbridges (5), Jazdów and Wawelska
footbridges, viaducts (Markiewicza, Andersa/Mickiewicza, the Powiśle ones), Rondo Czterdziestolatka's flyovers if it lies in our
box. Add an "infrastructure" tier to CITY_INVENTORY and name them in the map.

**P7. Metro entrances.** Politechnika has 7 entrances in their list and 4 in ours, Dworzec Gdański 8 against 7. Fix those two
first (Rondo Dmowskiego and the metro entrances section in BACKLOG).

**P8. The 134 street-gap names and 282 unknowns** are a hand-check list, not work yet: open the lists in
docs/inventory/tinywarsaw_area.md, drop what lies outside our box, and name the rest. Many unknowns are things we have under another
name (Belweder, Kolumna Zygmunta, Dom Wedla, Hotel Sobieski): match them in a short pass and tick their rows.

## 4. The rest of our backlog (what else we have to do)

Everything below is already written in docs/BACKLOG.md and the ROADMAP v1.0 checklist (58 open lines); this is the grouped
view. The order inside each group follows ROADMAP.

| Group | Open work |
| --- | --- |
| Gameplay (driving first) | driving gameplay plan phases 1-4 (drivability sweep, road fixes, lane assist, running clubs); street races R3-R7 and leaderboard L1-L5; driving extras D1; Vitkac quests and a story for every ride; the helicopter high up; free-play playtest P1-P10 with Autopilot; economy E1-E5 (after the beta) |
| Landmarks and city content | CITY_INVENTORY Part 3 (this plan's P1-P4); modernism lane M1-M17 and the "Betonowy album" quest; Eastern Wall photo pass (Marszałkowska fronts, Sezam WACZEK, Coca-Cola sign); Towarowa 22 and the Daszyńskiego towers photo pass; Krajobraz places; Old Town Market Square leftovers; all churches; Powiśle Mac photo checks; the monuments pass; Ujazdowski Castle and park; the railway lane S3c-e; roofs RF4 |
| Streets and the map | Tier C street passes (Żurawia-Chmielna cluster, Foksal next); courtyards (OSM inner rings need a Mac re-bake); grow the map north-east to Koneser and the fountain park (F: not now); Olszowa ground fill (own map thread); road objects and collisions plan; rail cutting re-bake; edge roadworks |
| Sound, polish, juice | Beta radio songs and idents; opening fly-over; juice (sparks, money pops, district ambience); chatter budget follow-ups; accessibility follow-ups (native text size) |
| Verify and release | full `tools/verify.sh` and `--ios` on the Mac; bench on iPhone 11 and 16 Pro Max; F's timed fresh-save run and the 30-minute soak; store: App Information, screenshots, icon, trailer, support page; TestFlight build >= 4; Play closed test; gamepad testing; outside players finish the first ten minutes |
| Console and docs | the city progress console (thread running); wiki model-progress page from CITY_INVENTORY; this plan's list regenerated after each landing |

## 5. How to keep it current

A thread that lands a place changes its mark in CITY_INVENTORY Part 1 (the existing rule) and re-runs
`python3 -I tools/city_inventory.py`; re-run `tools/tinywarsaw_area.py` for the filtered view when the names file is at hand
(it is not committed; copy the names from the gallery). The ROADMAP line for this plan lives next to "City inventory Part 3".
