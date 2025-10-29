#!/usr/bin/env bash
# Ubuntu Editor — BASIC (Ubuntu 22.04/24.04)
# Hanya memasang dari repo Ubuntu (stabil). Pilih-pasang via menu.
# Non-interaktif: CHOICES="VIM NEOVIM EMACS MICRO GEDIT KATE" ./basic.sh

set -u -o pipefail
[ "$(id -u)" -eq 0 ] && SUDO="" || SUDO="sudo"
LOGFILE="$HOME/editor-basic-install.log"
FAILED=()
mkdir -p "$(dirname "$LOGFILE")" && : >"$LOGFILE"

log()  { printf "🔧 %s\n" "$*" | tee -a "$LOGFILE"; }
ok()   { printf "✅ %s\n" "$*" | tee -a "$LOGFILE"; }
warn() { printf "⚠️  %s\n" "$*" | tee -a "$LOGFILE"; }

run() {
  local desc="$1"; shift
  printf "⏳ %s ...\n" "$desc" | tee -a "$LOGFILE"
  if ! "$@" >>"$LOGFILE" 2>&1; then
    warn "Gagal: $desc"; FAILED+=("$desc"); return 1
  fi
  ok "OK: $desc"
}

apt_install_one() {
  local pkg="$1"
  dpkg -s "$pkg" >/dev/null 2>&1 && { ok "APT: $pkg sudah ada"; return 0; }
  $SUDO apt-get install -y "$pkg" >>"$LOGFILE" 2>&1 || { warn "APT gagal: $pkg"; FAILED+=("apt $pkg"); return 1; }
  ok "APT: $pkg terpasang"
}

ensure_base() {
  run "apt-get update" $SUDO apt-get update -y
  apt_install_one dialog || true
  apt_install_one whiptail || true
}

pick_choices() {
  if [ -n "${CHOICES:-}" ]; then
    echo "$CHOICES"
    return 0
  fi

  local options=(
    VIM        "Vim (CLI editor klasik)"     OFF
    NEOVIM     "Neovim (CLI modern)"         OFF
    EMACS      "Emacs (GUI)"                 OFF
    EMACS_NOX  "Emacs (terminal only)"       OFF
    MICRO      "Micro (CLI simpel)"          OFF
    GEDIT      "Gedit (GNOME GUI)"           OFF
    KATE       "Kate (KDE GUI)"              OFF
  )
  local sel
  sel=$(whiptail --title "Ubuntu Editor — BASIC" \
        --checklist "Pilih editor yang ingin dipasang:" 18 78 10 "${options[@]}" \
        3>&1 1>&2 2>&3) || exit 1
  echo "$sel"
}

install_one() {
  case "$1" in
    VIM)        apt_install_one vim ;;
    NEOVIM)     apt_install_one neovim ;;
    EMACS)      apt_install_one emacs ;;
    EMACS_NOX)  apt_install_one emacs-nox ;;
    MICRO)      apt_install_one micro ;;     # tersedia di repo Ubuntu modern
    GEDIT)      apt_install_one gedit ;;
    KATE)       apt_install_one kate ;;
    *)          warn "Lewati: opsi tidak dikenal: $1" ;;
  esac
}

main() {
  ensure_base
  local CHOSEN; CHOSEN=$(pick_choices)
  log "Dipilih: $CHOSEN"

  # buang quote dari whiptail
  CHOSEN=$(echo "$CHOSEN" | tr -d '"')
  for c in $CHOSEN; do install_one "$c"; done

  echo
  echo "==============================================="
  echo "✅ Selesai BASIC. Log: $LOGFILE"
  if [ "${#FAILED[@]}" -gt 0 ]; then
    echo "⚠️  Komponen gagal: ${FAILED[*]}"
  else
    echo "🎉 Tidak ada kegagalan."
  fi
  echo "==============================================="
}
main "$@"
