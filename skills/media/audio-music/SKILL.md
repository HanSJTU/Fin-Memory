---
name: audio-music
description: "Music and audio tools: HeartMuLa open-source song generation from lyrics+tags, songsee audio spectrograms/features visualization, and songwriting craft with Suno AI prompt engineering. Covers generation, analysis, and creative craft."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [music, audio, generation, songwriting, suno, spectrogram, analysis, heartmula]
    absorbed: [heartmula, songsee, songwriting-and-ai-music]
---

# Audio & Music — Generation, Analysis, Songwriting

This umbrella covers three areas: music generation with HeartMuLa, audio analysis with songsee, and creative songwriting craft (including Suno AI prompt engineering).

---

## Section 1: HeartMuLa — Open-Source Music Generation

HeartMuLa is a family of open-source music foundation models (Apache-2.0) that generates music conditioned on lyrics and tags, with multilingual support. Comparable to Suno for open-source.

### Hardware Requirements
- **Minimum:** 8GB VRAM with `--lazy_load true` (loads/unloads models sequentially)
- **Recommended:** 16GB+ VRAM
- 3B model with lazy_load peaks at ~6.2GB VRAM

### Installation

```bash
git clone https://github.com/HeartMuLa/heartlib.git
cd heartlib
uv venv --python 3.10 .venv
. .venv/bin/activate
uv pip install -e .
uv pip install --upgrade datasets transformers

# Download checkpoints (several GB total)
hf download --local-dir './ckpt' 'HeartMuLa/HeartMuLaGen'
hf download --local-dir './ckpt/HeartMuLa-oss-3B' 'HeartMuLa/HeartMuLa-oss-3B-happy-new-year'
hf download --local-dir './ckpt/HeartCodec-oss' 'HeartMuLa/HeartCodec-oss-20260123'
```

### Usage

```bash
python ./examples/run_music_generation.py \
  --model_path=./ckpt \
  --version="3B" \
  --lyrics="./assets/lyrics.txt" \
  --tags="./assets/tags.txt" \
  --save_path="./assets/output.mp3" \
  --lazy_load true
```

### Tags Format
```
piano,happy,wedding,synthesizer,romantic
```

### Lyrics Format
```
[Intro]
[Verse]
Your lyrics here...
[Chorus]
Chorus lyrics...
```

### Key Parameters
| Parameter | Default | Description |
|-----------|---------|-------------|
| `--max_audio_length_ms` | 240000 | Max length in ms (240s) |
| `--topk` | 50 | Top-k sampling |
| `--temperature` | 1.0 | Sampling temperature |
| `--cfg_scale` | 1.5 | Classifier-free guidance scale |

### Pitfalls
1. Do NOT use bf16 for HeartCodec — degrades quality. Use fp32.
2. Tags may be ignored by the model — experiment with tag ordering.
3. Triton not available on macOS — Linux/CUDA only.
4. Requires Python 3.10.
5. The dependency pin conflicts require manual upgrades and patches (see repo issues).

**Links:** [Repo](https://github.com/HeartMuLa/heartlib) | [Models](https://huggingface.co/HeartMuLa) | [Paper](https://arxiv.org/abs/2601.10547)

---

## Section 2: songsee — Audio Spectrogram Visualization

Generate spectrograms and multi-panel audio feature visualizations from audio files.

### Installation
```bash
go install github.com/steipete/songsee/cmd/songsee@latest
```

### Quick Start
```bash
songsee track.mp3 -o spectrogram.png
songsee track.mp3 --viz spectrogram,mel,chroma,hpss,selfsim,loudness,tempogram,mfcc,flux
songsee track.mp3 --start 12.5 --duration 8 -o slice.jpg
cat track.mp3 | songsee - --format png -o out.png
```

### Visualization Types
| Type | Description |
|------|-------------|
| `spectrogram` | Standard frequency spectrogram |
| `mel` | Mel-scaled spectrogram |
| `chroma` | Pitch class distribution |
| `hpss` | Harmonic/percussive separation |
| `selfsim` | Self-similarity matrix |
| `loudness` | Loudness over time |
| `tempogram` | Tempo estimation |
| `mfcc` | Mel-frequency cepstral coefficients |
| `flux` | Spectral flux (onset detection) |

### Common Flags
| Flag | Description |
|------|-------------|
| `--viz` | Visualization types (comma-separated) |
| `--style` | Color palette: classic, magma, inferno, viridis, gray |
| `--start` / `--duration` | Time slice |
| `--format` | jpg or png |
| `-o` | Output file path |

### Notes
- WAV and MP3 are decoded natively; other formats require ffmpeg
- Output images can be inspected with `vision_analyze`

---

## Section 3: Songwriting & Suno AI Prompts

Creative songwriting craft guidelines and Suno AI prompt engineering. Everything here is a GUIDELINE, not a rule — art breaks rules on purpose.

### Song Structure
```
ABABCB  Verse/Chorus/Verse/Chorus/Bridge/Chorus  (most pop/rock)
AABA    Verse/Verse/Bridge/Verse                  (jazz standards)
AAA     Verse/Verse/Verse                         (folk, storytelling)
```

Building blocks: Intro, Verse, Pre-Chorus, Chorus, Bridge, Outro.

### Suno Style Field Formula
```
Genre + Mood + Era + Instruments + Vocal Style + Production + Dynamics
```

**Bad:** "sad rock song"
**Good:** "Cinematic orchestral spy thriller, 1960s Cold War era, smoky sultry female vocalist, big band jazz, minor key, vintage analog warmth"

**Describe the journey:**
```
"Begins as a haunting whisper over sparse piano. Gradually layers in muted brass. Builds through the chorus with full orchestra. Outro strips back to a lone piano."
```

### Suno Metatags
- **Structure:** [Intro] [Verse] [Pre-Chorus] [Chorus] [Bridge] [Outro] [Instrumental] [Guitar Solo]
- **Vocal:** [Whispered] [Spoken Word] [Belted] [Falsetto] [Soulful] [Raspy] [Breathy]
- **Dynamics:** [High Energy] [Low Energy] [Building Energy] [Explosive] [Emotional Climax]
- **Atmosphere:** [Melancholic] [Euphoric] [Nostalgic] [Aggressive] [Dreamy]

### Phonetic Tricks for AI Singers
- Spell words as they SOUND: "through" → "thru", "Nous" → "Noose"
- ALL CAPS = louder
- Vowel extension: "lo-o-o-ove" = sustained/melisma
- Space acronyms: "AI" → "A I"

### Workflow
1. Write the concept/hook first
2. If adapting, map original structure (syllables, rhyme, stress)
3. Draft lyrics into structure
4. Read/sing aloud — catch stumbles
5. Build style description — paint the dynamic journey
6. Generate 3-5 variations minimum
7. Pick best, use Extend to build on promising sections

### Parody Adaptation
- Count syllables per line of original
- Mark rhyme scheme and stressed syllables
- Match stressed syllables to same beats
- Keep some original lines for recognizability
