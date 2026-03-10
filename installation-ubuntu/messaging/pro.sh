#!/usr/bin/env bash
# Ubuntu Messaging • PRO
# Pilihan populer/enterprise: Slack, Discord, Signal, Element, Zoom, Skype, Mattermost, Rocket.Chat, Viber, Teams PWA, WhatsApp PWA.
# Default memilih jalur yang paling terpelihara (repo resmi/Snap). Bisa override via env var (lihat README).

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
ensure_snapd() {
  if ! command -v snap >/dev/null 2>&1; then
    log "📦 Pasang snapd"
    apt_install snapd
    # di beberapa sistem perlu start & path baru setelah login
  fi
}
snap_install() {
  local name="$1" extra="${2:-}"
  ensure_snapd
  if snap list "$name" >/dev/null 2>&1; then ok "Snap: $name sudah ada"
  else
    if $SUDO snap install $name $extra >>"$LOG" 2>&1; then ok "Snap: $name terpasang"
    else warn "Snap gagal: $name"; FAILED+=("snap:$name"); fi
  fi
}

# ---------- APT repos ----------
install_signal_repo() {
  log "🔑 Tambah repo Signal (APT)"
  $SUDO install -d -m 0755 /etc/apt/keyrings >/dev/null 2>&1 || true
  curl -fsSL https://updates.signal.org/desktop/apt/keys.asc | gpg --dearmor | $SUDO tee /etc/apt/keyrings/signal-desktop-keyring.gpg >/dev/null
  echo 'deb [arch=amd64 signed-by=/etc/apt/keyrings/signal-desktop-keyring.gpg] https://updates.signal.org/desktop/apt xenial main' | $SUDO tee /etc/apt/sources.list.d/signal-xenial.list >/dev/null
  apt_update_once
}
install_element_repo() {
  log "🔑 Tambah repo Element (APT)"
  $SUDO wget -qO /usr/share/keyrings/element-io-archive-keyring.gpg https://packages.element.io/debian/element-io-archive-keyring.gpg
  echo 'deb [signed-by=/usr/share/keyrings/element-io-archive-keyring.gpg] https://packages.element.io/debian/ default main' | $SUDO tee /etc/apt/sources.list.d/element-io.list >/dev/null
  apt_update_once
}
install_skype_repo() {
  log "🔑 Tambah repo Skype (APT)"
  curl -fsSL https://repo.skype.com/data/SKYPE-GPG-KEY | gpg --dearmor | $SUDO tee /usr/share/keyrings/skype-stable.gpg >/dev/null
  echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/skype-stable.gpg] https://repo.skype.com/deb stable main' | $SUDO tee /etc/apt/sources.list.d/skype-stable.list >/dev/null
  apt_update_once
}
install_edge_repo() {
  log "🔑 Tambah repo Microsoft Edge (untuk PWA Teams)"
  curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | $SUDO tee /usr/share/keyrings/microsoft.gpg >/dev/null
  echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/edge stable main' | $SUDO tee /etc/apt/sources.list.d/microsoft-edge-stable.list >/dev/null
  apt_update_once
  apt_install microsoft-edge-stable
}

# ---------- Installers ----------
install_slack() {
  if [ "${USE_SNAP:-1}" = "1" ]; then
    log "🟣 Slack via Snap"
    snap_install slack --classic
  else
    local url="${SLACK_DEB_URL:-}"
    if [ -z "$url" ]; then warn "URL .deb Slack tidak disetel. Set USE_SNAP=1 atau SLACK_DEB_URL='https://...deb'"; FAILED+=("slack"); return; fi
    log "⬇️  Slack .deb ($url)"
    tmp=$(mktemp -d); curl -fL "$url" -o "$tmp/slack.deb" >>"$LOG" 2>&1 || { warn "Unduh Slack gagal"; FAILED+=("slack"); return; }
    if $SUDO apt-get install -y "$tmp/slack.deb" >>"$LOG" 2>&1; then ok "Slack terpasang"; else warn "Install Slack .deb gagal"; FAILED+=("slack"); fi
  fi
}
install_discord() {
  if [ "${USE_SNAP:-1}" = "1" ]; then
    log "🟣 Discord via Snap"
    snap_install discord
  else
    local url="${DISCORD_DEB_URL:-https://discord.com/api/download?platform=linux&format=deb}"
    log "⬇️  Discord .deb ($url)"
    tmp=$(mktemp -d); curl -fL "$url" -o "$tmp/discord.deb" >>"$LOG" 2>&1 || { warn "Unduh Discord gagal"; FAILED+=("discord"); return; }
    if $SUDO apt-get install -y "$tmp/discord.deb" >>"$LOG" 2>&1; then ok "Discord terpasang"; else warn "Install Discord .deb gagal"; FAILED+=("discord"); fi
  fi
}
install_signal()   { install_signal_repo; apt_install signal-desktop; }
install_element()  {
  case "${ELEMENT_FROM:-repo}" in
    repo)  install_element_repo; apt_install element-desktop ;;
    snap)  snap_install element-desktop ;;
    *)     warn "ELEMENT_FROM tidak dikenal (repo/snap)"; FAILED+=("element");;
  esac
}
install_zoom() {
  local url="${ZOOM_DEB_URL:-https://zoom.us/client/latest/zoom_amd64.deb}"
  log "⬇️  Zoom .deb ($url)"
  tmp=$(mktemp -d); curl -fL "$url" -o "$tmp/zoom.deb" >>"$LOG" 2>&1 || { warn "Unduh Zoom gagal"; FAILED+=("zoom"); return; }
  if $SUDO apt-get install -y "$tmp/zoom.deb" >>"$LOG" 2>&1; then ok "Zoom terpasang"; else warn "Install Zoom .deb gagal"; FAILED+=("zoom"); fi
}
install_skype()   { install_skype_repo; apt_install skypeforlinux; }
install_mattermost() {
  if [ -n "${MATTERMOST_DEB_URL:-}" ]; then
    log "⬇️  Mattermost .deb ($MATTERMOST_DEB_URL)"
    tmp=$(mktemp -d); curl -fL "$MATTERMOST_DEB_URL" -o "$tmp/mattermost.deb" >>"$LOG" 2>&1 || { warn "Unduh Mattermost gagal"; FAILED+=("mattermost"); return; }
    if $SUDO apt-get install -y "$tmp/mattermost.deb" >>"$LOG" 2>&1; then ok "Mattermost terpasang (.deb)"; else warn "Install Mattermost .deb gagal"; FAILED+=("mattermost"); fi
  else
    log "🟣 Mattermost via Snap (disarankan karena repo 24.04 kadang belum tersedia)"
    snap_install mattermost-desktop
  fi
}
install_rocketchat(){ snap_install rocketchat-desktop; }
install_viber() {
  local url="${VIBER_DEB_URL:-https://download.cdn.viber.com/cdn/desktop/Linux/viber.deb}"
  log "⬇️  Viber .deb ($url)"
  tmp=$(mktemp -d); curl -fL "$url" -o "$tmp/viber.deb" >>"$LOG" 2>&1 || { warn "Unduh Viber gagal"; FAILED+=("viber"); return; }
  if $SUDO apt-get install -y "$tmp/viber.deb" >>"$LOG" 2>&1; then ok "Viber terpasang"; else warn "Install Viber .deb gagal"; FAILED+=("viber"); fi
}

# ---------- PWA .desktop ----------
create_pwa_shortcut() { # name, url, bin
  local name="$1" url="$2" bin="$3"
  local desktop="$HOME/.local/share/applications/${name// /-}.desktop"
  mkdir -p "$(dirname "$desktop")"
  cat >"$desktop" <<EOF
[Desktop Entry]
Type=Application
Name=$name
Exec=$bin --app=$url --new-window
StartupWMClass=$name
Categories=Network;InstantMessaging;
EOF
  update-desktop-database "$HOME/.local/share/applications" >/dev/null 2>&1 || true
  ok "PWA shortcut dibuat: $desktop"
}

install_teams_pwa() {
  if command -v microsoft-edge >/dev/null 2>&1 || command -v microsoft-edge-stable >/dev/null 2>&1; then
    local edge="$(command -v microsoft-edge || command -v microsoft-edge-stable)"
    create_pwa_shortcut "Microsoft Teams (PWA)" "https://teams.microsoft.com" "$edge"
  elif command -v chromium >/dev/null 2>&1 || command -v chromium-browser >/dev/null 2>&1; then
    local chr="$(command -v chromium || command -v chromium-browser)"
    create_pwa_shortcut "Microsoft Teams (PWA)" "https://teams.microsoft.com" "$chr"
  else
    log "🌐 Pasang Edge untuk PWA Teams"
    install_edge_repo
    local edge="$(command -v microsoft-edge || command -v microsoft-edge-stable)"
    create_pwa_shortcut "Microsoft Teams (PWA)" "https://teams.microsoft.com" "$edge"
  fi
}
install_whatsapp_pwa() {
  local bin=""
  for c in google-chrome-stable google-chrome chromium chromium-browser microsoft-edge microsoft-edge-stable; do
    command -v "$c" >/dev/null 2>&1 && { bin="$(command -v "$c")"; break; }
  done
  if [ -z "$bin" ]; then
    log "🌐 Pasang Chromium untuk PWA WhatsApp"
    apt_install chromium-browser || apt_install chromium
    bin="$(command -v chromium || command -v chromium-browser)"
  fi
  create_pwa_shortcut "WhatsApp Web" "https://web.whatsapp.com" "$bin"
}

# ---------- UI ----------
ensure_whiptail() { apt_install whiptail >/dev/null 2>&1 || true; }
choose_apps() {
  if [ -n "${CHOICES:-}" ]; then echo "$CHOICES"; return; fi
  ensure_whiptail
  if command -v whiptail >/dev/null 2>&1; then
    local out
    out=$(whiptail --title "Ubuntu Messaging • PRO" --checklist "Pilih aplikasi untuk dipasang:" 22 84 14 \
      slack        "Slack (Snap / .deb manual)"          OFF \
      discord      "Discord (Snap / .deb)"               OFF \
      signal       "Signal Desktop (repo resmi)"         OFF \
      element      "Element (Matrix) (repo/Snap)"        OFF \
      zoom         "Zoom (deb resmi)"                    OFF \
      skype        "Skype (repo resmi)"                  OFF \
      mattermost   "Mattermost Desktop (Snap / .deb)"    OFF \
      rocketchat   "Rocket.Chat Desktop (Snap)"          OFF \
      viber        "Viber (deb resmi)"                   OFF \
      teams_pwa    "Microsoft Teams (PWA shortcut)"      OFF \
      whatsapp_pwa "WhatsApp (PWA shortcut)"             OFF \
      3>&1 1>&2 2>&3) || { echo ""; return; }
    echo "$out" | tr -d '"'
  else
    echo "${CHOICES:-signal element}"
  fi
}

main() {
  log "📦 PRO installer mulai. Log: $LOG"
  local selected; selected="$(choose_apps)"
  [ -z "$selected" ] && { warn "Tidak ada pilihan. Keluar."; exit 0; }

  for item in $selected; do
    case "$item" in
      slack)        install_slack ;;
      discord)      install_discord ;;
      signal)       install_signal ;;
      element)      install_element ;;
      zoom)         install_zoom ;;
      skype)        install_skype ;;
      mattermost)   install_mattermost ;;
      rocketchat)   install_rocketchat ;;
      viber)        install_viber ;;
      teams_pwa)    install_teams_pwa ;;
      whatsapp_pwa) install_whatsapp_pwa ;;
      *)            warn "Lewati item tidak dikenal: $item" ;;
    esac
  done

  {
    echo "🎯 PRO selesai."
    echo "Dipilih: $selected"
    if [ "${#FAILED[@]}" -gt 0 ]; then
      echo "⚠️  Gagal dipasang: ${FAILED[*]}"
    else
      echo "✅ Tidak ada kegagalan terdeteksi."
    fi
    echo "📄 Log: $LOG"
  } >"$SUMMARY"

  echo -e "\n✅ Selesai. Ringkasan: $SUMMARY\n"
}
main "$@"
