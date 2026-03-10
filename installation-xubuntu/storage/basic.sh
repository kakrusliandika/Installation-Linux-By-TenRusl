#!/usr/bin/env bash
# Ubuntu Storage • BASIC (22.04/24.04)
# Komponen: filesystem tools, LVM2, mdadm, cryptsetup (LUKS), Samba/NFS/SSHFS,
# backup (restic/borg), rclone, smartmontools/nvme-cli/hdparm, kompresi.
# Contoh non-interaktif:
#   CHOICES="FILESYSTEM_TOOLS LVM2 MDADM CRYPTSETUP SAMBA_SERVER NFS_SERVER RESTIC SMARTMONTOOLS" ./basic.sh

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
    out=$(whiptail --title "Ubuntu Storage • BASIC" --checklist "Pilih komponen:" 24 100 18 \
      FILESYSTEM_TOOLS "mkfs/fsck & partisi (xfs, btrfs, exfat, ntfs, ext*, parted, gdisk)" ON  \
      LVM2            "Logical Volume Manager (lvm2)"                                     ON  \
      MDADM           "Software RAID (mdadm)"                                             ON  \
      CRYPTSETUP      "Enkripsi LUKS/dm-crypt (cryptsetup)"                               ON  \
      SAMBA_SERVER    "Samba server (samba)"                                              OFF \
      SAMBA_CLIENT    "Klien CIFS/SMB (cifs-utils, smbclient)"                            ON  \
      NFS_SERVER      "NFS server (nfs-kernel-server)"                                    OFF \
      NFS_CLIENT      "NFS client (nfs-common)"                                           ON  \
      SSHFS           "Mount via SSH (sshfs)"                                            ON  \
      RESTIC          "Backup modern (restic)"                                            ON  \
      BORGBACKUP      "Backup deduplikasi (borgbackup)"                                   OFF \
      RCLONE          "Sinkronisasi Cloud/S3 (rclone)"                                    ON  \
      SMARTMONTOOLS   "SMART health HDD/SSD (smartmontools)"                              ON  \
      NVME_CLI        "NVMe CLI tools (nvme-cli)"                                         ON  \
      HDPARM          "ATA/SATA tuning (hdparm)"                                          OFF \
      COMPRESSION_TOOLS "zstd, pigz, p7zip-full"                                          ON  \
      3>&1 1>&2 2>&3) || { echo ""; return; }
    echo "$out" | tr -d '"'
  else
    echo "${CHOICES:-FILESYSTEM_TOOLS LVM2 MDADM CRYPTSETUP SAMBA_CLIENT NFS_CLIENT SSHFS RESTIC RCLONE SMARTMONTOOLS NVME_CLI COMPRESSION_TOOLS}"
  fi
}

# --- Implementasi tiap komponen ---
install_FILESYSTEM_TOOLS() {
  for p in xfsprogs btrfs-progs exfatprogs ntfs-3g dosfstools e2fsprogs parted gdisk util-linux; do
    apt_install "$p" || true
  done
}
install_LVM2()            { apt_install lvm2; }
install_MDADM()           { apt_install mdadm; }
install_CRYPTSETUP()      { apt_install cryptsetup; }
install_SAMBA_SERVER()    { apt_install samba; }
install_SAMBA_CLIENT()    { apt_install cifs-utils; apt_install smbclient || true; }
install_NFS_SERVER()      { apt_install nfs-kernel-server; }
install_NFS_CLIENT()      { apt_install nfs-common; }
install_SSHFS()           { apt_install sshfs; }
install_RESTIC()          { apt_install restic || true; }
install_BORGBACKUP()      { apt_install borgbackup || true; }
install_RCLONE()          { apt_install rclone || true; }
install_SMARTMONTOOLS()   { apt_install smartmontools; }
install_NVME_CLI()        { apt_install nvme-cli || true; }
install_HDPARM()          { apt_install hdparm || true; }
install_COMPRESSION_TOOLS(){ apt_install zstd || true; apt_install pigz || true; apt_install p7zip-full || true; }

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
