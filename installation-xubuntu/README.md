# 🐧 Installation – Ubuntu (Jammy 22.04 / Noble 24.04)

Toolkit instalasi **modular** untuk Ubuntu: Audio, Browser, Cloud, Database, Editor, Image, Messaging, Office, Pentest, Remote, Security, Servers, Storage, Streaming, Tools, Utilities, dan Virtualization. Semua modul memiliki **`basic.sh`**, **`pro.sh`**, dan **README.md** sendiri. Orkestrasi utama dilakukan oleh **`installation-ubuntu/basic.sh`** (skrip di folder ini).

> Prinsip: **idempotent**, **best‑effort**, TUI **whiptail** (checklist) + **headless/CI** (variabel & argumen). Tidak ada paket terpasang kecuali yang Anda pilih.

---

## ✅ Lingkup & Kompatibilitas
- Diuji untuk **Ubuntu 22.04 (Jammy)** & **24.04 (Noble)**.
- Deteksi OS via **`/etc/os-release`** (`ID`, `VERSION_ID`). Bila di luar target: tampilkan peringatan & lanjut hanya jika Anda setuju.
- APT berjalan **non‑interaktif**; skrip memakai **`apt-get`** (bukan `apt`) agar output stabil untuk otomasi.

---

## 🚀 Quick Start

1. **Clone repo** dan masuk ke folder `installation-ubuntu`.
2. **Jadikan eksekusi**: `chmod +x basic.sh`.
3. **Jalankan orkestrator**:
   - **Interaktif**: `./basic.sh` → pilih kategori → Basic/Pro → checklist paket.
   - **Headless/CI**: `./basic.sh --module tools,utilities --mode pro --yes CHOICES="GH_CLI YQ EZA ZOXIDE"`
4. **Log & Ringkasan**:
   - Log: `~/orchestrator-install.log`
   - Ringkasan: `~/orchestrator-summary.txt`

> **Tip:** Jalankan kembali kapan pun; skrip idempoten. Pasca instalasi grup (mis. `libvirt`, `docker`), **logout/login** agar efektif.

---

## 🎛️ Opsi & Argumen

- `-m, --module <list>`: daftar modul dipisah koma (mis. `audio,tools,virtualization`).  
- `-M, --mode <basic|pro|prompt>`: mode sub‑modul. `prompt` = pilih per modul.  
- `-y, --yes` : non‑interaktif penuh (lewati TUI walau whiptail ada).  
- `--choices "<STR>"` : meneruskan **CHOICES** yang sama ke semua modul.  
- `--module-choices "<mod>=<STR>[;<mod>=<STR>...]"` : CHOICES khusus per modul.  
- `--log <PATH>` / `--summary <PATH>` : ganti lokasi log/ringkasan.  
- `-h, --help` : bantuan singkat.

**Contoh:**

```bash
# Interaktif, pilih modul sendiri
./basic.sh

# Headless: jalankan 3 modul sekaligus (BASIC semua)
./basic.sh -m audio,editor,tools -M basic -y

# Headless: PRO semua + CHOICES global
./basic.sh -m tools,virtualization -M pro -y --choices "GH_CLI YQ EZA ZOXIDE"

# Headless: CHOICES spesifik per modul
./basic.sh -m tools,virtualization -M pro -y \
  --module-choices "tools=GH_CLI EZA YQ;virtualization=KVM_CORE VIRT_MANAGER OVMF CLOUD_IMAGE"
```

---

## 📦 Modul yang Tersedia

| Kategori | Basic | Pro |
|---|---|---|
| **audio** | PipeWire desktop, codec, util | Studio: PipeWire‑JACK, DAW, plugin, low‑latency (opsional) |
| **browser** | Browser umum + codec | Opsi dev/DRM, profil terpisah |
| **cloud** | CLI/SDK umum | Orkestrasi/infra tambahan |
| **database** | Klien & util DB | Admin GUI/opsional lanjutan |
| **editor** | VS Code/NeoVim dkk | Ekstensi, SDK |
| **image** | Alat image/codec | Pipeline & plugin lanjutan |
| **messaging** | Chat/VoIP | Integrasi tambahan |
| **office** | Office suite, font, PDF | Extras & integrasi |
| **pentest** | Tool inti jaringan/web | Suite lengkap (AD/mobile/cloud) + disclaimer |
| **remote** | ssh/rdp/vnc | Alat enterprise tambahan |
| **security** | hardening & scanner | tooling lanjutan |
| **servers** | Web/DB/cache dasar | ekosistem opsional |
| **storage** | disk, backup, sync | manajemen lanjut |
| **streaming** | OBS/FFmpeg/GStreamer | RTMP/SRT/NDI dkk |
| **tools** | ripgrep/fd/bat/fzf/jq dkk | gh, yq, eza, zoxide, starship, oh‑my‑zsh, glow |
| **utilities** | Flathub, Tweaks, Flameshot, CopyQ... | TLP, PowerTOP, Timeshift, AppImageLauncher, Ulauncher, BleachBit, zram |
| **virtualization** | KVM/libvirt, virt‑manager, Boxes, Multipass, VirtualBox, LXD | OVMF, swtpm, Cockpit KVM, Netplan bridge, cloud‑image, Vagrant, Packer, nested KVM, VM tools |

> Baca README di masing‑masing modul untuk detail pilihan **CHOICES** & verifikasi alat.

---

## 🔒 Keamanan & Legal
- Repos pihak ketiga menggunakan **keyring** + `signed-by=` (hindari `apt-key`, deprekasikan).  
- Unduhan `.deb`/skrip pihak ketiga: verifikasi **checksum/GPG** terlebih dahulu (lihat README modul).  
- Modul **pentest**: gunakan **hanya** pada aset sendiri/izin tertulis; rujuk **OWASP WSTG**.

---

## 🧾 Rilis & Dokumentasi
- Versi mengikuti **SemVer**; catatan perubahan mematuhi **Keep a Changelog**.  
- File penting: `CHANGELOG.md`, `LICENSE`, `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`.

---

## ❓ FAQ
- **TUI tidak muncul?** Paket `whiptail` akan dipasang otomatis; jika gagal atau `--yes` dipakai, skrip beralih ke **headless**.  
- **APT terkunci?** Pastikan tidak ada proses apt lain berjalan; tunggu dan ulangi.  
- **Butuh reboot?** Hanya pada perubahan kernel/driver/grup tertentu (mis. `libvirt`, `docker`).

---

© TenRusli — gunakan sesuai lisensi masing‑masing. Skrip disediakan *as‑is* (best‑effort).