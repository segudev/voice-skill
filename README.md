# voice-skill

[![skills.sh](https://www.skills.sh/b/segudev/voice-skill)](https://www.skills.sh/segudev/voice-skill)

Ask your agent something, say "voice this" (or turn voice mode on), and it writes its answer on screen **and** dictates almost immediately a listening-optimized version using [Kyutai Pocket TTS](https://github.com/kyutai-labs/pocket-tts), a fully local and ultra-lightweight TTS model:

- **Runs on CPU with zero config.** No remote server, no GPU, no model wrangling. `pocket-tts generate --text "hi"` works out of the box; the first run pulls the model and you're done.
- **Ultra fast time-to-first-word.** It's a distilled, streaming model: it starts emitting audio almost immediately instead of rendering the whole clip first, so a reply begins speaking right away. With voice mode the model stays warm and replies start in a couple of seconds.
- **Clone any voice.** Pick a built-in voice by name (`michael`, `alba`, `eve`, ...) or point `--voice` at any `.wav` to clone it. This skill defaults to `michael`, and you can swap voices with one env var.

## How it works

 `SKILL.md` instructions plus a `speak.sh` helper that wraps Pocket TTS:

- **One-off** - `speak.sh "text"` runs `pocket-tts generate` and plays the result through your speakers. The model reloads each call, nothing stays running.
- **Voice mode** - `speak.sh on` launches `pocket-tts serve` (a local FastAPI server) so the model stays warm. Subsequent replies stream through `POST /tts` and start playing. `speak.sh off` stops it.

`speak.sh` auto-routes: if the server is up it uses it, otherwise it falls back to a one-off generate. Defaults: **English**, voice **`michael`**.

## Requirements

- **`curl`** on your `PATH`.
- **An audio player** on your `PATH`. The helper auto-detects a common one (`afplay`, `paplay`, `aplay`, `ffplay`, `play`, `mpv`, or `cvlc`). Override with `POCKET_TTS_PLAYER` to force a specific one.
- **[Pocket TTS](https://github.com/kyutai-labs/pocket-tts)** on your `PATH` as `pocket-tts`:

  ```bash
  uv tool install pocket-tts
  ```
  
## Install

### With the `skills` CLI (recommended)

This repo is compatible with the [open agent skills ecosystem](https://github.com/vercel-labs/skills):

```bash
npx skills add segudev/voice-skill
```

That installs the skill (with its `speak.sh` helper) into your agent's skills directory.

### Manual

```bash
git clone https://github.com/segudev/voice-skill.git
cp -r voice-skill/skills/voice <your-agent-skills-directory>/voice
chmod +x <your-agent-skills-directory>/voice/speak.sh
```

(Optional) Allow the helper in your agent's permission settings to avoid a prompt every time it runs.

## Usage

Talk to your agent normally and trigger it by voice:

- "use voice to respond" / "voice this" / "say that aloud" - voice the next reply (one-off)
- "voice mode on" - keep voicing every reply via the warm server
- "voice off" / "text only" - stop voicing and shut the server down

You can also drive the helper directly (use the path where the skill was installed):

```bash
speak.sh "Hello from Pocket TTS."   # speak text
echo "piped text works too" | speak.sh
speak.sh on                          # voice mode on (warm server)
speak.sh status                      # is the server up?
speak.sh off                         # voice mode off
```

## Configuration

`speak.sh` reads these environment variables (defaults shown):

| Variable | Default | Description |
|---|---|---|
| `POCKET_TTS_VOICE` | `michael` | A built-in voice name (`alba`, `eve`, `george`, `michael`, ...) or a path to a `.wav`/`.safetensors` clone file. |
| `POCKET_TTS_LANG` | English | Language model id, e.g. `french_24l`, `spanish_24l`, `german_24l`, `italian_24l`, `portuguese_24l`. |
| `POCKET_TTS_PORT` | `8000` | Port for the warm server. |
| `POCKET_TTS_PLAYER` | auto-detect | Audio player command, e.g. `POCKET_TTS_PLAYER="ffplay -nodisp -autoexit -loglevel quiet"`. |
| `POCKET_TTS_STARTUP_TIMEOUT` | `180` | Seconds to wait for the server to become healthy on first start. |

For a non-English voice mode, start the server with the matching model:

```bash
POCKET_TTS_LANG=french_24l speak.sh on
```

## Notes

- The first run downloads the model (and the selected voice) from Hugging Face and is slower; later runs are quick.
- Voice mode keeps a process running until you call `speak.sh off`.

## Credits

- [Kyutai Pocket TTS](https://github.com/kyutai-labs/pocket-tts) does the actual text-to-speech.
- This repo is just the skill glue around it, packaged for the [skills](https://github.com/vercel-labs/skills) ecosystem.
