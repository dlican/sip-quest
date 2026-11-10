# Party Party

A pixel-art party game collection for iOS and Android, built in Flutter.
Fully offline: no backend, no accounts, no network calls.

## Recordings

<table>
<tr><td align="center"><img src="docs/media/gifs/kings-cup.gif" width="250" alt="Four Kings: shuffle, draw, rules"><br><sub>Four Kings: shuffle, draw, rules</sub></td><td align="center"><img src="docs/media/gifs/one-of-a-kind.gif" width="250" alt="One of a Kind: 10s round"><br><sub>One of a Kind: 10s round</sub></td><td align="center"><img src="docs/media/gifs/horse-racing.gif" width="250" alt="Horse Racing: auto race (2x)"><br><sub>Horse Racing: auto race (2x)</sub></td></tr>
<tr><td align="center"><img src="docs/media/gifs/styles.gif" width="250" alt="Three styles + the game list"><br><sub>Three styles + the game list</sub></td></tr>
</table>

## Screenshots

**Three styles:** Neon Arcade, Pixel Tavern, Pocket Mono.

<table>
<tr><td align="center"><img src="docs/media/screens/home-neon.png" width="220" alt="Neon Arcade"><br><sub>Neon Arcade</sub></td><td align="center"><img src="docs/media/screens/home-tavern.png" width="220" alt="Pixel Tavern"><br><sub>Pixel Tavern</sub></td><td align="center"><img src="docs/media/screens/home-pocket.png" width="220" alt="Pocket Mono"><br><sub>Pocket Mono</sub></td></tr>
</table>

**Every game:**

<table>
<tr><td align="center"><img src="docs/media/screens/kings-cup.png" width="180" alt="Four Kings"><br><sub>Four Kings</sub></td><td align="center"><img src="docs/media/screens/one-of-a-kind.png" width="180" alt="One of a Kind"><br><sub>One of a Kind</sub></td><td align="center"><img src="docs/media/screens/charades.png" width="180" alt="Charades"><br><sub>Charades</sub></td><td align="center"><img src="docs/media/screens/paranoia.png" width="180" alt="Paranoia"><br><sub>Paranoia</sub></td></tr>
<tr><td align="center"><img src="docs/media/screens/fishbowl.png" width="180" alt="Fishbowl"><br><sub>Fishbowl</sub></td><td align="center"><img src="docs/media/screens/horse-racing.png" width="180" alt="Horse Racing"><br><sub>Horse Racing</sub></td><td align="center"><img src="docs/media/screens/ride-the-bus.png" width="180" alt="Ride the Bus"><br><sub>Ride the Bus</sub></td><td align="center"><img src="docs/media/screens/hot-potato.png" width="180" alt="Hot Potato Bomb"><br><sub>Hot Potato Bomb</sub></td></tr>
</table>

Media is captured from the web build at phone size (390 x 844); see "Updating the media" below.

## Games
| Mode | Folder | Notes |
|---|---|---|
| Four Kings | `lib/games/kings_cup/` | Riffle shuffle, 3D card flip, king meter, editable card rules, house rules from Jacks, Question Master tracking |
| One of a Kind | `lib/games/unique_answer/` | Host + timer (10/15/20/30s), category and difficulty filters, elimination, final-two "don't match the host" rule |
| Charades | `lib/games/charades/` | 5 word decks, 45/60/90s rounds, Got it / Pass, actor rotation |
| Imposter | `lib/games/imposter/` | Pass-the-phone secret word, 1 or 2 imposters, 7 categories, optional category hint for the imposter |
| Dial It In | `lib/games/dial/` | Clue giver sees a hidden target on a 40-scale deck; team drags the needle; 4/3/2 point bands |
| Mafia | `lib/games/mafia/` | Narrator-free: secret roles, every living player taps at night, Doctor and Detective, day vote, 5+ names |
| Fishbowl | `lib/games/fishbowl/` | Everyone adds secret slips, two teams, three rounds (describe, one word, act), timed turns, leftover time carries over |
| Paranoia | `lib/games/paranoia/` | Pass-the-phone secret question, pick a name, penalty / coin flip / mystery |
| Horse Racing | `lib/games/horse_racing/` | Per-player bets, 7 checkpoint side cards, auto-run, payout summary |
| Ride the Bus | `lib/games/ride_the_bus/` | Red/black, higher/lower, inside/outside, suit; miss = penalty and restart |
| Hot Potato Bomb | `lib/games/hot_potato/` | Hidden 10 to 45s fuse, ticking speeds up, 44 categories |

Add a game: create `lib/games/<name>/`, then register it in `lib/games/registry.dart`.

## One phone, no setup

Every game runs on a single phone passed around or placed in the middle of the
table. Player names are optional: add them and the phone calls turns, skip them
and games fall back to "pass it left" / point-on-3 / quick modes.

- **Charades** is heads-up style: landscape, phone on your forehead, 30s rounds,
  tilt down = got it, tilt up = pass (tap left/right halves as a fallback).
- **How to play**: the `?` on each menu tile (and in each game) opens an
  animated pixel-art demo plus the rules (`lib/games/how_to_play.dart`,
  `lib/widgets/demos.dart`).
- **Sound and haptics** go through `lib/services/fx.dart`. Settings (gear on the
  home screen) toggle sound, volume, countdown ticks and haptics; they persist
  on the phone. Effects are synthesized by `python3 tool/make_sfx.py` into
  `assets/sfx/` and mix with whatever music is already playing.

## Visual styles
Three palettes in `lib/theme/palette.dart`, switchable from the home screen ("Style" button):
**Neon Arcade**, **Pixel Tavern**, **Pocket Mono**. All pixel art is code (`lib/widgets/sprites.dart`),
stored as character grids so you can redraw sprites by editing text.

## Question bank
`assets/data/unique_answer_prompts.json` (565 prompts, 13 categories, letter templates).
Replace or extend this file to change One of a Kind prompts; schema is documented in
`lib/games/unique_answer/question_bank.dart`.

## Run
```
flutter pub get
flutter run            # on a connected iPhone/Android or simulator
flutter test           # unit + widget tests (every game, all styles, small-phone layout)
flutter test integration_test/app_flow_test.dart -d <device-id>   # basic flow on a phone
```
Web preview for screenshots: `flutter run -d chrome` and add `?style=tavern&players=A,B,C&open=kings_cup`.

Fonts: Press Start 2P and VT323 (SIL Open Font License), bundled in `assets/fonts/`.

## Updating the media
Screenshots and GIFs in `docs/media/` come from the release web build at a 390 x 844
viewport. Run `flutter build web --release`, serve `build/web`, open game screens
directly with `?style=neon&players=Deez,Sam,Alex,Jo,Priya&open=<game id>` (ids are in
`lib/games/registry.dart`), and record with any browser tool. The GIFs are 10 fps,
300 px wide.

## Releasing to Google Play
- Release builds are signed with the upload key named in `android/key.properties`
  (git-ignored, never commit it or the `.jks`). Without that file, release builds fall
  back to debug keys, which Play rejects.
- Bump `version:` in `pubspec.yaml` (the `+N` build number must go up every upload),
  then run `flutter build appbundle --release` and upload
  `build/app/outputs/bundle/release/app-release.aab`.
- Store icon and feature graphic live in `docs/store/` and are regenerated with
  `python tool/make_store_assets.py`.
- Privacy policy: `docs/privacy.html`, served by GitHub Pages at
  https://dlican.github.io/sip-quest/privacy.html once Pages is on for `main` `/docs`.
