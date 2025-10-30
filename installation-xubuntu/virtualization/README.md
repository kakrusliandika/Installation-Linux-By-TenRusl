# 🖥️ Ubuntu Virtualization – Basic & Pro

Modul **virtualization** menyiapkan hypervisor & alat virtualisasi di Ubuntu **22.04 (Jammy)** dan **24.04 (Noble)**. Semua skrip **selektif** (checklist) — hanya komponen yang Anda pilih yang dipasang. Fokus: **KVM/QEMU + libvirt**, GUI (virt‑manager/Boxes), **Multipass**, **VirtualBox**, serta opsi lanjutan (OVMF UEFI, TPM via swtpm, bridge Netplan, Cockpit KVM, Vagrant/Packer, cloud‑init tool).

> Folder: `installation-ubuntu/virtualization/`  
> Berkas: `basic.sh`, `pro.sh`, dan README ini.

---

## ✨ Ringkas
- **basic.sh** → fondasi KVM/QEMU + libvirt (daemon & CLI), **virt‑manager** & **virt‑viewer**, **GNOME Boxes**, **Multipass** (snap), **VirtualBox** (opsional), **LXD** (snap). Juga menambahkan user ke grup **libvirt**/**kvm**, enable layanan libvirtd.
- **pro.sh** → lanjutan dan opsional: **OVMF (UEFI)**, **swtpm** (TPM emulator untuk VM), **Cockpit + cockpit‑machines** (UI web KVM), **bridge Netplan** (br0) berbasis variabel, **cloud‑image-utils** (seed ISO cloud‑init), **Vagrant** (HashiCorp repo) + plugin libvirt, **Packer** (HashiCorp repo), **nested KVM** (opsional), util VM (`qemu-utils`, `virt-top`, `guestfs-tools`, `virtiofsd`).

Instalasi bersifat **best‑effort** — proses lanjut walau ada kegagalan; dibuat **log** & **ringkasan**. Tidak ada paket yang dipasang di luar pilihan Anda.

---

## ✅ Prasyarat
- Ubuntu Desktop/Server **22.04/24.04**.
- CPU mendukung **VT‑x/AMD‑V** dan diaktifkan di BIOS/UEFI.
- Akses `sudo`, internet aktif.

---

## 🚀 Cara Pakai

1) **Jadikan executable**
```bash
chmod +x basic.sh pro.sh
```

2) **Mode interaktif** (checklist)
```bash
./basic.sh
./pro.sh
```
Gunakan **Space** untuk memilih, **Tab → OK** untuk lanjut.

3) **Mode non‑interaktif** via `CHOICES="..."` (pisah spasi) dan variabel opsional:

```bash
# === BASIC ===
# KVM stack + GUI + Boxes + Multipass + VirtualBox + LXD
CHOICES="KVM_CORE VIRT_MANAGER BOXES MULTIPASS VIRTUALBOX LXD" ./basic.sh

# === PRO ===
# OVMF + swtpm + Cockpit (web) + bridge br0 (Netplan) + cloud-image-utils + Vagrant + Packer + nested KVM + tools
BR_IFACE="enp3s0" BR_ADDR="192.168.1.10/24" BR_GW="192.168.1.1" BR_DNS="1.1.1.1,8.8.8.8" \
HASHICORP_REPO=1 ENABLE_NESTED_KVM=1 \
CHOICES="OVMF SWTPM COCKPIT_KVM BRIDGE_NETPLAN CLOUD_IMAGE VAGRANT PACKER NESTED_KVM VM_TOOLS" ./pro.sh

# Opsi alternatif:
# - Gunakan DHCP untuk bridge: BR_DHCP=1 (abaikan BR_ADDR/BR_GW/BR_DNS)
# - Lewati HashiCorp repo: unset HASHICORP_REPO lalu install vagrant/packer manual
# - Tambah plugin libvirt di Vagrant: VAGRANT_LIBVIRT=1
```

4) **Log & Ringkasan**
- Log: `~/virt-install.log`  
- Ringkasan: `~/virt-summary.txt`

---

## 🧩 Pilihan Komponen

### BASIC
- `KVM_CORE` → `qemu-kvm`, `libvirt-daemon-system`, `libvirt-clients`, `virtinst`, `virt-viewer`; enable libvirtd; tambah user → grup **libvirt** & **kvm**; validasi `virt-host-validate` (jika ada).
- `VIRT_MANAGER` → `virt-manager` (GUI).
- `BOXES` → `gnome-boxes` (front‑end libvirt yang simpel).
- `MULTIPASS` → `snap install multipass` (CLI VM Ubuntu cepat).
- `VIRTUALBOX` → `virtualbox` dari repo Ubuntu (ext‑pack opsional manual).
- `LXD` → `snap install lxd` (container/VM manager dari Canonical).

### PRO
- `OVMF` → `ovmf` (firmware UEFI untuk KVM/QEMU).
- `SWTPM` → `swtpm`, `swtpm-tools` (TPM 1.2/2.0 emulator).
- `COCKPIT_KVM` → `cockpit cockpit-machines` (UI web KVM, port 9090).
- `BRIDGE_NETPLAN` → buat `/etc/netplan/99-bridge.yaml` menggunakan `BR_IFACE` atau `BR_DHCP=1` (butuh reboot/apply).
- `CLOUD_IMAGE` → `cloud-image-utils` (mis. `cloud-localds` untuk seed ISO), `genisoimage` (fallback).
- `VAGRANT` → tambah repo HashiCorp (opsional via `HASHICORP_REPO=1`) lalu `vagrant`; jika `VAGRANT_LIBVIRT=1` → pasang plugin `vagrant-libvirt`.
- `PACKER` → dari repo HashiCorp bila `HASHICORP_REPO=1`.
- `NESTED_KVM` → aktifkan nested virtualization (Intel/AMD) permanen via `modprobe.d` (butuh reboot).
- `VM_TOOLS` → util tambahan: `qemu-utils`, `virt-top`, `guestfs-tools`, `virtiofsd`.

> Semua komponen **opsional** dan **idempotent** — aman dijalankan berulang.

---

## 🔍 Verifikasi Cepat
```bash
# KVM/libvirt
kvm-ok 2>/dev/null || egrep -c '(vmx|svm)' /proc/cpuinfo
virsh --version && virt-host-validate 2>/dev/null || true
sudo systemctl status libvirtd --no-pager -l

# GUI/CLI
virt-manager --version 2>/dev/null || true
gnome-boxes --version 2>/dev/null || true
multipass version 2>/dev/null || true
VBoxManage --version 2>/dev/null || true

# Pro
ovmfdir=/usr/share/OVMF; ls "$ovmfdir" 2>/dev/null | head || true
swtpm --version 2>/dev/null || true
sudo systemctl status cockpit 2>/dev/null || true
ip addr show br0 2>/dev/null || true
cloud-localds --help 2>/dev/null | head -n 1 || true
vagrant --version 2>/dev/null || true
packer --version 2>/dev/null || true
```

---

## ⚙️ Variabel Penting (PRO)
- **Bridge**: set `BR_IFACE="enp3s0"`; gunakan `BR_DHCP=1` *atau* set `BR_ADDR`, `BR_GW`, `BR_DNS`. File dibuat: `/etc/netplan/99-bridge.yaml`. Jalankan `sudo netplan apply`/reboot.
- **HashiCorp repo**: `HASHICORP_REPO=1` menambah repo resmi (untuk `vagrant`/`packer` versi terbaru).
- **Vagrant libvirt**: `VAGRANT_LIBVIRT=1` memasang plugin `vagrant-libvirt`.
- **Nested KVM**: `ENABLE_NESTED_KVM=1` mengaktifkan nested (Intel/AMD) via `modprobe.d`. Reboot diperlukan.

---

## 🛡️ Catatan & Legal
- **VirtualBox Extension Pack** berlisensi **PUEL** (proprietary) dan **opsional**. Pasang manual sesuai kebutuhan.
- **Bridge**: pastikan akses fisik/konsol sebelum mengubah jaringan di host remote.
- **swtpm**: gunakan untuk kebutuhan fitur/kompatibilitas (mis. Windows 11 VM) — tetap patuhi kebijakan perusahaan.
- **LXD**: pada Ubuntu modern didistribusikan via **snap**.

---

_TenRusli – Ubuntu Virtualization installers (selective, forward‑looking setup)._ 