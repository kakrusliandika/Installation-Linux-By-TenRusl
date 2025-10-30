# 🌐 Ubuntu Browser – Basic & Pro

Skrip ini menyiapkan **browser** di Ubuntu **22.04/24.04** dengan **mode pilih‑sesuai‑kebutuhan** (selective install). Anda bisa centang browser yang ingin dipasang lewat antarmuka checklist (TUI).

- `basic.sh` → Chrome, Firefox (Snap), Chromium (Snap), Brave (APT), Opera (Snap).
- `pro.sh` → Edge (APT), Vivaldi (APT), Brave Beta (APT), Ungoogled Chromium (Flatpak/Flathub).

> Catatan ringkas paket:
> - **Firefox di Ubuntu 22.04+** didistribusikan sebagai **Snap** secara default.  
> - **Chromium** di Ubuntu banyak dirilis sebagai **Snap** (paket APT menjadi wrapper).  
> - **Brave** menyediakan **APT repository resmi** (lebih direkomendasikan daripada Snap/Flatpak untuk desktop).  
> - **Microsoft Edge** memakai **packages.microsoft.com** (repo resmi Microsoft).  
> - **Vivaldi** menyediakan installer `.deb` yang sekaligus mengaktifkan repo; skrip ini mengonfigurasi repo **signed-by** langsung.  
> - **Ungoogled Chromium** direkomendasikan via **Flatpak** (app id: `io.github.ungoogled_software.ungoogled_chromium`).

---

## ✅ Prasyarat
- Ubuntu 22.04 LTS (Jammy) atau 24.04 LTS (Noble).
- Akses `sudo` & koneksi internet.
- Untuk varian Snap/Flatpak, pastikan `snapd`/`flatpak` aktif (skrip akan mencoba memasang bila belum ada).

---

## 🚀 Cara Pakai

1. Jadikan eksekusi:
   ```bash
   chmod +x basic.sh pro.sh
   ```
2. Mode dasar (pilih browser mainstream):
   ```bash
   ./basic.sh
   ```
3. Mode pro (browser tambahan & alternatif):
   ```bash
   ./pro.sh
   ```

### Opsi non‑interaktif (otomasi CI)
Set environment `SELECT` untuk melewati checklist TUI, contoh:
```bash
# Basic: pasang Chrome + Brave
SELECT="CHROME BRAVE" ./basic.sh

# Pro: pasang Edge + Vivaldi + Ungoogled Chromium (Flatpak)
SELECT="EDGE VIVALDI UNGOOGLED_FLAT" ./pro.sh
```

---

## 📦 Komponen yang Disediakan

**Basic**
- **Google Chrome** (APT resmi Google, kunci di `/etc/apt/keyrings/`).
- **Mozilla Firefox (Snap)**
- **Chromium (Snap)**
- **Brave (APT repo resmi Brave)**
- **Opera (Snap)**

**Pro**
- **Microsoft Edge** (APT via `packages.microsoft.com`)
- **Vivaldi** (APT via repo resmi Vivaldi)
- **Brave Beta** (APT channel beta)
- **Ungoogled Chromium** (Flatpak via Flathub)

---

## 🔍 Verifikasi Cepat
```bash
google-chrome --version   || true
brave-browser --version   || true
microsoft-edge --version  || microsoft-edge-stable --version || true
vivaldi --version || vivaldi-stable --version || true
flatpak info io.github.ungoogled_software.ungoogled_chromium || true
snap list firefox chromium opera || true
```

---

## ❓ Troubleshooting
- **Repo APT & kunci**: skrip menggunakan model **keyring + `signed-by`** (bukan `apt-key`) agar sesuai praktik baru APT.
- **Firefox/Chromium (Snap)**: bila **snapd** tidak aktif, skrip akan mencoba memasangnya. Pastikan reboot bila service snap baru diaktifkan.
- **Edge gagal ambil repo**: pastikan versi Ubuntu terbaca benar di `/etc/os-release` (skrip memanggil paket `packages-microsoft-prod.deb` sesuai versi).
- **Flatpak Ungoogled Chromium**: pastikan remote **Flathub** sudah terpasang; skrip menambahkan bila belum ada.

---


## ⚠️ Catatan Legal
Peramban membawa lisensi masing‑masing. Pemasangan lewat repo resmi menjaga update keamanan dan integritas paket. Gunakan sesuai kebijakan organisasi Anda.

---

_TenRusli – Ubuntu Browser installers (selective, forward‑looking setup)._ 