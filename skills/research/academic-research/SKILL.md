---
name: academic-research
description: "End-to-end academic research workflow: arXiv paper search (keyword, author, category) with Semantic Scholar citation data, and full ML paper writing pipeline targeting NeurIPS/ICML/ICLR (experiment design, execution, analysis, LaTeX writing, review, revision)."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [research, arxiv, papers, academic, paper-writing, neurips, icml, latex, citations]
    absorbed: [arxiv, research-paper-writing]
---

# Academic Research — Paper Discovery & Writing

This umbrella covers the full research lifecycle: discovering papers via arXiv + Semantic Scholar, and writing publication-ready ML/AI papers targeting NeurIPS, ICML, ICLR, ACL, AAAI, and COLM.

---

## Section 1: arXiv Paper Discovery

Search and retrieve academic papers from arXiv via their free REST API. No API key, no dependencies — just curl. Also integrates Semantic Scholar for citation data and recommendations.

### Quick Reference

| Action | Command |
|--------|---------|
| Search papers | `curl "https://export.arxiv.org/api/query?search_query=all:QUERY&max_results=5"` |
| Get specific paper | `curl "https://export.arxiv.org/api/query?id_list=2402.03300"` |
| Read abstract | `web_extract(urls=["https://arxiv.org/abs/ID"])` |
| Read full PDF | `web_extract(urls=["https://arxiv.org/pdf/ID"])` |
| Citations (S2) | `curl -s "https://api.semanticscholar.org/graph/v1/paper/arXiv:ID?fields=title,citationCount"` |

### Search Query Syntax
- `all:transformer+attention` — all fields
- `ti:large+language+models` — title only
- `au:vaswani` — author
- `cat:cs.AI` — category
- Boolean: `+` (AND), `+OR+`, `+ANDNOT+`, `"exact+phrase"`

### Sort & Pagination
- `sortBy`: relevance, lastUpdatedDate, submittedDate
- `sortOrder`: ascending, descending
- `start`: result offset (0-based), `max_results`: count (default 10, max 30000)

### Clean Output (parse XML)
```bash
curl -s "https://export.arxiv.org/api/query?search_query=all:GRPO&max_results=5" | python3 -c "
import sys, xml.etree.ElementTree as ET
ns = {'a': 'http://www.w3.org/2005/Atom'}
root = ET.parse(sys.stdin).getroot()
for i, entry in enumerate(root.findall('a:entry', ns)):
    title = entry.find('a:title', ns).text.strip().replace(chr(10), ' ')
    arxiv_id = entry.find('a:id', ns).text.split('/abs/')[-1]
    print(f'{i+1}. [{arxiv_id}] {title}')
"
```

### Helper Script
`scripts/search_arxiv.py` handles XML parsing:
```bash
python scripts/search_arxiv.py "GRPO reinforcement learning"
python scripts/search_arxiv.py --author "Yann LeCun" --max 5
python scripts/search_arxiv.py --id 2402.03300
```

### Semantic Scholar Integration
- Citations: `curl "https://api.semanticscholar.org/graph/v1/paper/arXiv:ID?fields=citationCount"`
- References: add `/references` to the URL
- Search: `POST https://api.semanticscholar.org/recommendations/v1/papers/`
- Author lookup: `curl "https://api.semanticscholar.org/graph/v1/author/search?query=NAME"`

### Rate Limits
- arXiv: ~1 req / 3 seconds (no auth)
- Semantic Scholar: 1 req/sec (100/sec with API key)

### BibTeX Generation
```bash
curl -s "https://export.arxiv.org/api/query?id_list=ID" | python3 -c "
import sys, xml.etree.ElementTree as ET
ns = {'a': 'http://www.w3.org/2005/Atom'}
entry = ET.parse(sys.stdin).getroot().find('a:entry', ns)
title = entry.find('a:title', ns).text.strip().replace(chr(10), ' ')
authors = ' and '.join(a.find('a:name', ns).text for a in entry.findall('a:author', ns))
year = entry.find('a:published', ns).text[:4]
raw_id = entry.find('a:id', ns).text.split('/abs/')[-1]
last = entry.find('a:author', ns).find('a:name', ns).text.split()[-1]
print(f'@article{{{last}{year}, title={{{title}}}, author={{{authors}}}, year={year}, eprint={raw_id}, archivePrefix={{arXiv}}}}')
"
```

### Common Categories
cs.AI (AI), cs.CL (NLP), cs.CV (Vision), cs.LG (ML), stat.ML, math.OC

### Complete Research Workflow
1. Discover: `python scripts/search_arxiv.py "topic" --sort date --max 10`
2. Assess impact: Semantic Scholar citation count
3. Read abstract: `web_extract(urls=["https://arxiv.org/abs/ID"])`
4. Read full paper: `web_extract(urls=["https://arxiv.org/pdf/ID"])`
5. Find related: Semantic Scholar references endpoint
6. Track authors: Semantic Scholar author search

---

## Section 2: Research Paper Writing Pipeline

End-to-end pipeline for producing publication-ready ML/AI research papers (NeurIPS, ICML, ICLR, ACL, AAAI, COLM). This is an iterative loop — results trigger new experiments, reviews trigger new analysis.

### Pipeline Stages

1. **Experiment Design** — Hypothesis, protocol, baselines, metrics, ablation strategy, compute budget
2. **Execution & Monitoring** — Track experiments, handle failures, log results
3. **Analysis** — Statistical testing (t-tests, Mann-Whitney, bootstrap), effect sizes, power analysis
4. **Paper Writing** — LaTeX structure, abstract, introduction, figures, related work
5. **Review & Revision** — Structured review against venue criteria, iterative improvement
6. **Submission** — Format verification, appendix/anonymization checks

See `references/paper-writing.md` for full pipeline details including:
- LaTeX template structure and style files
- Statistical analysis recipes (significance tests, confidence intervals, multiple comparison corrections)
- Figure generation guidelines (resolution, aspect ratios, font sizes)
- Review rubric templates for NeurIPS/ICML/ICLR
- Common reviewer concerns and how to address them
- Submission checklist (formatting, anonymization, supplementary material, reproducibility)
- Experiment tracking spreadsheet format

### Required Dependencies
```bash
pip install semanticscholar arxiv habanero requests scipy numpy matplotlib SciencePlots
```

### Key Principles
- Results-first: analysis drives narrative, not the other way around
- Statistical rigor: report effect sizes and confidence intervals, not just p-values
- Reproducibility: document hyperparameters, seeds, compute, and data splits
- Iterative: each review pass should measurably improve clarity and completeness
