#!/usr/bin/env bash
# Ubuntu Image — BASIC (22.04/24.04)
# Pilih-pasang editor & CLI image dari repo Ubuntu (stabil)
# Non-interaktif contoh:
#   CHOICES="VIEWERS GIMP INKSCAPE CLI_MAGICK CLI_WEBP CLI_EXIF HEIF_SUPPORT" ./basic.sh

set -u -o pipefail
export DEBIAN_FRONTEND=noninteractive

[ "$(id -u)" -eq 0 ] && SUDO="" || SUDO="sudo"
LOG="$HOME/image-basic-install.log"
FAILED=()
: >"$LOG"

log()  { printf "🔧 %s\n" "$*" | tee -a "$LOG"; }
ok()   { printf "✅ %s\n" "$*" | tee -a "$LOG"; }
warn() { printf "⚠️  %s\n" "$*" | tee -a "$LOG"; }
run()  { local d="$1"; shift; printf "⏳ %s ...\n" "$d" | tee -a "$LOG"; "$@" >>"$LOG" 2>&1 || { warn "Gagal: $d"; return 1; }; ok "OK: $d"; }

apt_install_one() {
  local pkg="$1"
  dpkg -s "$pkg" >/dev/null 2>&1 && { ok "APT: $pkg sudah terpasang"; return 0; }
  $SUDO apt-get install -y "$pkg" >>"$LOG" 2>&1 || { warn "APT gagal: $pkg"; FAILED+=("$pkg"); return 1; }
  ok "APT: $pkg terpasang"
}

ensure_base() {
  run "apt-get update" $SUDO apt-get update -y
  apt_install_one whiptail || true
  apt_install_one dialog || true
  apt_install_one ca-certificates || true
  apt_install_one curl || true
}

pick_menu() {
  if [ -n "${CHOICES:-}" ]; then echo "$CHOICES"; return 0; fi
  local sel
  sel=$(whiptail --title "Ubuntu Image — BASIC" --checklist "Pilih komponen untuk dipasang" 22 88 14 \
    VIEWERS     "gThumb + Eye of GNOME (viewer)"          ON  \
    GIMP        "GIMP (editor raster serbaguna)"          ON  \
    PINTA       "Pinta (ringan ala Paint.NET)"            OFF \
    KRITA       "Krita (painting)"                         OFF \
    INKSCAPE    "Inkscape (vektor/SVG)"                   ON  \
    CLI_MAGICK  "ImageMagick (konversi/komposisi CLI)"    ON  \
    CLI_WEBP    "WebP utils (cwebp/dwebp/img2webp)"       ON  \
    CLI_PNGQUANT "pngquant (optimasi PNG lossy)"          OFF \
    CLI_EXIF    "ExifTool + Exiv2 (metadata)"             ON  \
    HEIF_SUPPORT "libheif-examples (heif-convert HEIC/AVIF)" ON \
    FFMPEG      "FFmpeg (alat bantu codec/konversi)"      OFF \
    3>&1 1>&2 2>&3) || exit 1
  echo "$sel"
}

install_one() {
  case "$1" in
    VIEWERS)        apt_install_one gthumb; apt_install_one eog ;;
    GIMP)           apt_install_one gimp ;;
    PINTA)          apt_install_one pinta ;;
    KRITA)          apt_install_one krita ;;
    INKSCAPE)       apt_install_one inkscape ;;
    CLI_MAGICK)     apt_install_one imagemagick ;;
    CLI_WEBP)       apt_install_one webp ;;                         # cwebp/dwebp/img2webp
    CLI_PNGQUANT)   apt_install_one pngquant ;;
    CLI_EXIF)       apt_install_one libimage-exiftool-perl; apt_install_one exiv2 ;;
    HEIF_SUPPORT)   apt_install_one libheif-examples ;;             # heif-convert/heif-enc
    FFMPEG)         apt_install_one ffmpeg ;;
    *)              warn "Lewati opsi tidak dikenali: $1" ;;
  esac
}

main() {
  ensure_base
  local CHOSEN; CHOSEN="$(pick_menu)"
  CHOSEN=$(echo "$CHOSEN" | tr -d '"')
  log "Dipilih: $CHOSEN"
  for x in $CHOSEN; do install_one "$x"; done

  echo
  echo "====================================="
  echo "✅ Selesai BASIC. Log: $LOG"
  if [ "${#FAILED[@]}" -gt 0 ]; then
    echo "⚠️  Gagal: ${FAILED[*]}"
  else
    echo "🎉 Tidak ada kegagalan mayor."
  fi
  echo "🔍 Cek cepat: gimp --version | inkscape --version | convert -version | cwebp -version | exiftool -ver | heif-convert -h | ffmpeg -version"
  echo "====================================="
}
main "$@"
