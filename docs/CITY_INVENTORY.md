# City inventory: every characteristic place, street by street

F asked (2026-11-02) for one list of every place in the map box that can make the city feel
real: landmarks, tenements (kamienice), monuments and sculptures, distinctive houses, museums,
popular bars, metro stations, shopping centres, upscale flats, skyscrapers and office buildings.
Sorted from the most valuable to the least, each marked done, not done, or done with the new
photo approach. **Part 1** is the ranked list (keep it current: a thread that lands an item
changes its status here in the same PR, like ROADMAP's v1.0 checklist). **Part 2** is the same
places street by street, regenerated from the map data with `python3 -I tools/city_inventory.py`
(it reads Part 1's statuses, so edit Part 1 and re-run). docs/LANDMARKS.md keeps the build detail
of each model; this file only says what exists and what is next.

## Why some places were rebuilt "outline only"

Most models from 2026-10-31 to 2026-11-02 were built by cloud threads. The cloud cannot open
Wikimedia Commons, GUGiK or Geoportal (403), and the photo library `refs/` lives on F's Mac, so
those threads had only the OpenStreetMap outline, the GUGiK LoD2 heights in the map and published
text. They built what the outline allows and marked every guessed value *(photo check)*: about
50 such checks are parked in docs/QUESTIONS.md. The places that look right (the Palace, the
Rotunda, the Eastern Wall stores, MSN, Złota 44, Warsaw Spire, Dom pod Orłami) are the ones built
from F's own photos or checked side by side with photos on the Mac. **Rule from now on:** a model
of a tier S or A place starts from photos (F's, or `refs/` on the Mac); a cloud thread without
photos asks the coordinator for them or for Mac folder access first, and does not build blind.

## The new approach (the MSN recipe)

The model-from-photos skill (`.claude/skills/model-from-photos`), as used for Muzeum Sztuki
Nowoczesnej, Złota 44 and Warsaw Spire: (1) photos: F's own or `refs/<slug>/` (several angles,
day and night) plus the GUGiK orthophoto for the roof; (2) all data: the OSM parts and outline,
LoD2 heights, published facts (architect's pages, news, listings); (3) an Opus spec in
`docs/landmarks/specs/<slug>.md` with a parts table, every value tied to a photo or a source;
(4) `object-modeler` builds within a triangle budget; (5) `art-director` scores it side by side
against the photos; (6) F's look on the Mac or the phone closes it.

## Status legend

| Mark | Meaning |
| --- | --- |
| ★ | **Photo build** (the new approach): built from F's photos or checked side by side against photos on the Mac |
| ◐ | **Outline build**: own model from the OSM outline, LoD2 and published facts, no photo yet; Mac photo check parked. Next step: photo re-pass |
| ○ | **Dress only**: colour skin, the shared tower builder, a neon sign, a card or street dress; no model of its own |
| ⏳ | In progress in an open PR or a running thread (do not start a second thread) |
| ✗ | **Not done**: a plain grey LoD2/OSM block, or not in the game at all |

Tiers: **S** the city's faces (postcards, skyline, the first ten minutes); **A** iconic, seen
often, known to every visitor; **B** characteristic, known to locals, gives a street its identity;
**C** texture (named tenements, offices, embassies, small institutions) in Part 2 only.

<!-- counts:start -->
**Counts** (Part 1, 140 ranked rows): ★ 16 photo builds · ◐ 54 outline builds · ○ 16 dress only · ⏳ 2 in progress · ✗ 52 not done. Part 2 adds 543 named outlines (tier C): 19 with a model of their own, 69 dressed or named in the game, 455 plain blocks.
<!-- counts:end -->

## Part 1. The ranked list

### Tier S: the city's faces

| # | Place | Street | Kind | Status | Next |
| --- | --- | --- | --- | --- | --- |
| 1 | Pałac Kultury i Nauki | Plac Defilad / Marszałkowska | landmark | ★ | stone colour and the 30th-floor terrace (QUESTIONS) |
| 2 | Rotunda (OSM: Rotunda PKO) | Marszałkowska (Rondo Dmowskiego) | landmark pavilion | ★ | none |
| 3 | Domy Towarowe Centrum: Junior, Sawa, Wars | Marszałkowska | department stores | ★ | the pavilions behind them (ROADMAP first-scene 4-5) |
| 4 | Muzeum Sztuki Nowoczesnej | Marszałkowska (Plac Defilad) | museum | ★ | R8: the ribbon and the roofline |
| 5 | Złota 44 | Złota | upscale flats, skyscraper | ★ | Mac look check |
| 6 | Warsaw Spire | Plac Europejski | office skyscraper | ★ | Mac look check |
| 7 | Varso Tower (with Varso I, Varso II) | Chmielna | office skyscraper | ◐ | photo re-pass of the crown, the spire and the two low towers |
| 8 | Złote Tarasy (with Lumen, Skylight) | Złota / Aleja Jana Pawła II | shopping centre, offices | ◐ | photo re-pass: the wave, Lumen's ribbons, Skylight's crown |
| 9 | Warszawa Centralna | Aleje Jerozolimskie | station | ★ | the wings' walls (QUESTIONS) |
| 10 | Zamek Królewski (OSM: Wieża Zegarowa) | Plac Zamkowy | royal castle | ⏳ | PR #299 (Clock Tower, Vistula front, Kubicki's Arcades); then a photo check |
| 11 | Kolumna Zygmunta | Plac Zamkowy | monument | ◐ | photo check |
| 12 | Rynek Starego Miasta and its Syrenka | Rynek Starego Miasta | square, statue | ◐ | photo re-pass: paving, umbrellas, the statue's pose; the north and west fronts' gables |
| 13 | Stadion Narodowy | Aleja Zieleniecka | stadium | ★ | the bank's grass against the orthophoto |
| 14 | Most Poniatowskiego (towers and deck) | Aleja Poniatowskiego | bridge | ◐ | **photo build**: the four towers' real heights, the arcades, balustrades |
| 15 | Most Świętokrzyski | Wybrzeże Kościuszkowskie | bridge | ◐ | photo check of the pylon and stays |
| 16 | Centrum Nauki Kopernik and Planetarium (OSM: Planetarium Niebo Kopernika) | Wybrzeże Kościuszkowskie | science centre | ★ | none |
| 17 | Biblioteka Uniwersytecka (BUW) and its roof garden | Dobra | library, garden | ★ | the philosophers and heights (no facade photo yet) |
| 18 | Teatr Wielki and Teatr Narodowy | Plac Teatralny (Moliera, Fredry) | opera, theatre | ◐ | photo re-pass of the colonnade; Teatr Narodowy's wing is ✗ |
| 19 | Grób Nieznanego Żołnierza and Plac Piłsudskiego | Plac Piłsudskiego | monument, square | ◐ | photo check |
| 20 | Muzeum Historii Żydów Polskich Polin and Pomnik Bohaterów Getta | Mordechaja Anielewicza | museum, monument | ★ | built 2026-11-02 from `refs/polin/` (25 Commons photos, the ortho) and LoD2, spec `polin.md`; F's look on the Mac or the phone |
| 21 | Muzeum Powstania Warszawskiego (OSM: Elektrownia Tramwajów Miejskich) | Przyokopowa / Grzybowska | museum | ✗ | **photo build**: the brick power station, the Freedom Park wall, the tower |
| 22 | Pomnik Powstania Warszawskiego | Plac Krasińskich | monument | ✗ | **photo build**: the two bronze groups, the fallen pillars, the manhole |
| 23 | Barbakan and the city walls (OSM: Baszta Prochowa) | Nowomiejska / Podwale | fortification | ◐ | Barbakan photo check; the walls and towers along Podwale are ✗ |
| 24 | Archikatedra św. Jana | Świętojańska | cathedral | ◐ | photo check; the tower |
| 25 | Kościół św. Anny | Krakowskie Przedmieście | church | ◐ | photo check: columns, the bell tower |
| 26 | Hotel Bristol and Hotel Europejski | Krakowskie Przedmieście | grand hotels | ◐ | photo re-pass of both fronts |
| 27 | Pałac Prezydencki | Krakowskie Przedmieście | palace | ◐ | photo check of the portico and statue |
| 28 | Rondo ONZ towers: Q22, Rondo 1, Cosmopolitan, InterContinental (OSM: InterContinental), Warsaw Trade Tower | Rondo ONZ / Emilii Plater / Twarda | skyscrapers | ○ | **photo build** of each crown and skin (one thread per tower, Q22 and Rondo 1 first) |
| 29 | Hotel Warszawa (the 1934 Prudential) | Plac Powstańców Warszawy | historic skyscraper, hotel | ✗ | **photo build**: the stepped tower, the 1930s stone, the crown |
| 30 | Cedet (Dom Towarowy CDT) | Krucza / Aleje Jerozolimskie | department store | ✗ | **photo build**: the glazed corner over the start area's crossing |

### Tier A: iconic, seen often

| # | Place | Street | Kind | Status | Next |
| --- | --- | --- | --- | --- | --- |
| 31 | Pomnik Syreny nad Wisłą (OSM: Syrenka na Powiślu) | Wybrzeże Kościuszkowskie | statue | ◐ | photo check of the plinth |
| 32 | Pomnik Mikołaja Kopernika and Pałac Staszica | Krakowskie Przedmieście | monument, palace | ◐ | photo check |
| 33 | Pomnik Adama Mickiewicza | Krakowskie Przedmieście | monument | ◐ | photo check |
| 34 | Kościół Świętego Krzyża | Krakowskie Przedmieście | church | ◐ | photo check: the helms, the dome |
| 35 | Brama Uniwersytetu Warszawskiego and Pałac Kazimierzowski | Krakowskie Przedmieście | gate, palace | ◐ | photo check |
| 36 | Kościół Wizytek, Kościół Karmelitów (OSM: Kościół Wniebowzięcia Najświętszej Maryi) | Krakowskie Przedmieście | churches | ◐ | photo check |
| 37 | Pałac Potockich, Kordegarda (OSM: Galeria Kordegarda), Pałac Czapskich | Krakowskie Przedmieście | palaces | ◐ | Czapski's own model (today a skin) |
| 38 | Plac Zamkowy's houses and Mariensztat | Plac Zamkowy / Mariensztat | tenements | ○ | photo re-pass of the gables; Mariensztat's reliefs |
| 39 | Old Town and New Town tenements: Kamienica Pod Bazyliszkiem, Pod Murzynkiem, Fukierowska, Baryczkowska, Pod Okrętem | Rynek Starego Miasta / Freta | tenements | ○ | photo pass per famous house (signs, portals, painted fronts) |
| 40 | Nowy Świat tenements and palaces (Zamoyski, Mikulski, Bürger, Jasiński, Kossakowski) | Nowy Świat | tenements | ○ | photo pass of the fronts |
| 41 | Kościół Świętego Aleksandra and Plac Trzech Krzyży | Plac Trzech Krzyży | church, square | ◐ | photo check; the square's houses (Kamienica pod Gryfami) |
| 42 | Sejm and Senat (OSM: Sala posiedzeń Sejmu RP, Senat RP) | Wiejska | parliament | ◐ | photo check; the Senate and the Sejm's office slabs are ✗ |
| 43 | Zamek Ujazdowski | Jazdów (Aleje Ujazdowskie) | castle, art centre | ◐ | photo check |
| 44 | Zachęta | Plac Małachowskiego | gallery | ★ | the back and the roof |
| 45 | Kościół Świętej Trójcy | Plac Małachowskiego | church | ★ | oculi count |
| 46 | Metropolitan | Plac Piłsudskiego | offices | ◐ | photo check |
| 47 | Muzeum Narodowe and Muzeum Wojska Polskiego's yard | Aleje Jerozolimskie | museum | ◐ | **photo build**: the 1930s front, the tanks and planes in the yard |
| 48 | Dom Partii (OSM: Centrum Bankowo-Finansowe) and Rondo de Gaulle'a's palm | Nowy Świat / Aleje Jerozolimskie | offices, monument | ◐ | photo check |
| 49 | Pawilony za Nowym Światem | Nowy Świat | bar pavilions | ◐ | photo check (neon, string lights) |
| 50 | Plac Konstytucji and MDM | Marszałkowska | socialist-realist square | ◐ | photo re-pass: arcades, reliefs, the candelabras |
| 51 | Kościół Najświętszego Zbawiciela and Plac Zbawiciela | Marszałkowska | church, square | ◐ | photo check: towers, the square's arcades |
| 52 | Rondo Dmowskiego and Patelnia (Metro Centrum) | Marszałkowska | square, metro | ◐ | Mac look check |
| 53 | Hala Mirowska and Hala Gwardii | Plac Mirowski | market halls | ◐ | photo check: brick, lantern |
| 54 | Hala Koszyki | Koszykowa | food hall | ◐ | photo check |
| 55 | Elektrownia Powiśle | Dobra | shopping centre in a power station | ◐ | photo check: chimneys |
| 56 | Fabryka Norblina (OSM: Modsen) | Prosta | shopping and offices | ◐ | photo check; K6 garden in PR #303 |
| 57 | Browary Warszawskie (OSM: Warzelnia, Laboratorium, Willa Schielego) | Grzybowska | shopping and offices | ◐ | photo check; K6 garden in PR #303 |
| 58 | Westfield Arkadia (Arkadka) | Aleja Jana Pawła II | shopping centre | ◐ | photo check |
| 59 | Forest | Aleja Jana Pawła II | office tower | ◐ | photo check |
| 60 | Rondo Daszyńskiego towers: Warsaw Unit, Skyliner, The Warsaw HUB, Mennica Legacy Tower, Generation Park Y | Rondo Daszyńskiego / Prosta | office skyscrapers | ○ | **photo build** per tower (the HUB's three towers first) |
| 61 | Wola towers: The Bridge, Generation Park X and Z, Atlas Tower, Pekao Tower, Warsaw Towers | Grzybowska / Aleje Jerozolimskie / Sienna | office skyscrapers | ○ | The Bridge and Atlas are the table's; Pekao Tower and Warsaw Towers ✗; photo build |
| 62 | Centrum LIM (Marriott) and Novotel | Aleje Jerozolimskie / Marszałkowska | hotel towers | ★ | Novotel from the Rondo photos; LIM's lit cells |
| 63 | Błękitny Wieżowiec and Plac Bankowy | Plac Bankowy | skyscraper, square | ○ | photo check of the glass |
| 64 | Plac Bankowy's palaces: Ratusz (OSM: Urząd Miasta Stołecznego Warszawy), Mazowiecki Urząd Wojewódzki, Gmach Giełdy i Banku Polskiego, Arsenał | Plac Bankowy / Długa | palaces | ○ | **photo build** of the colonnaded front (Corazzi's buildings) |
| 65 | Pomnik Juliusza Słowackiego and Pomnik Stefana Starzyńskiego | Plac Bankowy | monuments | ✗ | build both from photos |
| 66 | Pomnik Bohaterów Warszawy (Nike) | Aleja Solidarności | monument | ✗ | build from photos |
| 67 | Pomnik Małego Powstańca and Pomnik Jana Kilińskiego | Podwale | monuments | ✗ | build from photos |
| 68 | Pomnik Józefa Piłsudskiego, the Smolensk monuments, Pomnik Lecha Kaczyńskiego | Plac Piłsudskiego | monuments | ✗ | build from photos (affectionate, no politics on cards) |
| 69 | Pomnik Poległym i Pomordowanym na Wschodzie | Muranowska | monument | ✗ | build from photos (the railway truck of crosses) |
| 70 | Umschlagplatz memorial | Stawki | memorial | ✗ | build from photos, a quiet card |
| 71 | Warszawa Śródmieście, Ochota, Powiśle, Stadion stations | Aleje Jerozolimskie / Wybrzeże Kościuszkowskie | stations | ★ | Śródmieście and Stadion still ◐ (photo check) |
| 72 | Dworzec Gdański and its metro (OSM: Dworzec Warszawa Gdańska) | Słomińskiego | station | ✗ | railway S3d (Mac photos first) |
| 73 | Warszawa Wschodnia | Lubelska | station | ✗ | railway S3c (Mac photos first) |
| 74 | Metro stations: Centrum, Świętokrzyska, Ratusz-Arsenał, Politechnika, Rondo ONZ, Rondo Daszyńskiego, Nowy Świat-Uniwersytet, Centrum Nauki Kopernik, Stadion Narodowy, Dworzec Gdański | (84 entrances) | metro | ○ | the kit's canopies, stairwells and M posts are in; each station's own face (Świętokrzyska's glass, Nowy Świat's pavilions, Kopernik's art) is ✗ |
| 75 | Narodowy Bank Polski | Świętokrzyska | bank | ✗ | photo build of the 1970s stone block |
| 76 | Poczta Główna | Świętokrzyska | post office | ✗ | photo build |
| 77 | Filharmonia Narodowa | Jasna / Sienkiewicza | concert hall | ✗ | photo build |
| 78 | PAST-a | Zielna | historic telephone tower | ✗ | photo build: the 1908 tower, a famous Uprising site |
| 79 | Pałac Krasińskich and Ogród Krasińskich | Plac Krasińskich | palace, park | ✗ | photo build (the park's details are in) |
| 80 | Vitkac | Bracka | luxury department store | ✗ | photo build: the black stone block, start area |
| 81 | Dom Towarowy Braci Jabłkowskich | Bracka | historic department store | ✗ | photo build of the 1914 front |
| 82 | Sheraton Grand Warsaw | Wiejska / Plac Trzech Krzyży | hotel | ✗ | photo build |
| 83 | Teatr Polski and Teatr Powszechny | Karasia / Zamoyskiego | theatres | ✗ | photo build |
| 84 | Bazylika Katedralna Świętego Michała Archanioła i Świętego Floriana Męczennika | Floriańska | Praga cathedral | ✗ | photo build: the twin spires seen across the river |
| 85 | Koneser and Ząbkowska's tenements | Ząbkowska | vodka works, tenements | ✗ | photo build; the box's north-east edge cuts close, check first |
| 86 | Bazar Różyckiego | Targowa | bazaar | ✗ | stalls and the gate from photos |
| 87 | Park Praski's bear enclosure (Wybieg dla niedźwiedzi) | Aleja Solidarności | park | ✗ | the rock enclosure and the bears, a card |
| 88 | Multimedialny Park Fontann | Wybrzeże Gdańskie | fountains | ✗ | the fountain field and the evening show |
| 89 | Hotel Polonia Palace, Radisson Blu Sobieski (Radysław Blu) | Aleje Jerozolimskie / Plac Zawiszy | hotels | ◐ | photo check |
| 90 | Plac Defilad's pavilions: Cepelia, Zodiak, Scena Relax (OSM: Pawilon Cepelii) | Marszałkowska | modernist pavilions | ◐ | photo check |

### Tier B: characteristic, gives a street its identity

| # | Place | Street | Kind | Status | Next |
| --- | --- | --- | --- | --- | --- |
| 91 | Bars and clubs with parody names: Lusterko, Smoła, Jasna 0, Lombard, Miłość Hipoteczna, 1499 M2, Plan C, Apteczka, Przegryzki Zagryzki, Kasa Biletowa, Żwir, Bar Pyzowy, Hocki Bloki | Aleje Jerozolimskie, Smolna, Jasna, Mazowiecka, Kredytowa, Emilii Plater, Plac Zbawiciela, Nowy Świat, Kruczkowskiego | bars, clubs | ○ | neon fascias are in; queues at night and the pavilions of Smolna 38 and Kasa Biletowa need photos |
| 92 | Level 26 | Aleje Jerozolimskie (Atlas Tower) | rooftop club | ◐ | photo check |
| 93 | The river barges and the marina (Wieczorek, Biała Barka, Marinka, Kaskadka) | Wybrzeże Kościuszkowskie | bar barges | ◐ | photo check; boulevards' pavilions in PR #310 |
| 94 | Bulwary Wiślane: Schodki, the pavilions, the containers | Wybrzeże Kościuszkowskie | promenade, bars | ⏳ | PR #310 |
| 95 | Milk bars: Bar Prasowy (Marszałkowska), Bar Familijny (Nowy Świat), Bar Bambino (Krucza), Bar Pod Barbakanem (Mostowa) | Marszałkowska / Nowy Świat / Krucza / Mostowa | milk bars | ✗ | parody names and fascias, a lunch queue |
| 96 | Plan B's corner, Plac Zbawiciela's café row | Plac Zbawiciela | bars | ○ | the summer crowd on the pavement (crowds.gd) |
| 97 | Kawiarnia and bar street of Chmielna, Mokotowska, Hoża, Poznańska | Chmielna / Mokotowska / Poznańska | street of bars | ○ | more parody fascias and terraces per block |
| 98 | Kina: Muranów, Atlantic, Luna, Kultura, Elektronik, Femina, Kinoteka, Iluzjon (south of the box) | Andersa / Chmielna / Marszałkowska / Krakowskie Przedmieście / Aleja Solidarności | cinemas | ○ | marquee signs are in; poster facades and evening queues |
| 99 | Pałac Paca, Pałac Branickich (Miodowa), Pałac Prymasowski, Pałac Blanka, Pałac Jabłonowskich | Miodowa / Senatorska | palaces | ✗ | Miodowa street pass: palace fronts from photos |
| 100 | Katedra polowa, the Cerkiew, Kapucyni (Miodowa churches) | Miodowa | churches | ◐ | church kit; photo check |
| 101 | Synagoga Nożyków and Próżna's pre-war tenements (Kamienica Zalmana Nożyka, Kamienica Wolanowskiego) | Próżna / Twarda | synagogue, tenements | ◐ | the synagogue is the church kit's; Próżna's facades ✗ (photo build) |
| 102 | Plac Grzybowski and Kościół Wszystkich Świętych | Plac Grzybowski | square, church | ◐ | photo check; the square's fountain and benches |
| 103 | Dom pod Orłami and Skwer Linearny na Złotej | Jasna / Złota | historic office, new park | ★ | Mac look check |
| 104 | Hotel Wiktoria (Sofitel Victoria) and Królewska (OSM: Sofitel Victoria) | Królewska | hotel | ◐ | photo check |
| 105 | Ministerstwo Finansów | Świętokrzyska | ministry | ◐ | photo check |
| 106 | Saski Crescent, Saski Park, Senator | Królewska / Bielańska | offices | ✗ | photo build of the curved glass on the Saxon Garden |
| 107 | Gmach Główny Politechniki Warszawskiej (OSM: Gmach Główny PW) | Noakowskiego / Plac Politechniki | university | ✗ | **photo build**: the courtyard hall's front and the dome |
| 108 | Uniwersytet: Auditorium Maximum, Stary BUW, Biblioteka Królewska | Krakowskie Przedmieście | university | ✗ | photo pass of the campus |
| 109 | Pałac Pod Blachą and Biblioteka Królewska | Plac Zamkowy / Wybrzeże Gdańskie | palace | ✗ | with the Castle (after PR #299) |
| 110 | Zamek Ostrogskich and the Chopin Institute | Tamka | palace | ◐ | photo check |
| 111 | Piano House, Cube House, Hortus, Moderna, Dobra and Tamka tenements | Topiel / Leszczyńska / Drewniana / Zajęcza / Dobra / Tamka | upscale flats, tenements | ◐ | photo check |
| 112 | Kamienica Pod Gigantami, Pałac Pod Karczochem, Kamienica Ławrynowicza and Aleje Ujazdowskie's villas (OSM: Pałacyk Rembielińskiego) | Aleje Ujazdowskie | tenements, villas | ✗ | Aleje Ujazdowskie street pass from photos |
| 113 | Pomnik Ronalda Reagana, Pomnik Romana Dmowskiego (Plac Na Rozdrożu) | Aleje Ujazdowskie | monuments | ✗ | build from photos |
| 114 | Pomnik Polskiego Państwa Podziemnego i Armii Krajowej, Pomnik Wincentego Witosa, Pomnik Ignacego Daszyńskiego | Wiejska | monuments | ✗ | build from photos, with the Sejm pass |
| 115 | Pomnik Marii Skłodowskiej-Curie | Kościelna | statue | ✗ | build from photos |
| 116 | Pomnik Sapera | Czerniakowska | monument | ✗ | build from photos |
| 117 | Pomnik Kardynała Wyszyńskiego, Pomnik Bolesława Prusa | Krakowskie Przedmieście | monuments | ◐ | photo check |
| 118 | Kamienica Wedla | Szpitalna | tenement, chocolate shop | ✗ | photo build of the corner and its sign (parody) |
| 119 | Kamienica pod Gryfami, Kamienica Johna | Plac Trzech Krzyży / Krakowskie Przedmieście | tenements | ✗ | photo pass |
| 120 | Kamienica pod Zegarem and Chłodna's footbridge memorial (Kładka) | Chłodna | tenement, memorial | ✗ | the clock, the Kładka light sculpture |
| 121 | Hotel Saski, Pasaż Muranów, the Muranów estate | Plac Bankowy / Andersa | hotel, 1950s estate | ✗ | Muranów's rubble-brick blocks as a street dress |
| 122 | Osiedle Za Żelazną Bramą | Plac Żelaznej Bramy | 1960s estate | ◐ | photo check |
| 123 | Aleja Jana Pawła II's blocks and Kaskada | Aleja Jana Pawła II | 1950s blocks, offices | ○ | block-by-block pass from photos |
| 124 | Babka Tower, Atrium 2, Intraco Prime, North Gate | Aleja Jana Pawła II / Stawki / Bonifraterska | offices, flats | ✗ | photo build (Babka is the north's tallest) |
| 125 | Equator, Equator II, Brama Zachodnia, Proximo I and II, Crown Square, Prosta Office Center | Aleje Jerozolimskie / Prosta / Przyokopowa | office buildings | ✗ | office pass: skins by photo |
| 126 | Warsaw Corporate Centre, Centrum Giełdowe, Mysia 3, Liberty Corner, Nautilus, Ethos | Emilii Plater / Książęca / Mysia / Nowogrodzka | office buildings | ✗ | office pass |
| 127 | Żyletkowiec, Dom Słowa Polskiego, Dom Chłopa, Smyk's corner | Wspólna / Miedziana / Plac Powstańców / Krucza | modernist landmarks | ✗ | photo build (Dom Chłopa first: start area's south) |
| 128 | Atelier Residence, Rezydencja Foksal, Apartamenty Flare, Młotek, Solec Residence, Złota Chmielna | Bagno / Kopernika / Grzybowska / Smolna / Solec / Złota | upscale flats | ✗ | photo pass (Młotek is 66 m over Powiśle) |
| 129 | Platinum Towers, Łucka City, Ilmet, Central Tower, Spektrum, PZU, JM Tower, Chałubińskiego 8, Westynka, Chilton | Grzybowska / Łucka / Jana Pawła II / Jerozolimskie / Twarda / Chałubińskiego | skyscrapers | ○ | crowns by photo (tower table) |
| 130 | Torwar | Łazienkowska | arena | ✗ | photo build |
| 131 | Stadion Leguminy | Łazienkowska | stadium | ◐ | photo check |
| 132 | Gdański Business Center | Inflancka | offices | ◐ | photo check |
| 133 | WTS DESKA | Wioślarska | tennis club | ◐ | photo check |
| 134 | Klif | Okopowa | shopping centre | ✗ | plain glass mall, low priority |
| 135 | Galeria Wileńska and Dworzec Wileński | Targowa | shopping centre, metro | ✗ | outside the box today (the outside corner); only if the map grows |
| 136 | Skwer Hoovera's pavilions and the Christmas lights | Krakowskie Przedmieście | square | ✗ | the winter dress |
| 137 | Ogród Saski, Ogród Krasińskich, Park Ujazdowski | Marszałkowska / Świętojerska / Aleje Ujazdowskie | parks | ○ | park details in; the Saxon Garden's fountain and Wodozbiór (OSM: Wodozbiór "Świątynia Vesty") as models ✗ |
| 138 | Muzeum Karykatury, Kinomuzeum, Muzeum Niepodległości, Muzeum Wodociągów | Krakowskie Przedmieście / Marszałkowska / Aleja Solidarności / Nowogrodzka | small museums | ✗ | card and sign each |
| 139 | Warszawska Opera Kameralna, Teatr WARSawy, Pałac Ślubów | Aleja Solidarności / Freta / Rynek | culture | ✗ | card and sign each |
| 140 | Stara Prochownia, Collegium Nobilium, Klasztor Ojców Dominikanów (Kościół pw. Świętego Jacka) | Boleść / Miodowa / Freta | historic | ◐ | St Hyacinth is the church kit's; the others ✗ |

Tier C (named tenements, offices, embassies, small institutions) has no rows here: Part 2
lists all of them street by street with their status.

## Part 3. The top not-done items, one thread each

Proposed order for the next threads (photos first, see "Why some places were rebuilt"):

1. Most Poniatowskiego (14): real tower heights, arcades, balustrades, from photos.
2. Muzeum Powstania Warszawskiego (21): the brick power station, the wall, the tower.
3. Pomnik Powstania Warszawskiego and Plac Krasińskich's palace (22, 79).
4. Hotel Warszawa / Prudential (29) and Cedet (30): the start area's south.
5. Rondo ONZ towers by photo: Q22 and Rondo 1 first (28).
6. The monuments pass: Nike, Słowacki, Starzyński, Mały Powstaniec, Kiliński, Plac Piłsudskiego's (65-68), then 69, 70, 113-116.
7. Plac Bankowy's colonnades (64).
8. Świętokrzyska's big three: NBP, Poczta Główna, PAST-a (75, 76, 78); Filharmonia (77).
9. Photo re-pass of the outline builds on the first ten minutes' routes: Varso, Złote Tarasy, Teatr Wielki, Krakowskie Przedmieście (7, 8, 18, 24-27).
10. Praga's faces: the cathedral of St Michael and St Florian, Koneser, Bazar Różyckiego, Wschodnia (84-86, 73).

<!-- streets:start -->
## Part 2. Street by street

Generated by `python3 -I tools/city_inventory.py` from the map data and Part 1. Ranked places in bold with their number; the rest are named outlines in OpenStreetMap (tier C), marked "◐ model" when a hand-built site stands in them (the church kit, the hotels' fronts), "○ in game" when the game names them (a card, a sign, a skin), "○ old-town dress" for the dressed Old Town houses, and ✗ when they are a plain block. Streets are the nearest address point, so a corner building can sit on the cross street.

### Praga (50 places)

- **Targowa**: **#86 Bazar Różyckiego** ✗; **#135 Galeria Wileńska and Dworzec Wileński** ✗; Pasaż Handlowy "Targowa 33A" (commercial) ✗
- **Lubelska**: **#73 Warszawa Wschodnia** ✗; Klasztor pallotynów (monastery) ✗; Koleje Mazowieckie (offices) ✗; Warszawa Wschodnia (podmiejski) (station) ✗
- **Floriańska**: **#84 Bazylika Katedralna Świętego Michała Archanioła i Świętego Floriana Męczennika** ✗
- **Księdza Ignacego Kłopotowskiego**: Centrum Praha (public) ✗; Hit ✗; Kamienica Juliana Różyckiego (flats) ✗; Rainbow Center (government) ✗; Stacja Dializ (hospital) ✗; Symfonia (flats) ✗
- **Stefana Okrzei**: Kamienica pod Sowami (flats) ✗; Latarnia (flats) ✗; Manufaktura Praska (flats) ✗; Na Okrzei (flats) ✗; Port II (flats) ✗; Rezydencja Symfonia (flats) ✗
- **Grochowska**: Kościół pw. Matki Boskiej Zwycięskiej (cathedral) ◐ model; Allegro ✗; Plebania (presbytery) ✗; SPC (shop) ✗
- **Genewska**: Boathouse ✗; Wisełka (hotel) ✗
- **Jakuba Jasińskiego**: Budynek A (hospital) ✗; Przychodnia przyszpitalna (hospital) ✗
- **Jana Zamoyskiego**: Dworzec PKP Warszawa Stadion (station) ○ in game; Hotel Dedek Park (hotel) ✗
- **Sokola**: Marcowy Zając (offices) ✗; Narodowe Centrum Sportu (offices) ✗
- **Bliska**: Bliska Residence ✗
- **Finlandzka**: Pracownia Sztuk Plastycznych (offices) ✗
- **Francuska**: Restauracja Dom Polski (house) ✗
- **Jagiellońska**: Prokuratura Rejonowa Warszawa-Praga Północ (offices) ✗
- **Jakubowska**: Dom Funkcjonalny (semidetached_house) ✗
- **Józefa Sierakowskiego**: Centralne Biuro Śledcze Policji (public) ✗
- **Katowicka**: Dajemy Dzieciom Siłę (offices) ✗
- **Kijowska**: Ośrodek Dokumentacji Geodezyjnej PKP (offices) ✗
- **Kryniczna**: Białoruski Dom w Warszawie (commercial) ✗
- **Królowej Aldony**: Ambasada Łotwy (offices) ✗
- **Luksemburska**: Dwór Genzlów (house) ✗
- **Markowska**: Zbór „Praga dla Chrystusa” ✗
- **Olszowa**: Urząd Stanu Cywilnego Warszawa Praga-Północ (government) ✗
- **Panieńska**: Szpitalny Oddział Ratunkowy (hospital) ✗
- **Poselska**: Rezydencja ambasadora Portugalii (offices) ✗
- **Skaryszewska**: Kaplica pw. Matki Boskiej Częstochowskiej (church) ✗
- **Wał Miedzeszyński**: Ambasada Gruzji ✗
- **Wrzesińska**: DOSIR "Prawy Brzeg" (sports) ✗

### Stare Miasto (53 places)

- **Rynek Starego Miasta**: **#12 Rynek Starego Miasta and its Syrenka** ◐; **#39 Old Town and New Town tenements: Kamienica Pod Bazyliszkiem, Pod Murzynkiem, Fukierowska, Baryczkowska, Pod Okrętem** ○; Kamienica Balcerowska (flats) ○ old-town dress; Kamienica Baryczkowska (flats) ○ old-town dress; Kamienica Busserowska (flats) ○ old-town dress; Kamienica Falkiewiczowska (flats) ○ old-town dress; Kamienica Kazubowska (flats) ○ old-town dress; Kamienica Kleinpoldowska (flats) ○ old-town dress; Kamienica Klemensowska (flats) ○ old-town dress; Kamienica Pod Murzynkiem ○ old-town dress; Kamienica Talentich (flats) ○ old-town dress; Staromiejski Dom Kultury Słowa ✗
- **Miodowa**: **#99 Pałac Paca, Pałac Branickich (Miodowa), Pałac Prymasowski, Pałac Blanka, Pałac Jabłonowskich** ✗; **#100 Katedra polowa, the Cerkiew, Kapucyni (Miodowa churches)** ◐; Cerkiew pw. Zaśnięcia Najświętszej Marii Panny (church) ◐ model; Katedra polowa Wojska Polskiego Najświętszej Maryi Panny Królowej Polski (church) ◐ model; Bursa Szkolnictwa Artystycznego (dormitory) ✗; Monaster Zaśnięcia Najświętszej Bogurodzicy i św. Jozafata biskupa i męczennika (monastery) ✗
- **Nowomiejska**: **#23 Barbakan and the city walls** ◐; Kamienica Czechowska (flats) ○ old-town dress; Kamienica Montelupich (flats) ○ old-town dress; Kamienica Smockich (flats) ○ old-town dress; Kamienica pod św. Anną (flats) ○ old-town dress
- **Podwale**: **#67 Pomnik Małego Powstańca and Pomnik Jana Kilińskiego** ✗; Kościół pw. Świętego Ducha (church) ◐ model; Archiwum Główne Akt Dawnych (public) ✗
- **Jezuicka**: Archikatedra pw. Świętego Jana Chrzciciela ○ in game; Kamienica Długoszowa ○ old-town dress; Kamienica Pod Okrętem (flats) ○ old-town dress; Sanktuarium Matki Bożej Łaskawej ✗
- **Kanonia**: Arkady Kubickiego ✗; Dwór Dziekana Kapituły (flats) ✗; Stołeczne Centrum Edukacji Kulturalnej ✗
- **Piwna**: Kamienica Loupich (flats) ○ old-town dress; Kościół pw. Świętego Marcina (church) ◐ model; Dom Zakonny Sióstr Franciszkanek Służebnic Krzyża (monastery) ✗
- **Plac Zamkowy**: Kamienica Pod Pelikanem ○ old-town dress; Biblioteka Publiczna m. st. Warszawy (flats) ✗; Mansjonaria (flats) ✗
- **Szeroki Dunaj**: Kamienica Fukierowska (flats) ○ old-town dress; Kamienica Gizińska (flats) ○ old-town dress; Dom Szewców ✗
- **Długa**: Kamienica Gaszyńskiego ○ old-town dress; Komora Celna ✗
- **Freta**: Kamienica Piotra Hawermana ○ old-town dress; Kamienica Schenka ○ old-town dress
- **Krzywe Koło**: Kamienica Gębińska (flats) ○ old-town dress; Kamienica Mirosławska (flats) ○ old-town dress
- **Brzozowa**: Kamienica Bornbachów (flats) ○ old-town dress
- **Bugaj**: Wieczór nad Wisłą (boat) ○ in game
- **Mostowa**: Warszawskie Centrum Innowacji Edukacyjno-Społecznych i Szkoleń ✗
- **Piekarska**: Dom Prowincjalny Sióstr Elżbietanek (convent) ✗
- **Świętojerska**: Mazowieckie Samorządowe Centrum Doskonalenia Nauczycieli (offices) ✗

### Muranów (47 places)

- **Mordechaja Anielewicza**: **#20 Muzeum Historii Żydów Polskich Polin and Pomnik Bohaterów Getta** ★; SM Miła (offices) ✗
- **Stawki**: **#70 Umschlagplatz memorial** ✗; Budynek dydaktyczny - Szkoła Rodzenia "Baby Care" (hospital) ✗
- **Inflancka**: **#132 Gdański Business Center** ◐
- **Dzielna**: Hala Sportowa SP210 (school) ✗; Kamienica Muranów (flats) ✗; Przedszkole nr 124 (kindergarten) ✗; Społem (shop) ✗; Spółdzielnia Mieszkaniowa "Muranów" (offices) ✗; Szkoła Podstawowa nr 210 im. Bohaterów Pawiaka (school) ✗
- **Długa**: Biuro Rzecznika Praw Obywatelskich (public) ✗; Pałac Marii z Lubomirskich Radziwiłłowej (palace) ✗; Pałac Teppera-Dückerta (palace) ✗; Pałac na Podkańskiem ✗; Wydział Nauk Ekonomicznych UW ✗; Złota Milonga ✗
- **Aleja „Solidarności”**: Kościół Ewangelicko-Reformowany (church) ◐ model; Dom Dysydentów ✗; Kamienica Jacobsona (flats) ✗
- **Nowolipki**: Kościół pw. Świętego Augustyna (church) ◐ model; Pałac Mostowskich (public) ✗; ZGN Wola (offices) ✗
- **Senatorska**: Dom Bankowy Landaua ○ in game; Pałac Mniszchów ○ in game; Pałac Błękitny ✗
- **Spokojna**: Izba Wytrzeźwień ✗; Katakumby ✗; Kościół pw. Świętego Karola Boromeusza ✗
- **Karmelicka**: Kościół parafialny pw. Narodzenia Najświętszej Maryi Panny (church) ◐ model; Akademia WSB Wydział Zamiejscowy w Warszawie (university) ✗
- **Niska**: Bursa nr 6 w Warszawie (dormitory) ✗; Rezydencja Niska 30 (flats) ✗
- **Nowolipie**: Centrum Aktywności Międzypokoleniowej „Nowolipie” (public) ✗; Pałac Działyńskich (university) ✗
- **Zygmunta Słomińskiego**: Apartamenty Gdański ✗; Słomińskiego Art Office (offices) ✗
- **Świętojerska**: Instytut Pamięci Narodowej ✗; Sąd Najwyższy ✗
- **Aleja Jana Pawła II**: Kamienica Trachtenberga ✗
- **Antonia Corazziego**: Carrefour Express (shop) ✗
- **Generała Władysława Andersa**: Ibis Warszawa Stare Miasto ✗
- **Ludwika Zamenhofa**: Dom studencki nr 4 (dormitory) ✗
- **Miła**: NZOZ Karmelicka (commercial) ✗
- **Okopowa**: Vizja Park (offices) ✗
- **Pawia**: Pływalnia Foka (sports hall) ✗
- **Stare Nalewki**: Villa Bogoria (flats) ✗

### Śródmieście (97 places)

- **Świętokrzyska**: **#75 Narodowy Bank Polski** ✗; **#76 Poczta Główna** ✗; **#105 Ministerstwo Finansów** ◐; Instytut Ekonomiki Rolnictwa i Gospodarki Żywnościowej ✗
- **Bracka**: **#80 Vitkac** ✗; **#81 Dom Towarowy Braci Jabłkowskich** ✗; Kamienica Zofii Kiersnowskiej (flats) ✗; Pałac Brzozowskich (flats) ✗
- **Chmielna**: **#7 Varso Tower (with Varso I, Varso II)** ◐; **#97 Kawiarnia and bar street of Chmielna, Mokotowska, Hoża, Poznańska** ○; Kamienica Braci Jabłkowskich (commercial) ✗; Kamienica Lilpopów (flats) ✗
- **Jasna**: **#77 Filharmonia Narodowa** ✗; **#103 Dom pod Orłami and Skwer Linearny na Złotej** ★; Centrum Jasna ✗; Kamienica Maksymiliana Harczyka (flats) ✗
- **Złota**: **#5 Złota 44** ★; **#8 Złote Tarasy (with Lumen, Skylight)** ◐; Kiseki (shop) ✗; Wojskowe Biuro Emerytalne ✗
- **Królewska**: **#104 Hotel Wiktoria (Sofitel Victoria) and Królewska** ◐; **#106 Saski Crescent, Saski Park, Senator** ✗
- **Zielna**: **#78 PAST-a** ✗; Mała PAST-a (commercial) ✗; Pałac Janaszów (offices) ✗
- **Plac Grzybowski**: **#102 Plac Grzybowski and Kościół Wszystkich Świętych** ◐; Kamienica Brenkina ✗
- **Bagno**: **#128 Atelier Residence, Rezydencja Foksal, Apartamenty Flare, Młotek, Solec Residence, Złota Chmielna** ✗
- **Próżna**: **#101 Synagoga Nożyków and Próżna's pre-war tenements (Kamienica Zalmana Nożyka, Kamienica Wolanowskiego)** ◐
- **Szpitalna**: **#118 Kamienica Wedla** ✗
- **Marszałkowska**: Central Point ✗; Centrum Królewska ✗; Centrum Marszałkowska ✗; PKO BP ✗; Wolf Marszałkowska ✗
- **Miodowa**: Kościół Przemienienia Pańskiego (church) ◐ model; Klasztor Ojców Kapucynów (monastery) ✗; Pałac Arcybiskupi d. Pałac Borchów (palace) ✗; Pałac Chodkiewiczów ✗; Pałac Szaniawskich (palace) ✗
- **Senatorska**: Kościół Świętego Antoniego Padewskiego (church) ◐ model; Biuro Rent Zagranicznych Zakładu Ubezpieczeń Społecznych (offices) ✗; Kamienica Małachowskiego (offices) ✗; Pałac Biskupów Krakowskich (palace) ✗; Zakład Ubezpieczeń Społecznych ✗
- **Grzybowska**: Grzybowska Park (commercial) ✗; Osiedle "Graniczna" (flats) ✗; Pasaż Saski (flats) ✗; Radisson Collection Hotel (hotel) ✗
- **Nowogrodzka**: Hotel Metropol ○ in game; Novotel Warszawa Centrum ○ in game; Gmach Urzędu Telekomunikacyjnego i Telegraficznego (offices) ✗; N21 (offices) ✗
- **Aleje Jerozolimskie**: PKP Warszawa Śródmieście (station) ○ in game; Kamienica Hoserów (flats) ✗; Kamienica Lipińskiego (flats) ✗
- **Tadeusza Czackiego**: Brain Embassy (offices) ✗; Dom Technika (offices) ✗; Kapsuła Hostel (commercial) ✗
- **Emilii Plater**: Warszawskie Centrum Finansowe ○ in game; Igrek ✗
- **Kredytowa**: Ministerstwo Cyfryzacji (government) ✗; Urząd m.st. Warszawy (flats) ✗
- **Mazowiecka**: Hotel Mazowiecki ✗; Okręg Warszawski Związku Polskich Artystów Plastyków ✗
- **Przeskok**: Astoria ✗; Wojewódzki Sąd Administracyjny (flats) ✗
- **Ptasia**: Pałac Lubomirskich ✗; Tadeusz Kościuszko ✗
- **Twarda**: Spektrum Tower ○ in game; Biały Budynek (flats) ✗
- **Widok**: Puro Warszawa Centrum (hotel) ○ in game; Widok Towers ○ in game
- **Wierzbowa**: Kamienica Dmuszewskiego (offices) ✗; Kamienica Petyskusa ✗
- **Aleja Jana Pawła II**: PZU Tower ○ in game
- **Aleja „Solidarności”**: Dom Pod Królami (palace) ✗
- **Bielańska**: Kościół św. Brata Alberta i św. Andrzeja Apostoła (church) ◐ model
- **Daniłowiczowska**: Reduta Bank Polski ✗
- **Elektoralna**: Mazowiecki Instytut Kultury (public) ✗
- **Gabriela Piotra Boduena**: Naczelny Sąd Administracyjny (civic) ✗
- **Henryka Sienkiewicza**: Urząd Ochrony Konkurencji i Konsumentów ✗
- **Kapitulna**: Pałac Młodziejowskiego (palace) ✗
- **Krucza**: Mercure Warszawa Grand ✗
- **Krzysztofa Kamila Baczyńskiego**: Rezydencja Warecka (flats) ✗
- **Leona Schillera**: Sąd Rejonowy dla Warszawy-Mokotowa ✗
- **Mariańska**: Skysawa ○ in game
- **Mysia**: Polska Grupa Energetyczna ✗
- **Niecała**: PURO Warszawa Stare Miasto (hotel) ✗
- **Nowy Świat**: Nowy Świat 2.0 ✗
- **Plac Jana Henryka Dąbrowskiego**: Ambasada Włoch (flats) ✗
- **Plac Stanisława Małachowskiego**: Kamienica Krasińskich ✗
- **Sienna**: Mercure Warszawa Centrum ✗
- **Stanisława Moniuszki**: Telewizja Polska (commercial) ✗
- **Wojciecha Górskiego**: Restaura Górskiego (flats) ✗
- **Świętej Barbary**: Urząd Dzielnicy Śródmieście ✗
- **Żurawia**: Ministerstwo Aktywów Państwowych (government) ✗

### Trakt Królewski (76 places)

- **Krakowskie Przedmieście**: **#25 Kościół św. Anny** ◐; **#26 Hotel Bristol and Hotel Europejski** ◐; **#27 Pałac Prezydencki** ◐; **#32 Pomnik Mikołaja Kopernika and Pałac Staszica** ◐; **#33 Pomnik Adama Mickiewicza** ◐; **#34 Kościół Świętego Krzyża** ◐; **#35 Brama Uniwersytetu Warszawskiego and Pałac Kazimierzowski** ◐; **#36 Kościół Wizytek, Kościół Karmelitów** ◐; **#37 Pałac Potockich, Kordegarda, Pałac Czapskich** ◐; **#108 Uniwersytet: Auditorium Maximum, Stary BUW, Biblioteka Królewska** ✗; **#117 Pomnik Kardynała Wyszyńskiego, Pomnik Bolesława Prusa** ◐; **#136 Skwer Hoovera's pavilions and the Christmas lights** ✗; **#138 Muzeum Karykatury, Kinomuzeum, Muzeum Niepodległości, Muzeum Wodociągów** ✗; Kościół Niepokalanego Poczęcia Najświętszej Maryi Panny (church) ◐ model; Kościół Wniebowzięcia Najświętszej Maryi Panny i świętego Józefa Oblubieńca (church) ○ in game; Kościół pw. Świętego Krzyża (church) ○ in game; Kościół pw. Świętej Anny (church) ○ in game; Centrum Nauczania Języków Obcych UW (university) ✗; Departament Mecenatu Państwa Ministerstwa Kultury i Dziedzictwa Narodowego ✗; Dom Polonii (offices) ✗; Dziekanka (offices) ✗; Instytut Filologii Klasycznej UW (university) ✗; Instytut Kultury Polskiej UW (university) ✗; Kamienica Heyna (flats) ✗; Kamienica Roesslera i Hurtiga (shop) ✗; Kamienica Skalskiego (flats) ✗; Narodowy Instytut Kultury i Dziedzictwa Wsi (public) ✗; Nowa Dziekanka (dormitory) ✗; Wydział Filozofii UW (university) ✗; Wydział Geografii i Studiów Regionalnych UW (university) ✗; Wydział Historii UW (university) ✗; Wydział Nauk Politycznych i Studiów Międzynarodowych (university) ✗; Wydział Prawa i Administracji UW (university) ✗
- **Nowy Świat**: **#40 Nowy Świat tenements and palaces (Zamoyski, Mikulski, Bürger, Jasiński, Kossakowski)** ○; **#48 Dom Partii and Rondo de Gaulle'a's palm** ◐; **#49 Pawilony za Nowym Światem** ◐; Kamienica Bürgera (flats) ○ in game; Kamienica Jasińskiego (flats) ○ in game; Kamienica Mikulskiego przy Nowym Świecie 53 (flats) ○ in game; Kamienica Mikulskiego przy Nowym Świecie 55 (flats) ○ in game; Pałac Kossakowskich (commercial) ○ in game; Pałac Zamoyskich (university) ○ in game
- **Plac Trzech Krzyży**: **#41 Kościół Świętego Aleksandra and Plac Trzech Krzyży** ◐; **#119 Kamienica pod Gryfami, Kamienica Johna** ✗
- **Karowa**: Biuro Bezpieczeństwa Narodowego (government) ✗; Budynek "pod Wizytkami" (university) ✗; Dawne Centrum Informatyczne UW (university) ✗; Instytut Slawistyki Zachodniej i Południowej UW (university) ✗; Klasztor Sióstr Wizytek (convent) ✗; Polskie Towarzystwo Higieniczne ✗; Wydział Socjologii (offices) ✗
- **Oboźna**: Collegium Iuridicum III (university) ✗; Stołówka Uniwersytecka (university) ✗; Wydział Archeologii UW (university) ✗; Wydział Kultur Azji i Afryki (university) ✗; Wydział Neofilologii (university) ✗; Wydział Polonistyki UW (university) ✗
- **Królewska**: Departament Wojskowej Służby Zdrowia (offices) ○ in game; Dom Bez Kantów ○ in game; Kamienica Grodzickiego ✗; Oficyna Pałacu Potockich (Archiwum UW) (university) ✗; Pałac Tyszkiewiczów-Potockich (university) ✗
- **Bednarska**: Kamienica Wernera (flats) ✗; Państwowa Szkoła Muzyczna II St. nr 2 im. Fryderyka Chopina (school) ✗
- **Bracka**: Polska Agencja Prasowa (offices) ✗; Wydział Stosowanych Nauk Społecznych i Resocjalizacji UW (university) ✗
- **Senatorska**: Kamienica Prażmowskich (flats) ✗; Pałac Małachowskiego (flats) ✗
- **Żurawia**: Ministerstwo Funduszy i Polityki Regionalnej (government) ✗; Ministerstwo Rozwoju i Technologii ✗
- **Aleje Jerozolimskie**: Kuratorium Oświaty (offices) ✗
- **Hoża**: Ministerstwo Nauki i Szkolnictwa Wyższego (government) ✗
- **Kozia**: Pałac Wesslów ✗
- **Romualda Traugutta**: Dom zakonny Księży Misjonarzy (monastery) ✗
- **Sewerynów**: Dom Generalny Zgromadzenia Sługi Jezusa (flats) ✗
- **Smolna**: Indigo (commercial) ✗

### Powiśle (55 places)

- **Wybrzeże Kościuszkowskie**: **#15 Most Świętokrzyski** ◐; **#16 Centrum Nauki Kopernik and Planetarium** ★; **#31 Pomnik Syreny nad Wisłą** ◐; **#93 The river barges and the marina (Wieczorek, Biała Barka, Marinka, Kaskadka)** ◐; **#94 Bulwary Wiślane: Schodki, the pavilions, the containers** ⏳; Dworzec Wodny ○ in game; Marina Warszawa (boat) ○ in game; Pawilon 512 ✗; Pracownia Przewrotu Kopernikańskiego ✗
- **Dobra**: **#17 Biblioteka Uniwersytecka (BUW) and its roof garden** ★; **#55 Elektrownia Powiśle** ◐; Bella Italia (shop) ✗; Kamienica Jana Struskiego (flats) ✗; Młodsza Siostra (shop) ✗; Pawilon Tańca ✗; Wydział "Artes Liberales" UW (university) ✗; Wydział Prawa i Administracji UW. Collegium Iuridicum IV (university) ✗
- **Tamka**: **#110 Zamek Ostrogskich and the Chopin Institute** ◐; Narodowy Instytut Fryderyka Chopina (offices) ○ in game; Parafia Świętej Teresy od Dzieciątka Jezus (church) ○ in game; Hostel Tatamka (hotel) ✗
- **Topiel**: **#111 Piano House, Cube House, Hortus, Moderna, Dobra and Tamka tenements** ◐
- **Aleja 3 Maja**: Autoreduta Powiśle (shop) ✗; Centrum Handlowe Arkada (shop) ✗; Nordic Park (offices) ✗; Orlen (shop) ✗
- **Zajęcza**: Moderna Powiśle (flats) ○ in game; Barceló (hotel) ✗; Carpathia Office House (offices) ✗; Stacja elektroenergetyczna 110/15 kV „RPZ Warszawa Powiśle” (offices) ✗
- **Foksal**: Dom Dziennikarza (commercial) ✗; Pawilon wystawowo-konferencyjny SARP (offices) ✗; Pałac Przezdzieckich (government) ✗
- **Smolna**: Dworzec PKP Powiśle ○ in game; Klub Bankowca (offices) ✗; XVIII Liceum Ogólnokształcące im. Jana Zamoyskiego (school) ✗
- **Frascati**: Biały Pałacyk ✗; Willa Pniewskiego ✗
- **Książęca**: Domek Holenderski (house) ✗; Yours House (offices) ✗
- **Wioślarska**: The Tides (offices) ✗; Warszawskie Towarzystwo Wioślarskie (offices) ✗
- **Wiślana**: Bursa Salezjańska dla Młodzieży Męskiej imienia Księdza Siemca (dormitory) ✗; Szary Dom ✗
- **Adama Idźkowskiego**: Pałacyk Simona de Symonowicza (kindergarten) ✗
- **Bednarska**: Wydział Dziennikarstwa, Informacji i Bibliologii (university) ✗
- **Browarna**: Dom Księży Misjonarzy św. Wincentego a Paulo ✗
- **Dynasy**: Rotunda na Dynasach ✗
- **Emiliana Konopczyńskiego**: Motel One Warsaw-Chopin ✗
- **Juliana Smulikowskiego**: Związek Nauczycielstwa Polskiego (offices) ✗
- **Lipowa**: Collegium Iuridicum II (university) ○ in game
- **Ludna**: GfK Polonia (offices) ✗
- **Mieczysława Orłowicza**: Rezydencja Orłowicza (flats) ✗
- **Oboźna**: Dom Strażaka (offices) ✗
- **Okólnik**: Gmach Biblioteki Ordynacji Krasińskich (commercial) ✗

### Wola (121 places)

- **Aleje Jerozolimskie**: **#9 Warszawa Centralna** ★; **#47 Muzeum Narodowe and Muzeum Wojska Polskiego's yard** ◐; **#62 Centrum LIM (Marriott) and Novotel** ★; **#71 Warszawa Śródmieście, Ochota, Powiśle, Stadion stations** ★; **#89 Hotel Polonia Palace, Radisson Blu Sobieski (Radysław Blu)** ◐; **#91 Bars and clubs with parody names: Lusterko, Smoła, Jasna 0, Lombard, Miłość Hipoteczna, 1499 M2, Plan C, Apteczka, Przegryzki Zagryzki, Kasa Biletowa, Żwir, Bar Pyzowy, Hocki Bloki** ○; **#92 Level 26** ◐; **#125 Equator, Equator II, Brama Zachodnia, Proximo I and II, Crown Square, Prosta Office Center** ✗; Warszawa Ochota (station) ○ in game; Kamienica Stanisława Rostkowskiego (flats) ✗; Nimbus ✗
- **Aleja Jana Pawła II**: **#58 Westfield Arkadia (Arkadka)** ◐; **#59 Forest** ◐; **#123 Aleja Jana Pawła II's blocks and Kaskada** ○; **#124 Babka Tower, Atrium 2, Intraco Prime, North Gate** ✗; The Westin Warsaw ○ in game; Atrium Centrum ✗; Atrium Plaza ✗; Deloitte House ✗; Life Building ✗; Wise Point ✗
- **Grzybowska**: **#57 Browary Warszawskie** ◐; **#61 Wola towers: The Bridge, Generation Park X and Z, Atlas Tower, Pekao Tower, Warsaw Towers** ○; **#129 Platinum Towers, Łucka City, Ilmet, Central Tower, Spektrum, PZU, JM Tower, Chałubińskiego 8, Westynka, Chilton** ○; Biura przy Bramie (offices) ○ in game; Biura przy Warzelni ○ in game; Biura przy Willi ○ in game; Concept Tower ✗; Kamienica Gawłowiczów (flats) ✗; Karolkowa Business Park ✗; Kolmex ✗; Prime Corporate Center ✗; Wydział Ruchu Drogowego Komendy Stołecznej Policji ✗
- **Prosta**: **#56 Fabryka Norblina** ◐; Crown Point (offices) ✗; Mennica Legacy Tower Budynek Zachodni (commercial) ✗; Prosta Tower ✗; Studio A ✗
- **Chłodna**: **#120 Kamienica pod Zegarem and Chłodna's footbridge memorial (Kładka)** ✗; Kamienica Markowskiego (flats) ✗; Meridian (flats) ✗
- **Przyokopowa**: **#21 Muzeum Powstania Warszawskiego** ✗; Proximo II (offices) ✗; Wola Center ✗
- **Plac Europejski**: **#6 Warsaw Spire** ★; Bellona (offices) ✗
- **Plac Mirowski**: **#53 Hala Mirowska and Hala Gwardii** ◐; Kamienica Mulmanów (flats) ✗
- **Okopowa**: **#134 Klif** ✗
- **Żelazna**: Dom Kereta ✗; Feniks (commercial) ✗; Kamienica "Pod Strzelcem" (flats) ✗; Kamienica Partowicza (flats) ✗; SwedeCenter ✗; Wojewódzka Stacja Sanitarno-Epidemiologiczna ✗; Zgromadzenie Sióstr Franciszkanek Rodziny Maryi (religious) ✗
- **Nowogrodzka**: Kościół parafialny pw. Dzieciątka Jezus (church) ◐ model; Dom Księdza Boduena ✗; Muzeum Wodociągów i Kanalizacji ✗; Ośrodek Edukacji Informatycznej i Zastosowań Komputerów (university) ✗; Placówka opiekuńczo-wychowawcza "Bajkowy Dworek" ✗; Warszawskie Centrum Zdrowia (shop) ✗
- **Łucka**: Platinum Tower A (flats) ○ in game; Platinum Tower B (flats) ○ in game; Cosinus (school) ✗; Galwan (commercial) ✗; Plater (commercial) ✗; Studio B ✗
- **Aleja „Solidarności”**: Chronos ✗; Kamienica Jabłońskiego ✗; Sąd Okręgowy w Warszawie (offices) ✗; Willa Natalia (flats) ✗
- **Sienna**: Kościół Zielonoświątkowy (church) ◐ model; Instytut Pileckiego (offices) ✗; Nowa Sienna Building (offices) ✗; Sienna Center (offices) ✗
- **Wronia**: Hilton Warsaw City ○ in game; Bar a Boo (shop) ✗; Office House ✗; Oxygen (flats) ✗
- **Chmielna**: HOP (offices) ✗; Kamienica Bagieńskiego (flats) ✗; V Tower ✗
- **Ogrodowa**: City Gate (offices) ✗; Ibis Warszawa Centrum ✗; Wojewódzki Fundusz Ochrony Środowiska i Gospodarki Wodnej (offices) ✗
- **Skwer Kardynała Stefana Wyszyńskiego**: Kościół pw. Miłosierdzia Bożego i Świętej Faustyny (church) ◐ model; Dom Sióstr Uczennic Boskiego Mistrza (convent) ✗; Katolicka Agencja Informacyjna (commercial) ✗
- **Towarowa**: Generation Park Z ✗; Moxy Warsaw City (hotel) ✗; Vibe ✗
- **Daleka**: Centrum Zaopatrzenia Fryzjerów (shop) ✗; Salzburg Center ✗
- **Grójecka**: Kościół parafialny pw. Niepokalanego Poczęcia Najświętszej Maryi Panny ✗; Mazowiecki Dom Pogrzebowy (shop) ✗
- **Hrubieszowska**: Crown Tower (offices) ✗; Metropoint Office (offices) ✗
- **Pańska**: The Form ✗; Verit (commercial) ✗
- **Raszyńska**: Cartech (industrial) ✗; Ośrodek Edukacji Informatycznej i Zastosowań Komputerów w Warszawie ✗
- **Słupecka**: Polityka (offices) ✗; Sala św. Faustyny (chapel) ✗
- **Tadeusza Joteyki**: Pauza Ochota (flats) ✗; Wojewódzka Stacja Pogotowia Ratunkowego (hospital) ✗
- **Twarda**: Holiday Inn Warszawa City Centre ✗; Kamienica Lejba Osnosa (flats) ✗
- **Waliców**: Ibis Styles Warszawa City (hotel) ✗; Kaplica Kościoła Baptystów (chapel) ✗
- **Złota**: Kamienica Wolfa Krongolda (flats) ✗; Zarząd Dróg Miejskich (government) ✗
- **Biała**: Kościól Św. Karola Boromeusza (church) ◐ model
- **Icchoka Lejba Pereca**: Apartamenty Pereca (flats) ✗
- **Juliana Ursyna Niemcewicza**: Stacja ozonowania pośredniego „Sokrates” (industrial) ✗
- **Krochmalna**: Rezydencja Krochmalna 44 (flats) ✗
- **Miedziana**: M7 ✗
- **Plac Sokratesa Starynkiewicza**: Miejskie Przedsiębiorstwo Wodociągów i Kanalizacji (offices) ✗
- **Spiska**: Instytut Edukacji Artystycznej Akademii Pedagogiki Specjalnej (flats) ✗
- **Srebrna**: Pałacyk Sikorskiego (public) ✗
- **Sękocińska**: Wojskowe Centrum Rekrutacji Warszawa-Ochota (offices) ✗

### Śródmieście Południowe (89 places)

- **Marszałkowska**: **#2 Rotunda** ★; **#3 Domy Towarowe Centrum: Junior, Sawa, Wars** ★; **#4 Muzeum Sztuki Nowoczesnej** ★; **#50 Plac Konstytucji and MDM** ◐; **#51 Kościół Najświętszego Zbawiciela and Plac Zbawiciela** ◐; **#52 Rondo Dmowskiego and Patelnia (Metro Centrum)** ◐; **#90 Plac Defilad's pavilions: Cepelia, Zodiak, Scena Relax** ◐; **#95 Milk bars: Bar Prasowy (Marszałkowska), Bar Familijny (Nowy Świat), Bar Bambino (Krucza), Bar Pod Barbakanem (Mostowa)** ✗; **#137 Ogród Saski, Ogród Krasińskich, Park Ujazdowski** ○; Kamienica Domańskich (flats) ✗; M76 (offices) ✗
- **Koszykowa**: **#54 Hala Koszyki** ◐; Biblioteka Publiczna m.st. Warszawy (public) ✗; Dom Medyków ✗; Gmach Matematyki i Nauk Informacyjnych ✗; Gmach Szkoły Biznesu (university) ✗; Gmach Technologii Chemicznej ✗; Katedra i Zakład Medycyny Sądowej (university) ✗; Klinika Dermatologiczna WUM (university) ✗; Nobu Hotel Warsaw (hotel) ✗; Nowa Kreślarnia (university) ✗
- **Wspólna**: **#127 Żyletkowiec, Dom Słowa Polskiego, Dom Chłopa, Smyk's corner** ✗; Kościół pw. Świętych Apostołów Piotra i Pawła (church) ◐ model; Hampton by Hilton Warsaw City Centre ✗; Park Avenue ✗; Ufficio Primo (offices) ✗
- **Emilii Plater**: **#126 Warsaw Corporate Centre, Centrum Giełdowe, Mysia 3, Liberty Corner, Nautilus, Ethos** ✗; Komuna Warszawa (school) ✗; Rezydencja Ambasadora Maroka (house) ✗
- **Krucza**: **#30 Cedet (Dom Towarowy CDT)** ✗; Referat Paszportów nr 1 (flats) ✗
- **Plac Zbawiciela**: **#96 Plan B's corner, Plac Zbawiciela's café row** ○
- **Filtrowa**: Ministerstwo Obrony Narodowej ○ in game; Ambasada Izraela ✗; Focus ✗; Gmach Rektorska 4 ✗; Instytut Techniki Budowlanej ✗; Najwyższa Izba Kontroli ✗; Ośrodek Akademicki "Przy Filtrowej" (dormitory) ✗; Spółdzielnia Budowlano-Mieszkaniowa (offices) ✗; Stołówka Centralna (university) ✗
- **Nowowiejska**: Budynek Starej Kotłowni (university) ✗; Gmach Aerodynamiki (university) ✗; Gmach Elektrotechniki (university) ✗; Gmach Fizyki (university) ✗; Gmach Inżynierii Środowiska (university) ✗; Gmach Mechaniki (university) ✗; Muzeum Politechniki Warszawskiej (university) ✗; Specjalistyczna Przychodnia Lekarska dla Pracowników Wojska ✗
- **Aleja Niepodległości**: Gmach Lotniczy (university) ✗; Gmach Nowy Lotniczy (university) ✗; ITLIMS ✗; Pałacyk Rektorski ✗; Służba Wywiadu Wojskowego (offices) ✗
- **Piękna**: IPC Business Centre ✗; Stoen Operator ✗; The Nest (offices) ✗; Willa Struvego (offices) ✗; Zaułek Piękna ✗
- **Nowogrodzka**: Dom Katolicki "Roma" (commercial) ✗; Dom Parafialny im. Prymasa Tysiąclecia ✗; Prima Court (offices) ✗; RCKiK w Warszawie TO III Warszawa (hospital) ✗
- **Stanisława Noakowskiego**: Budynek Pod Kominem (university) ✗; Gmach Chemii (university) ✗; Instytut Techniki Cieplnej ✗; Wydział Transportu PW ✗
- **Księdza Ignacego Skorupki**: Bankowy Fundusz Gwarancyjny (offices) ✗; Skłot "Przychodnia" (commercial) ✗; Stratos Office Center (offices) ✗
- **Mokotowska**: Instytut Adama Mickiewicza (offices) ✗; Mokotowska Square (offices) ✗; Wydział Pedagogiczny UW (university) ✗
- **Polna**: 2 Społeczne Liceum Ogólnokształcące STO imienia Pawła Jasienicy (school) ✗; Bazar Polna (shop) ✗; Wydział Elektroniki i Technik Informacyjnych (university) ✗
- **Wilcza**: Komenda Rejonowa Policji Warszawa I (public) ✗; Muzeum i Instytut Zoologii PAN (commercial) ✗; Skłot "Syrena" (flats) ✗
- **Aleje Jerozolimskie**: Kamienica Mikołaja Szelechowa (flats) ✗; Nowogrodzka Square ✗
- **Lwowska**: Gmach Architektury (university) ✗; Norway House (offices) ✗
- **Hoża**: PGE Energetyka Kolejowa (offices) ✗
- **Jana i Jędrzeja Śniadeckich**: Instytut Matematyczny PAN (offices) ✗
- **Ludwika Waryńskiego**: Polna Corner (offices) ✗
- **Tytusa Chałubińskiego**: Collegium Anatomicum (hospital) ✗
- **Świętej Barbary**: Centrum Systemów Telekomunikacyjnych (offices) ✗
- **Żurawia**: Dom Spółdzielczości Pracy (flats) ✗

### Ujazdów i Łazienki (55 places)

- **Wiejska**: **#42 Sejm and Senat** ◐; **#82 Sheraton Grand Warsaw** ✗; **#114 Pomnik Polskiego Państwa Podziemnego i Armii Krajowej, Pomnik Wincentego Witosa, Pomnik Ignacego Daszyńskiego** ✗; Kamienica Karskich (offices) ✗
- **Aleje Ujazdowskie**: **#112 Kamienica Pod Gigantami, Pałac Pod Karczochem, Kamienica Ławrynowicza and Aleje Ujazdowskie's villas** ✗; **#113 Pomnik Ronalda Reagana, Pomnik Romana Dmowskiego (Plac Na Rozdrożu)** ✗; Kamienica Jakuba Lindelfelda ✗; Kamienica Kulkiewicza (offices) ✗; Kamienica Pusłowskiego (flats) ✗; Pałac Karnickich (offices) ✗; Pałac Sobańskich (offices) ✗; Pałacyk Dziewulskich ✗; Willa L. Jaroszczyńskiego ✗
- **Jazdów**: **#43 Zamek Ujazdowski** ◐; Główna Biblioteka Lekarska im. Stanisława Konopki ○ in game; Instytut Teatralny im. Z. Raszewskiego ○ in game; Dawna Łaźnia (offices) ✗; Oddział XV Dzienny Psychiatryczny Rehabilitacyjny (hospital) ✗; Rotacyjny Dom Kultury (house) ✗
- **Czerniakowska**: **#116 Pomnik Sapera** ✗
- **Górnośląska**: Sejm RP ○ in game; Kamienica Leona Breslauera (flats) ✗; Monkey Love (shop) ✗; Stary Dom Poselski ✗; Yutori ✗
- **Aleja Róż**: Ambasada Serbii (offices) ✗; Kamienica Szelechowa (government) ✗; Pałacyk Wielopolskich (offices) ✗; Wydział Konsularny Ambasady Czech (commercial) ✗
- **Fryderyka Chopina**: Ambasada Węgier (offices) ✗; Pałacyk Leszczyńskich ✗; Pałacyk Śleszyńskich (commercial) ✗
- **Jana Matejki**: Ambasada Kanady Wydział Wizowy i Imigracji (government) ✗; Budynek Komisji Sejmowych ✗; Desa Unicum (commercial) ✗
- **Myśliwiecka**: Dom Oficerski Funduszu Kwaterunku Wojskowego (flats) ✗; Oficyna Ermitażu ✗; Polskie Radio ✗
- **Zagórna**: Matki Bożej Częstochowskiej (church) ◐ model; Ibis Budget Warszawa Centrum (hotel) ✗; Ibis Styles (hotel) ✗
- **Fabryczna**: Biuro Legia Sekcja Strzelecka (offices) ✗; Strzelnica Legia ✗
- **Frascati**: Dom Poselski (hotel) ✗; Kancelaria Senatu (government) ✗
- **Mokotowska**: Kamienica "Krakowiacy i Górale" (shop) ✗; Mokotowska 69 (shop) ✗
- **Przemysłowa**: Kościół Matki Bożej Jerozolimskiej (church) ◐ model; Torwar II (sports hall) ✗
- **Aleja Na Skarpie**: Stary Budynek Komisji Sejmowych ✗
- **Francesca Nulla**: Wolf Nullo (offices) ✗
- **Piękna**: Willa Raua (government) ✗
- **Plac Na Rozdrożu**: Rozdroże 1974 (shop) ✗
- **Profesorska**: Ambasada Tunezji (commercial) ✗
- **Świętej Teresy**: Ministerstwo Sprawiedliwości (government) ✗

### poza dzielnicami (40 places)

- **Plac Bankowy**: **#63 Błękitny Wieżowiec and Plac Bankowy** ○; **#64 Plac Bankowy's palaces: Ratusz, Mazowiecki Urząd Wojewódzki, Gmach Giełdy i Banku Polskiego, Arsenał** ○; **#65 Pomnik Juliusza Słowackiego and Pomnik Stefana Starzyńskiego** ✗; **#121 Hotel Saski, Pasaż Muranów, the Muranów estate** ✗
- **Plac Zamkowy**: **#10 Zamek Królewski** ⏳; **#11 Kolumna Zygmunta** ◐; **#38 Plac Zamkowy's houses and Mariensztat** ○; **#109 Pałac Pod Blachą and Biblioteka Królewska** ✗
- **Aleja Solidarności**: **#66 Pomnik Bohaterów Warszawy (Nike)** ✗; **#87 Park Praski's bear enclosure (Wybieg dla niedźwiedzi)** ✗; **#139 Warszawska Opera Kameralna, Teatr WARSawy, Pałac Ślubów** ✗
- **Plac Piłsudskiego**: **#19 Grób Nieznanego Żołnierza and Plac Piłsudskiego** ◐; **#46 Metropolitan** ◐; **#68 Pomnik Józefa Piłsudskiego, the Smolensk monuments, Pomnik Lecha Kaczyńskiego** ✗
- **Plac Krasińskich**: **#22 Pomnik Powstania Warszawskiego** ✗; **#79 Pałac Krasińskich and Ogród Krasińskich** ✗
- **Plac Małachowskiego**: **#44 Zachęta** ★; **#45 Kościół Świętej Trójcy** ★
- **Łazienkowska**: **#130 Torwar** ✗; **#131 Stadion Leguminy** ◐
- **(84 entrances)**: **#74 Metro stations: Centrum, Świętokrzyska, Ratusz-Arsenał, Politechnika, Rondo ONZ, Rondo Daszyńskiego, Nowy Świat-Uniwersytet, Centrum Nauki Kopernik, Stadion Narodowy, Dworzec Gdański** ○
- **Aleja Poniatowskiego**: **#14 Most Poniatowskiego (towers and deck)** ◐
- **Aleja Zieleniecka**: **#13 Stadion Narodowy** ★
- **Andersa**: **#98 Kina: Muranów, Atlantic, Luna, Kultura, Elektronik, Femina, Kinoteka, Iluzjon (south of the box)** ○
- **Boleść**: **#140 Stara Prochownia, Collegium Nobilium, Klasztor Ojców Dominikanów (Kościół pw. Świętego Jacka)** ◐
- **Karasia**: **#83 Teatr Polski and Teatr Powszechny** ✗
- **Kościelna**: **#115 Pomnik Marii Skłodowskiej-Curie** ✗
- **Muranowska**: **#69 Pomnik Poległym i Pomordowanym na Wschodzie** ✗
- **Noakowskiego**: **#107 Gmach Główny Politechniki Warszawskiej** ✗
- **Plac Defilad**: **#1 Pałac Kultury i Nauki** ★
- **Plac Powstańców Warszawy**: **#29 Hotel Warszawa (the 1934 Prudential)** ✗
- **Plac Teatralny**: **#18 Teatr Wielki and Teatr Narodowy** ◐
- **Plac Żelaznej Bramy**: **#122 Osiedle Za Żelazną Bramą** ◐
- **Rondo Daszyńskiego**: **#60 Rondo Daszyńskiego towers: Warsaw Unit, Skyliner, The Warsaw HUB, Mennica Legacy Tower, Generation Park Y** ○
- **Rondo ONZ**: **#28 Rondo ONZ towers: Q22, Rondo 1, Cosmopolitan, InterContinental, Warsaw Trade Tower** ○
- **Słomińskiego**: **#72 Dworzec Gdański and its metro** ✗
- **Wioślarska**: **#133 WTS DESKA** ◐
- **Wybrzeże Gdańskie**: **#88 Multimedialny Park Fontann** ✗
- **Ząbkowska**: **#85 Koneser and Ząbkowska's tenements** ✗
- **Świętojańska**: **#24 Archikatedra św. Jana** ◐
<!-- streets:end -->
