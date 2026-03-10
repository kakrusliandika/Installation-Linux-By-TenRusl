#!/usr/bin/env bash
# Ubuntu Office • BASIC (22.04/24.04)
# Pilih-pasang komponen dari repo Ubuntu (stabil & ringan).
# Non-interaktif contoh:
#   CHOICES="LIBREOFFICE PDF_ARRANGER FONTS_MS DICTS_ID FONTS_NOTO_CJK" ./basic.sh

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
    out=$(whiptail --title "Ubuntu Office • BASIC" --checklist "Pilih komponen untuk dipasang:" 22 86 14 \
      LIBREOFFICE     "Suite LibreOffice (Writer/Calc/Impress)"           ON  \
      PDF_VIEWERS     "Evince/Okular (PDF viewers)"                        OFF \
      PDF_ARRANGER    "PDF Arranger (merge/split/rotate PDF)"              ON  \
      FONTS_MS        "Microsoft Core Fonts (EULA)"                        OFF \
      FONTS_NOTO      "Noto + emoji"                                       ON  \
      FONTS_NOTO_CJK  "Noto CJK (Cina/Jepang/Korea)"                       OFF \
      DICTS_ID        "hunspell-id + l10n LibreOffice (Indonesia)"         OFF \
      CONVERTERS      "unzip, p7zip-full, ghostscript, qpdf"               OFF \
      3>&1 1>&2 2>&3) || { echo ""; return; }
    echo "$out" | tr -d '"'
  else
    echo "${CHOICES:-LIBREOFFICE PDF_ARRANGER FONTS_NOTO}"
  fi
}

install_LIBREOFFICE()    { apt_install libreoffice; }
install_PDF_VIEWERS()    { apt_install evince; apt_install okular || true; }
install_PDF_ARRANGER()   { apt_install pdfarranger; }
install_FONTS_MS()       { apt_install ttf-mscorefonts-installer; }
install_FONTS_NOTO()     { apt_install fonts-noto; apt_install fonts-noto-color-emoji || true; }
install_FONTS_NOTO_CJK() { apt_install fonts-noto-cjk || apt_install fonts-noto-cjk-extra || true; }
install_DICTS_ID()       { apt_install hunspell-id || true; apt_install libreoffice-l10n-id || true; }
install_CONVERTERS()     { apt_install unzip; apt_install p7zip-full; apt_install ghostscript; apt_install qpdf; }

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
