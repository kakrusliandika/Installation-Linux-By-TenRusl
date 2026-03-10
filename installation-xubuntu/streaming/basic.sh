#!/usr/bin/env bash
# Ubuntu Streaming • BASIC (22.04/24.04)
# Komponen: OBS Studio, FFmpeg, GStreamer good/bad/ugly + libav, VLC/MPV,
# Streamlink + yt-dlp, Virtual Camera (v4l2loopback).
# Contoh non-interaktif:
#   CHOICES="OBS_STUDIO FFMPEG GSTREAMER_FULL PLAYERS STREAMLINK_YTDLP V4L2LOOPBACK" ./basic.sh

set -u -o pipefail
export DEBIAN_FRONTEND=noninteractive
[ "$(id -u)" -eq 0 ] && SUDO="" || SUDO="sudo"

LOG="$HOME/streaming-install.log"
SUMMARY="$HOME/streaming-summary.txt"
FAILED=()
: >"$LOG"

log()  { printf "🔧 %s\n" "$*" | tee -a "$LOG"; }
ok()   { printf "✅ %s\n" "$*" | tee -a "$LOG"; }
warn() { printf "⚠️  %s\n" "$*" | tee -a "$LOG"; }

apt_update_once() {
  if [ -z "${APT_UPDATED:-}" ]; then
    $SUDO apt-get update -y >>"$LOG" 2>&1 || warn "apt update gagal (lanjut best-effort)"
    APT_UPDATED=1
  fi
}
apt_install() {
  local pkg="$1"
  apt_update_once
  if ! dpkg -s "$pkg" >/dev/null 2>&1; then
    if $SUDO apt-get install -y "$pkg" >>"$LOG" 2>&1; then ok "APT: $pkg terpasang"
    else warn "APT gagal: $pkg"; FAILED+=("$pkg"); fi
  else ok "APT: $pkg sudah ada"; fi
}

ensure_whiptail() { apt_install whiptail >/dev/null 2>&1 || true; }

choose_menu() {
  if [ -n "${CHOICES:-}" ]; then echo "$CHOICES"; return; fi
  ensure_whiptail
  if command -v whiptail >/dev/null 2>&1; then
    local out
    out=$(whiptail --title "Ubuntu Streaming • BASIC" --checklist "Pilih komponen:" 22 100 14 \
      OBS_STUDIO     "OBS Studio (repo Ubuntu)"                                      ON  \
      FFMPEG         "FFmpeg (encoder/decoder)"                                       ON  \
      GSTREAMER_FULL "GStreamer good/bad/ugly + libav"                                ON  \
      PLAYERS        "Pemutar: VLC, MPV"                                              ON  \
      STREAMLINK_YTDLP "Streamlink + yt-dlp (watch/download streaming)"               ON  \
      V4L2LOOPBACK   "Virtual Camera (v4l2loopback-dkms)"                             OFF \
      3>&1 1>&2 2>&3) || { echo ""; return; }
    echo "$out" | tr -d '"'
  else
    echo "${CHOICES:-OBS_STUDIO FFMPEG GSTREAMER_FULL PLAYERS STREAMLINK_YTDLP}"
  fi
}

# --- Implementasi tiap komponen ---
install_OBS_STUDIO()     { apt_install obs-studio; }
install_FFMPEG()         { apt_install ffmpeg; }
install_GSTREAMER_FULL() {
  for p in gstreamer1.0-plugins-base gstreamer1.0-plugins-good \
           gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly \
           gstreamer1.0-libav; do apt_install "$p" || true; done
}
install_PLAYERS()        { apt_install vlc; apt_install mpv || true; }
install_STREAMLINK_YTDLP(){ apt_install streamlink || true; apt_install yt-dlp || true; }
install_V4L2LOOPBACK()   {
  apt_install v4l2loopback-dkms || { warn "v4l2loopback gagal (perlu DKMS/Secure Boot?)"; }
}

main() {
  log "📦 BASIC mulai. Log: $LOG"
  local selected; selected="$(choose_menu)"
  [ -z "$selected" ] && { warn "Tidak ada pilihan. Keluar."; exit 0; }

  for item in $selected; do
    fn="install_${item}"
    if declare -f "$fn" >/dev/null 2>&1; then "$fn"; else warn "Lewati opsi tidak dikenal: $item"; fi
  done

  {
    echo "🎯 BASIC selesai."
    echo "Dipilih: $selected"
    if [ "${#FAILED[@]}" -gt 0 ]; then
      echo "⚠️  Gagal: ${FAILED[*]}"
    else
      echo "✅ Tidak ada kegagalan terdeteksi."
    fi
    echo "📄 Log: $LOG"
  } >"$SUMMARY"

  echo -e "\n✅ Selesai. Ringkasan: $SUMMARY\n"
}
main "$@"
