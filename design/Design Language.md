# Cribbage Club — Design Language v1.0

Competitive online cribbage. Serious-game aesthetic: quiet charcoal, one decisive green, gold reserved for skill. Dark theme primary; light mapping at the end. All tokens are CSS custom properties, ready for Tailwind arbitrary values (`bg-[var(--surface-2)]`).

---

## 1. Design principles

1. **The count is always legible at a glance.** The pegging count is the largest live number on screen. Nothing crowds, overlays, or restyles it mid-play.
2. **Gold means skill, nothing else.** `--gold` appears only where ability is measured: ratings, trophies, rating deltas, the 121 hole. Never buttons, never decoration.
3. **One green, and it always means "act."** Action green is the only saturated interactive color. If it's green, clicking it advances the game or the player.
4. **Cards are instruments, not decoration.** Faces are optimized for reading at 40px, not beauty at 400px. No bevels, gloss, or ornamental backs.
5. **Records are content, motion is punctuation.** Ratings, streaks, and analysis get layout priority. Animation confirms what happened in ≤320ms — nothing bouncy, ever.

---

## 2. Color system (dark, primary)

Contrast ratios are against the surface named; all text tokens meet WCAG AA (≥4.5:1) on their intended surface.

```css
:root {
  /* Surfaces — 4 elevation steps */
  --surface-0: #262421;  /* chrome: sidebar, headers */
  --surface-1: #312e2b;  /* page background */
  --surface-2: #3c3936;  /* panels, cards, table headers */
  --surface-3: #47433f;  /* hover, raised, selected rows */
  --board:     #38342f;  /* cribbage board panel — 2 steps warmer */
  --border:        rgba(255,255,255,0.08);
  --border-strong: rgba(255,255,255,0.14);

  /* Text — on --surface-1 */
  --text-1: #f0ede8;     /* 11.5:1  headings, scores, names */
  --text-2: #b8b3ac;     /*  6.5:1  body, table cells */
  --text-3: #9c968e;     /*  4.6:1  labels, timestamps, meta */
  --text-faint: #6b6660; /*  2.5:1  disabled/decorative ONLY, never copy */

  /* Action green */
  --green-300: #a4d372;  /* focus ring, green-on-green */
  --green-400: #93c757;  /* hover fill */
  --green-500: #81b64c;  /* base fill · as text: 5.6:1 on surface-1 */
  --green-600: #5d9948;  /* pressed edge / bottom bevel */
  --on-green:  #16240c;  /* text on green fills — 6.8:1 (white fails: 2.5:1) */

  /* Rating & semantic — on --surface-1 */
  --gold:   #e3aa24;     /* 6.5:1  ratings, trophies, 121 hole — nothing else */
  --win:    #81b64c;     /* 5.6:1 */
  --loss:   #e5766d;     /* 4.6:1  also --error */
  --draw:   #9c968e;     /* 4.6:1  aborted/void games */
  --streak: #e2833f;     /* 4.9:1  win streaks — deliberately not gold */

  /* Card faces */
  --card-face:  #f5f0e8;
  --card-red:   #c0392b; /* 5.7:1 on card-face */
  --card-black: #1a1a1a; /* 15:1  on card-face */
  --card-back:  #4a5568; /* cool slate + 45° hairline stripes + 4px card-stock border */

  /* Player identity (replaces gold-vs-white) */
  --player-self: #81b64c; /* your pegs, popups, bar accent — your action color follows you */
  --player-opp:  #d9d4cc; /* card-stock ivory: neutral, never "premium" */

  /* Board */
  --board-track: rgba(0,0,0,0.22);
  --board-hole:  #211f1d;
}
```

**Player identity rationale:** gold-vs-white made the opponent look premium and diluted rating gold. Green = you (it already means "you/act" everywhere); ivory = opponent (echoes card stock). ~9× luminance gap holds for all color-vision types. Score popups fill with the scorer's identity color + dark text (both ≥6:1).

---

## 3. Typography

**System stack, defended.** `-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif` — native rendering on web/iOS/Android, zero load time, first-rate tabular figures. No webfont.

`font-variant-numeric: tabular-nums` is mandatory on: scores, ratings, the pegging count, timers, and every table column.

| Step | Size/Line | Weight | Use |
|---|---|---|---|
| display | 40/44 | 700 | pegging count, big scores |
| title | 28/34 | 700 | panel titles, game-over result |
| heading | 20/28 | 600 | section heads, card titles |
| body | 15/22 | 400 | default UI text |
| label | 13/18 | 500 | metadata, secondary rows |
| caption | 12/16 | 500 · +0.06em · uppercase | section labels, table headers, stage names |

---

## 4. Component specs

### Player bar (in-game)
- 60px tall, `--surface-0`, r8, padding 10/14. Grid: 40px avatar · flexible identity · right-aligned score.
- 3px identity edge on the left (`--player-self` / `--player-opp`).
- Name 14/600 `--text-1`, ellipsizes (fits 6–20 chars); rating `(1847)` 13px `--gold`, tabular, never truncates; DEALER chip 10/700 uppercase on `--surface-3`.
- Progress-to-121 bar: 4px, track `--surface-3`, fill identity color.
- Score: 32px/700 tabular `--text-1`; column reserves width for "121".
- States: active turn → edge brightens to `--green-400`; inactive → edge at 40% opacity.

### Play CTA
- 56px, r8, fill `--green-500`, text 18/700 `--on-green`, bottom bevel `inset 0 -4px 0 var(--green-600)`.
- Hover `--green-400` (100ms); press: bevel collapses to 1px + translateY(2px), instant; focus 2px `--green-300` ring, 2px offset; disabled 40% opacity, no bevel.

### Secondary / surface button
- 40px, r8, `--surface-2` fill, `--border-strong` border, 14/600 `--text-1`; hover `--surface-3`.
- Tertiary: transparent, `--text-3` → hover `--text-1` + `--surface-2` fill.

### Stat / rating card
- `--surface-2`, r8, p16, `--border`. Caption label + 28/700 tabular value; gold only when the value is a rating. Optional delta 13/600 in `--win`/`--loss`.

### Data table row (lobby, leaderboard)
- 42px rows, padding 11/14, hairline separators `--border` at 6%, header row caption-style on `--surface-2`.
- Hover `--surface-3`; "you" row: `rgba(129,182,76,0.08)` wash.
- All numerals tabular, right-aligned. Lobby variant: trailing columns = time control + Join button revealed on hover.

### Playing card
- Ratio 5:7, radius 8% of width. **Corner index only** (rank over suit) + one large center pip — no pip grids; this is what keeps 40px readable.
- Rank ≥25% of card width, 700, tabular ("10" is the widest case). Face `--card-face`; pips `--card-red`/`--card-black`.
- Back: `--card-back` slate, 45° hairline stripes `rgba(255,255,255,0.07)`, 4px `--card-face` border, no logo.
- Selected-in-hand: lift 8px + 2px `--green-300` ring. Shadow: `0 1px 3px rgba(0,0,0,0.4)` always.

### Score popup
- Pill, r-full, padding 7/14. Points 14/700 tabular + reason 14/500 at 75% opacity ("+2 fifteen").
- Fill = scorer's identity color, text dark `#26221e`/`--on-green`. Anchored above the scoring card / peg.

### Stage / turn indicator
- Pill strip: Deal · Discard · Pegging · Count. Active = `--green-500` fill + `--on-green`; past = `--text-3`; future = `--text-faint`. 12/600 +0.04em.
- Single source of turn truth, paired with a 13px instruction line ("Your discard").

### Nav sidebar item
- Sidebar `--surface-0`, 240px expanded / 68px rail. Item 38px, r6, icon 20px (geometric, 1.5px stroke) + 14px label.
- Active: `--surface-2` fill + 3px `--green-500` left marker + green icon tint. Hover: fill only. Rail keeps the marker, drops labels.

### Invite-code display
- `--surface-0`, r8, **1px dashed** `--border-strong` (signals "share me"), padding 14/16.
- Code: monospace 20px, +0.18em tracking, groups of 4 (`QJ4K-7H2P`), `--text-1`. Whole card is the copy target; flash `--green-500` 400ms on copy.

### Game-over panel
- Modal 340px, `--surface-2`, r12, `--border-strong`, shadow `0 12px 40px rgba(0,0,0,0.5)`, scrim `rgba(0,0,0,0.55)`.
- Result word 26/700 `--text-1` — never colored; the rating delta carries valence. Score line 14 `--text-3` tabular.
- Rating chip on `--surface-0`: new rating 24/700 `--gold` + delta in `--win`/`--loss`.
- Buttons: Rematch (44px CTA), then Analyze game / New opponent (38px outline pair). Defeat = identical layout.

---

## 5. The cribbage board

**Recommendation: flatten it.** Drop the walnut canvas — a wood object floating in a charcoal UI reads as a different app, and it's the skeuomorphism the brief bans. Keep the warmth in the *tint*, not the texture:

- Board panel `--board: #38342f` (2 steps warmer than surface-2), r12.
- Lanes: recessed tracks `rgba(0,0,0,0.22)`, r-full.
- Holes: 13px circles `#211f1d`, inset top shadow (`inset 0 1px 2px rgba(0,0,0,0.6)`) — "drilled" via lighting only. Groups of 5 with 10px gaps; street markers 30/60/90 as caption labels below the track.
- Hole 121: the only gold on the field — 2px `--gold` ring.
- Pegs: front peg filled identity color + drop shadow; back peg 2px outlined ring of the same color.
- Mobile (<480px): lanes compress to a 6px linear track with peg dots; holes drop out.

---

## 6. Layout grids

8px base grid throughout. Breakpoint: **1024px**.

**Game screen (≥1024):** nav rail 68px · game column fluid (min 640px) · right panel fixed 400px (moves/chat/analysis) · 24px gutters. Opponent bar top, your bar bottom; the board strip sits between table and your hand so count and pegs share one eye-line. <1024: right panel becomes bottom tabs; board strip persists above the hand.

**Home dashboard:** 12-col, max 1140px, 24px gutters. Play block spans 8 + rating card spans 4 (the CTA and your number are the above-fold story) → 3× 4-col stat cards → recent-games table full width. <1024: single column, CTA first.

**Landing hero:** 64px nav, then one centered 720px column: display headline, one line of copy, Play + Sign in pair, live-games counter in tabular caption. No feature grid above the fold — the proof is the player count.

---

## 7. Motion

Two easings only. No spring, overshoot, or bounce. Nothing exceeds 320ms.

```css
--ease-out: cubic-bezier(0.2, 0, 0, 1);   /* things arriving */
--ease-in:  cubic-bezier(0.4, 0, 1, 1);   /* things leaving  */
```

| Event | Duration | Easing | Notes |
|---|---|---|---|
| Card play (hand → table) | 180ms | ease-out | translate + ≤3° settle rotation |
| Starter cut (flip) | 240ms | ease-out | rotateY, face legible by 60% |
| Score popup | 140ms in / 200ms out | out / in | rise 6px, hold 1100ms |
| Peg movement | 240ms (cap 320ms) | ease-out | one slide — never hole-by-hole hops |
| Count / score swap | 120ms | ease-out | crossfade, no odometer rolls |
| Page / panel | 160ms | ease-out | fade + 4px rise |
| Hover / press | 100ms / 0ms | linear | press feedback is instant |

---

## 8. Voice & microcopy

Confident, understated, specific. State facts, use numbers, never cheerlead. Zero exclamation points.

- **Match found:** "Rated match found. MugginsMaude (1512) · first deal is yours."
- **Win:** "Victory · 121–98. Rating 1855 (+8)."
- **Loss:** "Defeat · 104–121. Rating 1839 (−8)."
- **Skunk:** "Skunk · 121–87. That one counts double on the ladder."
- **Empty history:** "No games yet. Your first rated game sets your rating."
- **Empty friends:** "No club members yet. Share your invite code to start a match."
- **Streak:** "Five straight. Best streak: 7."
- **Guest upsell:** "You're playing unrated. Create an account to keep a rating and your game history."
- **Resign confirm:** "Resign this game? It counts as a loss." — [Resign] [Keep playing]
- **Disconnect:** "Opponent disconnected. You can claim the win in 0:47."
- **Daily puzzle:** "Today's puzzle: pick the discard. 12,431 solved."
- **Analysis ready:** "Analysis ready. Two inaccuracies, one missed 4-point discard."

---

## 9. Light theme mapping

Warm paper, same token names. Button fills don't change — `--green-500` + `--on-green` pass on both themes, so the CTA is theme-invariant. Card faces, backs, and pegs are identical in both themes.

```css
[data-theme="light"] {
  --surface-0: #eae6e0;   /* chrome */
  --surface-1: #f4f1ec;   /* page */
  --surface-2: #ffffff;   /* panels */
  --surface-3: #efece6;   /* hover */
  --board:     #ece7df;
  --border:        rgba(0,0,0,0.08);
  --border-strong: rgba(0,0,0,0.14);

  --text-1: #2a2622;      /* 13.6:1 on surface-1 */
  --text-2: #57524b;      /*  7.4:1 */
  --text-3: #767066;      /*  4.7:1 */
  --text-faint: #a8a29a;

  --gold:  #9a7514;       /* rating text · 4.8:1 (#e3aa24 fails on light: 2.1:1) */
  --win:   #4e7a2e;       /* green as text · 4.7:1 */
  --loss:  #b6362a;       /* 4.9:1 */
  --draw:  #767066;
  --streak:#b25a17;

  --player-self: #81b64c;
  --player-opp:  #a49c90; /* ivory would vanish on paper */
  --board-track: rgba(0,0,0,0.07);
  --board-hole:  #d8d2c8;
}
```
