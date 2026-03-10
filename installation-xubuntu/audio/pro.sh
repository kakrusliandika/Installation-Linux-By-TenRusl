#!/usr/bin/env bash
# Ubuntu Audio (Pro) - selective installer with TUI checklist
# Fokus produksi audio: low-latency kernel, JACK stack, DAW & plugin.
# Proteksi konflik JACK vs pipewire-jack (pakai salah satu).
set -euo pipefail

SUDO="$(command -v sudo >/dev/null 2>&1 && echo sudo || echo "")"
LOG="${LOG:-$HOME/ubuntu-audio-pro.log}"
export DEBIAN_FRONTEND=noninteractive
FAILED=()

log()  { printf "🔧 %s\n" "$*" | tee -a "$LOG"; }
ok()   { printf "✅ %s\n" "$*" | tee -a "$LOG"; }
warn() { printf "⚠️ %s\n" "$*" | tee -a "$LOG"; }

apt_update_once() { $SUDO apt-get update -y >>"$LOG" 2>&1 || true; }
apt_install()     {
  local p; for p in "$@"; do
    if dpkg -s "$p" >/dev/null 2>&1; then ok "already: $p"; else
      if ! $SUDO apt-get install -y "$p" >>"$LOG" 2>&1; then
        warn "install failed: $p"; FAILED+=("$p")
      else ok "installed: $p"; fi
    fi
  done
}

ensure_repos() {
  $SUDO add-apt-repository -y universe   >>"$LOG" 2>&1 || true
  $SUDO add-apt-repository -y multiverse >>"$LOG" 2>&1 || true
}

ensure_whiptail() {
  if ! command -v whiptail >/dev/null 2>&1; then
    apt_install whiptail || apt_install dialog || true
  fi
}

menu_select() {
  if [ -n "${SELECT:-}" ]; then echo "$SELECT"; return 0; fi
  if command -v whiptail >/dev/null 2>&1; then
    whiptail --title "Ubuntu Audio (Pro)" --checklist \
      "Pilih komponen pro (Spasi=toggle, Tab=Next, Enter=OK)" \
      22 90 12 \
      LOWLAT      "Low-latency kernel (butuh reboot untuk aktif)" OFF \
      JACK_STACK  "JACK server (jackd2), QjackCtl, a2jmidid (MIDI bridging)" ON \
      DAWS        "DAW: Ardour, LMMS"                             ON \
      PLUGINS     "LV2 plugins: calf-plugins, lsp-plugins, zam-plugins" ON \
      PW_JACK     "PipeWire-JACK compatibility layer (bukan jackd2)" OFF \
      3>&1 1>&2 2>&3 || true
  else
    echo "JACK_STACK DAWS PLUGINS"
  fi
}

handle_conflicts() {
  local sel="$1"
  if [[ "$sel" == *JACK_STACK* ]] && [[ "$sel" == *PW_JACK* ]]; then
    warn "Memilih JACK_STACK + PW_JACK bersamaan → pakai JACK_STACK, hapus PW_JACK."
    sel="${sel//PW_JACK/}"  # drop PW_JACK
  fi
  echo "$sel"
}

install_selected() {
  local sel="$1"

  if [[ "$sel" == *LOWLAT* ]]; then
    apt_install linux-lowlatency
    warn "Low-latency kernel terpasang. Reboot agar kernel aktif."
  fi

  if [[ "$sel" == *JACK_STACK* ]]; then
    # Bila sebelumnya terpasang pipewire-jack, lepaskan agar tidak bentrok
    if dpkg -s pipewire-jack >/dev/null 2>&1; then
      warn "Menghapus pipewire-jack untuk memakai jackd2 asli"
      $SUDO apt-get remove -y pipewire-jack >>"$LOG" 2>&1 || true
    fi
    apt_install jackd2 qjackctl a2jmidid
  fi

  if [[ "$sel" == *DAWS* ]]; then
    apt_install ardour lmms
  fi

  if [[ "$sel" == *PLUGINS* ]]; then
    # Kumpulan plugin LV2 populer (tersedia di repo Ubuntu)
    apt_install calf-plugins lsp-plugins zam-plugins || true
  fi

  if [[ "$sel" == *PW_JACK* ]]; then
    # PipeWire JACK compat—untuk workflow tanpa jackd2
    apt_install pipewire-jack
  fi
}


summary() {
  echo
  echo "===== SUMMARY (pro) ====="
  if [ "${#FAILED[@]}" -gt 0 ]; then
    echo "Gagal dipasang (bisa diabaikan bila tidak perlu): ${FAILED[*]}"
  else
    echo "Selesai tanpa kegagalan."
  fi
  echo "Log: $LOG"
  echo "Catatan:"
  echo "- JACK GUI: jalankan 'qjackctl' untuk start/stop & routing JACK." 
  echo "- MIDI ALSA → JACK: 'a2jmidid -e' (bridging otomatis)." 
  echo "- Jika pilih LOWLAT: reboot untuk kernel lowlatency."
}

# --- Run ---
touch "$LOG"
log "Ubuntu Audio Pro installer (selective)"
ensure_repos
apt_update_once
ensure_whiptail
SEL="$(menu_select)"
SEL="$(handle_conflicts "$SEL")"
log "Selected: $SEL"
install_selected "$SEL"
summary
