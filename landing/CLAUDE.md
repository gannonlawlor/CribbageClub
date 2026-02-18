# CLAUDE.md — Landing Page

## Overview

Static marketing landing page for Cribbage Club. Pure HTML/CSS/JS with no build tools or frameworks.

## Structure

```
landing/
├── index.html          # Single-page layout: hero, features, how-it-works, download, footer
├── css/styles.css      # Responsive styles, felt-green theme, scroll animations
├── js/main.js          # Navbar scroll, mobile menu, modal, scroll reveal
└── images/             # Empty — needs hero image, feature icons, app store badges, OG image
```

## Features

- **Hero section**: "The Card Game. Elevated." tagline with CTA
- **Features grid**: Play vs AI, Real-Time Multiplayer, Stats & Analysis, Play Anywhere
- **How it works**: 3-step flow (Sign Up → Find a Game → Play & Improve)
- **Download section**: App Store + Google Play badge placeholders
- **Coming Soon modal**: Email collection form (submit handler is client-side placeholder only)
- **Mobile responsive**: Hamburger nav, stacked layouts at 768px breakpoint
- **Scroll reveal**: CSS transition animations triggered on scroll via IntersectionObserver-style JS

## Design System

```css
--felt-green: #2E7D32;
--felt-green-dark: #1B5E20;
--gold-accent: #FFD54F;
--card-white: #FFFDE7;
--bg-darkest: #0A2E0F;
```

Font: Inter (Google Fonts).

## Outstanding Issues

1. **Images directory is empty** — hero-board.webp, feature icons, app-store.svg, google-play.svg, logo.svg, favicon.ico, og-image.png all referenced but missing
2. **Email form is a no-op** — submit handler just shows success message, no backend integration
3. **All footer/nav links are `#` placeholders** — Privacy Policy, Terms, Contact, Blog, Our Story, social links
4. **No analytics** — No Google Analytics, Plausible, or similar
5. **No favicon** — Referenced but not in images/
6. **"Play Now" buttons open Coming Soon modal** — need to link to actual app when deployed
7. **No SEO optimization** — Basic meta tags present but no structured data, sitemap, or robots.txt

## Serving

No build step. Serve directly with any static file server:
```bash
cd landing
python3 -m http.server 3000
# or
npx serve .
```
