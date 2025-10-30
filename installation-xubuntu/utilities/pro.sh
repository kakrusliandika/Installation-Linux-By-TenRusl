#!/usr/bin/env bash
# Ubuntu Utilities • PRO (22.04/24.04)
# Komponen: TLP, PowerTOP, Timeshift, AppImageLauncher (.deb/apt), Ulauncher (.deb), BleachBit (.deb/apt), zram-tools.
# Contoh non-interaktif:
#   CHOICES="TLP POWERTOP TIMESHIFT APPIMAGELAUNCHER ULAUNCHER BLEACHBIT ZRAM_TOOLS" ./pro.sh
#   APPIMAGELAUNCHER_DEB_URL="https://github.com/TheAssassin/AppImageLauncher/releases/download/v2.2.0/appimagelauncher_2.2.0-jammy_amd64.deb" CHOICES="APPIMAGELAUNCHER" ./pro.sh
#   ULAUNCHER_DEB_URL="https://github.com/Ulauncher/Ulauncher/releases/download/5.15.5/ulauncher_5.15.5_all.deb" CHOICES="ULAUNCHER" ./pro.sh
#   BLEACHBIT_DEB_URL="https://download.bleachbit.org/bleachbit_5.0.2_all_ubuntu2404.deb" CHOICES="BLEACHBIT" ./pro.sh

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
    out=$(whiptail --title "Ubuntu Utilities • PRO" --checklist "Pilih komponen:" 22 114 14 \
      TLP              "TLP (hemat baterai; default optimal)"                              ON  \
      POWERTOP         "PowerTOP (diagnostik & tuning power)"                              OFF \
      TIMESHIFT        "Timeshift (snapshot OS)"                                           OFF \
      APPIMAGELAUNCHER "AppImageLauncher (.deb via URL atau APT jika tersedia)"            OFF \
      ULAUNCHER        "Ulauncher (.deb via URL)"                                         OFF \
      BLEACHBIT        "BleachBit (APT atau .deb via URL)"                                OFF \
      ZRAM_TOOLS       "zram-tools (swap terkompresi)"                                    OFF \
      3>&1 1>&2 2>&3) || { echo ""; return; }
    echo "$out" | tr -d '"'
  else
    echo "${CHOICES:-TLP}"
  fi
}

install_TLP() { apt_install tlp; $SUDO systemctl enable --now tlp >>"$LOG" 2>&1 || true; }
install_POWERTOP() { apt_install powertop; }
install_TIMESHIFT() { apt_install timeshift || { warn "timeshift APT gagal"; FAILED+=("timeshift"); }; }

install_APPIMAGELAUNCHER() {
  if [ -n "${APPIMAGELAUNCHER_DEB_URL:-}" ]; then
    tmp="/tmp/appimagelauncher.deb"
    curl -fsSL "$APPIMAGELAUNCHER_DEB_URL" -o "$tmp" >>"$LOG" 2>&1 || { warn "unduh AppImageLauncher gagal"; FAILED+=("appimagelauncher"); return; }
    $SUDO dpkg -i "$tmp" >>"$LOG" 2>&1 || { warn "dpkg AppImageLauncher gagal"; $SUDO apt-get -f install -y >>"$LOG" 2>&1 || true; }
    ok "AppImageLauncher dari .deb terpasang"
  else
    apt_install appimagelauncher || { warn "AppImageLauncher APT tidak tersedia di rilis ini"; FAILED+=("appimagelauncher"); }
  fi
}

install_ULAUNCHER() {
  if [ -n "${ULAUNCHER_DEB_URL:-}" ]; then
    tmp="/tmp/ulauncher.deb"
    curl -fsSL "$ULAUNCHER_DEB_URL" -o "$tmp" >>"$LOG" 2>&1 || { warn "unduh Ulauncher gagal"; FAILED+=("ulauncher"); return; }
    $SUDO apt-get install -y ./"$tmp" >>"$LOG" 2>&1 || { warn "dpkg Ulauncher gagal"; FAILED+=("ulauncher"); return; }
    ok "Ulauncher dari .deb terpasang"
  else
    warn "ULAUNCHER_DEB_URL kosong; lewati"
    FAILED+=("ulauncher (URL kosong)")
  fi
}

install_BLEACHBIT() {
  if [ -n "${BLEACHBIT_DEB_URL:-}" ]; then
    tmp="/tmp/bleachbit.deb"
    curl -fsSL "$BLEACHBIT_DEB_URL" -o "$tmp" >>"$LOG" 2>&1 || { warn "unduh BleachBit gagal"; FAILED+=("bleachbit"); return; }
    $SUDO dpkg -i "$tmp" >>"$LOG" 2>&1 || { warn "dpkg BleachBit gagal"; $SUDO apt-get -f install -y >>"$LOG" 2>&1 || true; }
    ok "BleachBit dari .deb terpasang"
  else
    apt_install bleachbit || { warn "BleachBit APT mungkin versi lama"; }
  fi
}

install_ZRAM_TOOLS() { apt_install zram-tools; }

main() {
  log "📦 PRO mulai. Log: $LOG"
  local selected; selected="$(choose_menu)"
  [ -z "$selected" ] && { warn "Tidak ada pilihan. Keluar."; exit 0; }

  apt_update_once

  for item in $selected; do
    fn="install_${item}"
    if declare -f "$fn" >/dev/null 2>&1; then "$fn"; else warn "Lewati opsi tidak dikenal: $item"; fi
  done

  {
    echo "🎯 PRO selesai."
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
