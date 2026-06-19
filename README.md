# pocket-tts-voice

A [Claude Code](https://docs.anthropic.com/en/docs/claude-code) skill that speaks Claude's replies out loud on macOS using [Kyutai Pocket TTS](https://github.com/kyutai-labs/pocket-tts).

Ask Claude something, say "voice this" (or turn voice mode on), and Claude writes its answer on screen **and** dictates a listening-optimized version through your speakers. Runs fully local on CPU.

## How it works

The skill is a `SKILL.md` (instructions for Claude) plus a `speak.sh` helper that wraps Pocket TTS:

- **One-off** — `speak.sh "text"` runs `pocket-tts generate` and plays the result with `afplay`. The model reloads each call (~10s), but nothing stays running.
- **Voice mode** — `speak.sh on` launches `pocket-tts serve` (a local FastAPI server) so the model stays warm. Subsequent replies route through `POST /tts` and play in ~5s. `speak.sh off` stops it.

`speak.sh` auto-routes: if the server is up it uses it, otherwise it falls back to a one-off generate. Defaults: **English**, voice **`michael`**.

## Requirements

- macOS (uses the built-in `afplay` and `curl`)
- [Pocket TTS](https://github.com/kyutai-labs/pocket-tts) on your `PATH` as `pocket-tts`:

  ```bash
  uv tool install pocket-tts
  ```

  See the upstream repo for the authoritative install instructions.

## Install

Copy the `voice/` directory into your Claude Code skills folder:

```bash
git clone https://github.com/segudev/pocket-tts-voice.git
cp -r pocket-tts-voice/voice ~/.claude/skills/voice
chmod +x ~/.claude/skills/voice/speak.sh
```

(Optional) To avoid a permission prompt every time Claude runs the helper, add it to your Claude Code allowlist in `~/.claude/settings.json`:

```json
{
  "permissions": {
    "allow": [
      "Bash(~/.claude/skills/voice/speak.sh:*)"
    ]
  }
}
```

## Usage

Talk to Claude normally and trigger it by voice:

- "use voice to respond" / "voice this" / "say that aloud" — voice the next reply (one-off)
- "voice mode on" — keep voicing every reply via the warm server
- "voice off" / "text only" — stop voicing and shut the server down

You can also drive the helper directly:

```bash
~/.claude/skills/voice/speak.sh "Hello from Pocket TTS."   # speak text
echo "piped text works too" | ~/.claude/skills/voice/speak.sh
~/.claude/skills/voice/speak.sh on                          # voice mode on (warm server)
~/.claude/skills/voice/speak.sh status                      # is the server up?
~/.claude/skills/voice/speak.sh off                         # voice mode off
```

## Configuration

`speak.sh` reads these environment variables (defaults shown):

| Variable | Default | Description |
|---|---|---|
| `POCKET_TTS_VOICE` | `michael` | A built-in voice name (`alba`, `eve`, `george`, `michael`, ...) or a path to a `.wav`/`.safetensors` clone file. |
| `POCKET_TTS_LANG` | English | Language model id, e.g. `french_24l`, `spanish_24l`, `german_24l`, `italian_24l`, `portuguese_24l`. |
| `POCKET_TTS_PORT` | `8000` | Port for the warm server. |
| `POCKET_TTS_STARTUP_TIMEOUT` | `180` | Seconds to wait for the server to become healthy on first start. |

For French voice mode, start the server with the matching model:

```bash
POCKET_TTS_LANG=french_24l ~/.claude/skills/voice/speak.sh on
```

## Notes

- The first run downloads the model (and the selected voice) from Hugging Face and is slower; later runs are quick.
- Voice mode keeps a Python process running until you call `speak.sh off`.

## Credits

- [Kyutai Pocket TTS](https://github.com/kyutai-labs/pocket-tts) does the actual text-to-speech.
- This repo is just the Claude Code skill glue around it.
