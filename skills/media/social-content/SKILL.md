---
name: social-content
description: "Social media and content platform tools: X/Twitter API (post, search, DM, media), YouTube transcript extraction (summaries, threads, blogs), and Tenor GIF search. Covers posting, engagement, content extraction, and media search."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [social-media, twitter, youtube, gifs, content, api, transcripts]
    absorbed: [xurl, youtube-content, gif-search]
---

# Social & Content Platforms

This umbrella covers three external content platforms: X/Twitter (posting, search, DMs, media), YouTube (transcript extraction and content reformatting), and Tenor GIF search.

---

## Section 1: X (Twitter) API — xurl

Official X developer platform CLI for the X API v2. All commands return JSON.

### Installation

```bash
curl -fsSL https://raw.githubusercontent.com/xdevplatform/xurl/main/install.sh | bash
# or: brew install --cask xdevplatform/tap/xurl
# or: npm install -g @xdevplatform/xurl
```

### One-Time User Setup (user runs these, NOT agent)

```bash
xurl auth apps add my-app --client-id YOUR_CLIENT_ID --client-secret YOUR_CLIENT_SECRET
xurl auth oauth2 --app my-app YOUR_USERNAME
xurl auth default my-app
xurl auth status
xurl whoami
```

### Quick Reference

| Action | Command |
|--------|---------|
| Post | `xurl post "Hello world!"` |
| Reply | `xurl reply POST_ID "Nice!"` |
| Quote | `xurl quote POST_ID "My take"` |
| Search | `xurl search "QUERY" -n 10` |
| Whoami | `xurl whoami` |
| User lookup | `xurl user @handle` |
| Timeline | `xurl timeline -n 20` |
| Mentions | `xurl mentions -n 10` |
| Like/Unlike | `xurl like POST_ID` / `xurl unlike POST_ID` |
| Repost/Undo | `xurl repost POST_ID` / `xurl unrepost POST_ID` |
| Follow/Unfollow | `xurl follow @handle` / `xurl unfollow @handle` |
| DM | `xurl dm @handle "message"` |
| List DMs | `xurl dms -n 10` |
| Upload media | `xurl media upload path/to/file.mp4` |

### Raw API Access

```bash
xurl /2/users/me
xurl -X POST /2/tweets -d '{"text":"Hello!"}'
xurl -X DELETE /2/tweets/1234567890
```

### Secret Safety (MANDATORY)
- Never read/print/send `~/.xurl` to LLM context
- Never pass secrets inline in agent sessions
- Never use `--verbose` in agent sessions
- Forbidden flags: `--bearer-token`, `--consumer-key`, `--access-token`, `--client-id`, `--client-secret`

---

## Section 2: YouTube Content

Extract transcripts from YouTube videos and convert them into structured formats.

### Setup

```bash
pip install youtube-transcript-api
```

### Usage

The helper script at `scripts/fetch_transcript.py` accepts any YouTube URL format.

```bash
python3 SKILL_DIR/scripts/fetch_transcript.py "https://youtube.com/watch?v=VIDEO_ID" --text-only --timestamps
python3 SKILL_DIR/scripts/fetch_transcript.py "URL" --text-only
python3 SKILL_DIR/scripts/fetch_transcript.py "URL" --language tr,en
```

### Output Formats

See `references/youtube-output-formats.md` for templates.

- **Chapters** — timestamped topic list
- **Summary** — 5-10 sentence overview
- **Chapter summaries** — per-section paragraphs
- **Thread** — Twitter/X numbered posts
- **Blog post** — full article with sections
- **Quotes** — notable quotes with timestamps

### Workflow

1. Fetch transcript with `--text-only --timestamps`
2. Validate output is non-empty
3. Chunk if > 50K chars (40K chunks, 2K overlap)
4. Transform into requested format
5. Verify coherence before presenting

### Error Handling
- **Transcript disabled** — tell user
- **No matching language** — retry without `--language`
- **Dep missing** — `pip install youtube-transcript-api`

---

## Section 3: GIF Search (Tenor API)

Search and download GIFs via the Tenor API using curl + jq.

### Setup

```bash
# Set in ~/.hermes/.env:
TENOR_API_KEY=your_key_here
```

Get a free key at https://developers.google.com/tenor/guides/quickstart

### Search

```bash
# Get GIF URLs
curl -s "https://tenor.googleapis.com/v2/search?q=thumbs+up&limit=5&key=${TENOR_API_KEY}" \
  | jq -r '.results[].media_formats.gif.url'

# Download top result
URL=$(curl -s "https://tenor.googleapis.com/v2/search?q=celebration&limit=1&key=${TENOR_API_KEY}" \
  | jq -r '.results[0].media_formats.gif.url')
curl -sL "$URL" -o celebration.gif

# Get metadata
curl -s "https://tenor.googleapis.com/v2/search?q=cat&limit=3&key=${TENOR_API_KEY}" \
  | jq '.results[] | {title: .title, url: .media_formats.gif.url}'
```

### API Parameters

| Parameter | Description |
|-----------|-------------|
| `q` | Search query (spaces as `+`) |
| `limit` | Max results (1-50) |
| `media_filter` | gif, tinygif, mp4, tinymp4, webm |
| `contentfilter` | off, low, medium, high |

### Media Formats

| Format | Use |
|--------|-----|
| `gif` | Full quality |
| `tinygif` | Small preview |
| `mp4` | Video (smaller file) |
| `tinymp4` | Small video preview |
| `webm` | WebM format |
