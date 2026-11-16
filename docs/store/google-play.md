# Google Play Console listing

Everything Play Console asks for, in the order the Console asks. Like the App Store
listing (`app-store.md`), keep every field free of drinking language.

## Create app
- **App name (30 max):** Party Party: Pixel Games
- **Default language:** English (United States) – en-US
- **App or game:** Game
- **Free or paid:** Free
- Declarations: accept the Developer Program Policies and US export laws.

## Store settings
- **Category:** Game → Casual
- **Tags:** Party, Card, Word, Trivia, Offline (pick whatever the Console offers that fits)
- **Contact email:** your developer email (shown publicly on the listing)
- **Website:** https://github.com/dlican/sip-quest

## Main store listing
**Short description (80 max):**
Eleven pixel-art party games on one phone. Offline, no ads, no accounts.

**Full description (4000 max):**
Party Party turns one phone into a whole night of party games. Pass it around or put it in the middle of the table, no setup and no sign-up. Your group picks the penalties: a dare, a push-up, a silly hat, whatever your table likes.

ELEVEN GAMES
• Four Kings: draw a card, obey the rule, and hope you don't draw the fourth king
• One of a Kind: answer fast, but match anyone and you're out
• Charades: phone on your forehead, tilt to score
• Imposter: everyone knows the secret word except one faker. Give clues, then vote
• Dial It In: one clue, one hidden target on a scale. Can your team read your mind?
• Mafia: secret roles and deadly nights for 5+ players, no narrator needed
• Fishbowl: everyone fills the bowl with secret slips, then teams describe, one-word and act them out over three rounds
• Paranoia: a secret question, a name said out loud
• Horse Racing: bet penalties and dares on a suit and watch the aces race
• Ride the Bus: four right in a row to get off
• Hot Potato: name one and pass it on before the hidden fuse blows

BUILT FOR THE TABLE
• Add player names and the phone calls turns, or skip names and just play
• Every game has an animated how-to-play demo
• Three hand-drawn pixel-art styles: Neon Arcade, Pixel Tavern, Pocket Mono
• Tilt-controlled Charades using the motion sensor
• Retro sound effects and haptics that mix with your music

PRIVATE BY DESIGN
No accounts, no ads, no tracking, no internet needed. Nothing leaves your phone.

**Graphics:**
- App icon (512 x 512): `docs/store/play-icon-512.png`
- Feature graphic (1024 x 500): `docs/store/feature-graphic-1024x500.png`
- Phone screenshots: `docs/store/android-phone/01.png` to `06.png` (1320 x 2640;
  Play rejects anything taller than 2:1, so these are the iPhone shots cropped)

## App content (Policy → App content)
- **Privacy policy:** https://dlican.github.io/sip-quest/privacy.html
- **App access:** All functionality is available without special access.
- **Ads:** No, my app does not contain ads.
- **Content rating:** start the IARC questionnaire and pick the category **Game**.
  Email: your developer email.
  - Violence: No (Mafia "kills" are only words on a card, nothing is shown)
  - Fear / horror: No
  - Sexuality: No
  - Language / crude humor: mild, if asked (some Paranoia questions are cheeky)
  - Controlled substances (drugs, alcohol, tobacco): No
  - Gambling / simulated gambling: No. Horse Racing bets are penalties and dares,
    nothing of value is wagered and there is no casino-style play.
  - User interaction: users can't chat or share content, no location sharing,
    no digital purchases, no unrestricted internet access.
  - Expected result: Everyone 10+ / Teen range (PEGI 7–12 / ESRB E10+–T).
- **Target audience and content:** ages **13–15, 16–17 and 18+**. Do not tick
  any under-13 box (that pulls the app into the Families policy). "Could the app
  unintentionally appeal to children?" → No.
- **News app:** No
- **Data safety:**
  - Does your app collect or share any required user data types? **No**
  - (The form then skips the rest.) Player names and settings stay on the device
    and are never sent anywhere, which Google does not count as collection.
- **Government app:** No
- **Financial features:** My app doesn't provide any financial features
- **Health apps:** No health features
- **Advertising ID:** No (the app doesn't use it)

## Testing (new personal accounts)
1. Testing → Closed testing → create a track, add an email list of at least 12
   testers, and upload `build/app/outputs/bundle/release/app-release.aab`.
2. Accept Play App Signing when asked.
3. Testers opt in through the link and keep the app installed for 14 days in a row.
4. Then Dashboard → Apply for production.

Remember to raise the `+N` in `pubspec.yaml` before every new upload.
