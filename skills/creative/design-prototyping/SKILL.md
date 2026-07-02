---
name: design-prototyping
description: "HTML/CSS design artifact creation: claude-design process for one-off HTML artifacts (landing pages, prototypes, decks), sketch for throwaway HTML mockups with 2-3 design variants for rapid comparison, and popular-web-designs (54 ready-to-paste design systems from Stripe, Linear, Vercel, etc.)."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [design, html, css, prototyping, mockups, ui, ux, design-systems]
    absorbed: [claude-design, sketch, popular-web-designs]
---

# Design & Prototyping — HTML Artifacts, Mockups & Design Systems

This umbrella covers three complementary approaches to creating HTML/CSS design artifacts: from-scratch designed artifacts (claude-design process), quick throwaway mockups (sketch), and ready-to-paste design systems from real companies (popular-web-designs).

---

## Section 1: Claude-Design Process — From-Scratch Artifacts

Design process and taste for creating one-off HTML artifacts. Default deliverable: a self-contained HTML file with embedded CSS/JS.

### Workflow
1. **Understand the brief** — what's being designed, for whom, what artifact format?
2. **Gather context** — read supplied docs, screenshots, repo files before designing
3. **Define design system** — colors, type, spacing, radii, shadows, motion
4. **Build the artifact** — single self-contained HTML file
5. **Verify** — file exists, no syntax errors, test in browser if possible
6. **Report** — file path, what was created, caveats, next step

### Design Principles
- **Start from context, not vibes** — read actual source files before inventing UI
- **Choose the right format** — static comparison, clickable prototype, slide deck, component lab
- **Avoid AI-design slop** — no aggressive gradients, glassmorphism by default, generic SaaS cards
- **Use type as hierarchy** before adding boxes, icons, or color
- **Content discipline** — every element must earn its place, no filler

### Variation Rules
Default to at least three options: Conservative (lowest risk), Strong-fit (best interpretation), Divergent (novel).

### Technical Standards
- CSS variables for tokens, CSS grid for layout, container queries
- `prefers-reduced-motion` handling, responsive scaling, semantic HTML
- 44px minimum hit targets for mobile

### Artifact Format Rules
- Descriptive filename: `Landing Page.html`
- Embed CSS in `<style>`, JS in `<script>`
- Avoid remote deps unless stable and useful
- Preserve prior versions for major revisions

---

## Section 2: Sketch — Throwaway HTML Mockups

Quick HTML mockups for rapid visual exploration. Create 2-3 variants for comparison.

### When to Use
- User wants to "see what this would look like" before building
- Comparing layout options, color schemes, or component arrangements
- Rapid iteration on UI concepts

### Approach
- Create standalone HTML files with embedded CSS
- Deliver 2-3 variants unless the user specifies otherwise
- Focus on layout, hierarchy, and visual feel — not production code
- Discuss trade-offs and pick a direction before moving to implementation
- Files are throwaway by design

### Workflow
1. Clarify what needs visualization
2. Produce variants as separate HTML files or in-page toggles
3. Present with observations about each variant's strengths
4. After user picks a direction, either refine or move to production build

---

## Section 3: Popular Web Designs — Ready-to-Paste Design Systems

54 real-world design systems capturing complete visual language: color palette, typography, components, spacing, shadows, responsive behavior.

### How to Use
1. Pick a design from the catalog
2. Load it: `skill_view(name="design-prototyping", file_path="templates/<site>.md")`
3. Use design tokens and component specs when generating HTML

### HTML Generation Pattern
```html
<!DOCTYPE html><html lang="en"><head>
  <link href="https://fonts.googleapis.com/css2?family=..." rel="stylesheet">
  <style>
    :root { --color-bg: #fff; --color-text: #171717; --color-accent: #533afd; }
    body { font-family: 'Inter', system-ui, sans-serif; }
  </style>
</head><body><!-- Build using component specs --></body></html>
```

### Design Catalog (54 sites)

**AI/ML:** Claude (warm terracotta), Cohere (vibrant gradients), ElevenLabs (dark cinematic), Mistral AI (purple minimal), Ollama (terminal-first), OpenCode AI (dark monospace), Replicate (clean white), RunwayML (cinematic dark), Together AI (blueprint), xAI (stark monochrome), VoltAgent (void-black emerald).

**Developer Tools:** Cursor (sleek dark), Expo (dark code-centric), Linear (ultra-minimal purple), Lovable (playful gradients), Mintlify (clean green), PostHog (playful dark), Raycast (sleek chrome), Resend (minimal dark), Sentry (dark dashboard), Supabase (dark emerald), Superhuman (premium dark), Vercel (black/white precision), Warp (IDE-like), Zapier (warm orange).

**Infrastructure/Cloud:** ClickHouse (yellow technical), Composio (modern dark), HashiCorp (enterprise), MongoDB (green leaf), Sanity (red editorial), Stripe (purple gradients).

**Design/Productivity:** Airtable (colorful), Cal.com (clean neutral), Clay (organic shapes), Figma (vibrant playful), Framer (bold black/blue), Intercom (friendly blue), Miro (yellow infinite canvas), Notion (warm minimalism), Pinterest (red accent), Webflow (blue polished).

**Fintech/Crypto:** Coinbase (clean blue), Kraken (purple dark), Revolut (sleek dark), Wise (green friendly).

**Enterprise/Consumer:** Airbnb (warm coral), Apple (premium white), BMW (dark premium), IBM (carbon structured), NVIDIA (green-black energy), SpaceX (stark black/white), Spotify (vibrant green dark), Uber (bold black/white).

### Font Substitution
- Geist → Geist (Google Fonts)
- sohne-var → Source Sans 3
- Berkeley Mono → JetBrains Mono
- Circular → DM Sans
- figmaSans → Inter
