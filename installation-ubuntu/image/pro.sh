#!/usr/bin/env bash
# Ubuntu Image — PRO (22.04/24.04)
# Pilih-pasang tool lanjutan: RAW, DAM, HDR, Scan+OCR, Color Mgmt, AI upscaler
# Non-interaktif contoh:
#   CHOICES="DARKTABLE RAWTHERAPEE DIGIKAM LUMINANCE_HDR SCAN_SIMPLE OCR_TESSERACT COLOR_DISPLAYCAL COLOR_ARGYLL AI_WAIFU2X" ./pro.sh

set -u -o pipefail
export DEBIAN_FRONTEND=noninteractive

[ "$(id -u)" -eq 0 ] && SUDO="" || SUDO="sudo"
LOG="$HOME/image-pro-install.log"
FAILED=()
: >"$LOG"

log()  { printf "🔧 %s\n" "$*" | tee -a "$LOG"; }
ok()   { printf "✅ %s\n" "$*" | tee -a "$LOG"; }
warn() { printf "⚠️  %s\n" "$*" | tee -a "$LOG"; }
run()  { local d="$1"; shift; printf "⏳ %s ...\n" "$d" | tee -a "$LOG"; "$@" >>"$LOG" 2>&1 || { warn "Gagal: $d"; return 1; }; ok "OK: $d"; }

apt_install_one(){ local pkg="$1"; dpkg -s "$pkg" >/dev/null 2>&1 && { ok "APT: $pkg sudah ada"; return 0; }; $SUDO apt-get install -y "$pkg" >>"$LOG" 2>&1 || { warn "APT gagal: $pkg"; FAILED+=("$pkg"); return 1; }; ok "APT: $pkg terpasang"; }

ensure_base(){
  run "apt-get update" $SUDO apt-get update -y
  apt_install_one whiptail || true
  apt_install_one dialog || true
  apt_install_one ca-certificates || true
  apt_install_one curl || true
}

ensure_snap(){ command -v snap >/dev/null 2>&1 || apt_install_one snapd; }
ensure_flatpak(){
  command -v flatpak >/dev/null 2>&1 || apt_install_one flatpak
  flatpak remotes | grep -q flathub || run "Tambah Flathub" flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
}

pick_menu(){
  if [ -n "${CHOICES:-}" ]; then echo "$CHOICES"; return 0; fi
  local sel
  sel=$(whiptail --title "Ubuntu Image — PRO" --checklist "Pilih komponen untuk dipasang" 24 96 16 \
    DARKTABLE        "RAW workflow & DAM"                              ON  \
    RAWTHERAPEE      "RAW developer alternatif"                        OFF \
    DIGIKAM          "Manajer foto (DAM)"                              OFF \
    LUMINANCE_HDR    "HDR workflow (Luminance HDR)"                    OFF \
    SCAN_SIMPLE      "Simple-Scan + sane-airscan (driver eSCL/WSD)"    ON  \
    SCAN_GSCAN2PDF   "gscan2pdf (scan → PDF/DjVu + OCR)"               OFF \
    OCR_TESSERACT    "Tesseract OCR + eng + ind"                       ON  \
    COLOR_DISPLAYCAL "DisplayCAL (Flatpak Flathub)"                    OFF \
    COLOR_ARGYLL     "ArgyllCMS (profiling ICC)"                       OFF \
    AI_WAIFU2X       "waifu2x-ncnn-vulkan (Snap)"                      OFF \
    AI_UPSCALER_REALESRGAN "UpScaler (Real-ESRGAN frontend; Snap)"     OFF \
    CLI_OPTIMIZERS   "jpegoptim + optipng (optimasi)"                  OFF \
    FFMPEG           "FFmpeg (bantuan codec/konversi)"                 OFF \
    3>&1 1>&2 2>&3) || exit 1
  echo "$sel"
}

# ---- komponen ----
inst_darktable()       { apt_install_one darktable; }
inst_rawtherapee()     { apt_install_one rawtherapee; }
inst_digikam()         { apt_install_one digikam; }
inst_luminance_hdr()   { apt_install_one luminance-hdr; }

inst_scan_simple()     { apt_install_one simple-scan; apt_install_one sane-airscan; }
inst_scan_gscan2pdf()  { apt_install_one gscan2pdf; }

inst_ocr_tesseract()   { apt_install_one tesseract-ocr; apt_install_one tesseract-ocr-eng; apt_install_one tesseract-ocr-ind; }

inst_displaycal()      { ensure_flatpak; run "Flatpak DisplayCAL" flatpak install -y flathub net.displaycal.DisplayCAL || true; }
inst_argyll()          { apt_install_one argyll; }

inst_waifu2x()         { ensure_snap; run "Snap waifu2x-ncnn-vulkan" $SUDO snap install waifu2x-ncnn-vulkan || $SUDO snap install waifu2x-ncnn-vulkan --beta || true; }
inst_upscaler()        { ensure_snap; run "Snap UpScaler (Real-ESRGAN frontend)" $SUDO snap install upscaler || true; }

inst_cli_optim()       { apt_install_one jpegoptim; apt_install_one optipng; }
inst_ffmpeg()          { apt_install_one ffmpeg; }

install_one(){
  case "$1" in
    DARKTABLE)              inst_darktable ;;
    RAWTHERAPEE)            inst_rawtherapee ;;
    DIGIKAM)                inst_digikam ;;
    LUMINANCE_HDR)          inst_luminance_hdr ;;
    SCAN_SIMPLE)            inst_scan_simple ;;
    SCAN_GSCAN2PDF)         inst_scan_gscan2pdf ;;
    OCR_TESSERACT)          inst_ocr_tesseract ;;
    COLOR_DISPLAYCAL)       inst_displaycal ;;
    COLOR_ARGYLL)           inst_argyll ;;
    AI_WAIFU2X)             inst_waifu2x ;;
    AI_UPSCALER_REALESRGAN) inst_upscaler ;;
    CLI_OPTIMIZERS)         inst_cli_optim ;;
    FFMPEG)                 inst_ffmpeg ;;
    *)                      warn "Lewati opsi tidak dikenali: $1" ;;
  esac
}

main(){
  ensure_base
  local CHOSEN; CHOSEN="$(pick_menu)"
  CHOSEN=$(echo "$CHOSEN" | tr -d '"')
  log "Dipilih: $CHOSEN"
  $SUDO apt-get update -y >>"$LOG" 2>&1 || true
  for x in $CHOSEN; do install_one "$x"; done

  echo
  echo "====================================="
  echo "✅ Selesai PRO. Log: $LOG"
  if [ "${#FAILED[@]}" -gt 0 ]; then
    echo "⚠️  Gagal: ${FAILED[*]}"
  else
    echo "🎉 Tidak ada kegagalan mayor."
  fi
  echo "🔍 Cek cepat: darktable --version | rawtherapee-cli -v | digikam --version | luminance-hdr --version | tesseract --list-langs | colprof -V | waifu2x-ncnn-vulkan -h | upscaler -h"
  echo "====================================="
}
main "$@"
