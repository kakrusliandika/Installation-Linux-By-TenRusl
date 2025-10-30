#!/usr/bin/env bash
# Ubuntu Remote • BASIC (22.04/24.04)
# Pilih-pasang: OpenSSH, Mosh, AutoSSH, RDP client (Remmina/FreeRDP), RDP server (xRDP), VNC (TigerVNC).
# Non-interaktif contoh:
#   CHOICES="SSH_SERVER MOSH RDP_CLIENT VNC_VIEWER" ./basic.sh

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

choose_menu() {
  if [ -n "${CHOICES:-}" ]; then echo "$CHOICES"; return; fi
  ensure_whiptail
  if command -v whiptail >/dev/null 2>&1; then
    local out
    out=$(whiptail --title "Ubuntu Remote • BASIC" --checklist "Pilih komponen untuk dipasang:" 22 92 14 \
      SSH_CLIENT   "OpenSSH client"                                            ON  \
      SSH_SERVER   "OpenSSH server (sshd)"                                     OFF \
      MOSH         "Mosh (shell tahan roaming/putus-sambung, UDP 60000–61000)" OFF \
      AUTOSSH      "AutoSSH (monitor & auto-restart SSH tunnel)"               OFF \
      RDP_CLIENT   "Remmina + FreeRDP (klien RDP)"                             ON  \
      RDP_SERVER   "xRDP (server RDP)"                                         OFF \
      VNC_SERVER   "TigerVNC server"                                           OFF \
      VNC_VIEWER   "TigerVNC viewer"                                           OFF \
      3>&1 1>&2 2>&3) || { echo ""; return; }
    echo "$out" | tr -d '"'
  else
    echo "${CHOICES:-SSH_CLIENT RDP_CLIENT}"
  fi
}

install_SSH_CLIENT() { apt_install openssh-client; }
install_SSH_SERVER() { apt_install openssh-server; $SUDO systemctl enable --now ssh >/dev/null 2>&1 || true; }
install_MOSH()       { apt_install mosh; }
install_AUTOSSH()    { apt_install autossh; }
install_RDP_CLIENT() { apt_install remmina; apt_install remmina-plugin-rdp || true; apt_install freerdp2-x11 || true; }
install_RDP_SERVER() { apt_install xrdp; $SUDO systemctl enable --now xrdp >/dev/null 2>&1 || true; }
install_VNC_SERVER() { apt_install tigervnc-standalone-server; }
install_VNC_VIEWER() { apt_install tigervnc-viewer; }

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
