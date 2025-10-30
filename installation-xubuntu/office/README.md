# 🧩 Ubuntu Office – Basic & Pro

Modul **office** ini menyiapkan suite perkantoran & tool dokumen di Ubuntu **22.04 (Jammy)** dan **24.04 (Noble)**. Semua skrip **bersifat selektif** (pilih‑pasang), bukan memasang semuanya.

> Folder: `installation-ubuntu/office/`  
> Berisi: `basic.sh`, `pro.sh`, dan README ini.

---

## ✨ Ringkas
- **basic.sh** → **Repo Ubuntu** (stabil & ringan): LibreOffice (Writer/Calc/Impress), PDF tools (Evince/Okular, PDF Arranger), font, kamus/spellcheck, converter CLI.
- **pro.sh** → **Power user / enterprise**: ONLYOFFICE Desktop Editors (**repo resmi**), **SoftMaker Office** (repo resmi), **WPS Office** (`.deb`), LaTeX (**TeX Live**), **Pandoc**, PDF tool tingkat lanjut. Semua **opsional** & bisa diganti metode (APT / repo / .deb / Flatpak/Snap jika diperlukan).

---

## ✅ Prasyarat
- Ubuntu 22.04/24.04, akses `sudo`, koneksi internet.
- Untuk varian Snap/Flatpak, pastikan `snapd`/`flatpak` aktif bila memilih opsi tersebut.
- Saat memasang **Microsoft Core Fonts**, Anda perlu menyetujui **EULA** (paket `ttf-mscorefonts-installer`).

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
Gunakan **Space** untuk memilih beberapa item, **Tab → OK** untuk lanjut.

3) **Mode non‑interaktif** (opsional) — daftar **kode komponen** dipisah spasi:
```bash
# BASIC: LibreOffice + PDF Arranger + font MS + kamus ID + Noto CJK
CHOICES="LIBREOFFICE PDF_ARRANGER FONTS_MS DICTS_ID FONTS_NOTO_CJK" ./basic.sh

# PRO: ONLYOFFICE (repo), SoftMaker (repo), Pandoc, TeX Live full
CHOICES="ONLYOFFICE SOFTMAKER PANDOC TEXLIVE_FULL" ./pro.sh

# PRO contoh lain: WPS Office dari .deb (set URL .deb dulu)
WPS_DEB_URL="https://example.com/wps-office-amd64.deb" CHOICES="WPS_OFFICE" ./pro.sh
```

4) **Log & Ringkasan**  
- Log: `~/office-install.log`  
- Ringkasan: `~/office-summary.txt`

---

## 🧩 Pilihan Komponen

### BASIC (repo Ubuntu)
- `LIBREOFFICE` → Suite office utama (`libreoffice` + l10n/help opsional).  
- `PDF_VIEWERS` → **Evince** (GNOME) &/atau **Okular** (KDE).  
- `PDF_ARRANGER` → **PDF Arranger** (merge/split/rotate PDF).  
- `FONTS_MS` → **Microsoft Core Fonts** (`ttf-mscorefonts-installer`).  
- `FONTS_NOTO` → **fonts-noto** (Latin/emoji), `fonts-noto-color-emoji`.  
- `FONTS_NOTO_CJK` → **Noto CJK** (Cina/Jepang/Korea).  
- `DICTS_ID` → **hunspell-id** (KBBI/hunspell Indonesia) + `libreoffice-l10n-id` (bila tersedia).  
- `CONVERTERS` → util CLI umum (unzip, p7zip-full, ghostscript, qpdf).

### PRO (lanjutan / enterprise)
- `ONLYOFFICE` → **ONLYOFFICE Desktop Editors** via **repo resmi** (`onlyoffice-desktopeditors`).  
- `SOFTMAKER` → **SoftMaker Office 2024** via **repo resmi** (`softmaker-office-2024`).  
- `WPS_OFFICE` → **WPS Office** via paket **`.deb` resmi** (set `WPS_DEB_URL`).  
- `PANDOC` → **Pandoc** (converter dokumen universal).  
- `TEXLIVE_BASE` → **TeX Live (base)** untuk LaTeX dasar.  
- `TEXLIVE_FULL` → **TeX Live Full** (komplet; ukuran besar).  
- `PDF_EXTRAS` → tool PDF lanjut (pdftk-java, pdfgrep, poppler-utils).

> Semua **opsional** — centang sesuai kebutuhan.

---

## 🔍 Verifikasi Cepat
```bash
libreoffice --version || soffice --version || true
onlyoffice-desktopeditors --version || desktopeditors --version || true
textmaker --version || softmaker --version || true
wps --version || true
pandoc --version | head -n1 || true
pdflatex --version | head -n1 || true
pdfarranger --version || true
```
Cek font & kamus: buka LibreOffice → **Tools → Options → Language Settings** (UI/Spellcheck).

---

## ❓ Troubleshooting
- **ttf-mscorefonts-installer** butuh persetujuan **EULA** saat instal — bila gagal, hapus lalu pasang ulang (`sudo apt remove --purge ttf-mscorefonts-installer && sudo apt install ttf-mscorefonts-installer`).  
- **ONLYOFFICE**: pastikan **GPG key** diletakkan di `/usr/share/keyrings/onlyoffice.gpg` & sumber `onlyoffice.list` benar, lalu `sudo apt update` ulang.  
- **SoftMaker**: pastikan keyring `softmaker.gpg` ada di `/etc/apt/keyrings/` dan entri repo sesuai.  
- **WPS Office**: URL `.deb` sering berubah; ambil dari halaman unduhan resmi Linux lalu set `WPS_DEB_URL="https://…/wps-office…amd64.deb"` sebelum menjalankan `pro.sh`.  
- **TeX Live Full** ukurannya besar (± beberapa GB). Pastikan ruang disk cukup.  
- **Pandoc**: versi repo Ubuntu mungkin bukan yang paling terbaru; jika perlu versi terbaru, ikuti petunjuk di situs pandoc.

---

## 📚 Rujukan Resmi
- **ONLYOFFICE Desktop Editors (repo APT)** – panduan resmi.  
- **WPS Office Linux** – unduh `.deb` resmi.  
- **SoftMaker Office 2024 (repo APT)** – panduan resmi.  
- **LibreOffice di Ubuntu** – metapackage `libreoffice`.  
- **Microsoft Core Fonts** (`ttf-mscorefonts-installer`) – paket resmi Ubuntu.  
- **TeX Live** – dokumentasi resmi (TUG).  
- **Pandoc** – instruksi instalasi resmi.  
- **PDF Arranger** – proyek & paket (Debian/Ubuntu).

---

_TenRusli – Ubuntu Office installers (selective, forward‑looking setup)._ 