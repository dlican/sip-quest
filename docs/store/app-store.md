# App Store Connect listing

Copy these into App Store Connect (My Apps → + → New App). Screenshots for the
6.9" iPhone slot are in `docs/store/ios-6.9/` (1320 x 2868). App Store Connect
scales them down for the smaller iPhone sizes. The app is iPhone-only, so no
iPad screenshots are needed.

Guideline 4.3(b) (June 2026) calls drinking-game apps low-value and warns that
repeated submissions can cost the developer account. Keep every field below free
of drinking language: no "drink", "shots", "booze", "pregame" or "drinking game".

## App record
- **Name:** Party Party
- **Bundle ID:** com.funapps.partyParty
- **SKU:** partyparty-ios
- **Primary language:** English (U.S.)
- **Primary category:** Games → Party · **Secondary:** Games → Card
- **Price:** Free

## Version info
**Subtitle (30 max):** Pixel party games, one phone

**Promotional text (170 max):**
Ten pixel-art party games on one phone. Four Kings, Charades, Horse Racing and more. Fully offline, no accounts, no ads.

**Description:**
Party Party turns one phone into a whole night of party games. Pass it around or put it in the middle of the table, no setup and no sign-up. Your group picks the penalties: a dare, a push-up, a silly hat, whatever your table likes.

TEN GAMES
• Four Kings: draw a card, obey the rule, and hope you don't draw the fourth king
• One of a Kind: answer fast, but match anyone and you're out
• Charades: phone on your forehead, tilt to score
• Paranoia: a secret question, a name said out loud
• Horse Racing: bet penalties and dares on a suit and watch the aces race
• Ride the Bus: four right in a row to get off
• Hot Potato: name one and pass it on before the hidden fuse blows
• Most Likely To: secret votes, bar-chart reveals
• Pixel Roulette: spin the wheel of fate
• Truth or Penalty: answer honestly, or take the penalty

BUILT FOR THE TABLE
• Add player names and the phone calls turns, or skip names and just play
• Every game has an animated how-to-play demo
• Three hand-drawn pixel-art styles: Neon Arcade, Pixel Tavern, Pocket Mono
• Tilt-controlled Charades using the motion sensor
• Retro sound effects and haptics that mix with your music

PRIVATE BY DESIGN
No accounts, no ads, no tracking, no internet needed. Nothing leaves your phone.

**Keywords (100 max):**
party,games,charades,truth or dare,group,friends,card game,pixel,retro,icebreaker,game night

**Support URL:** https://github.com/dlican/sip-quest/issues
**Marketing URL:** https://github.com/dlican/sip-quest
**Privacy Policy URL:** https://dlican.github.io/sip-quest/privacy.html
**Copyright:** 2026 Daniel Li

## App Privacy (nutrition label)
- Data collection: **No, we do not collect data from this app.**

## Age rating questionnaire
- Mature/Suggestive Themes: **Infrequent/Mild** (truth questions, some prompts)
- Profanity or Crude Humor: **Infrequent/Mild**
- Alcohol, Tobacco, or Drug Use or References: **None**
- Everything else: **None**. Unrestricted web access: No. Gambling: No (bets are
  penalties, no money).
- Expected result: **13+**.

## Export compliance
`ITSAppUsesNonExemptEncryption = NO` is set in Info.plist, so builds skip the
encryption question.

## App Review notes
Party Party is an offline party game collection: ten card, word and guessing games
played by passing one phone around a group. It has no login, no network access
and no in-app purchases, so no demo account is needed.

What sets it apart: all art is original pixel art drawn in code, with three
switchable visual styles; each game has an animated how-to-play demo; Charades
uses the accelerometer for heads-up tilt scoring; and everything runs fully
offline with no data collection. Penalties are chosen by the players (dares,
push-ups and similar), and the app never references alcohol.

## Upload
1. Bump `version:` in `pubspec.yaml` (build number must rise every upload).
2. `flutter build ipa --release`
3. Upload `build/ios/ipa/*.ipa` with Xcode Organizer or Transporter, or
   `xcodebuild -exportArchive` with `destination: upload` in ExportOptions.plist.
