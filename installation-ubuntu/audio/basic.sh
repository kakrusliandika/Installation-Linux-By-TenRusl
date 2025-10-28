#!/usr/bin/env bash
# Ubuntu Audio (Basic) - selective installer with TUI checklist
# Installs only what you pick: PipeWire core, ALSA tools, codecs, players, Audacity.
# Works on Ubuntu 22.04 / 24.04 LTS or newer.
set -euo pipefail

# --- Config & helpers ---
SUDO="$(command -v sudo >/dev/null 2>&1 && echo sudo || echo "")"
LOG="${LOG:-$HOME/ubuntu-audio-basic.log}"
export DEBIAN_FRONTEND=noninteractive
FAILED=()

log()  { printf "[*] %s\n" "$*" | tee -a "$LOG"; }
ok()   { printf "[✓] %s\n" "$*" | tee -a "$LOG"; }
warn() { printf "[!] %s\n" "$*" | tee -a "$LOG"; }

apt_update_once() {
  $SUDO apt-get update -y >>"$LOG" 2>&1 || true
}

apt_install() {
  local p; for p in "$@"; do
    if dpkg -s "$p" >/dev/null 2>&1; then ok "already: $p"; else
      if ! $SUDO apt-get install -y "$p" >>"$LOG" 2>&1; then
        warn "install failed: $p"; FAILED+=("$p")
      else ok "installed: $p"; fi
    fi
  done
}

ensure_repos() {
  # Enable Universe/Multiverse if needed (best-effort)
  $SUDO add-apt-repository -y universe   >>"$LOG" 2>&1 || true
  $SUDO add-apt-repository -y multiverse >>"$LOG" 2>&1 || true
}

ensure_whiptail() {
  if ! command -v whiptail >/dev/null 2>&1; then
    apt_install whiptail || apt_install dialog || true
  fi
}

# --- Choices & mapping ---
show_menu_and_get_selection() {
  if [ -n "${SELECT:-}" ]; then
    echo "$SELECT"; return 0
  fi

  if command -v whiptail >/dev/null 2>&1; then
    whiptail --title "Ubuntu Audio (Basic)" --checklist \
      "Pilih komponen yang ingin dipasang (Spasi=toggle, Tab=Next, Enter=OK)" \
      20 86 10 \
      PIPEWIRE_CORE "PipeWire+WirePlumber+compat (alsa,pulse)" ON \
      ALSA_TOOLS    "ALSA utils & Pavucontrol"                    ON \
      CODECS        "Codecs & tools (restricted-extras, ffmpeg, sox, flac, lame, vorbis-tools)" ON \
      PLAYERS       "VLC & Rhythmbox"                              OFF \
      AUDACITY      "Audacity (editor audio)"                      OFF \
      3>&1 1>&2 2>&3 || true
  else
    # Fallback non-interaktif default
    echo "PIPEWIRE_CORE ALSA_TOOLS CODECS"
  fi
}

install_selected() {
  local sel="$1"

  if [[ "$sel" == *PIPEWIRE_CORE* ]]; then
    # PipeWire core stack (default sejak 23.04; WirePlumber = session manager)
    apt_install pipewire wireplumber pipewire-alsa pipewire-pulse
  fi

  if [[ "$sel" == *ALSA_TOOLS* ]]; then
    apt_install alsa-utils pavucontrol
  fi

  if [[ "$sel" == *CODECS* ]]; then
    # Codec & tools playback/encoding umum
    apt_install ubuntu-restricted-extras ffmpeg sox flac lame vorbis-tools
  fi

  if [[ "$sel" == *PLAYERS* ]]; then
    apt_install vlc rhythmbox
  fi

  if [[ "$sel" == *AUDACITY* ]]; then
    apt_install audacity
  fi
}

summary() {
  echo
  echo "===== SUMMARY (basic) ====="
  if [ "${#FAILED[@]}" -gt 0 ]; then
    echo "Gagal dipasang (aman diabaikan bila tidak perlu): ${FAILED[*]}"
  else
    echo "Selesai tanpa kegagalan."
  fi
  echo "Log: $LOG"
}

# --- Run ---
touch "$LOG"
log "Ubuntu Audio Basic installer (selective)"
ensure_repos
apt_update_once
ensure_whiptail
SEL="$(show_menu_and_get_selection)"
log "Selected: $SEL"
install_selected "$SEL"
summary
