#!/usr/bin/env bash
# Ubuntu Messaging • BASIC
# Mode: pilih aplikasi via checklist (whiptail) atau env CHOICES="telegram thunderbird ..."
# Diuji untuk Ubuntu 22.04/24.04. Best-effort; lanjut walau ada paket gagal.

set -u -o pipefail
export DEBIAN_FRONTEND=noninteractive
[ "$(id -u)" -eq 0 ] && SUDO="" || SUDO="sudo"

LOG="$HOME/messaging-install.log"
SUMMARY="$HOME/messaging-summary.txt"
FAILED=()
touch "$LOG"

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

choose_apps() {
  if [ -n "${CHOICES:-}" ]; then
    echo "$CHOICES"
    return
  fi
  ensure_whiptail
  if command -v whiptail >/dev/null 2>&1; then
    local out
    out=$(whiptail --title "Ubuntu Messaging • BASIC" --checklist "Pilih aplikasi untuk dipasang:" 20 76 10 \
      telegram    "Telegram Desktop (APT)"         OFF \
      thunderbird "Thunderbird (APT → Snap di 24.04)" OFF \
      pidgin      "Pidgin (multi-protocol)"        OFF \
      weechat     "WeeChat (IRC/TUI)"              OFF \
      3>&1 1>&2 2>&3) || { echo ""; return; }
    # whiptail mengembalikan item dalam tanda kutip
    echo "$out" | tr -d '"'
  else
    echo "${CHOICES:-telegram thunderbird}"
  fi
}

install_telegram()   { apt_install telegram-desktop; }
install_thunderbird(){ apt_install thunderbird; }  # 24.04 akan tarik Snap secara otomatis
install_pidgin()     { apt_install pidgin; }
install_weechat()    { apt_install weechat; }

main() {
  log "📦 BASIC installer mulai. Log: $LOG"
  local selected; selected="$(choose_apps)"
  [ -z "$selected" ] && { warn "Tidak ada pilihan. Keluar."; exit 0; }

  for item in $selected; do
    case "$item" in
      telegram)    install_telegram ;;
      thunderbird) install_thunderbird ;;
      pidgin)      install_pidgin ;;
      weechat)     install_weechat ;;
      *) warn "Lewati item tidak dikenal: $item" ;;
    esac
  done

  {
    echo "🎯 BASIC selesai."
    echo "Dipilih: $selected"
    if [ "${#FAILED[@]}" -gt 0 ]; then
      echo "⚠️  Gagal dipasang: ${FAILED[*]}"
    else
      echo "✅ Semua paket terpasang tanpa kegagalan yang terdeteksi."
    fi
  } >"$SUMMARY"

  echo -e "\n✅ Selesai. Ringkasan: $SUMMARY\n"
}
main "$@"
