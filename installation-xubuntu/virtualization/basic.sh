#!/usr/bin/env bash
# Ubuntu Virtualization • BASIC (22.04/24.04)
# Komponen: KVM/QEMU + libvirt (daemon/CLI), virt-manager, virt-viewer,
# GNOME Boxes, Multipass (snap), VirtualBox (opsional), LXD (snap).
# Contoh non-interaktif:
#   CHOICES="KVM_CORE VIRT_MANAGER BOXES MULTIPASS VIRTUALBOX LXD" ./basic.sh

set -u -o pipefail
export DEBIAN_FRONTEND=noninteractive
[ "$(id -u)" -eq 0 ] && SUDO="" || SUDO="sudo"

LOG="$HOME/virt-install.log"
SUMMARY="$HOME/virt-summary.txt"
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
    out=$(whiptail --title "Ubuntu Virtualization • BASIC" --checklist "Pilih komponen:" 22 110 14 \
      KVM_CORE     "KVM/QEMU + libvirt (daemon/CLI), virt-viewer, group user"           ON  \
      VIRT_MANAGER "virt-manager (GUI KVM/libvirt)"                                     ON  \
      BOXES        "GNOME Boxes (front-end simple untuk libvirt)"                       OFF \
      MULTIPASS    "Multipass (snap) VM Ubuntu cepat"                                   OFF \
      VIRTUALBOX   "VirtualBox dari repo Ubuntu (ExtPack pasang manual)"                OFF \
      LXD          "LXD (snap) container/VM manager"                                    OFF \
      3>&1 1>&2 2>&3) || { echo ""; return; }
    echo "$out" | tr -d '"'
  else
    echo "${CHOICES:-KVM_CORE VIRT_MANAGER}"
  fi
}

install_KVM_CORE() {
  # Paket inti KVM/libvirt
  for p in qemu-kvm libvirt-daemon-system libvirt-clients virtinst virt-viewer; do
    apt_install "$p" || true
  done
  # Alat cek CPU virtualization (kvm-ok)
  apt_install cpu-checker || true
  # Enable & start libvirtd
  $SUDO systemctl enable --now libvirtd >>"$LOG" 2>&1 || true
  # Tambah user ke grup 'libvirt' dan 'kvm'
  $SUDO usermod -aG libvirt "$USER"   >>"$LOG" 2>&1 || true
  $SUDO usermod -aG kvm "$USER"       >>"$LOG" 2>&1 || true
  ok "User '$USER' ditambahkan ke grup libvirt & kvm (logout/login diperlukan)"
}

install_VIRT_MANAGER() { apt_install virt-manager; }
install_BOXES()        { apt_install gnome-boxes; }

install_MULTIPASS() {
  if command -v snap >/dev/null 2>&1; then
    $SUDO snap install multipass >>"$LOG" 2>&1 || { warn "snap multipass gagal"; FAILED+=("multipass"); }
  else
    warn "snapd tidak tersedia; lewati Multipass"
    FAILED+=("multipass (snapd tidak ada)")
  fi
}

install_VIRTUALBOX() {
  # Paket dari repo Ubuntu (stabil). Extension Pack → pasang manual (PUEL).
  apt_install virtualbox || { warn "VirtualBox gagal"; FAILED+=("virtualbox"); }
}

install_LXD() {
  if command -v snap >/dev/null 2>&1; then
    $SUDO snap install lxd >>"$LOG" 2>&1 || { warn "snap lxd gagal"; FAILED+=("lxd"); }
  else
    warn "snapd tidak tersedia; lewati LXD"
    FAILED+=("lxd (snapd tidak ada)")
  fi
}

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
    echo "🔁 Tips: Logout/login agar grup 'libvirt' & 'kvm' efektif."
  } >"$SUMMARY"

  echo -e "\n✅ Selesai. Ringkasan: $SUMMARY\n"
}
main "$@"
