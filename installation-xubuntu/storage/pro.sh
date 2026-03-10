#!/usr/bin/env bash
# Ubuntu Storage • PRO (22.04/24.04)
# Komponen: ZFS, mergerfs, SnapRAID, iSCSI target/initiator, GlusterFS, Ceph client, MinIO, S3 tools.
# Non-interaktif contoh:
#   MERGERFS_DEB_URL="https://github.com/trapexit/mergerfs/releases/download/2.36.0/mergerfs_2.36.0.ubuntu-jammy_amd64.deb" \
#   MINIO_TGZ_URL="https://dl.min.io/server/minio/release/linux-amd64/archive/minio_20241020.000000.0_linux_amd64.tgz" \
#   CHOICES="ZFS MERGERFS SNAPRAID ISCSI_TARGET MINIO_SERVER" ./pro.sh

set -u -o pipefail
export DEBIAN_FRONTEND=noninteractive
[ "$(id -u)" -eq 0 ] && SUDO="" || SUDO="sudo"

LOG="$HOME/storage-install.log"
SUMMARY="$HOME/storage-summary.txt"
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
    out=$(whiptail --title "Ubuntu Storage • PRO" --checklist "Pilih komponen:" 24 104 18 \
      ZFS              "OpenZFS utils (zfsutils-linux). Opsional DKMS."                           ON  \
      MERGERFS         "Union FS (APT atau .deb upstream via MERGERFS_DEB_URL)"                   OFF \
      SNAPRAID         "Parity untuk data (APT)"                                                   OFF \
      ISCSI_TARGET     "iSCSI Target (targetcli-fb)"                                               OFF \
      ISCSI_INITIATOR  "iSCSI Initiator (open-iscsi)"                                              OFF \
      GLUSTERFS_SERVER "GlusterFS server"                                                          OFF \
      GLUSTERFS_CLIENT "GlusterFS client"                                                          OFF \
      CEPH_CLIENT      "Ceph client (ceph-common)"                                                 OFF \
      MINIO_SERVER     "MinIO (S3-compatible) via tarball upstream (MINIO_TGZ_URL)"               OFF \
      S3_TOOLS         "awscli & s3cmd (CLI S3)"                                                   OFF \
      3>&1 1>&2 2>&3) || { echo ""; return; }
    echo "$out" | tr -d '"'
  else
    echo "${CHOICES:-ZFS}"
  fi
}

install_ZFS() {
  # Sesuai OpenZFS docs: Ubuntu menyertakan modul; util via zfsutils-linux.
  apt_install zfsutils-linux
  # Opsional untuk kernel khusus: zfs-dkms
  apt_install zfs-dkms || true
}

install_MERGERFS() {
  if [ -n "${MERGERFS_DEB_URL:-}" ]; then
    log "📦 mergerfs via .deb upstream: $MERGERFS_DEB_URL"
    tmp="/tmp/mergerfs.deb"
    curl -fsSL "$MERGERFS_DEB_URL" -o "$tmp" >>"$LOG" 2>&1 || { warn "unduh mergerfs gagal"; FAILED+=("mergerfs"); return; }
    $SUDO dpkg -i "$tmp" >>"$LOG" 2>&1 || { warn "dpkg mergerfs gagal"; FAILED+=("mergerfs"); return; }
    ok "mergerfs terpasang (upstream)"
  else
    apt_install mergerfs || { warn "mergerfs APT gagal"; FAILED+=("mergerfs"); }
  fi
}

install_SNAPRAID() { apt_install snapraid; }

install_ISCSI_TARGET() { apt_install targetcli-fb; }
install_ISCSI_INITIATOR() { apt_install open-iscsi; }

install_GLUSTERFS_SERVER() { apt_install glusterfs-server; }
install_GLUSTERFS_CLIENT() { apt_install glusterfs-client; }

install_CEPH_CLIENT() { apt_install ceph-common; }

install_MINIO_SERVER() {
  # Memasang minio dari tarball upstream; gunakan MINIO_TGZ_URL untuk kontrol versi.
  local url="${MINIO_TGZ_URL:-}"
  if [ -z "$url" ]; then
    warn "MINIO_TGZ_URL belum diset; lewati MinIO"
    FAILED+=("minio (URL kosong)")
    return
  fi
  tmpd="$(mktemp -d)"
  curl -fsSL "$url" -o "$tmpd/minio.tgz" >>"$LOG" 2>&1 || { warn "unduh MinIO gagal"; FAILED+=("minio"); return; }
  tar -xzf "$tmpd/minio.tgz" -C "$tmpd" >>"$LOG" 2>&1 || { warn "ekstrak MinIO gagal"; FAILED+=("minio"); return; }
  $SUDO install -m 0755 "$tmpd/minio" /usr/local/bin/minio >>"$LOG" 2>&1 || { warn "install bin MinIO gagal"; FAILED+=("minio"); return; }
  ok "MinIO terpasang (/usr/local/bin/minio)"
}

install_S3_TOOLS() { apt_install awscli || true; apt_install s3cmd || true; }

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
