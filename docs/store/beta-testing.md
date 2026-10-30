# Beta testing: TestFlight and Google Play

The notes testers see with each build, and what to ask them to try. App Store Connect →
TestFlight → the build → **Test Details → What to Test** (4000 characters, one text per
language: set English, then Polish). Play Console → Testing → the track → the release →
**Release notes** (`<en-US>` and `<pl-PL>` tags, 500 characters each). The store answers
themselves: [app-store-connect.md](app-store-connect.md), [play-console.md](play-console.md).
Testers who need help go to `https://aroundwarsaw.app/support/` (`docs/support.md`).

Update this file with every build that goes to testers, newest first, and keep the old notes
below it: they are the record of what each build asked for.

## 0.1, the first beta (October 2026)

### TestFlight: What to Test

English:

```
Thanks for testing Around Warsaw! This is the first beta: the real centre of Warsaw, from Śródmieście to the Stadium.

Please try:
1. Drive for ten minutes. Does steering feel right? Do you get stuck on other cars or small things on the road?
2. Do a side job: kebab at night, the Sunday słoiki run from Dworzec Centralny, or a Podwózka ride.
3. Take the helicopter up over the Vistula.
4. Let the police catch you speeding once.
5. Change the time and weather; try night and rain.
6. Close the game and open it again: is your złoty still there?

Tell us: your iPhone model, anything that broke (with a screenshot if you can), where it got slow or hot, and the one thing you'd change.

Send feedback from TestFlight (take a screenshot while playing), or through aroundwarsaw.app/support.
```

Polish:

```
Dzięki za testy Around Warsaw! To pierwsza beta: prawdziwe centrum Warszawy, od Śródmieścia po Stadion.

Spróbuj:
1. Pojeździj dziesięć minut. Czy skręcanie jest w porządku? Czy auto blokuje się na innych autach albo drobiazgach na jezdni?
2. Zrób zlecenie: kebab nocą, niedzielny kurs ze słoikami z Dworca Centralnego albo kurs Podwózki.
3. Wzleć helikopterem nad Wisłę.
4. Daj się raz złapać policji za prędkość.
5. Zmień porę dnia i pogodę; sprawdź noc i deszcz.
6. Zamknij grę i otwórz ją ponownie: czy złotówki zostały?

Napisz nam: model iPhone'a, co się zepsuło (najlepiej ze zrzutem ekranu), gdzie tnie albo grzeje, i jedną rzecz, którą byś zmienił(a).

Opinie wysyłaj z TestFlighta (zrzut ekranu w trakcie gry) albo przez aroundwarsaw.app/support.
```

### Google Play: release notes (internal and closed testing)

```
<en-US>
The first beta of Around Warsaw. Drive the real centre of Warsaw, do a side job, fly the helicopter, meet the police. Tell us what breaks and which phone you have: aroundwarsaw.app/support
</en-US>
<pl-PL>
Pierwsza beta Around Warsaw. Jedź przez prawdziwe centrum Warszawy, zrób zlecenie, poleć helikopterem, poznaj policję. Napisz, co się sypie i jaki masz telefon: aroundwarsaw.app/support
</pl-PL>
```

Play's testers don't get a "What to Test" field: send them the TestFlight list above by email or
Telegram with the opt-in link.

## Ten minutes on the phone before inviting anyone

Do this on each new build yourself, on the iPhone (TestFlight) and an Android phone (Play
internal testing), before it goes to external testers:

- [ ] It installs from the store's test link and opens past the title.
- [ ] Ten minutes of driving: frame rate steady (Settings → OBRAZ → TEST gives the bench
      card; KOPIUJ copies it), the phone warm but not hot.
- [ ] One kebab job, one helicopter flight, one police stop.
- [ ] Night and rain look right; the radio plays.
- [ ] Quit from the app switcher, reopen: settings and złoty kept.
- [ ] Portrait lock and both landscape sides: the HUD clears the notch or camera hole.
- [ ] Haptics on a bump.
- [ ] The support and privacy links in the store listing open.

## Who to invite

- **TestFlight**: internal testers first (you, up to 100 team members, no review). Then the
  external group "Warsaw locals" with a public link (the first build of each version passes
  Beta App Review, usually within a day). Builds expire after 90 days.
- **Google Play**: internal testing (an email list, up to 100) for your own phones. A
  personal developer account made after November 2023 then needs a **closed test with at
  least 12 testers opted in for 14 days in a row** before it can apply for production: start
  the closed track as soon as the internal build looks right, and invite the people who sign
  up on aroundwarsaw.app.
- Put each public link on the website when it exists (`site/README.md`, "When the betas have
  public links").
