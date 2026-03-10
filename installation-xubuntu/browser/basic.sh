# Ubuntu Browser (Basic) — selective installer
# Opsi: Chrome (repo resmi), Firefox (Snap), Chromium (Snap), Brave (repo resmi), Opera (Snap)
# Ubuntu 22.04 / 24.04
set -euo pipefail

SUDO="$(command -v sudo >/dev/null 2>&1 && echo sudo || echo "")"
LOG="${LOG:-$HOME/ubuntu-browser-basic.log}"
export DEBIAN_FRONTEND=noninteractive
FAILED=()

log()  { printf "[*] %s\n" "$*" | tee -a "$LOG"; }
ok()   { printf "[✓] %s\n" "$*" | tee -a "$LOG"; }
warn() { printf "[!] %s\n" "$*" | tee -a "$LOG"; }

apt_update_once() { $SUDO apt-get update -y >>"$LOG" 2>&1 || true; }
apt_install() {
  local p
  for p in "$@"; do
    if dpkg -s "$p" >/dev/null 2>&1; then ok "already: $p"; else
      if ! $SUDO apt-get install -y "$p" >>"$LOG" 2>&1; then
        warn "install failed: $p"; FAILED+=("$p")
      else ok "installed: $p"; fi
    fi
  done
}


ensure_whiptail() { command -v whiptail >/dev/null 2>&1 || apt_install whiptail dialog || true; }
ensure_snap()     { command -v snap >/dev/null 2>&1 || apt_install snapd || true; }

select_menu() {
  if [ -n "${SELECT:-}" ]; then echo "$SELECT"; return 0; fi
  if command -v whiptail >/dev/null 2>&1; then
    whiptail --title "Ubuntu Browser (Basic)" --checklist \
      "Pilih komponen (Spasi=toggle, Tab=Next, Enter=OK)" \
      20 86 10 \
      CHROME          "Google Chrome (paket .deb resmi, menambah repo otomatis)" ON \
      FIREFOX_SNAP    "Firefox (Snap resmi oleh Mozilla)"                         ON \
      CHROMIUM_SNAP   "Chromium (Snap)"                                          OFF \
      BRAVE           "Brave (APT repo resmi Brave)"                             ON \
      OPERA_SNAP      "Opera (Snap)"                                             OFF \
      3>&1 1>&2 2>&3 || true
  else
    echo "CHROME FIREFOX_SNAP BRAVE"
  fi
}

install_chrome() {
  # Cara resmi: pasang .deb → repo Google otomatis terset
  local deb=/tmp/google-chrome-stable_current_amd64.deb
  curl -fsSLo "$deb" https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
  # gunakan 'apt install ./file.deb' agar dependensi otomatis
  if $SUDO apt-get install -y "$deb" >>"$LOG" 2>&1; then
    ok "installed: google-chrome-stable"
  else
    warn "failed: google-chrome-stable"; FAILED+=("google-chrome-stable")
  fi
}

install_firefox_snap()   { ensure_snap; $SUDO snap install firefox   >>"$LOG" 2>&1 && ok "installed: firefox (snap)"   || { warn "failed: firefox (snap)";   FAILED+=("firefox-snap");   }; }
install_chromium_snap()  { ensure_snap; $SUDO snap install chromium  >>"$LOG" 2>&1 && ok "installed: chromium (snap)"  || { warn "failed: chromium (snap)";  FAILED+=("chromium-snap");  }; }
install_opera_snap()     { ensure_snap; $SUDO snap install opera     >>"$LOG" 2>&1 && ok "installed: opera (snap)"     || { warn "failed: opera (snap)";     FAILED+=("opera-snap");     }; }

install_brave() {
  # Instruksi resmi Brave: keyring + .sources
  apt_install curl
  $SUDO curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
  $SUDO curl -fsSLo /etc/apt/sources.list.d/brave-browser-release.sources https://brave-browser-apt-release.s3.brave.com/brave-browser.sources
  apt_update_once
  apt_install brave-browser
}

summary() {
  echo
  echo "===== SUMMARY (browser basic) ====="
  if [ "${#FAILED[@]}" -gt 0 ]; then
    echo "Gagal/terlewat: ${FAILED[*]}"
  else
    echo "Selesai tanpa kegagalan."
  fi
  echo "Log: $LOG"
}

: >"$LOG"
log "Ubuntu Browser Basic (selective)"
ensure_whiptail
SEL="$(select_menu)"; log "Selected: $SEL"

[[ "$SEL" == *CHROME* ]]         && install_chrome
[[ "$SEL" == *FIREFOX_SNAP* ]]   && install_firefox_snap
[[ "$SEL" == *CHROMIUM_SNAP* ]]  && install_chromium_snap
[[ "$SEL" == *BRAVE* ]]          && install_brave
[[ "$SEL" == *OPERA_SNAP* ]]     && install_opera_snap

summary
