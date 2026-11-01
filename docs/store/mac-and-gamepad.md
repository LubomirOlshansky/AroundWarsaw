# The Mac version and gamepads (lane file)

F asked on 2026-11-01 whether the game can run on macOS and go to the Mac App Store, and
whether it works with a gamepad: "prepare this game to the Mac and gamepad as well". This file
is the lane: what is built, what is left, and the Mac steps for the beta. The Mac App Store
version is post-v1.0 (the iPhone demo and TestFlight come first) unless F says otherwise.
ROADMAP "v1.0 checklist" carries one line per item; BACKLOG has the section "The Mac App Store
version and gamepads".

## Can it run on a Mac today?

Yes, as a developer build: the game is Godot 4.7.2 with the Mobile renderer, which runs on
macOS (Metal); `godot --path game` on the Mac already plays it with the keyboard
(W A S D / arrows, Space, Q / E, H, M, K, Esc and the rest in main.gd `_unhandled_key_input`),
and since this lane with a gamepad too. What a store build still needs is below.

Two ways onto Macs, cheapest first:

1. **The iPhone app on Apple Silicon Macs.** App Store Connect can offer the iOS build on M1 and
   later Macs as it is (Pricing and Availability → "iPhone and iPad Apps on Apple Silicon
   Macs"). No new build, the same TestFlight, but it runs as a phone-shaped window with touch
   mapped to the mouse. Worth leaving on for the beta if the first TestFlight build behaves on
   a Mac; check it on F's Mac before saying yes.
2. **A native macOS build** (this lane's items): a resizable window, keyboard, mouse and pad
   first, Intel Macs too, the Mac App Store's own listing and screenshots.

## Gamepad: built (2026-11-01)

`game/scripts/gamepad.gd`, read next to touch and the keys in main.gd `_read_input`; checked by
`game/tools/check_gamepad.gd` (verify step `gamepad`, CI too). Godot's joypad input covers Xbox,
PlayStation and MFi pads with the same button layout on iOS (Apple's Game Controller framework),
macOS, Windows and Android.

| Pad | Driving | Helicopter |
| --- | --- | --- |
| Left stick | Point / Fixed: point the way (further = more gas). Classic: steer | fly that way |
| RT (R2) | gas (Classic) | climb |
| LT (L2) or B (circle) | brake / reverse | sink (LT) |
| A (cross) | the mission card's first button (M) | same |
| X (square) | the mission card's second button (K) | same |
| Y (triangle) | car / helicopter (H) | land |
| LB / RB | turn the view (Q / E) | same |
| R3 / L3 | follow camera (C) / horn (B) | |
| D-pad | up / down zoom, right radio, left flash lights | same |
| Back (View, Share) | the full map | same |
| Start (Menu, Options) | Settings | same |

Menus: the title takes A / Start (continue), Y (NOWA GRA) and on the question A (TAK) / B
(NIE). Settings opens on the open tab's button with an accent ring; the D-pad or the stick moves
it, A presses, LB / RB change the tab, B / Start / Back close. The full map closes on B, Start
or Back. `install` adds A to `ui_accept` and B to `ui_cancel` (Godot leaves them off by default),
so the garage card closes on B too.

The pad used last hides the touch pedals and pads (as `--no-touch` does), the ghost finger's
hint says "Lewa gałka: wskaż, dokąd jechać / Left stick: point the way" and the helicopter's
toast names RT / LT; the first finger on the screen brings the pedals back on that same touch.

Left for the gamepad (BACKLOG):
- [ ] Try a real Xbox, DualSense and an MFi pad on the iPhone and the Mac (only a device shows
      it: the button indices are checked on synthetic events only). Part of the beta below.
- [x] Settings' volume bars, the notebook page and the garage card take pad focus (2026-11-01):
      a focused bar steps 0.1 on the D-pad's left / right; the notebook has its own cursor over its
      drawn targets (the nearest one each way, A opens, B comes back to the card it left); the
      garage opens on the paint worn, B or Start closes it. Opened by a finger, nothing takes focus.
- [x] The full map with the pad (2026-11-01): the left stick pans, RT / LT zoom, A held on the
      cross at the centre teleports there; the hint says so.
- [ ] Button glyphs per family (A / cross) in the HUD's hints; rumble on crashes
      (`Input.start_joy_vibration` behind Settings' vibration switch, through haptics.gd).

## The Mac App Store version (post-v1.0)

- [ ] **macOS export preset** in `game/export_presets.cfg`: bundle ID `com.olshanskysoft.aroundwarsaw`
      (the iOS one, so the purchase is universal), category Games, universal (arm64 + x86_64),
      the icon, and a `tools/export_macos.sh` like `export_ios.sh` (split the map, prebuild the
      sectors, export). The Mac export templates are in the same 4.7.2 templates download.
- [ ] **Sandbox entitlements and signing**: App Sandbox on (the Mac App Store requires it), with
      only what the game uses (no network unless the beta form needs it; the save already goes to
      `user://`, inside the sandbox container); an "Apple Distribution" certificate for the app and
      a "Mac Installer Distribution" one for the .pkg; a Mac provisioning profile for the bundle ID.
- [ ] **Keyboard and mouse controls**: the keys exist; add a keys card in Settings (the mouse wheel
      zooms already), click-to-point for Point, rebinding later; `--no-touch` becomes the
      Mac's default (no touch pedals drawn on a Mac).
- [ ] **Window and resolution settings**: a resizable window and full screen (Settings → OBRAZ),
      the HUD's points measured from the window (screen_points.gd), a minimum window size, the
      pixel image's size rule (tiers.gd) for Mac GPUs, Retina scale.
- [ ] **Mac store screenshots**: 16:10 at 2880 × 1800 (or 2560 × 1600, 1440 × 900, 1280 × 800),
      from `tools/shots.sh --size=2880x1800` on the Mac, with the window's HUD.
- [ ] **The Mac's own pass**: the bench on an Apple Silicon and an Intel Mac, Metal on both,
      the pause on losing focus, Cmd+Q, the menu bar's app name.

## The beta plan: adding the Mac

TestFlight runs on macOS too (macOS 12 or later, the TestFlight app from the Mac App Store), so
the Mac joins the same beta once the iPhone beta is running. One step per line:

1. **macOS TestFlight builds**: one Mac build per beta round next to the iPhone build, the same
   version and build number line; testers in the "Warsaw locals" group get both.
2. **The macOS export and signing**: `tools/export_macos.sh` on F's Mac, App Sandbox on, signed
   with Apple Distribution, packaged as a .pkg signed with Mac Installer Distribution.
3. **A universal purchase or a separate Mac app record**: add macOS to the existing App Store
   Connect record (Apple ID 6829306630, same bundle ID) for a universal purchase: one listing,
   one price, shared TestFlight testers. Recommended. A separate Mac record only if the Mac
   version needs its own name or price.
4. **Upload**: the Mac App Store and Mac TestFlight take the signed .pkg through Transporter (or
   Xcode's Organizer); notarization is only for a Mac build given out outside the store (a .dmg
   on aroundwarsaw.app), not needed for the store.
5. **Beta App Review** for the first Mac build, then the Mac's What to Test (below).

Gamepad testing in every beta round (iPhone and Mac):

- [ ] Pair an Xbox, PlayStation or MFi pad; drive five minutes in Point and in Classic; fly the
      helicopter (RT / LT for height); open Settings with Start and move round it; open the full
      map with Back; put a finger on the screen and check the pedals come back.

What to Test for the Mac (add to beta-testing.md when the first Mac build goes out):

```
On the Mac: play with the keyboard (W A S D, Space to brake, H for the helicopter, Esc for Settings) or a game controller. Resize the window and try full screen. Tell us your Mac model and whether it ran smoothly.
```
