---
name: text-art
description: "ASCII art creation and animation: static banners (pyfiglet, cowsay, boxes, toilet), image-to-ASCII conversion, ASCII video production pipeline, and Pretext creative browser demos (DOM-free text layout for kinetic typography, text-as-geometry, reflow-around-obstacle)."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [ascii, text-art, banners, cowsay, video, pretext, typography, creative]
    absorbed: [ascii-art, ascii-video, pretext]
---

# Text Art — ASCII Art, ASCII Video & Pretext Demos

This umbrella covers three areas of text-based visual art: static ASCII art generation, animated ASCII video production, and pretext creative browser demos using DOM-free text layout.

---

## Section 1: Static ASCII Art

### Text Banners (pyfiglet)
```bash
pip install pyfiglet
python3 -m pyfiglet "YOUR TEXT" -f slant
python3 -m pyfiglet "TEXT" -f doom -w 80
python3 -m pyfiglet --list_fonts
```
**Fonts:** slant (clean), doom (bold), big, banner3 (wide), cyberlarge (tech), 3-d.

### Text Banners (asciified API — no install)
```bash
curl -s "https://asciified.thelicato.io/api/v2/ascii?text=Hello+World&font=Slant"
curl -s "https://asciified.thelicato.io/api/v2/fonts"  # list all fonts
```

### Cowsay (Message Art)
```bash
sudo apt install cowsay -y
cowsay "Hello World"
cowsay -f tux "Linux rules"       # Tux the penguin
cowsay -f dragon "Rawr!"
cowthink "Hmm..."
cowsay -l                          # list 50+ characters
```
Modifiers: `-b` (borg), `-d` (dead), `-g` (greedy), `-p` (paranoid), `-e "OO"` (custom eyes).

### Boxes (Decorative Borders)
```bash
sudo apt install boxes -y
echo "Hello World" | boxes -d stone            # Stone border
echo "Hello World" | boxes -d parchment        # Scroll
python3 -m pyfiglet "HERMES" -f slant | boxes -d stone  # Combined
boxes -l                                         # list 70+ designs
```

### TOIlet (Colored Text Art)
```bash
sudo apt install toilet toilet-fonts -y
toilet "Hello World"
toilet --gay "Rainbow!"     # rainbow coloring
toilet --metal "Metal!"     # metallic effect
toilet -F border --gay "Fancy!"
```

### Image to ASCII
```bash
# ascii-image-converter (recommended)
sudo snap install ascii-image-converter
ascii-image-converter image.png -C              # color output
ascii-image-converter https://url/image.jpg     # direct URL

# jp2a (lightweight, JPEG only)
sudo apt install jp2a -y
jp2a --width=80 image.jpg --colors
```

### Pre-Made ASCII Art
```bash
curl -s 'https://ascii.co.uk/art/cat' -o /tmp/art.html
# Then extract <pre> tags with Python
```
Subjects: cat, dog, dragon, skull, robot, car, ship, tree, flower, etc.

### Fun Utilities
```bash
curl -s "qrenco.de/Hello+World"           # QR code ASCII
curl -s "wttr.in/London"                   # weather ASCII art
curl -s https://api.github.com/octocat     # GitHub Octocat
```

---

## Section 2: ASCII Video Production Pipeline

Convert video/audio/images into colored ASCII character video output (MP4, GIF, image sequence). Audio-reactive music visualizers, generative animations, hybrid video+audio reactive modes.

### Modes
- **Video-to-ASCII** — recreates source footage as ASCII
- **Audio-reactive** — generative visuals driven by audio features
- **Generative** — procedural ASCII animation from seed params
- **Hybrid** — video + audio with reactive overlays

### Stack
Python 3.10+, NumPy, SciPy (FFT), Pillow, ffmpeg (CLI), concurrent.futures. No GPU required.

### Pipeline
```
INPUT → ANALYZE → SCENE_FN → TONEMAP → SHADE → ENCODE
```

### Aesthetic Dimensions
Character palette (density ramps, block elements, symbols, scripts), color strategy (HSV, OKLAB, discrete RGB palettes), background texture (sine fields, fBM noise, voronoi), effects (rings, spirals, tunnel, waves, particles), shader mood (CRT, glitch, cinematic, dreamy).

### Critical Implementation Notes
- **Use tonemap(), not linear multipliers** — `canvas * N` clips highlights
- **Font cell height** — use `font.getmetrics()` not `textbbox()`
- **ffmpeg pipe** — never `stderr=subprocess.PIPE` (deadlocks at 64KB)
- **Per-clip architecture** for segmented videos

See `references/ascii-video-architecture.md` for full grid system, character palettes, color system, blend modes, feedback buffer, shader chain, scene functions, and troubleshooting.

---

## Section 3: Pretext Creative Demos

[`@chenglou/pretext`](https://github.com/chenglou/pretext) is a 15KB zero-dependency library for DOM-free multiline text measurement and layout. Use for kinetic typography, text-as-geometry, reflow-around-obstacle, and text-powered generative art demos.

### Stack
Single self-contained HTML file. Import from `https://esm.sh/@chenglou/pretext@0.0.6`.

### Two Use Cases

**Use-case 1 — measure, then render with CSS/DOM:**
```js
const prepared = prepare(text, "16px Inter");
const { height, lineCount } = layout(prepared, 320, 20);
```

**Use-case 2 — measure and render yourself (creative path):**
```js
const prepared = prepareWithSegments(text, FONT);
const { lines } = layoutWithLines(prepared, 320, 26);
for (let i = 0; i < lines.length; i++) {
  ctx.fillText(lines[i].text, 0, i * 26);
}
```

**Variable-width per line (flow around obstacles):**
```js
let cursor = { segmentIndex: 0, graphemeIndex: 0 };
while (true) {
  const lineWidth = widthAtY(y);
  const range = layoutNextLineRange(prepared, cursor, lineWidth);
  if (!range) break;
  const line = materializeLineRange(prepared, range);
  ctx.fillText(line.text, leftEdgeAtY(y), y);
  cursor = range.end;
  y += lineHeight;
}
```

### Demo Patterns
| Pattern | Key API |
|---------|---------|
| Reflow around obstacle | `layoutNextLineRange` + per-row width function |
| Text-as-geometry game | `layoutWithLines` + per-line collision rects |
| Shatter / particles | `walkLineRanges` → per-grapheme (x,y) → physics |
| Kinetic type | `layoutWithLines` + per-line transform over time |
| Multiline shrink-wrap | `measureLineStats` |

### Pitfalls
- Drifting CSS/canvas font strings — keep in sync
- Re-preparing inside animation loop — `prepare()` once only
- `Intl.Segmenter` for grapheme splits (emoji, CJK)
- Monospace fallbacks erasing the point — verify font in DevTools
