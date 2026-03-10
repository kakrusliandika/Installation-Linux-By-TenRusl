#!/usr/bin/env bash
# Ubuntu Office • PRO (22.04/24.04)
# Pilih-pasang: ONLYOFFICE (repo resmi), SoftMaker (repo resmi), WPS (.deb), Pandoc, TeX Live, PDF tools lanjut.
# Non-interaktif contoh:
#   CHOICES="ONLYOFFICE SOFTMAKER PANDOC TEXLIVE_FULL" ./pro.sh
#   WPS_DEB_URL="https://…/wps-office_amd64.deb" CHOICES="WPS_OFFICE" ./pro.sh

set -u -o pipefail
export DEBIAN_FRONTEND=noninteractive
[ "$(id -u)" -eq 0 ] && SUDO="" || SUDO="sudo"

LOG="$HOME/office-install.log"
SUMMARY="$HOME/office-summary.txt"
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
    out=$(whiptail --title "Ubuntu Office • PRO" --checklist "Pilih komponen untuk dipasang:" 22 94 14 \
      ONLYOFFICE    "ONLYOFFICE Desktop Editors (repo resmi APT)"          ON  \
      SOFTMAKER     "SoftMaker Office 2024 (repo resmi APT)"               OFF \
      WPS_OFFICE    "WPS Office (.deb resmi; set WPS_DEB_URL)"             OFF \
      PANDOC        "Pandoc (converter dokumen universal)"                 ON  \
      TEXLIVE_BASE  "TeX Live (base)"                                      OFF \
      TEXLIVE_FULL  "TeX Live Full (komplet; besar)"                       OFF \
      PDF_EXTRAS    "pdftk-java, pdfgrep, poppler-utils"                   OFF \
      3>&1 1>&2 2>&3) || { echo ""; return; }
    echo "$out" | tr -d '"'
  else
    echo "${CHOICES:-ONLYOFFICE PANDOC}"
  fi
}

# ---- ONLYOFFICE (repo resmi) ----
install_ONLYOFFICE() {
  log "🔑 Tambah repo ONLYOFFICE (APT)"
  $SUDO install -d -m 0755 /usr/share/keyrings >/dev/null 2>&1 || true
  gpg --no-default-keyring --keyring gnupg-ring:/tmp/onlyoffice.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys CB2DE8E5 >>"$LOG" 2>&1 \
    && chmod 644 /tmp/onlyoffice.gpg && $SUDO chown root:root /tmp/onlyoffice.gpg && $SUDO mv /tmp/onlyoffice.gpg /usr/share/keyrings/onlyoffice.gpg \
    || warn "Gagal impor key ONLYOFFICE (lanjut best-effort)"
  echo 'deb [signed-by=/usr/share/keyrings/onlyoffice.gpg] https://download.onlyoffice.com/repo/debian squeeze main' | \
    $SUDO tee /etc/apt/sources.list.d/onlyoffice.list >/dev/null
  apt_update_once
  apt_install onlyoffice-desktopeditors
}

# ---- SoftMaker Office (repo resmi) ----
install_SOFTMAKER() {
  log "🔑 Tambah repo SoftMaker (APT)"
  $SUDO install -d -m 0755 /etc/apt/keyrings >/dev/null 2>&1 || true
  curl -fsSL https://shop.softmaker.com/repo/linux-repo-public.key | gpg --dearmor | $SUDO tee /etc/apt/keyrings/softmaker.gpg >/dev/null
  echo 'deb [signed-by=/etc/apt/keyrings/softmaker.gpg] https://shop.softmaker.com/repo/apt stable non-free' | \
    $SUDO tee /etc/apt/sources.list.d/softmaker.list >/dev/null
  apt_update_once
  apt_install softmaker-office-2024
}

# ---- WPS Office (.deb) ----
install_WPS_OFFICE() {
  local url="${WPS_DEB_URL:-}"
  if [ -z "$url" ]; then warn "WPS_DEB_URL belum disetel. Ambil .deb resmi dari situs WPS Linux, lalu set WPS_DEB_URL='https://…/wps-office_amd64.deb'"; FAILED+=("wps-office"); return; fi
  log "⬇️  Unduh WPS .deb: $url"
  tmp="$(mktemp -d)"
  if curl -fL "$url" -o "$tmp/wps.deb" >>"$LOG" 2>&1; then
    if $SUDO apt-get install -y "$tmp/wps.deb" >>"$LOG" 2>&1; then ok "WPS Office terpasang"; else warn "Install WPS .deb gagal"; FAILED+=("wps-office"); fi
  else
    warn "Unduh WPS .deb gagal"; FAILED+=("wps-office")
  fi
}

# ---- Lainnya ----
install_PANDOC()       { apt_install pandoc; }
install_TEXLIVE_BASE() { apt_install texlive; }
install_TEXLIVE_FULL() { apt_install texlive-full; }
install_PDF_EXTRAS()   { apt_install pdftk-java; apt_install pdfgrep; apt_install poppler-utils; }

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
