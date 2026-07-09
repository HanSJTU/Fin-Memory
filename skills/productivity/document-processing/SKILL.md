---
name: document-processing
description: "Create, read, edit, and extract text from PDFs, PowerPoint decks, and scanned documents. Covers nano-pdf for NL-driven PDF editing, pymupdf/marker-pdf for text extraction and OCR, python-pptx for PowerPoint, and python-docx for Word docs."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [pdf, documents, ocr, text-extraction, powerpoint, editing, productivity]
    absorbed: [nano-pdf, ocr-and-documents, powerpoint]
---

# Document Processing

Umbrella skill covering all document formats — PDFs, PowerPoint (.pptx), and Word (.docx). Create, read, edit, extract text, and search documents using the right tool for each job.

## Quick Decision Guide

| You want to... | Use this section |
|----------------|------------------|
| Edit text in a PDF via natural language | Section 2 — PDF Text Editing (nano-pdf) |
| Extract text from a PDF (URL or local) | Section 3 — Document Text Extraction |
| Extract text from a scanned PDF (OCR) | Section 3 — marker-pdf path |
| Create or edit a PowerPoint deck | Section 4 — PowerPoint |
| Read a Word document (.docx) | Section 3 — DOCX note |
| Split/merge/search PDFs | Section 3 — Split, Merge & Search |

---

## Section 1: Remote URL First

If the document has a URL, **always try `web_extract` first**:

```
web_extract(urls=["https://arxiv.org/pdf/2402.03300"])
web_extract(urls=["https://example.com/report.pdf"])
```

This handles PDF-to-markdown conversion via Firecrawl with no local dependencies. Only use local extraction when: the file is local, web_extract fails, or you need batch processing.

For arxiv papers:
- Abstract: `web_extract(urls=["https://arxiv.org/abs/2402.03300"])`
- Full paper: `web_extract(urls=["https://arxiv.org/pdf/2402.03300"])`
- Search: `web_search(query="arxiv GRPO reinforcement learning 2026")`

---

## Section 2: PDF Text Editing (nano-pdf)

Edit PDFs using natural-language instructions via the `nano-pdf` CLI.

### Prerequisites

```bash
# Install with uv (recommended — already available in Hermes)
uv pip install nano-pdf
```

### Usage

```bash
nano-pdf edit <file.pdf> <page_number> "<instruction>"
```

### Examples

```bash
# Change a title on page 1
nano-pdf edit deck.pdf 1 "Change the title to 'Q3 Results' and fix the typo in the subtitle"

# Update a date on a specific page
nano-pdf edit report.pdf 3 "Update the date from January to February 2026"

# Fix content
nano-pdf edit contract.pdf 2 "Change the client name from 'Acme Corp' to 'Acme Industries'"
```

### Notes

- Page numbers may be 0-based or 1-based depending on version — if the edit hits the wrong page, retry with ±1
- Always verify the output PDF after editing (use `read_file` to check file size, or open it)
- The tool uses an LLM under the hood — requires an API key (check `nano-pdf --help` for config)
- Works well for text changes; complex layout modifications may need a different approach

---

## Section 3: Document Text Extraction

Extract text from PDFs and scanned documents using pymupdf (lightweight) or marker-pdf (high-quality OCR).

### Extractor Comparison

| Feature | pymupdf (~25MB) | marker-pdf (~3-5GB) |
|---------|-----------------|---------------------|
| **Text-based PDF** | ✅ | ✅ |
| **Scanned PDF (OCR)** | ❌ | ✅ (90+ languages) |
| **Tables** | ✅ (basic) | ✅ (high accuracy) |
| **Equations / LaTeX** | ❌ | ✅ |
| **Code blocks** | ❌ | ✅ |
| **Forms** | ❌ | ✅ |
| **Headers/footers removal** | ❌ | ✅ |
| **Reading order detection** | ❌ | ✅ |
| **Markdown output** | ✅ (via pymupdf4llm) | ✅ (native, higher quality) |
| **Install size** | ~25MB | ~3-5GB (PyTorch + models) |
| **Speed** | Instant | ~1-14s/page (CPU), ~0.2s/page (GPU) |

**Decision**: Use pymupdf unless you need OCR, equations, forms, or complex layout analysis.

If the system lacks ~5GB free disk for marker-pdf:
> "This document needs OCR/advanced extraction (marker-pdf), which requires ~5GB for PyTorch and models. Your system has [X]GB free. Options: free up space, provide a URL, or use pymupdf (works for text-based PDFs but not scanned documents or equations)."

### pymupdf (lightweight)

```bash
pip install pymupdf pymupdf4llm
```

**Helper script** (if available from absorbed skills):
```bash
python scripts/extract_pymupdf.py document.pdf              # Plain text
python scripts/extract_pymupdf.py document.pdf --markdown    # Markdown
python scripts/extract_pymupdf.py document.pdf --tables      # Tables
python scripts/extract_pymupdf.py document.pdf --images out/ # Extract images
python scripts/extract_pymupdf.py document.pdf --pages 0-4   # Specific pages
```

**Inline**:
```bash
python3 -c "
import pymupdf
doc = pymupdf.open('document.pdf')
for page in doc:
    print(page.get_text())
"
```

### marker-pdf (high-quality OCR)

```bash
# Check disk space first
pip install marker-pdf
```

**CLI** (installed with marker-pdf):
```bash
marker_single document.pdf --output_dir ./output
marker /path/to/folder --workers 4    # Batch
```

### Split, Merge & Search

pymupdf handles these natively — use `execute_code` or inline Python:

```python
# Split: extract pages 1-5 to a new PDF
import pymupdf
doc = pymupdf.open("report.pdf")
new = pymupdf.open()
for i in range(5):
    new.insert_pdf(doc, from_page=i, to_page=i)
new.save("pages_1-5.pdf")
```

```python
# Merge multiple PDFs
import pymupdf
result = pymupdf.open()
for path in ["a.pdf", "b.pdf", "c.pdf"]:
    result.insert_pdf(pymupdf.open(path))
result.save("merged.pdf")
```

```python
# Search for text across all pages
import pymupdf
doc = pymupdf.open("report.pdf")
for i, page in enumerate(doc):
    results = page.search_for("revenue")
    if results:
        print(f"Page {i+1}: {len(results)} match(es)")
        print(page.get_text("text"))
```

### DOCX (Word Documents)

For Word docs: `pip install python-docx` — parses actual document structure, far better than OCR.

### Notes

- `web_extract` is always first choice for URLs
- pymupdf is the safe default — instant, no models, works everywhere
- marker-pdf is for OCR, scanned docs, equations, complex layouts — install only when needed
- marker-pdf downloads ~2.5GB of models to `~/.cache/huggingface/` on first use

---

## Section 4: PowerPoint (.pptx)

Create, read, and edit PowerPoint presentations using python-pptx.

### Quick Reference

| Task | Guide |
|------|-------|
| Read/analyze content | `python -m markitdown presentation.pptx` |
| Create from scratch | Use `pptxgenjs` via `npm install -g pptxgenjs` |
| Edit from template | Use python-pptx to unpack, manipulate slides, edit content, repack |

### Dependencies

```bash
pip install "markitdown[pptx]"   # text extraction
pip install Pillow               # thumbnail grids
npm install -g pptxgenjs         # creating from scratch
```

Additionally: LibreOffice (`soffice`) for PDF conversion, Poppler (`pdftoppm`) for PDF to images.

### Visual QA (Required)

**Assume there are problems. Your job is to find them.** First render is almost never correct.

#### Content QA

```bash
python -m markitdown output.pptx
```

Check for missing content, typos, wrong order. When using templates, check for leftover placeholder text:

```bash
python -m markitdown output.pptx | grep -iE "xxxx|lorem|ipsum|this.*(page|slide).*layout"
```

#### Visual QA

Convert slides to images for visual inspection:

```bash
python scripts/office/soffice.py --headless --convert-to pdf output.pptx
pdftoppm -jpeg -r 150 output.pdf slide
```

Use subagents for QA — they have fresh eyes and catch what you miss.

#### Verification Loop

1. Generate slides → Convert to images → Inspect
2. List issues found (if none found, look again more critically)
3. Fix issues
4. Re-verify affected slides — one fix often creates another problem
5. Repeat until a full pass reveals no new issues

### Design Best Practices

- **Pick a bold, content-informed color palette** — don't default to generic blue
- **Dark/light contrast** — dark backgrounds for title + conclusion slides, light for content
- **Every slide needs a visual element** — image, chart, icon, or shape
- **Commit to a visual motif** — pick ONE distinctive element and repeat it across every slide
- **Choose an interesting font pairing** — header font with personality + clean body font
- **Vary layouts** across slides — don't repeat the same layout pattern

#### Color Palettes

| Theme | Primary | Secondary | Accent |
|-------|---------|-----------|--------|
| Midnight Executive | `1E2761` (navy) | `CADCFC` (ice blue) | `FFFFFF` (white) |
| Forest & Moss | `2C5F2D` (forest) | `97BC62` (moss) | `F5F5F5` (cream) |
| Coral Energy | `F96167` (coral) | `F9E795` (gold) | `2F3C7E` (navy) |
| Warm Terracotta | `B85042` (terracotta) | `E7E8D1` (sand) | `A7BEAE` (sage) |
| Charcoal Minimal | `36454F` (charcoal) | `F2F2F2` (off-white) | `212121` (black) |
| Cherry Bold | `990011` (cherry) | `FCF6F5` (off-white) | `2F3C7E` (navy) |

#### Typography

| Element | Size |
|---------|------|
| Slide title | 36-44pt bold |
| Section header | 20-24pt bold |
| Body text | 14-16pt |
| Captions | 10-12pt muted |

#### Common Mistakes to Avoid

- Don't repeat the same layout across slides
- Don't center body text — left-align paragraphs
- Don't default to blue — pick topic-specific colors
- Don't create text-only slides — add visual elements
- NEVER use accent lines under titles — hallmark of AI-generated slides
- Don't use low-contrast elements
