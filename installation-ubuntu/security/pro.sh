#!/usr/bin/env bash
# Ubuntu Security • PRO (22.04/24.04)
# Pilih-pasang: osquery, CrowdSec, Falco, AIDE, auditd (+ dependensi seperlunya).
# Contoh non-interaktif:
#   CHOICES="OSQUERY CROWDSEC FALCO AIDE AUDITD" ./pro.sh
#   CROWDSEC_METHOD=repo CHOICES="CROWDSEC" ./pro.sh

set -u -o pipefail
export DEBIAN_FRONTEND=noninteractive
[ "$(id -u)" -eq 0 ] && SUDO="" || SUDO="sudo"

LOG="$HOME/security-install.log"
SUMMARY="$HOME/security-summary.txt"
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
    out=$(whiptail --title "Ubuntu Security • PRO" --checklist "Pilih komponen untuk dipasang:" 22 96 14 \
      OSQUERY     "Telemetry & query OS (SQL-like)"                      ON  \
      CROWDSEC    "CrowdSec (repo resmi / script installer)"             OFF \
      FALCO       "Falco runtime security (DEB repo falcosecurity)"      OFF \
      AIDE        "File integrity monitoring"                             ON  \
      AUDITD      "Linux auditing (syscalls/policy)"                      ON  \
      3>&1 1>&2 2>&3) || { echo ""; return; }
    echo "$out" | tr -d '"'
  else
    echo "${CHOICES:-OSQUERY AIDE AUDITD}"
  fi
}

install_OSQUERY() {
  # Coba paket distro; jika tidak tersedia, tandai gagal (user bisa tambah repo resmi sesuai dok).
  if ! apt_install osquery; then
    warn "osquery dari repo Ubuntu tidak tersedia/bermasalah. Lihat dokumentasi resmi untuk metode alternatif."
    FAILED+=("osquery")
  fi
}

install_CROWDSEC() {
  case "${CROWDSEC_METHOD:-quick}" in
    repo)
      log "🔑 Tambah repo CrowdSec (packagecloud)"
      curl -fsSL https://packagecloud.io/install/repositories/crowdsec/crowdsec/script.deb.sh | $SUDO bash >>"$LOG" 2>&1 || { warn "Gagal set repo CrowdSec"; FAILED+=("crowdsec"); return; }
      APT_UPDATED=""; apt_update_once
      apt_install crowdsec
      ;;
    quick|*)
      log "📜 CrowdSec via installer resmi cepat"
      if curl -s https://install.crowdsec.net | $SUDO sh >>"$LOG" 2>&1; then ok "CrowdSec terpasang"; else warn "CrowdSec installer gagal"; FAILED+=("crowdsec"); fi
      ;;
  esac
}

install_FALCO() {
  log "🔑 Tambah repo Falco (falcosecurity)"
  $SUDO install -d -m 0755 /usr/share/keyrings >/dev/null 2>&1 || true
  curl -fsSL https://falco.org/repo/falcosecurity-packages.asc | $SUDO gpg --dearmor -o /usr/share/keyrings/falco-archive-keyring.gpg >>"$LOG" 2>&1 || true
  echo "deb [signed-by=/usr/share/keyrings/falco-archive-keyring.gpg] https://download.falco.org/packages/deb stable main" | \
    $SUDO tee /etc/apt/sources.list.d/falcosecurity.list >/dev/null
  APT_UPDATED=""; apt_update_once
  # Header kernel kadang dibutuhkan untuk driver kmod
  apt_install "linux-headers-$(uname -r)" || true
  apt_install dialog || true
  apt_install falco
}

install_AIDE()   { apt_install aide; }
install_AUDITD() { apt_install auditd; $SUDO systemctl enable --now auditd >/dev/null 2>&1 || true; }

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
