#!/usr/bin/env bash
# Ubuntu Security • BASIC (22.04/24.04)
# Pilih-pasang: UFW/Gufw, Fail2ban, ClamAV, Lynis, rkhunter, chkrootkit, AppArmor tools,
# unattended-upgrades, needrestart (opsional).
# Contoh non-interaktif:
#   CHOICES="UFW GUFW FAIL2BAN CLAMAV LYNIS" ./basic.sh

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
    out=$(whiptail --title "Ubuntu Security • BASIC" --checklist "Pilih komponen untuk dipasang:" 22 92 14 \
      UFW               "Uncomplicated Firewall (host firewall)"                         ON  \
      GUFW              "GUI untuk UFW"                                                  OFF \
      FAIL2BAN          "Banned otomatis untuk brute-force dari log"                     ON  \
      CLAMAV            "Antivirus FOSS (clamav + freshclam; daemon opsional)"           ON  \
      LYNIS             "Audit & rekomendasi hardening"                                  ON  \
      RKHUNTER          "Pemeriksa indikasi rootkit"                                     OFF \
      CHKROOTKIT        "Pemeriksa indikasi rootkit (alternatif)"                        OFF \
      APPARMOR_TOOLS    "apparmor-utils + profiles-extra"                                OFF \
      UNATTENDED_UPGRADES "Update keamanan otomatis"                                     ON  \
      NEEDRESTART       "Info layanan yang perlu restart setelah update (opsional)"      OFF \
      3>&1 1>&2 2>&3) || { echo ""; return; }
    echo "$out" | tr -d '"'
  else
    echo "${CHOICES:-UFW FAIL2BAN CLAMAV LYNIS UNATTENDED_UPGRADES}"
  fi
}

install_UFW()                { apt_install ufw; }
install_GUFW()               { apt_install gufw || true; }
install_FAIL2BAN()           { apt_install fail2ban; $SUDO systemctl enable --now fail2ban >/dev/null 2>&1 || true; }
install_CLAMAV()             { apt_install clamav; apt_install clamav-freshclam || true; $SUDO systemctl enable --now clamav-freshclam >/dev/null 2>&1 || true; }
install_LYNIS()              { apt_install lynis; }
install_RKHUNTER()           { apt_install rkhunter; }
install_CHKROOTKIT()         { apt_install chkrootkit; }
install_APPARMOR_TOOLS()     { apt_install apparmor-utils; apt_install apparmor-profiles || true; apt_install apparmor-profiles-extra || true; }
install_UNATTENDED_UPGRADES(){ apt_install unattended-upgrades; }
install_NEEDRESTART()        { apt_install needrestart; }

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
