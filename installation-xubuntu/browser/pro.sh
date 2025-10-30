# Ubuntu Browser (Pro) — selective installer
# Opsi: Edge (APT), Vivaldi (repo resmi), Brave Beta (APT), Ungoogled Chromium (Flatpak)
# Ubuntu 22.04 / 24.04
set -euo pipefail

SUDO="$(command -v sudo >/dev/null 2>&1 && echo sudo || echo "")"
LOG="${LOG:-$HOME/ubuntu-browser-pro.log}"
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

ensure_flatpak() {
  if ! command -v flatpak >/dev/null 2>&1; then apt_install flatpak; fi
  if ! flatpak remote-list --columns=name | grep -qx flathub; then
    $SUDO flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo >>"$LOG" 2>&1 || true
  fi
}

version_id() { . /etc/os-release; echo "${VERSION_ID:-24.04}"; }

menu() {
  if [ -n "${SELECT:-}" ]; then echo "$SELECT"; return 0; fi
  if command -v whiptail >/dev/null 2>&1; then
    whiptail --title "Ubuntu Browser (Pro)" --checklist \
      "Pilih komponen (Spasi=toggle, Tab=Next, Enter=OK)" \
      22 92 12 \
      EDGE            "Microsoft Edge (APT resmi Microsoft)"             ON \
      VIVALDI         "Vivaldi (repo resmi Vivaldi, signed-by)"          ON \
      BRAVE_BETA      "Brave Beta (APT channel beta)"                    OFF \
      UNGOOGLED_FLAT  "Ungoogled Chromium (Flatpak/Flathub)"             OFF \
      3>&1 1>&2 2>&3 || true
  else
    echo "EDGE VIVALDI"
  fi
}

install_edge() {
  local vid; vid="$(version_id)"
  curl -fsSLo /tmp/packages-microsoft-prod.deb "https://packages.microsoft.com/config/ubuntu/${vid}/packages-microsoft-prod.deb"
  $SUDO dpkg -i /tmp/packages-microsoft-prod.deb >>"$LOG" 2>&1 || true
  apt_update_once
  apt_install microsoft-edge-stable
}

install_vivaldi() {
  # Setup repo via signed-by (lebih stabil untuk otomasi headless)
  curl -fsSL https://repo.vivaldi.com/archive/linux_signing_key.pub | gpg --dearmor | $SUDO tee /usr/share/keyrings/vivaldi-archive-keyring.gpg >/dev/null
  echo "deb [signed-by=/usr/share/keyrings/vivaldi-archive-keyring.gpg] https://repo.vivaldi.com/archive/deb/ stable main" | \
    $SUDO tee /etc/apt/sources.list.d/vivaldi.list >/dev/null
  apt_update_once
  apt_install vivaldi-stable
}

install_brave_beta() {
  $SUDO curl -fsSLo /usr/share/keyrings/brave-browser-beta-archive-keyring.gpg https://brave-browser-apt-beta.s3.brave.com/brave-browser-beta-archive-keyring.gpg
  $SUDO curl -fsSLo /etc/apt/sources.list.d/brave-browser-beta.sources https://brave-browser-apt-beta.s3.brave.com/brave-browser.sources
  apt_update_once
  apt_install brave-browser-beta
}

install_ungoogled_flatpak() {
  ensure_flatpak
  $SUDO flatpak install -y flathub io.github.ungoogled_software.ungoogled_chromium >>"$LOG" 2>&1 && ok "installed: Ungoogled Chromium (flatpak)" || { warn "failed: Ungoogled Chromium (flatpak)"; FAILED+=("ungoogled-chromium"); }
}

summary() {
  echo
  echo "===== SUMMARY (browser pro) ====="
  if [ "${#FAILED[@]}" -gt 0 ]; then
    echo "Gagal/terlewat: ${FAILED[*]}"
  else
    echo "Selesai tanpa kegagalan."
  fi
  echo "Log: $LOG"
}

: >"$LOG"
log "Ubuntu Browser Pro (selective)"
ensure_whiptail
SEL="$(menu)"; log "Selected: $SEL"

[[ "$SEL" == *EDGE* ]]           && install_edge
[[ "$SEL" == *VIVALDI* ]]        && install_vivaldi
[[ "$SEL" == *BRAVE_BETA* ]]     && install_brave_beta
[[ "$SEL" == *UNGOOGLED_FLAT* ]] && install_ungoogled_flatpak

summary
