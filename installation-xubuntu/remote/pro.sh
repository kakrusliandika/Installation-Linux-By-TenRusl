#!/usr/bin/env bash
# Ubuntu Remote • PRO (22.04/24.04)
# Pilih-pasang: Tailscale (repo), ZeroTier (repo script/snap), WireGuard tools, OpenVPN,
# AnyDesk (repo), TeamViewer (.deb), RustDesk (.deb), NoMachine (.deb).
# Non-interaktif contoh:
#   CHOICES="TAILSCALE WIREGUARD OPENVPN ANYDESK" ./pro.sh
#   ZEROTIER_METHOD=snap CHOICES="ZEROTIER" ./pro.sh
#   TEAMVIEWER_DEB_URL="https://download.teamviewer.com/download/linux/teamviewer_amd64.deb" CHOICES="TEAMVIEWER" ./pro.sh

set -u -o pipefail
export DEBIAN_FRONTEND=noninteractive
[ "$(id -u)" -eq 0 ] && SUDO="" || SUDO="sudo"

LOG="$HOME/remote-install.log"
SUMMARY="$HOME/remote-summary.txt"
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

ensure_snapd() {
  if ! command -v snap >/dev/null 2>&1; then
    log "📦 Pasang snapd"
    apt_install snapd
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

choose_menu() {
  if [ -n "${CHOICES:-}" ]; then echo "$CHOICES"; return; fi
  ensure_whiptail
  if command -v whiptail >/dev/null 2>&1; then
    local out
    out=$(whiptail --title "Ubuntu Remote • PRO" --checklist "Pilih komponen untuk dipasang:" 22 92 14 \
      TAILSCALE   "Mesh VPN Tailscale (repo stable)"                 ON  \
      ZEROTIER    "Mesh VPN ZeroTier (script repo / SNAP)"           OFF \
      WIREGUARD   "WireGuard tools (wg, wg-quick)"                   ON  \
      OPENVPN     "OpenVPN client (easy-rsa opsional)"               OFF \
      ANYDESK     "AnyDesk (repo APT resmi)"                         OFF \
      TEAMVIEWER  "TeamViewer (.deb resmi; set TEAMVIEWER_DEB_URL)"  OFF \
      RUSTDESK    "RustDesk (.deb resmi; set RUSTDESK_DEB_URL)"      OFF \
      NOMACHINE   "NoMachine (.deb resmi; set NOMACHINE_DEB_URL)"    OFF \
      3>&1 1>&2 2>&3) || { echo ""; return; }
    echo "$out" | tr -d '"'
  else
    echo "${CHOICES:-TAILSCALE WIREGUARD}"
  fi
}

install_TAILSCALE() {
  log "🔑 Tambah repo Tailscale (stable)"
  $SUDO mkdir -p /usr/share/keyrings
  curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/jammy.noarmor.gpg | $SUDO tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
  # Noble/jammy: gunakan '$(. /etc/os-release && echo $VERSION_CODENAME)'
  codename="$(. /etc/os-release && echo "$VERSION_CODENAME")"
  echo "deb [signed-by=/usr/share/keyrings/tailscale-archive-keyring.gpg] https://pkgs.tailscale.com/stable/ubuntu/ ${codename} main" | \
    $SUDO tee /etc/apt/sources.list.d/tailscale.list >/dev/null
  APT_UPDATED=""; apt_update_once
  apt_install tailscale
  ok "Tailscale terpasang. Jalankan 'sudo tailscale up' untuk otentikasi."
}

install_ZEROTIER() {
  case "${ZEROTIER_METHOD:-repo_script}" in
    snap)
      log "🟣 ZeroTier via Snap"
      snap_install zerotier
      ;;
    repo_script|*)
      log "📜 ZeroTier via skrip resmi (menambahkan repo & paket)"
      if curl -s https://install.zerotier.com | $SUDO bash >>"$LOG" 2>&1; then ok "ZeroTier terpasang"; else warn "ZeroTier gagal"; FAILED+=("zerotier-one"); fi
      ;;
  esac
}

install_WIREGUARD() { apt_install wireguard-tools; }
install_OPENVPN()   { apt_install openvpn; apt_install easy-rsa || true; }

install_ANYDESK() {
  log "🔑 Tambah repo AnyDesk"
  $SUDO install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://keys.anydesk.com/repos/DEB-GPG-KEY -o /tmp/anydesk.key
  $SUDO install -m 0644 /tmp/anydesk.key /etc/apt/keyrings/keys.anydesk.com.asc
  echo "deb [signed-by=/etc/apt/keyrings/keys.anydesk.com.asc] https://deb.anydesk.com all main" | \
    $SUDO tee /etc/apt/sources.list.d/anydesk-stable.list >/dev/null
  APT_UPDATED=""; apt_update_once
  apt_install anydesk
}

install_TEAMVIEWER() {
  local url="${TEAMVIEWER_DEB_URL:-https://download.teamviewer.com/download/linux/teamviewer_amd64.deb}"
  log "⬇️  TeamViewer .deb ($url)"
  tmp="$(mktemp -d)"
  if curl -fL "$url" -o "$tmp/teamviewer.deb" >>"$LOG" 2>&1; then
    if $SUDO apt-get install -y "$tmp/teamviewer.deb" >>"$LOG" 2>&1; then ok "TeamViewer terpasang"; else warn "Install TeamViewer .deb gagal"; FAILED+=("teamviewer"); fi
  else
    warn "Unduh TeamViewer gagal"; FAILED+=("teamviewer")
  fi
}

install_RUSTDESK() {
  local url="${RUSTDESK_DEB_URL:-}"
  if [ -z "$url" ]; then warn "Set RUSTDESK_DEB_URL ke .deb resmi dari rustdesk.com"; FAILED+=("rustdesk"); return; fi
  log "⬇️  RustDesk .deb ($url)"
  tmp="$(mktemp -d)"
  if curl -fL "$url" -o "$tmp/rustdesk.deb" >>"$LOG" 2>&1; then
    if $SUDO apt-get install -y "$tmp/rustdesk.deb" >>"$LOG" 2>&1; then ok "RustDesk terpasang"; else warn "Install RustDesk .deb gagal"; FAILED+=("rustdesk"); fi
  else
    warn "Unduh RustDesk gagal"; FAILED+=("rustdesk")
  fi
}

install_NOMACHINE() {
  local url="${NOMACHINE_DEB_URL:-}"
  if [ -z "$url" ]; then warn "Set NOMACHINE_DEB_URL ke .deb resmi NoMachine"; FAILED+=("nomachine"); return; fi
  log "⬇️  NoMachine .deb ($url)"
  tmp="$(mktemp -d)"
  if curl -fL "$url" -o "$tmp/nomachine.deb" >>"$LOG" 2>&1; then
    if $SUDO apt-get install -y "$tmp/nomachine.deb" >>"$LOG" 2>&1; then ok "NoMachine terpasang"; else warn "Install NoMachine .deb gagal"; FAILED+=("nomachine"); fi
  else
    warn "Unduh NoMachine gagal"; FAILED+=("nomachine")
  fi
}

main() {
  log "📦 PRO mulai. Log: $LOG"
  local selected; selected="$(choose_menu)"
  [ -z "$selected" ] && { warn "Tidak ada pilihan. Keluar."; exit 0; }

  # update awal
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
