#!/usr/bin/env bash
# Ubuntu Utilities • BASIC (22.04/24.04)
# Komponen: Flatpak + Flathub (plugin GUI), GNOME Tweaks, Flameshot, CopyQ, GParted, Baobab,
# PDF tools (pdfarranger, ocrmypdf, poppler-utils), Archiver (file-roller).
# Contoh non-interaktif:
#   CHOICES="FLATPAK_SETUP TWEAKS FLAMESHOT COPYQ GPARTED BAOBAB PDF_TOOLS ARCHIVER" ./basic.sh

set -u -o pipefail
export DEBIAN_FRONTEND=noninteractive
[ "$(id -u)" -eq 0 ] && SUDO="" || SUDO="sudo"

LOG="$HOME/utilities-install.log"
SUMMARY="$HOME/utilities-summary.txt"
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
    out=$(whiptail --title "Ubuntu Utilities • BASIC" --checklist "Pilih komponen:" 22 110 14 \
      FLATPAK_SETUP "Flatpak + gnome-software-plugin-flatpak + Flathub remote"       ON  \
      TWEAKS        "GNOME Tweaks"                                                   ON  \
      FLAMESHOT     "Flameshot (screenshot)"                                         ON  \
      COPYQ         "CopyQ (clipboard manager)"                                      ON  \
      GPARTED       "GParted (manajer partisi)"                                      ON  \
      BAOBAB        "Disk Usage Analyzer (baobab)"                                   ON  \
      PDF_TOOLS     "pdfarranger, ocrmypdf, poppler-utils"                           ON  \
      ARCHIVER      "file-roller (GUI arsip)"                                        ON  \
      3>&1 1>&2 2>&3) || { echo ""; return; }
    echo "$out" | tr -d '"'
  else
    echo "${CHOICES:-FLATPAK_SETUP TWEAKS FLAMESHOT COPYQ GPARTED BAOBAB PDF_TOOLS ARCHIVER}"
  fi
}

install_FLATPAK_SETUP() {
  apt_install flatpak
  apt_install gnome-software-plugin-flatpak
  # Tambah Flathub remote (idempotent)
  if command -v flatpak >/dev/null 2>&1; then
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo >>"$LOG" 2>&1 || true
    ok "Flathub remote diverifikasi/ditambahkan"
  fi
}
install_TWEAKS()      { apt_install gnome-tweaks; }
install_FLAMESHOT()   { apt_install flameshot; }
install_COPYQ()       { apt_install copyq; }
install_GPARTED()     { apt_install gparted; }
install_BAOBAB()      { apt_install baobab; }
install_PDF_TOOLS()   { apt_install pdfarranger || true; apt_install ocrmypdf || true; apt_install poppler-utils || true; }
install_ARCHIVER()    { apt_install file-roller || true; }

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
