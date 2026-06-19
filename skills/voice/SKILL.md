---
name: voice
description: Speak the agent's reply aloud through Kyutai Pocket TTS. Use whenever the user asks to hear the answer instead of (or in addition to) reading it - triggers like "use voice to respond", "voice this", "say that aloud", "read your reply out loud", "dictate the answer", "respond with voice", or "turn voice mode on/off".
---

# Voice replies (Pocket TTS)

Dictate your reply out loud with the local Kyutai Pocket TTS install. Defaults: English, voice `michael`.

## How to respond

1. Answer the user's actual question normally in text. The on-screen answer stays.
2. Build a **spoken version** of that answer optimized for listening, then play it.

The spoken version is NOT the markdown answer read verbatim. Convert it to clean prose:

- Plain sentences only. No markdown, bullets, headings, asterisks, or backticks.
- Drop code blocks, long file paths, and raw URLs - describe them instead ("the config file", "the GitHub link"). Read short identifiers naturally.
- ASCII only. Expand symbols the way a person would say them.
- Keep it tight. Speak the substance, not throat-clearing. If the answer is long, speak a spoken summary and tell the user the full detail is on screen.

## Playing it

The `speak.sh` helper is bundled in this skill's directory. Invoke it by its path (wherever the skill was installed).

Pass the spoken text to the helper:

```bash
speak.sh "your spoken text here"
```

For multi-line or long text, pipe it instead to avoid quoting issues:

```bash
speak.sh <<'EOF'
your spoken text here
EOF
```

The helper auto-routes: if voice mode is on it uses the warm background server (fast); otherwise it does a one-off `pocket-tts generate`. Either way it plays the audio through your speakers and blocks until playback finishes. Run it after you have written the text answer.

## One-off vs voice mode

- **One-off** (user says "voice this" once): just call `speak.sh "..."`. No server, slower first synth, nothing left running.
- **Voice mode** (user says "voice mode on" / "keep responding with voice"): first run `speak.sh on` to launch the warm server, then voice every subsequent reply with `speak.sh "..."` (now fast). The first `on` may take a minute to load the model.
- **Turn it off** (user says "voice off", "stop the voice", "text only"): run `speak.sh off` and go back to text-only replies.

`speak.sh status` reports whether the server is up.

## Options

The helper reads these environment variables (defaults shown):

- `POCKET_TTS_VOICE` (default `michael`) - a built-in voice name (e.g. `alba`, `eve`, `george`, `michael`) or a path to a `.wav`/`.safetensors` clone file.
- `POCKET_TTS_LANG` (default English) - language model id, e.g. `french_24l`, `spanish_24l`, `german_24l`, `italian_24l`, `portuguese_24l`. For French TTS, prefix `POCKET_TTS_LANG=french_24l` on the command (start the server with it too if using voice mode).
- `POCKET_TTS_PORT` (default `8000`) - server port.
- `POCKET_TTS_PLAYER` (default auto-detect) - audio player command. The helper auto-detects a common player; set this to force a specific one or if none is found, e.g. `POCKET_TTS_PLAYER="ffplay -nodisp -autoexit -loglevel quiet"`.

## Notes

- An audio player must be available. If playback reports "no audio player found", install one (e.g. `ffmpeg` for `ffplay`) or set `POCKET_TTS_PLAYER`.
- The first run downloads the model and selected voice; later runs are quick.
