# Rondo Daszyńskiego's plazas (Krajobraz places K5)

Spec written 2026-11-02 from the map data and text sources. **No photos:** the cloud gets 403 from
the image hosts, so the look is a guess until the Mac photo check (QUESTIONS, "Krajobraz places:
Rondo Daszyńskiego"). Built by `tools/plaza_gardens.py`.

## What the real places are

- **Skyliner** (Prosta 69, 2020-21, the oval 195 m tower and its podium). RS Architektura
  Krajobrazu's green passage is "forest-like": three tiers, tall trees with open crowns,
  solitary shrubs, and low shrubs and perennials, carrying on the trees of the roundabout's
  square; wooden benches on terraces; it shelters the wind. The terrace gardens high up (nearly
  900 m², a 570 m² top terrace with an amphitheatre) are in the tower, not at street level.
- **Generation Park** (X, Y, Z, 2021): office blocks round plazas that join Prosta to the
  roundabout.
- **Mennica Legacy Tower** (2020): a landscaped plaza at Prosta and Żelazna, both buildings open
  onto it with a walkway between them, more than 60 % of the site given to outdoor space with
  places to sit (terraces on the 5th level of the tower and the 8th of the west building).

## What the map has

OSM ground and the buildings; the laser scan (2023) holds only a few trunks between them. Part
of Skyliner's ground is mapped as a construction site (kept free: nothing is planted on it).

## What was built

Three tiers, for each place, on the open ground the map allows (clear of buildings, carriageways,
lamps, kerbs, the construction site):

1. **Tall tier**: young trees (4-5 years, 8-11 m) in staggered rows 6-7.5 m apart with a
   jitter: birch, small-leaved linden, hornbeam and a few pines at Skyliner (the "forest"
   with open crowns); Generation Park and Mennica take more linden and hornbeam and a rowan.
   They keep 4.2 m from every existing trunk, so the scanned trees stay the older grove.
2. **Shrub and perennial tiers**: small uneven green beds (`areas` kind "park") beside about
   0.6-0.9 of the trees, a lawn-green stand-in for both tiers (the game draws no separate shrubs).
3. **Benches**: wooden benches by the groves, seat towards the plaza's tower (3 / 4 / 4).

Counts: Skyliner 44 trees, 18 beds, 3 benches; Generation Park 43, 21, 4; Mennica 34, 12, 4.

## Not built, and why

- Terraces of benches and the wind-sheltering levels: the ground is flat in the game.
- Planters and water features at Mennica: no source says where they are.
- Brand names: none are shown (the towers keep their parody-neutral landmark cards).

## To check on the Mac (photos)

Do the groves sit where the real ones do (orthophoto), is the Skyliner passage forest-like, are
the Mennica forecourts as open as the game now makes them (too many trees there?), where are the
real benches. Move a zone in `PLAZAS`, re-run `python3 -I tools/plaza_gardens.py` on a clean
map and the derived bakes.
