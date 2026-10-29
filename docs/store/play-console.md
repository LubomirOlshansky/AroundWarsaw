# Google Play Console: ready answers

Answers for Nocna Warszawa's Play Console forms, version 0.1 (code 1 was the first upload to
internal testing, October 2026; code 2 requires Vulkan). The build: `tools/export_android.sh`
(README, "Android (Google Play)"). Field names follow Play Console's English labels; Play may
reword them. Facts behind the answers: no network code, no INTERNET permission, VIBRATE only,
saves in `user://` on the device (`settings.gd`, `wallet.gd`), no accounts, ads or purchases;
Vulkan required (level 1, version 1.1.0).

## 1. Create app

| Field | Answer |
| --- | --- |
| App name | Nocna Warszawa |
| Default language | Polish (pl-PL); add English (en-US) as a translation of the listing |
| App or game | Game |
| Free or paid | Free (this can't be changed to paid later) |
| Declarations | Tick the Developer Program Policies and US export laws boxes |

## 2. Internal testing (the "Drop app bundles here" screen)

1. Test and release → Testing → Internal testing → Create new release.
2. **Play App Signing**: accept "Let Google manage and protect your app signing key"
   (recommended). The key in `~/.android-keys/` stays the **upload key**: every later upload
   must be signed with it (`tools/export_android.sh` does).
3. Drop the newest `build/android/nocnawarszawa-0.1-<code>.aab` (now `nocnawarszawa-0.1-2.aab`).
4. Release name: `0.1 (<code>)`, e.g. `0.1 (2)`. Release notes, `<pl-PL>` and `<en-US>`:

```
<pl-PL>
Pierwsza wersja testowa na Androida. Jeździ, świeci i pada. Daj znać, co się sypie.
</pl-PL>
<en-US>
The first Android test build. It drives, it lights up, it rains. Tell us what breaks.
</en-US>
```

5. Testers: create an email list (yourself first), save, then "Copy link" and open it on the
   phone signed in with that Google account.
6. Expected warning, safe to ignore for now: "This App Bundle contains native code, and you've
   not uploaded debug symbols" (symbols only make native crash reports readable; Godot's
   official templates don't ship them).
7. **From code 2 on, fewer supported devices, on purpose.** The AAB requires Vulkan
   (`android.hardware.vulkan.level` 1 and `android.hardware.vulkan.version` 0x401000, Vulkan
   1.1.0, both `required="true"`), because the game's Mobile renderer can't start without it.
   When code 2 replaces code 1, the release summary and Device catalog show a smaller number of
   supported devices, and Play may say the release "removes support for N devices": that is
   expected; confirm it. Release notes for code 2:

```
<pl-PL>
Gra działa teraz tylko na telefonach z Vulkanem, czyli tam, gdzie naprawdę ruszy.
</pl-PL>
<en-US>
The game now installs only on phones with Vulkan, the ones it can actually run on.
</en-US>
```

**Personal developer accounts made after November 2023** must run a *closed* test with at least
12 testers for 14 days before Play lets them apply for production. Internal testing doesn't
count towards that; plan a closed track when the internal build looks right.

## 3. App content (Policy → App content)

### Privacy policy

`https://aroundwarsaw.app/privacy/` (the website's copy of `docs/privacy.md`, `site/README.md`; until the site is live, `https://github.com/LubomirOlshansky/AroundWarsaw/blob/main/docs/privacy.md`)
(it exists once this branch is merged and pushed to `main`; open the link before you submit).

### App access

**All functionality is available without any access restrictions.** No login, no account, no
code.

### Ads

**No, my app does not contain ads.**

### Advertising ID

**No.** The app doesn't use the advertising ID (no ads or analytics SDK; the manifest has no
`AD_ID` permission).

### Content rating (IARC questionnaire)

Email: yours. Category: **Game** (not "All other app types").

| Question (paraphrased) | Answer | Why |
| --- | --- | --- |
| Violence (realistic, fantasy, blood, gore, harm to characters) | **No** | Cars bump into cars, kerbs and roadwork barriers (which wobble), and a jar of Mum's preserves can crack in the słoiki job; nobody is ever hurt, and the pedestrians and pigeons have no collision, so nobody can be hit |
| Fear, horror | No | |
| Sexuality, nudity, suggestive themes | No | |
| Language (profanity, crude humour, slurs) | No | Gentle Warsaw jokes; the dialogue has no swearing |
| Controlled substances (drugs, alcohol, tobacco) | No | The 3 a.m. delivery is kebab; no drinks in the game |
| Gambling, simulated gambling, real-money betting | No | The złoty you earn buys nothing real and can't be bought |
| Users interact or exchange content | No | Single player, offline |
| Shares the user's location | No | The map is fixed data; the device's location is never read |
| Digital purchases | No | |
| Unrestricted internet access (browser) | No | |
| Promotes or is a "Live" app | No | |

The police: cartoon officers with a speed trap, a lizak (the stop sign) and a chase that ends by
itself; it ends in a funny talking-to and a caution, **never a fine**, no weapons, no arrests.
If a question asks about "law enforcement" or "crime", answer that it's comic and non-violent.

Expected result: PEGI 3 / ESRB Everyone / USK 0 (IARC decides). If you'd rather be
conservative about the bumping, answering *Violence → fantasy or cartoon, against objects only*
likely gives PEGI 7 / ESRB Everyone; either is honest.

### Target audience and content

| Field | Answer |
| --- | --- |
| Target age groups | **13-15, 16-17, 18 and over** (not 12 and under) |
| Could the store listing unintentionally appeal to children? | **No**: the humour is about commuting, rents, roadworks and the city's quirks, written for teenagers and adults; no characters, mascots or language aimed at children |
| Families program | Don't opt in |

Choosing no age under 13 keeps the app out of the Families policy and the Designed for
Families requirements.

### Data safety

| Question | Answer |
| --- | --- |
| Does your app collect or share any of the required user data types? | **No** |
| (then) Is all user data encrypted in transit? / Account deletion | Not asked when nothing is collected; if asked: no data is transmitted, no accounts |

Summary Play will show: "No data collected · No data shared with third parties". Saves stay on
the device and never leave it (Play's definition of "collected" is data sent off the device).
Android's own Play services crash reports are Google's and not declared by the app.

### Government apps, financial features, health, news

Not a government app · no financial features · no health features · not a news app.

### Permissions

Only `android.permission.VIBRATE` (haptics). No sensitive permission declaration is needed.

## 4. Store settings

| Field | Answer |
| --- | --- |
| App category | **Racing** (alternative: Arcade) |
| Tags | Racing, Arcade, Driving, Pixel art, Casual, Offline (Play's own tag list; pick up to five) |
| Contact email | your support address (not written here: the repo is public) |
| Website | `https://aroundwarsaw.app` |

## 5. Main store listing

App name (30 characters at most): **Nocna Warszawa**

### Polish (pl-PL)

Short description (80 characters at most; this is 73):

```
Prawdziwe centrum Warszawy w pikselach. Kebab o trzeciej, korki, gołębie.
```

Full description:

```
Nocna Warszawa to zręcznościowa jazda małym autem (i helikopterem) po prawdziwym centrum miasta, zbudowanym z otwartych danych map, w pikselowej izometrii.

Od Śródmieścia po Stadion: Pałac Kultury, Marszałkowska, Rondo Dmowskiego, Most Poniatowskiego i Wisła, której lepiej nie sprawdzać kołami.

• Kebab o trzeciej w nocy, niedzielny kurs ze słoikami i Podwózka, aplikacja, która ufa GPS-owi bardziej niż Tobie.
• Akcje ratunkowe helikopterem i wyścigi z miejscowymi. Seba z Pragi już grzeje silnik.
• Ruch, tramwaje, światła, piesi i gołębie, którym nigdzie się nie spieszy.
• Dzień, zmierzch, noc i deszcz: neony, latarnie i podświetlony Pałac.
• Policja jest, ale z humorem: suszarka, lizak, pogadanka. Mandatu nie będzie. Pouczenie owszem.
• Radio w aucie i miasto, które ciągle coś do Ciebie mówi.

Bez reklam, bez zakupów, bez internetu, bez zbierania danych. Darmowa gra open source, zrobiona z miłości do Warszawy.

Remont Marszałkowskiej trwa. Ty jedź.
```

### English (en-US)

Short description (80 characters at most; this is 79):

```
Arcade drive through the real centre of Warsaw. Kebab at 3 a.m., jams, pigeons.
```

Full description:

```
Nocna Warszawa (Warsaw by Night) is an arcade drive in a small car (and a helicopter) through the real centre of Warsaw, built from open map data, in isometric pixel art.

From Śródmieście to the Stadium: the Palace of Culture, Marszałkowska, Rondo Dmowskiego, Poniatowski Bridge and the Vistula, which you'd better not test with your wheels.

• Kebab at 3 a.m., the Sunday run with słoiki (jars of Mum's cooking) and Podwózka, the ride app that trusts its GPS more than it trusts you.
• Helicopter rescues and street races against the locals. Seba from Praga is already revving.
• Traffic, trams, traffic lights, pedestrians and pigeons in no hurry at all.
• Day, dusk, night and rain: neon, street lamps and the Palace floodlit.
• The police are here, with a sense of humour: speed traps, the lizak, a little talk. No fine, ever. A caution, maybe.
• A car radio and a city that keeps talking back.

No ads, no purchases, no internet, no data collected. A free, open-source game made out of love for Warsaw.

The Marszałkowska roadworks continue. You keep driving.
```

Tone check (warsaw-tone skill): real places only, no brand, station or app named (Podwózka is
the game's own invented app-taxi), invented people only (Seba z Pragi is a type, one of the
game's rivals), Polish diacritics checked. The game itself is Polish above English on every
screen; the listing says "Polish with English" nowhere because Play shows one language at a time.

### Graphics (still to make; nothing here is in the repo yet)

| Asset | Requirement | Suggestion |
| --- | --- | --- |
| App icon | 512 × 512 PNG, 32-bit, ≤ 1 MB | `game/icon.svg` (the Palace in 32 × 32 pixels) scaled ×16 with nearest-neighbour, no smoothing |
| Feature graphic | 1024 × 500 JPEG or 24-bit PNG | a night shot of the Palace and Marszałkowska, the title in the pixel font |
| Phone screenshots | 2 to 8, 16:9 landscape, each side 320-3840 px, the long side at most twice the short | `tools/shots.sh --size=1920x1080` (not 2532×1170: that is 2.16:1, over Play's 2:1 limit): spawn by day, the Palace at night, rain at night, the helicopter, a kebab or Podwózka card |
| 7" and 10" tablet screenshots | optional for a phone game | skip for internal testing |

## 6. Before you go past internal testing

- [ ] Install from the internal-testing link on a real Android phone; play 10 minutes: does it
      start, hold 60 fps or 30, keep its save after a restart, vibrate?
- [ ] Rotate the phone both ways (sensor landscape) and check the HUD clears any camera cutout.
- [ ] Check Play Console's device catalogue (Test and release → Device catalog): from code 2 the
      AAB **requires Vulkan** (level 1, version 1.1.0), so the count of supported devices drops
      compared with code 1. That is expected: those phones (OpenGL ES only, or Vulkan 1.0) can't
      run the Mobile renderer. Don't exclude more by hand.
- [ ] Paste the BENCH card (Settings → TEST, KOPIUJ · COPY) from the phone into the chat: no
      Android frame number exists yet.
- [ ] The privacy-policy link opens (after `main` is pushed).
