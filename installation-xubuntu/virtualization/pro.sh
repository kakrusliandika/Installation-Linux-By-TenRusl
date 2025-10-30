#!/usr/bin/env bash
# Ubuntu Virtualization • PRO (22.04/24.04)
# Komponen: OVMF (UEFI), swtpm (TPM emulator), Cockpit + cockpit-machines (UI web KVM),
# Bridge Netplan (br0), cloud-image-utils (seed ISO), Vagrant + Packer (HashiCorp),
# nested KVM, serta alat tambahan (qemu-utils, virt-top, guestfs-tools, virtiofsd).
# Contoh non-interaktif:
#   BR_IFACE="enp3s0" BR_DHCP=1 HASHICORP_REPO=1 ENABLE_NESTED_KVM=1 \
#   CHOICES="OVMF SWTPM COCKPIT_KVM BRIDGE_NETPLAN CLOUD_IMAGE VAGRANT PACKER NESTED_KVM VM_TOOLS" ./pro.sh
#   # Plugin libvirt untuk Vagrant:
#   VAGRANT_LIBVIRT=1 CHOICES="VAGRANT" ./pro.sh

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
    out=$(whiptail --title "Ubuntu Virtualization • PRO" --checklist "Pilih komponen:" 22 124 14 \
      OVMF           "Firmware UEFI untuk KVM/QEMU (ovmf)"                                 ON  \
      SWTPM          "Software TPM emulator (swtpm, swtpm-tools)"                           ON  \
      COCKPIT_KVM    "cockpit + cockpit-machines (UI web KVM, port 9090)"                   OFF \
      BRIDGE_NETPLAN "Buat br0 via Netplan (pakai BR_IFACE / BR_DHCP=1)"                    OFF \
      CLOUD_IMAGE    "cloud-image-utils + genisoimage (seed ISO cloud-init)"                ON  \
      VAGRANT        "Vagrant (opsi repo HashiCorp); plugin libvirt (VAGRANT_LIBVIRT=1)"    OFF \
      PACKER         "Packer (opsi repo HashiCorp)"                                         OFF \
      NESTED_KVM     "Aktifkan nested virtualization (Intel/AMD) [reboot]"                  OFF \
      VM_TOOLS       "qemu-utils, virt-top, guestfs-tools, virtiofsd"                       ON  \
      3>&1 1>&2 2>&3) || { echo ""; return; }
    echo "$out" | tr -d '"'
  else
    echo "${CHOICES:-OVMF CLOUD_IMAGE VM_TOOLS}"
  fi
}

install_OVMF()      { apt_install ovmf; }
install_SWTPM()     { apt_install swtpm; apt_install swtpm-tools || true; }
install_COCKPIT_KVM() {
  apt_install cockpit
  apt_install cockpit-machines
  $SUDO systemctl enable --now cockpit >>"$LOG" 2>&1 || true
}
install_CLOUD_IMAGE() {
  apt_install cloud-image-utils
  apt_install genisoimage || true
}
install_VM_TOOLS()  { apt_install qemu-utils; apt_install virt-top || true; apt_install guestfs-tools || true; apt_install virtiofsd || true; }

install_VAGRANT() {
  if [ "${HASHICORP_REPO:-0}" = "1" ]; then
    # Tambah repo HashiCorp resmi (apt.releases.hashicorp.com)
    apt_install curl; apt_install gnupg; apt_install ca-certificates
    $SUDO install -d -m 0755 /usr/share/keyrings >>"$LOG" 2>&1 || true
    curl -fsSL https://apt.releases.hashicorp.com/gpg | $SUDO gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg >>"$LOG" 2>&1 || { warn "GPG key HashiCorp gagal"; FAILED+=("hashicorp-key"); }
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(. /etc/os-release && echo $VERSION_CODENAME) main" | \
      $SUDO tee /etc/apt/sources.list.d/hashicorp.list >/dev/null
    APT_UPDATED=""
  fi
  apt_update_once
  apt_install vagrant || { warn "vagrant gagal"; FAILED+=("vagrant"); }
  if [ "${VAGRANT_LIBVIRT:-0}" = "1" ] && command -v vagrant >/dev/null 2>&1; then
    vagrant plugin install vagrant-libvirt >>"$LOG" 2>&1 || { warn "plugin vagrant-libvirt gagal"; FAILED+=("vagrant-libvirt"); }
  fi
}

install_PACKER() {
  if [ "${HASHICORP_REPO:-0}" = "1" ]; then
    apt_install packer || { warn "packer gagal"; FAILED+=("packer"); }
  else
    warn "HASHICORP_REPO=1 tidak diset; lewati packer (opsional)"
    FAILED+=("packer (repo tidak diset)")
  fi
}

install_BRIDGE_NETPLAN() {
  local ifc="${BR_IFACE:-}"
  local dhcp="${BR_DHCP:-0}"
  local addr="${BR_ADDR:-}"
  local gw="${BR_GW:-}"
  local dns="${BR_DNS:-}"

  if [ -z "$ifc" ]; then
    warn "BR_IFACE kosong; contoh: BR_IFACE=enp3s0"
    FAILED+=("bridge (BR_IFACE kosong)")
    return
  fi

  $SUDO mkdir -p /etc/netplan
  local f="/etc/netplan/99-bridge.yaml"
  if [ "$dhcp" = "1" ]; then
    $SUDO tee "$f" >/dev/null <<YAML
network:
  version: 2
  renderer: networkd
  ethernets:
    $ifc: { dhcp4: no }
  bridges:
    br0:
      interfaces: [ $ifc ]
      dhcp4: true
      parameters:
        stp: true
      mtu: 1500
YAML
  else
    if [ -z "$addr" ] || [ -z "$gw" ]; then
      warn "BR_ADDR/BR_GW kosong; atau set BR_DHCP=1"
      FAILED+=("bridge (alamat/gateway kosong)")
      return
    fi
    $SUDO tee "$f" >/dev/null <<YAML
network:
  version: 2
  renderer: networkd
  ethernets:
    $ifc: { dhcp4: no }
  bridges:
    br0:
      interfaces: [ $ifc ]
      addresses: [ $addr ]
      routes: [ { to: default, via: $gw } ]
      nameservers:
        addresses: [ ${dns:-8.8.8.8,1.1.1.1} ]
      parameters:
        stp: true
      mtu: 1500
YAML
  fi
  ok "Netplan bridge ditulis: $f (jalankan: sudo netplan apply)"
}

install_NESTED_KVM() {
  local cpu; cpu="$(awk -F: '/vendor_id/ {print $2; exit}' /proc/cpuinfo | tr -d '[:space:]')"
  case "$cpu" in
    GenuineIntel)
      echo "options kvm-intel nested=1" | $SUDO tee /etc/modprobe.d/kvm-intel.conf >/dev/null
      ok "Nested KVM diaktifkan (Intel). Reboot diperlukan."
      ;;
    AuthenticAMD)
      echo "options kvm-amd nested=1" | $SUDO tee /etc/modprobe.d/kvm-amd.conf >/dev/null
      ok "Nested KVM diaktifkan (AMD). Reboot diperlukan."
      ;;
    *)
      warn "CPU vendor tidak dikenali untuk nested KVM: '$cpu'"
      ;;
  esac
  if [ "${FORCE_KVM_RELOAD:-0}" = "1" ]; then
    $SUDO modprobe -r kvm_intel 2>>"$LOG" || true
    $SUDO modprobe -r kvm_amd   2>>"$LOG" || true
    $SUDO modprobe -r kvm       2>>"$LOG" || true
    $SUDO modprobe kvm          2>>"$LOG" || true
    $SUDO modprobe kvm_intel 2>>"$LOG" || $SUDO modprobe kvm_amd 2>>"$LOG" || true
    ok "Module KVM direload (paksa)."
  fi
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
    echo "ℹ️  Catatan: Netplan bridge butuh 'sudo netplan apply' atau reboot."
  } >"$SUMMARY"

  echo -e "\n✅ Selesai. Ringkasan: $SUMMARY\n"
}
main "$@"
