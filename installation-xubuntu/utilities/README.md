# 🔧 Ubuntu Utilities – Basic & Pro

Modul **utilities** menyiapkan utilitas sistem & desktop untuk Ubuntu **22.04 (Jammy)** dan **24.04 (Noble)**. Semua skrip **selektif** (checklist) — hanya item yang dipilih yang dipasang. Cocok untuk workstation, laptop, hingga host dev sehari‑hari.

> Folder: `installation-ubuntu/utilities/`  
> Berkas: `basic.sh`, `pro.sh`, dan README ini.

---

## ✨ Ringkas
- **basic.sh** → utilitas desktop/sistem dari repo Ubuntu: **Flatpak + Flathub (GUI plugin)**, **GNOME Tweaks**, **Flameshot** (screenshot), **CopyQ** (clipboard), **GParted** (partisi), **Disk Usage Analyzer (baobab)**, **PDF tools** (`pdfarranger`, `ocrmypdf`, `poppler-utils`), **archiver** (`file-roller`).
- **pro.sh** → opsi lanjutan: **TLP** (hemat baterai), **PowerTOP** (profiling power), **Timeshift** (snapshot OS), **AppImageLauncher** (integrasi AppImage), **Ulauncher** (app launcher), **BleachBit** (pembersih), **zram-tools**.

Instalasi bersifat **best‑effort** — lanjut meski ada paket gagal; dibuat **log** & **ringkasan**.

---

## ✅ Prasyarat
- Ubuntu 22.04/24.04, akses `sudo`, koneksi internet.
- Untuk komponen **upstream** (mis. AppImageLauncher/Ulauncher/BleachBit), skrip menyediakan **variable URL** agar Anda mengontrol sumber/versi .deb.

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

3) **Mode non‑interaktif** — set `CHOICES="..."` (pisah spasi) + variabel opsional:

```bash
# BASIC: Flatpak + Flathub + Tweaks + Flameshot + CopyQ + GParted + Baobab + PDF tools
CHOICES="FLATPAK_SETUP TWEAKS FLAMESHOT COPYQ GPARTED BAOBAB PDF_TOOLS ARCHIVER" ./basic.sh

# PRO: TLP + PowerTOP + Timeshift + AppImageLauncher (.deb URL) + Ulauncher (.deb URL) + BleachBit + zram-tools
APPIMAGELAUNCHER_DEB_URL="https://github.com/TheAssassin/AppImageLauncher/releases/download/v2.2.0/appimagelauncher_2.2.0-jammy_amd64.deb" \
ULAUNCHER_DEB_URL="https://github.com/Ulauncher/Ulauncher/releases/download/5.15.5/ulauncher_5.15.5_all.deb" \
BLEACHBIT_DEB_URL="https://download.bleachbit.org/bleachbit_5.0.2_all_ubuntu2404.deb" \
CHOICES="TLP POWERTOP TIMESHIFT APPIMAGELAUNCHER ULAUNCHER BLEACHBIT ZRAM_TOOLS" ./pro.sh
```

4) **Log & Ringkasan**
- Log: `~/utilities-install.log`  
- Ringkasan: `~/utilities-summary.txt`

---

## 🧩 Pilihan Komponen

### BASIC (repo Ubuntu, stabil)
- `FLATPAK_SETUP` → `flatpak`, `gnome-software-plugin-flatpak` + **Flathub remote**.  
- `TWEAKS` → `gnome-tweaks`.  
- `FLAMESHOT` → `flameshot` (screenshot modern).  
- `COPYQ` → `copyq` (clipboard manager).  
- `GPARTED` → `gparted` (manajer partisi).  
- `BAOBAB` → `baobab` (Disk Usage Analyzer).  
- `PDF_TOOLS` → `pdfarranger`, `ocrmypdf`, `poppler-utils`.  
- `ARCHIVER` → `file-roller` (GUI arsip).

### PRO (lanjutan)
- `TLP` → `tlp` (hemat baterai; laptop).  
- `POWERTOP` → `powertop` (diagnostik power/per‑komponen).  
- `TIMESHIFT` → `timeshift` (snapshot OS rsync/btrfs).  
- `APPIMAGELAUNCHER` → integrasi AppImage (APT bila ada, atau `.deb` via `APPIMAGELAUNCHER_DEB_URL`).  
- `ULAUNCHER` → app launcher cepat (via `.deb` `ULAUNCHER_DEB_URL`).  
- `BLEACHBIT` → pembersih sistem (APT atau `.deb` via `BLEACHBIT_DEB_URL`).  
- `ZRAM_TOOLS` → `zram-tools` (swap terkompresi).

> Semua **opsional** — pilih sesuai kebijakan host/produksi Anda.

---

## 🔍 Verifikasi Cepat
```bash
# Desktop util
flatpak --version || true
gnome-tweaks --version || true
flameshot --version || true
copyq --version || true
gparted --version || true
baobab --help | head -n 1 || true
pdfarranger --version || true
ocrmypdf --version || true

# Power & snapshot
tlp-stat -s 2>/dev/null | head -n 5 || true
powertop --version 2>/dev/null || true
timeshift --version 2>/dev/null || true

# App integration & launcher
appimagelauncher --version 2>/dev/null || true
ulauncher --version 2>/dev/null || true
bleachbit --version 2>/dev/null || true
```

---

## 🛡️ Catatan & Tips
- **Flathub**: setelah menambah remote, Anda bisa memasang aplikasi Flatpak via GNOME Software atau CLI.  
- **TLP**: default sudah optimal; aktifkan/disable otomatis sesuai mode AC/Battery.  
- **PowerTOP**: gunakan untuk *profiling* (tab `Tunables`/`Overview`), bukan sekadar auto‑tuning membabi buta.  
- **Timeshift**: untuk rootfs — **bukan** pengganti backup data. Gunakan bersama backup file (restic/borg) jika perlu.  
- **AppImageLauncher**: gunakan `.deb` resmi saat paket APT belum tersedia untuk rilis Ubuntu terbaru.  
- **zram-tools**: profil default biasanya cukup; sesuaikan ukuran ZRAM bila RAM besar/kecil.

---

_TenRusli – Ubuntu Utilities installers (selective, forward‑looking setup)._ 