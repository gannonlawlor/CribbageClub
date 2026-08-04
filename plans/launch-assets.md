# Launch Assets — Icon Inventory + Gemini Image-Generation Prompts

## Context

For full launch we need every visual asset inventoried with exact sizes and a repeatable Gemini image-generation prompt per asset, all conforming to Design Language v1.0 (`design/Design Language.md`). Current state:

- The only art in the repo is the **peg-in-hole app icon** (`mobile/assets/icon/app_icon.png` + adaptive background/foreground layers) and a splash mark (`mobile/assets/branding/splash_mark.png`). The iOS asset files are literally named `Gemini_Generated_Image_*` — Gemini generation is already the established pipeline, but no prompts were recorded.
- `avatarIndex` exists on the profile model (`mobile/lib/core/models/profile_response.dart`, `users.avatar_index` since V9) with **no avatar art anywhere**; players today get initial-letter circles (`CcAvatar` in `mobile/lib/shared/widgets/cc_screen.dart`).
- `plans/achievements.md` Phase 3 requires **512×512 art for each of 25 Game Center achievements** plus Play Games equivalents — the largest outstanding art need. In-app, achievements currently render as a Material `Icons.emoji_events` glyph.
- Web has a **dead favicon link** (`web/index.html` references `/favicon.png`; no `web/public/` directory exists) and no og-image or social card.
- No Android notification small icon (white silhouette) exists — needed by plans/play-while-waiting.md and plans/notification-center.md.
- `mobile/pubspec.yaml` declares only `assets/sounds/` as runtime assets; any new in-app art (avatars, achievement glyphs) needs new `assets:` entries.

**Deliverable of executing this plan:** `design/launch-assets/PROMPTS.md` (the complete inventory with one final prompt per asset) and the generated, post-processed assets wired into mobile, web, and the store consoles.

## Master style preamble

Prepend this to **every** Gemini prompt so the set reads as one system:

> Flat, geometric vector-style illustration for a serious competitive card-game app. Dark warm charcoal background #262421. Primary accent green #81b64c used sparingly and only for one focal element. Muted warm ivory #f0ede8 and #b8b3ac for secondary shapes. Gold #e3aa24 reserved strictly for trophy and skill motifs. No gradients except a subtle vertical darkening, no gloss, no bevels, no drop shadows, no photorealism, no wood textures, no text or letters. Clean geometry on an 8px grid, generous negative space, rounded corners around 8% radius, calm and understated mood — quiet confidence, not celebration.

Per-category modifiers:
- **Light-theme variants** (only where needed, e.g. og-image light mode): swap background to warm paper #f4f1ec, ivory shapes to #2a2622/#57524b.
- **Achievement tiers**: generate tier-neutral glyphs in ivory; bronze `#a97142` / silver `#b8b3ac` / gold `#e3aa24` applied programmatically at export (ring + recolor), so 25 generations cover 75 tier renderings.
- **Transparent-background assets** (avatars, glyphs): add "single centered subject on a plain solid background for clean background removal, subject fills ~70% of frame".

## Phase 1 — Inventory + write all prompts (`design/launch-assets/PROMPTS.md`)

### 1. App icon set (exists — verify, don't regenerate by default)

| Asset | Size | Notes |
|---|---|---|
| iOS app icon | 1024×1024 | Current peg-in-hole mark; keep unless quality review at 48px fails |
| Android adaptive background | 1024×1024 | Vertical charcoal gradient layer (exists) |
| Android adaptive foreground | 1024×1024 | Peg mark on transparent layer (exists) |

Regeneration prompt (only if needed): preamble + "App icon: a single upright cribbage peg descending into a drilled board hole, centered, bold silhouette readable at 48 pixels, green peg #81b64c, hole suggested by a dark inset circle."
Pipeline: replace `mobile/assets/icon/*`, run `dart run flutter_launcher_icons`.

### 2. Store listing

| Asset | Size | Prompt approach |
|---|---|---|
| Google Play hi-res icon | 512×512 PNG | Same as app icon prompt |
| Google Play feature graphic | 1024×500 | Preamble + "wide banner: cribbage board hole grid receding subtly into charcoal, one green peg mid-jump as focal point, left 40% kept as calm empty space for logo overlay" |
| App Store screenshots | 6.9" 1320×2868, 6.5" 1284×2778 (+ 13" iPad 2064×2752 if iPad ships) | **Real framed screenshots, not AI-generated.** Only the backdrop panel behind device frames comes from Gemini: preamble + "abstract minimal backdrop, faint board-hole dot grid, charcoal" |
| Play Store screenshots | phone 1080×1920+ | Same treatment |

Screenshot captions follow the voice rules: factual, no exclamation points ("Play rated games.", "Analyze every discard.").

### 3. Achievement glyphs — 25 base generations (from the catalog in `plans/achievements.md`)

One 1024×1024 tier-neutral glyph each; export 512×512 PNG for Game Center/Play Games and a trimmed in-app set for the profile grid. Prompt = preamble + transparent-background modifier + "badge glyph:" + subject line:

| Key | Subject line |
|---|---|
| FIRST_GAME (Welcome to the Club) | an open club door formed from a card suit club symbol |
| FIRST_WIN (On the Board) | a single peg standing in the first hole of a board track |
| WINS_10 (Regular) | a small stack of ten flat pegs arranged in two rows |
| WINS_50 (Club Veteran) | a laurel-framed club suit symbol |
| WINS_100 (Centurion) | a Roman numeral C shape built from board holes |
| STREAK_5 (Hot Streak) | five pegs in a row with a subtle ember-orange #e2833f trail |
| STREAK_10 (Unstoppable) | an unbroken line of pegs crossing the frame diagonally |
| BEAT_AI_MEDIUM (Worthy Opponent) | a handshake formed from two card shapes |
| BEAT_AI_HARD (Machine Breaker) | a cracked circuit-pattern card split in two |
| SKUNK (Skunked!) | a minimal geometric skunk silhouette with one ivory stripe |
| DOUBLE_SKUNK (Double Skunk) | the same skunk silhouette with two ivory stripes |
| SKUNK_AI_HARD (Humbled the Machine) | a skunk silhouette over a faint circuit grid |
| COMEBACK (The Comeback) | a peg path arcing down then sharply up to the final hole |
| HAND_20 (Twenty Club) | a fanned four-card hand with a "score pip" cluster of 20 dots |
| HAND_24 (Twenty-Four Karat) | a fanned card hand with a gold ingot corner accent |
| HAND_29 (The Perfect Hand) | three fives and a jack fanned around a centered five, abstract pips only |
| CRIB_12 (Golden Crib) | a face-down two-card pile with a gold underglow line |
| HIS_HEELS (His Heels) | a single upright jack card with a boot-heel motif at its base |
| PEG_31 (Thirty-One) | a pegging count arc terminating at a bold endpoint |
| PEG_12_ROUND (Pegging Machine) | a gear shape whose teeth are cribbage pegs |
| FIRST_ONLINE_WIN (People Person) | two player circles linked by a board track |
| RATING_1600 (Sixteen Hundred) | an upward rating line breaking through a horizontal threshold, gold accent |
| FRIEND_ADDED (Making Friends) | two overlapping rounded-square avatars |
| PUZZLE_FIRST (Daily Habit) | a single puzzle-piece-shaped playing card |
| PUZZLE_OPTIMAL_10 (Optimizer) | a target with a card-suit diamond at its center |

Tier ring/recolor applied at export (script or manual batch in Phase 2).

### 4. Avatar set — 16 avatars for `avatarIndex`

512×512, circular-crop-safe (subject inside center 80%), consistent charcoal background so they read uniformly in `CcAvatar` circles. Prompt = preamble + transparent/centered modifier + "circular profile avatar mark:" + subject. Motif families:

- **Suits (0–3):** club, spade, heart (card-red #c0392b allowed here), diamond — each as a bold geometric mark with one green accent line.
- **Pegs & board (4–7):** single peg, crossed pegs, board-hole triangle, the 121 hole ringed in gold.
- **Card figures (8–11):** abstract geometric jack, queen, king, joker — profile silhouettes built from rectangles and circles, no faces.
- **Quiet objects (12–15):** anchor, compass, lantern, north star — same reduction style.

Integration steps (noted here, executed with the assets): new `mobile/assets/avatars/avatar_00.png … avatar_15.png`, add `assets/avatars/` to `pubspec.yaml`, extend `CcAvatar` to render the image when `avatarIndex != null` (fallback to initials). Avatar *picker* UI is out of scope — separate backlog item.

### 5. In-app illustration spots

- Empty states (no games / no friends / no notifications): decide at execution between small Gemini spot images and the existing quiet Material-icon treatment. Default recommendation: keep icons; generate spots only if the icon version feels flat in review.
- Tutorial board illustration (feeds `plans/tutorial.md` lesson 1): preamble + "a full cribbage board seen from above as flat geometry: three lanes of drilled holes, start and finish marked, one green and one ivory peg mid-race, the 121 hole ringed in gold".
- Tutorial completion artwork: preamble + "a finished board with the green peg in the final gold-ringed hole, understated".

### 6. Web

- `web/public/favicon.png` (512×512 source, plus 32×32) — fixes the dead `web/index.html` link; same mark as the app icon.
- `web/public/og-image.png` 1200×630: preamble + "wide social card: peg-in-hole mark left of calm empty space reserved for a headline, faint board-hole grid" (headline text added in post, never generated).

### 7. Platform chrome (not AI-generated — flagged so nobody tries)

- **Android notification small icon**: 24dp pure-white silhouette of the peg mark, hand-derived from `app_icon_foreground.png` (AI generation is unsuitable for strict monochrome alpha masks). Needed by the local/push notification plans.
- Splash mark: verify current `splash_mark.png` against both OS appearances; regenerate config with `dart run flutter_native_splash:create` only if the mark changes.

## Phase 2 — Generate + post-process

1. For each PROMPTS.md entry, generate 2–3 candidates at ≥1024², pick one, record the chosen prompt verbatim next to the asset in PROMPTS.md (prompts are the source of truth for future regeneration — the missing piece that left us with `Gemini_Generated_Image_*.png` files today).
2. Post-process: background removal where flagged, center + pad normalization (subject ~70% of frame), palette snap of near-miss colors to the exact tokens, downscale exports (512/256/128 as needed per asset).
3. Achievement tier variants: batch script (ImageMagick or a small Dart/Python script committed to `design/launch-assets/`) applying tier ring + recolor to the 25 base glyphs → 75 outputs for Game Center/Play Games.

## Phase 3 — Integrate

- Mobile: `mobile/assets/avatars/`, achievement glyph set, updated `pubspec.yaml` `assets:` entries; `flutter_launcher_icons` / `flutter_native_splash` if the marks changed; notification small icon into `android/app/src/main/res/drawable-*`.
- Web: `web/public/favicon.png`, `web/public/og-image.png`, `<meta property="og:image">` tag in `web/index.html`.
- Stores: upload icon/feature graphic/screenshots to App Store Connect and Play Console; achievement art to Game Center + Play Games consoles per `plans/achievements.md` Phase 3.

## Verification

- App/store icons legible at 48px in light and dark launcher contexts.
- All 25 achievement glyphs distinguishable from each other at 64px in the profile grid; tier variants visually ranked (gold reads "highest") without relying on color alone (the ring treatment differs).
- Every `avatarIndex` 0–15 renders in `CcAvatar` (widget test iterating the range).
- `web/index.html` favicon request returns 200 in `npm run dev`; og-image validates in a social-card debugger.
- Store console validators accept all uploaded dimensions.
- `design/launch-assets/PROMPTS.md` contains the final chosen prompt for every shipped asset.
