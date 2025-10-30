# 🖼️ Ubuntu Image – Basic & Pro

Skrip pada folder **installation-ubuntu/image** menyiapkan **tool grafis** di Ubuntu **22.04/24.04** dengan mode **pilih‑pasang (selective)**. Kamu centang yang diperlukan saja — skrip **tidak** memasang semuanya sekaligus.

> Folder: `installation-ubuntu/image/`  
> Berisi: `basic.sh`, `pro.sh`, dan `README.md` ini.

---

## ✨ Ringkas
- **basic.sh** → Editor & utilitas dari **repo Ubuntu** (stabil & ringan): **GIMP**, **Pinta**, **Krita**, **Inkscape**, viewer (gThumb/EOG), serta **CLI** (ImageMagick, WebP utils, pngquant, ExifTool, Exiv2, HEIF converter).
- **pro.sh** → Tool **power user**: **Darktable**, **RawTherapee**, **digiKam**, **Luminance HDR**, **scanner & OCR** (Simple‑Scan, sane‑airscan, gscan2pdf, **Tesseract** + bahasa), **color management** (DisplayCAL via Flatpak, **ArgyllCMS**), serta **AI upscaler** (waifu2x‑ncnn‑vulkan / Real‑ESRGAN frontend). Semuanya **opsional**.

---

## ✅ Prasyarat
- Ubuntu **22.04 (Jammy)** atau **24.04 (Noble)**.
- Akses `sudo` & internet.
- Untuk opsi **Snap** (waifu2x/UpScaler) pastikan `snapd` aktif; untuk **Flatpak** (DisplayCAL) pastikan `flatpak` & **Flathub** aktif.

---

## 🚀 Cara Pakai

```bash
# 1) jadikan executable
chmod +x basic.sh pro.sh

# 2) mode basic (repo Ubuntu)
./basic.sh

# 3) mode pro (alat lanjutan)
./pro.sh
```

Kedua skrip menampilkan **menu checklist** (pakai **Space** untuk memilih, **Tab → OK** untuk lanjut).

### Mode non‑interaktif (opsional)
Gunakan variabel `CHOICES` berisi **kode komponen**, dipisah spasi:
```bash
# Basic: GIMP + Inkscape + CLI (Magick/WebP/Exif/HEIF)
CHOICES="GIMP INKSCAPE CLI_MAGICK CLI_WEBP CLI_EXIF HEIF_SUPPORT" ./basic.sh

# Pro: Darktable + RawTherapee + OCR (ID+EN) + DisplayCAL + waifu2x
CHOICES="DARKTABLE RAWTHERAPEE OCR_TESSERACT COLOR_DISPLAYCAL AI_WAIFU2X" ./pro.sh
```

---

## 🧩 Opsi Komponen

### BASIC (repo Ubuntu)
- `VIEWERS` → **gThumb**, **Eye of GNOME (eog)**.
- `GIMP` → Editor raster serbaguna.
- `PINTA` → Editor ringan ala Paint.NET.
- `KRITA` → Editor/painting (juga cocok untuk tablet).
- `INKSCAPE` → Editor **vektor** (SVG).
- `CLI_MAGICK` → **ImageMagick** (konversi/komposisi CLI).
- `CLI_WEBP` → **WebP utilities** (`cwebp`, `dwebp`).
- `CLI_PNGQUANT` → **pngquant** (optimasi PNG lossy).
- `CLI_EXIF` → **ExifTool** + **Exiv2** (metadata).
- `HEIF_SUPPORT` → **libheif‑examples** (`heif‑convert` untuk HEIC/AVIF → JPEG/PNG).
- `FFMPEG` → **FFmpeg** (konversi format gambar/video dasar).

### PRO (lanjutan)
- `DARKTABLE` → RAW workflow & DAM.
- `RAWTHERAPEE` → RAW developer alternatif.
- `DIGIKAM` → Manajer foto canggih.
- `LUMINANCE_HDR` → HDR workflow.
- `SCAN_SIMPLE` → **Simple‑Scan** + **sane‑airscan** (driver eSCL/WSD).
- `SCAN_GSCAN2PDF` → **gscan2pdf** (scan → PDF/DjVu + OCR).
- `OCR_TESSERACT` → **Tesseract OCR** + bahasa **English** & **Indonesian**.
- `COLOR_DISPLAYCAL` → **DisplayCAL** (via **Flatpak Flathub**).
- `COLOR_ARGYLL` → **ArgyllCMS** (profiling/kalibrasi ICC).
- `AI_WAIFU2X` → **waifu2x‑ncnn‑vulkan** (Snap).
- `AI_UPSCALER_REALESRGAN` → **UpScaler** (frontend Real‑ESRGAN ncnn Vulkan; Snap).
- `CLI_OPTIMIZERS` → **jpegoptim**, **optipng**.
- `FFMPEG` → **FFmpeg** (jika belum dipasang di Basic).

> Semua **opsional** — centang hanya yang diperlukan.

---

## 🔍 Verifikasi Cepat
```bash
# GUI/Editor
gimp --version || true
pinta --version || true
krita --version || true
inkscape --version || true

# CLI
convert -version || magick -version || true      # ImageMagick
cwebp -version && dwebp -version || true
pngquant --version || true
exiftool -ver || true
exiv2 -V || true
heif-convert -h | head -n1 || true
ffmpeg -version | head -n1 || true

# Pro
darktable --version || true
rawtherapee-cli -v || true
digikam --version || true
luminance-hdr --version || true
simple-scan --version || true
gscan2pdf --version || true
tesseract --list-langs | grep -E 'eng|ind' || true
flatpak run --command=displaycal-apply-profiles net.displaycal.DisplayCAL --version || true
colprof -V || true                               # ArgyllCMS
waifu2x-ncnn-vulkan -h | head -n1 || true
upscaler -h | head -n1 || true
```

---

## ❓ Troubleshooting
- **GPG key / `signed‑by`**: pastikan keyring ada di `/etc/apt/keyrings/` dan izinnya **644**, lalu `sudo apt update` ulang.
- **Snap/Flatpak**: aktifkan `snapd`/`flatpak` dulu bila belum terpasang. Untuk Flathub:  
  `sudo apt install flatpak && sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo`
- **HEIC/AVIF**: gunakan `heif-convert input.heic output.jpg`. AVIF/HEIF encoder/decoder disediakan oleh **libheif**.
- **OCR Bahasa**: pastikan paket bahasa Tesseract (`tesseract-ocr-eng`, `tesseract-ocr-ind`) ikut terpasang.
- **Wayland + Pen Tablet**: untuk Krita, aktifkan **HiDPI/pen settings** di preferensi jika pen tablet terasa lag.

---

## 📚 Referensi Resmi
- GIMP • Linux (APT/Flathub/Snap tersedia) – gimp.org  
- Krita • Linux (Snap/AppImage/Flatpak) – docs.krita.org  
- Inkscape • Ubuntu/Debian (APT & PPA) – wiki.inkscape.org  
- ImageMagick • Download / AppImage – imagemagick.org  
- ExifTool • Install – exiftool.org  
- pngquant – pngquant.org  
- WebP utilities (`cwebp`, `dwebp`) – developers.google.com/speed/webp  
- libheif (HEIF/AVIF) – github.com/strukturag/libheif  
- Darktable – darktable.org/install/  
- RawTherapee – rawtherapee.com/downloads  
- digiKam – digikam.org (APT/Flatpak/Snap)  
- Luminance HDR – paket `luminance-hdr` (Ubuntu)  
- Simple‑Scan – paket `simple-scan` (Ubuntu)  
- sane‑airscan – paket `sane-airscan` (Ubuntu)  
- gscan2pdf – paket `gscan2pdf` (Ubuntu)  
- Tesseract OCR – tesseract-ocr.github.io/tessdoc/Installation.html  
- DisplayCAL – **Flathub** `net.displaycal.DisplayCAL`  
- ArgyllCMS – argyllcms.com  
- waifu2x‑ncnn‑vulkan (Snap) – snapcraft.io/waifu2x-ncnn-vulkan  
- UpScaler (Real‑ESRGAN frontend; Snap) – snapcraft.io/upscaler

---

_TenRusli – Ubuntu Image installers (selective, forward‑looking setup)._ 