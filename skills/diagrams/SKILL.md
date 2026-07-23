---
name: diagrams
description: "Create visual diagrams — dark-themed SVG architecture diagrams OR hand-drawn Excalidraw JSON diagrams. Covers infra/cloud/tech diagrams, flowcharts, sequence diagrams, and concept maps."
version: 1.0.0
author: Hermes Agent Curator
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [diagrams, architecture, svg, excalidraw, visualization, infrastructure, cloud, flowcharts]
    related_skills: [design-md, p5js, baoyu-infographic]
---

# Diagrams

Generate professional visual diagrams in two styles using two different tools,
depending on the desired output format and aesthetic:

| Style | Tool | Output | Best For |
|-------|------|--------|----------|
| **Dark-themed tech SVG** | Architecture Diagram | Self-contained `.html` file with inline SVG | Cloud/infra diagrams, microservice topology, database maps, dark-background documentation sites |
| **Hand-drawn sketch** | Excalidraw | `.excalidraw` JSON file (drag onto [excalidraw.com](https://excalidraw.com)) | Architecture, flowcharts, sequence diagrams, concept maps, whiteboard-style sketches, early-stage design exploration |

## Decision Guide

| You Want… | Use… |
|-----------|------|
| A dark, polished, production-ready architecture diagram with grid background, semantic colors, and info cards | **Architecture Diagram** (dark SVG) |
| A hand-drawn whiteboard sketch you can iterate on interactively | **Excalidraw** |
| A diagram you can embed in documentation or share as a standalone page | **Architecture Diagram** |
| A diagram you want to collaborate on or share via a URL | **Excalidraw** (has upload-to-shareable-link workflow) |
| Flowcharts, sequence diagrams, concept maps | **Excalidraw** |
| Cloud infrastructure / AWS / microservice topology | **Architecture Diagram** (has built-in cloud/AWS color system) |
| Scientific diagrams (physics, chemistry, biology) | Look elsewhere — neither tool is designed for scientific subjects |

---

## Dark-Themed SVG Architecture Diagrams

Generate a self-contained `.html` file with inline SVG graphics for technical
architecture, cloud infrastructure, and system topology. No external tools,
no API keys, no rendering libraries — just write the HTML and open it in a
browser.

### When to use this approach

- Software system architecture diagrams (frontend / backend / database layers)
- Cloud infrastructure (VPC, regions, subnets, managed services)
- Microservice / service-mesh topology
- Database + API maps, deployment diagrams
- Any tech-infra subject that fits a dark, grid-backed aesthetic

### Workflow

1. User describes architecture (components, connections, technologies)
2. Load the template with `skill_view(name="diagrams", file_path="templates/architecture-template.html")`
3. Follow the design system below to generate the HTML
4. Save with `write_file` to a `.html` file

### Color Palette (Semantic Mapping)

| Component Type | Fill (rgba) | Stroke (Hex) |
| :--- | :--- | :--- |
| **Frontend** | `rgba(8, 51, 68, 0.4)` | `#22d3ee` (cyan-400) |
| **Backend** | `rgba(6, 78, 59, 0.4)` | `#34d399` (emerald-400) |
| **Database** | `rgba(76, 29, 149, 0.4)` | `#a78bfa` (violet-400) |
| **AWS/Cloud** | `rgba(120, 53, 15, 0.3)` | `#fbbf24` (amber-400) |
| **Security** | `rgba(136, 19, 55, 0.4)` | `#fb7185` (rose-400) |
| **Message Bus** | `rgba(251, 146, 60, 0.3)` | `#fb923c` (orange-400) |
| **External** | `rgba(30, 41, 59, 0.5)` | `#94a3b8` (slate-400) |

### Typography

- **Font:** JetBrains Mono (Monospace), loaded from Google Fonts
- **Sizes:** 12px (Names), 9px (Sublabels), 8px (Annotations), 7px (Tiny labels)
- **Background:** Slate-950 (`#020617`) with subtle 40px grid pattern

### Key Implementation Details

- **Double-rect masking:** draw opaque background rect first, then semi-transparent styled rect — prevents arrows from showing through fills
- **Z-Order:** arrows drawn EARLY (after grid) so they render behind boxes
- **Arrowheads:** defined via SVG `<marker>` elements
- **Security flows:** dashed lines in rose (`#fb7185`)
- **Boundaries:** Security Groups dashed (`4,4`), rose; Regions large-dashed (`8,4`), amber
- **Legend placement:** must be OUTSIDE all boundary boxes — calculate lowest Y and place 20px below
- **Standard height:** 60px (Services), 80-120px (Large components), min 40px vertical gap
- **Info cards:** 3-card grid below the diagram for high-level details

### Output Structure

The generated HTML has four parts:
1. **Header:** Title + pulsing dot indicator + subtitle
2. **Main SVG:** The diagram in a rounded-border card
3. **Summary Cards:** 3 info cards below the diagram
4. **Footer:** Minimal metadata

### Template

Load the full HTML template with working examples of every component type and
styling pattern:

```
skill_view(name="diagrams", file_path="templates/architecture-template.html")
```

### Pitfalls

- Not for scientific subjects (physics, chemistry, biology), physical objects,
  floor plans, or narrative journeys — use Excalidraw or a specialized skill
- Legend must be placed outside all boundary boxes; inside a region boundary it
  looks like a component
- Component positions are absolute SVG coordinates; resize the viewBox if total
  width/height exceeds the default

---

## Hand-Drawn Excalidraw Diagrams

Create hand-drawn-style diagrams as standard Excalidraw element JSON and save
as `.excalidraw` files. Drag-and-drop onto [excalidraw.com](https://excalidraw.com)
for viewing, editing, and shareable links.

### When to use this approach

- Architecture diagrams, flowcharts, sequence diagrams, concept maps
- Whiteboard-style sketches for early-stage design exploration
- Any diagram where a hand-drawn, informal look is preferred

### Workflow

1. Write the elements JSON array following the format below
2. Wrap in the `.excalidraw` envelope and save with `write_file`
3. Optionally upload for a shareable link using the upload script

### Element Format

Each element has `type`, `id` (unique string), `x`, `y`, `width`, `height`.

**Sensible defaults** (skip these):
- `strokeColor`: `"#1e1e1e"`, `backgroundColor`: `"transparent"`
- `fillStyle`: `"solid"`, `strokeWidth`: `2`, `roughness`: `1`, `opacity`: `100`

### Container Binding (CRITICAL — not label property)

**NEVER** use a `"label"` property on shapes — it is NOT a valid Excalidraw property
and will be silently ignored, producing blank shapes. Always use container binding:

The shape needs `boundElements` listing the text, and the text needs `containerId` pointing back:
```json
{ "type": "rectangle", "id": "r1", "x": 100, "y": 100, "width": 200, "height": 80,
  "roundness": { "type": 3 }, "backgroundColor": "#a5d8ff", "fillStyle": "solid",
  "boundElements": [{ "id": "t_r1", "type": "text" }] },
{ "type": "text", "id": "t_r1", "x": 105, "y": 110, "width": 190, "height": 25,
  "text": "Hello", "fontSize": 20, "fontFamily": 1, "strokeColor": "#1e1e1e",
  "textAlign": "center", "verticalAlign": "middle",
  "containerId": "r1", "originalText": "Hello", "autoResize": true }
```

- Works on rectangles, ellipses, diamonds, and arrows
- Always include `fontFamily: 1` (Virgil hand-drawn font), `originalText`, `autoResize: true`
- Text `x`/`y`/`width`/`height` are approximate — Excalidraw recalculates on load

### Element Types

**Rectangle:** `{ "type": "rectangle", "id": "r1", "x": 100, "y": 100, "width": 200, "height": 100 }`
- `roundness: { "type": 3 }` for rounded corners

**Ellipse / Diamond:** Same shape but `"type": "ellipse"` or `"type": "diamond"`

**Arrow:** `{ "type": "arrow", "id": "a1", "x": 300, "y": 150, "width": 200, "height": 0, "points": [[0,0],[200,0]], "endArrowhead": "arrow" }`
- `points` are `[dx, dy]` offsets from element `x`, `y`
- `endArrowhead`: `null` | `"arrow"` | `"bar"` | `"dot"` | `"triangle"`
- `strokeStyle`: `"solid"` (default) | `"dashed"` | `"dotted"`

**Arrow bindings (connect to shapes):**
```json
{ "type": "arrow", "id": "a1", "x": 300, "y": 150, "width": 150, "height": 0,
  "points": [[0,0],[150,0]], "endArrowhead": "arrow",
  "startBinding": { "elementId": "r1", "fixedPoint": [1, 0.5] },
  "endBinding": { "elementId": "r2", "fixedPoint": [0, 0.5] } }
```
`fixedPoint`: `top=[0.5,0]`, `bottom=[0.5,1]`, `left=[0,0.5]`, `right=[1,0.5]`

### Drawing Order (Z-Order)

Array order = z-order (first = back, last = front). Emit progressively:
**background zones → shape → its bound text → its arrows → next shape**
Gaps between shapes: minimum 20-30px

### Sizing Guidelines

| Element | Minimum Size |
|---------|-------------|
| Labeled rectangles/ellipses | 120x60 |
| Font size: body/labels | 16 |
| Font size: titles | 20 |
| Font size: secondary annotations | 14 (sparingly) |
| NEVER below | 14 |

### Color Palette

See `references/excalidraw-colors.md` for full table. Quick reference:

| Use | Fill | Hex |
|-----|------|-----|
| Primary / Input | Light Blue | `#a5d8ff` |
| Success / Output | Light Green | `#b2f2bb` |
| Warning / External | Light Orange | `#ffd8a8` |
| Processing / Special | Light Purple | `#d0bfff` |
| Error / Critical | Light Red | `#ffc9c9` |
| Notes / Decisions | Light Yellow | `#fff3bf` |
| Storage / Data | Light Teal | `#c3fae8` |

### Dark Mode

For dark-themed Excalidraw diagrams, see `references/excalidraw-dark-mode.md`.
Add a massive dark-background rectangle as the FIRST element, then use dark
shape fills and light text colors.

### Examples

Full working examples (simple flow, photosynthesis, sequence diagram):
`references/excalidraw-examples.md`

### Upload for Shareable Link

```bash
python3 <skill_dir>/scripts/excalidraw-upload.py ~/diagrams/my_diagram.excalidraw
```
Requires `pip install cryptography`. Uploads to excalidraw.com (no account) and
prints a shareable URL. The diagram is encrypted client-side before upload.

### Pitfalls

1. **NEVER use `"label"` property** — silently produces blank shapes. Always use container binding (`containerId` + `boundElements`).
2. **Every bound text needs BOTH sides linked** — shape needs `boundElements`, text needs `containerId`. Missing either breaks the binding.
3. **Include `originalText` and `autoResize: true`** on all text elements.
4. **Include `fontFamily: 1`** on all text — without it, text may not use the hand-drawn font.
5. **Arrow labels need space** — keep labels short or make arrows generous.
6. **Text contrast** — minimum text color on white: `#757575`. Never light gray on white.
7. **No emoji** — they don't render in Excalidraw's font.
8. **Draw decorations LAST** — cute illustrations at end of array so they render on top.
