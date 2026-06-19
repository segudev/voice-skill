#!/usr/bin/env bash
# Speak text with Kyutai Pocket TTS and play it through the speakers.
# Plays audio through whichever common player is available (override with POCKET_TTS_PLAYER).
#
# Usage:
#   speak.sh "text to speak"      Speak text. Uses the warm server if voice mode
#   echo "text" | speak.sh        is on, otherwise a one-off `pocket-tts generate`.
#   speak.sh on                   Voice mode ON: launch the background server (warm model).
#   speak.sh off                  Voice mode OFF: stop the server.
#   speak.sh status               Report whether the server is running.
#
# Defaults: English language, "michael" voice. Override per call:
#   POCKET_TTS_VOICE   built-in voice name or path to a .wav/.safetensors (default: michael)
#   POCKET_TTS_LANG    language model id, e.g. french_24l (default: english)
#   POCKET_TTS_PORT    server port (default: 8000)
#   POCKET_TTS_PLAYER  audio player command to use (default: auto-detect)
set -euo pipefail

export PATH="$HOME/.local/bin:$PATH"

VOICE="${POCKET_TTS_VOICE:-michael}"
LANG_ID="${POCKET_TTS_LANG:-}"          # empty = the model's default (english)
HOST="127.0.0.1"
PORT="${POCKET_TTS_PORT:-8000}"
STARTUP_TIMEOUT="${POCKET_TTS_STARTUP_TIMEOUT:-180}"

STATE_DIR="${POCKET_TTS_STATE:-$HOME/.cache/pocket-tts}"
PIDFILE="$STATE_DIR/server.pid"
LOGFILE="$STATE_DIR/server.log"

base_url="http://$HOST:$PORT"

server_up() { curl -fsS -o /dev/null --max-time 2 "$base_url/health" 2>/dev/null; }

play_audio() {
  # Play a wav file, blocking until playback finishes. Tries, in order: an
  # explicit override, then the first available player for this platform.
  local wav="$1"

  if [ -n "${POCKET_TTS_PLAYER:-}" ]; then
    # Intentionally unquoted so a player set with flags is word-split.
    $POCKET_TTS_PLAYER "$wav"
    return
  fi

  if   command -v afplay >/dev/null 2>&1; then afplay "$wav"; return            # CoreAudio
  elif command -v paplay >/dev/null 2>&1; then paplay "$wav"; return            # PulseAudio/PipeWire
  elif command -v aplay  >/dev/null 2>&1; then aplay -q "$wav"; return          # ALSA
  elif command -v ffplay >/dev/null 2>&1; then ffplay -nodisp -autoexit -loglevel quiet "$wav"; return
  elif command -v play   >/dev/null 2>&1; then play -q "$wav"; return           # sox
  elif command -v mpv    >/dev/null 2>&1; then mpv --no-video --really-quiet "$wav"; return
  elif command -v cvlc   >/dev/null 2>&1; then cvlc --play-and-exit --quiet "$wav" >/dev/null 2>&1; return
  fi

  # No PATH player found: fall back to PowerShell's SoundPlayer.
  case "$(uname -s 2>/dev/null || echo unknown)" in
    MINGW*|MSYS*|CYGWIN*)
      local winpath="$wav"
      command -v cygpath >/dev/null 2>&1 && winpath="$(cygpath -w "$wav")"
      powershell.exe -NoProfile -Command "(New-Object Media.SoundPlayer '$winpath').PlaySync()" && return
      ;;
  esac

  echo "speak.sh: no audio player found. Install one (e.g. paplay, aplay, ffplay) or set POCKET_TTS_PLAYER." >&2
  return 1
}

play() {
  # Play a wav file then remove it (and its temp dir), even on failure.
  local wav="$1" rc=0
  play_audio "$wav" || rc=$?
  rm -rf "$(dirname "$wav")"
  return "$rc"
}

speak_via_server() {
  local text="$1" tmpdir out
  tmpdir="$(mktemp -d "${TMPDIR:-/tmp}/pockettts.XXXXXX")"
  out="$tmpdir/speech.wav"
  curl -fsS --max-time 600 -X POST "$base_url/tts" \
    --form-string "text=$text" \
    --form-string "voice_url=$VOICE" \
    -o "$out"
  play "$out"
}

speak_via_cli() {
  local text="$1" tmpdir out
  tmpdir="$(mktemp -d "${TMPDIR:-/tmp}/pockettts.XXXXXX")"
  out="$tmpdir/speech.wav"
  local args=(generate --quiet --text "$text" --voice "$VOICE" --output-path "$out")
  [ -n "$LANG_ID" ] && args+=(--language "$LANG_ID")
  pocket-tts "${args[@]}"
  play "$out"
}

speak() {
  local text="$1"
  if [ -z "${text//[[:space:]]/}" ]; then
    echo "speak.sh: no text provided" >&2
    exit 1
  fi
  if server_up; then
    speak_via_server "$text"
  else
    speak_via_cli "$text"
  fi
}

start_server() {
  if server_up; then
    echo "voice mode already on ($base_url)"
    return 0
  fi
  mkdir -p "$STATE_DIR"
  local args=(serve --host "$HOST" --port "$PORT")
  [ -n "$LANG_ID" ] && args+=(--language "$LANG_ID")
  nohup pocket-tts "${args[@]}" >"$LOGFILE" 2>&1 &
  echo $! >"$PIDFILE"
  local waited=0
  while [ "$waited" -lt "$STARTUP_TIMEOUT" ]; do
    if server_up; then
      echo "voice mode on (server pid $(cat "$PIDFILE"), $base_url)"
      return 0
    fi
    sleep 2
    waited=$((waited + 2))
  done
  echo "speak.sh: server did not become healthy in ${STARTUP_TIMEOUT}s; see $LOGFILE" >&2
  return 1
}

stop_server() {
  local stopped=0
  if [ -f "$PIDFILE" ]; then
    kill "$(cat "$PIDFILE")" 2>/dev/null && stopped=1
    rm -f "$PIDFILE"
  fi
  if command -v pkill >/dev/null 2>&1; then
    pkill -f 'pocket-tts serve' 2>/dev/null && stopped=1
  fi
  [ "$stopped" -eq 1 ] && echo "voice mode off" || echo "voice mode was not on"
}

status_server() {
  if server_up; then
    echo "voice mode ON ($base_url, voice=$VOICE)"
  else
    echo "voice mode OFF (one-off generate, voice=$VOICE)"
  fi
}

case "${1:-}" in
  on|start)  start_server ;;
  off|stop)  stop_server ;;
  status)    status_server ;;
  -h|--help) sed -n '2,16p' "$0" | sed 's/^# \{0,1\}//' ;;
  "")        speak "$(cat)" ;;
  *)         speak "$*" ;;
esac
