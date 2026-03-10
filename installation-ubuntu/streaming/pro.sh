#!/usr/bin/env bash
# Ubuntu Streaming • PRO (22.04/24.04)
# Komponen: OBS Studio via PPA, Nginx + libnginx-mod-rtmp (opsional sampel),
# SRT tools, obs-ndi (DistroAV) + NDI Runtime (URL disediakan user).
# Contoh non-interaktif:
#   CHOICES="OBS_STUDIO_PPA NGINX_RTMP SRT_TOOLS" ./pro.sh
#   SETUP_RTMP_SAMPLE=1 CHOICES="NGINX_RTMP" ./pro.sh
#   OBS_NDI_DEB_URL="https://github.com/DistroAV/DistroAV/releases/download/v6.1.1/obs-ndi-6.1.1-linux-x86_64.deb" \
#   NDI_TGZ_URL="https://downloads.ndi.tv/SDK/NDI_SDK_Linux/Install_NDI_SDK_v6_Linux.tar.gz" \
#   CHOICES="OBS_NDI" ./pro.sh

set -u -o pipefail
export DEBIAN_FRONTEND=noninteractive
[ "$(id -u)" -eq 0 ] && SUDO="" || SUDO="sudo"

LOG="$HOME/streaming-install.log"
SUMMARY="$HOME/streaming-summary.txt"
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
    out=$(whiptail --title "Ubuntu Streaming • PRO" --checklist "Pilih komponen:" 22 110 14 \
      OBS_STUDIO_PPA "OBS Studio dari PPA obsproject (lebih baru)"                            ON  \
      NGINX_RTMP     "Nginx + libnginx-mod-rtmp (RTMP/HLS/DASH). SETUP_RTMP_SAMPLE=1 opsional" OFF \
      SRT_TOOLS      "Alat CLI SRT (srt-tools)"                                              OFF \
      OBS_NDI        "DistroAV (obs-ndi) + NDI Runtime (butuh URL resmi)"                    OFF \
      3>&1 1>&2 2>&3) || { echo ""; return; }
    echo "$out" | tr -d '"'
  else
    echo "${CHOICES:-OBS_STUDIO_PPA}"
  fi
}

install_OBS_STUDIO_PPA() {
  apt_install software-properties-common
  $SUDO add-apt-repository -y ppa:obsproject/obs-studio >>"$LOG" 2>&1 || { warn "add PPA OBS gagal"; FAILED+=("obs-ppa"); return; }
  APT_UPDATED=""
  apt_update_once
  apt_install obs-studio
}

install_NGINX_RTMP() {
  apt_install nginx
  apt_install libnginx-mod-rtmp
  if [ "${SETUP_RTMP_SAMPLE:-0}" = "1" ]; then
    # load module (dynamic) + contoh rtmp minimal
    $SUDO mkdir -p /etc/nginx/modules-enabled /etc/nginx/conf.d
    echo 'load_module /usr/lib/nginx/modules/ngx_rtmp_module.so;' | $SUDO tee /etc/nginx/modules-enabled/50-mod-rtmp.conf >/dev/null
    cat <<'RTMP' | $SUDO tee /etc/nginx/conf.d/rtmp.conf >/dev/null
rtmp {
  server {
    listen 1935;
    chunk_size 4096;
    application live {
      live on;
      # record off;
    }
  }
}
RTMP
    $SUDO nginx -t >>"$LOG" 2>&1 && $SUDO systemctl reload nginx || warn "uji/reload nginx gagal (cek config)"
    ok "RTMP sample ditulis ke /etc/nginx/conf.d/rtmp.conf"
  fi
}

install_SRT_TOOLS() { apt_install srt-tools; }

install_OBS_NDI() {
  local ndi_url="${NDI_TGZ_URL:-}"
  local obsndi_url="${OBS_NDI_DEB_URL:-}"
  if [ -z "$ndi_url" ] || [ -z "$obsndi_url" ]; then
    warn "OBS_NDI dilewati (NDI_TGZ_URL/OBS_NDI_DEB_URL kosong)"
    FAILED+=("obs-ndi (URL kosong)")
    return
  fi
  # Pasang NDI Runtime dari tarball resmi (berisi .deb libndi*)
  tmpd="$(mktemp -d)"
  curl -fsSL "$ndi_url" -o "$tmpd/ndi.tgz" >>"$LOG" 2>&1 || { warn "unduh NDI Runtime gagal"; FAILED+=("ndi-runtime"); return; }
  tar -xzf "$tmpd/ndi.tgz" -C "$tmpd" >>"$LOG" 2>&1 || { warn "ekstrak NDI Runtime gagal"; FAILED+=("ndi-runtime"); return; }
  mapfile -t debs < <(find "$tmpd" -type f -name "libndi*.deb" 2>/dev/null || true)
  if [ "${#debs[@]}" -eq 0 ]; then warn "paket libndi*.deb tidak ditemukan"; FAILED+=("ndi-runtime"); else
    for d in "${debs[@]}"; do $SUDO dpkg -i "$d" >>"$LOG" 2>&1 || warn "dpkg gagal: $(basename "$d")"; done
  fi
  # Pasang plugin obs-ndi (DistroAV)
  curl -fsSL "$obsndi_url" -o "$tmpd/obs-ndi.deb" >>"$LOG" 2>&1 || { warn "unduh obs-ndi gagal"; FAILED+=("obs-ndi"); return; }
  $SUDO dpkg -i "$tmpd/obs-ndi.deb" >>"$LOG" 2>&1 || { warn "dpkg obs-ndi gagal"; FAILED+=("obs-ndi"); return; }
  ok "obs-ndi (DistroAV) + NDI Runtime terpasang (best-effort)"
}

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
