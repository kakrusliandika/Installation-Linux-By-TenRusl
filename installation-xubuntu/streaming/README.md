# 📺 Ubuntu Streaming – Basic & Pro

Modul **streaming** ini menyiapkan ekosistem **pemutaran, penyandian, dan siaran** di Ubuntu **22.04 (Jammy)** & **24.04 (Noble)**. Semua skrip **selektif** (checklist), jadi **hanya** komponen yang Anda pilih yang akan dipasang. Fokus ke **OBS Studio**, **FFmpeg**, **GStreamer**, virtual camera (**v4l2loopback**), alat live‑streaming (RTMP/SRT), dan pemutar (VLC/MPV).

> Folder: `installation-ubuntu/streaming/`  
> Berisi: `basic.sh`, `pro.sh`, dan README ini.

---

## ✨ Ringkas
- **basic.sh** → install dari **repo Ubuntu** yang stabil: **OBS Studio**, **FFmpeg**, **GStreamer good/bad/ugly + libav**, **VLC/MPV**, **Streamlink + yt‑dlp**, opsional **Virtual Camera (v4l2loopback)**.
- **pro.sh** → opsi **power user / upstream**: **OBS Studio dari PPA resmi**, **Nginx + libnginx‑mod‑rtmp** (server RTMP/HLS/DASH), **SRT tools (srt‑tools)**, **obs‑ndi/DistroAV** (*opsional*; butuh NDI Runtime), plus util lanjutan.

Instalasi bersifat **best‑effort** – skrip lanjut meski sebagian paket gagal, dan membuat **log** & **ringkasan**.

---

## ✅ Prasyarat
- Ubuntu 22.04/24.04, akses `sudo`, koneksi internet.
- Untuk **Virtual Camera** (v4l2loopback), bila **Secure Boot** aktif, modul DKMS bisa perlu penandatanganan; ikuti kebijakan perangkat Anda.
- **NDI (obs‑ndi/DistroAV)** memerlukan **NDI Runtime** (proprietary). Skrip menyediakan flag & URL agar Anda **mengontrol** sumber/versi.

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

3) **Mode non‑interaktif** – set `CHOICES="..."` (dipisah spasi) + variabel opsi:
```bash
# BASIC: OBS + FFmpeg + GStreamer + pemutar + virtualcam
CHOICES="OBS_STUDIO FFMPEG GSTREAMER_FULL PLAYERS V4L2LOOPBACK STREAMLINK_YTDLP" ./basic.sh

# PRO: OBS PPA + Nginx RTMP + SRT tools
CHOICES="OBS_STUDIO_PPA NGINX_RTMP SRT_TOOLS" ./pro.sh

# PRO: aktifkan contoh konfigurasi RTMP minimal (opsional)
SETUP_RTMP_SAMPLE=1 CHOICES="NGINX_RTMP" ./pro.sh

# PRO: pasang obs‑ndi (DistroAV) + NDI Runtime (Anda sediakan URL)
OBS_NDI_DEB_URL="https://github.com/DistroAV/DistroAV/releases/download/v6.1.1/obs-ndi-6.1.1-linux-x86_64.deb" \
NDI_TGZ_URL="https://downloads.ndi.tv/SDK/NDI_SDK_Linux/Install_NDI_SDK_v6_Linux.tar.gz" \
CHOICES="OBS_NDI" ./pro.sh
```

4) **Log & Ringkasan**
- Log: `~/streaming-install.log`  
- Ringkasan: `~/streaming-summary.txt`

---

## 🧩 Pilihan Komponen

### BASIC (repo Ubuntu, stabil)
- `OBS_STUDIO` → `obs-studio` (OBS Studio).  
- `FFMPEG` → `ffmpeg` (enkode/dekode).  
- `GSTREAMER_FULL` → `gstreamer1.0-plugins-{good,bad,ugly}` + `gstreamer1.0-libav`.  
- `PLAYERS` → `vlc`, `mpv`.  
- `STREAMLINK_YTDLP` → `streamlink`, `yt-dlp`.  
- `V4L2LOOPBACK` → `v4l2loopback-dkms` (OBS Virtual Camera).

### PRO (lanjutan/enterprise)
- `OBS_STUDIO_PPA` → OBS dari **PPA resmi** (lebih baru daripada repo Ubuntu).  
- `NGINX_RTMP` → `nginx` + `libnginx-mod-rtmp` (server RTMP/HLS/DASH).  
- `SRT_TOOLS` → `srt-tools` (alat CLI protokol **SRT**).  
- `OBS_NDI` → **DistroAV (obs‑ndi)** + **NDI Runtime** (*opsional*; Anda sediakan URL/arsip resmi).

> Semua **opsional** — pilih sesuai kebutuhan host/produksi Anda.

---

## 🔍 Verifikasi Cepat
```bash
# Aplikasi
obs --version || true
ffmpeg -version || true
vlc --version || true
mpv --version || true
streamlink --version || true
yt-dlp --version || true

# GStreamer
gst-inspect-1.0 | head -n 10
gst-inspect-1.0 x264 || true

# Virtual Camera
modinfo v4l2loopback 2>/dev/null | head -n 5 || true

# RTMP (jika diinstal)
nginx -V 2>&1 | grep -i rtmp || true

# SRT
srt-live-transmit -version 2>/dev/null || true
```

---

## 🛡️ Catatan & Tips
- **OBS**: pada Ubuntu, instal via **PPA resmi** untuk versi terbaru — atau gunakan Flatpak (di luar cakupan skrip).  
- **Virtual Camera** memakai **v4l2loopback**; pada beberapa perangkat **Secure Boot** perlu penandatanganan modul.  
- **Nginx + RTMP**: modulnya **dinamis** (`libnginx-mod-rtmp`); aktifkan dengan `load_module` dan tambahkan blok `rtmp {}` pada konfigurasi.  
- **SRT** cocok untuk jalur kontribusi *low‑latency*; gunakan `srt-live-transmit`/`ffmpeg` dengan `srt://...`.  
- **NDI (DistroAV)** memerlukan **NDI Runtime**; periksa lisensi & sumber resmi—skrip hanya membantu otomasi terarah.

---

## 📚 Rujukan Resmi/Kredibel
- **OBS Studio di Ubuntu (PPA resmi)** – petunjuk instal dari OBS Project.  
- **Virtual Camera di Linux** – `v4l2loopback` digunakan OBS; lihat diskusi & panduan.  
- **Nginx RTMP** – modul RTMP (dinamis), dan panduan konfigurasi.  
- **DigitalOcean** – setup Nginx RTMP & HLS/DASH contoh praktis.  
- **SRT** – protokol & alat CLI `srt-tools`.  
- **GStreamer plugins** – “good/bad/ugly/libav” (lisensi & cakupan).  
- **DistroAV (obs‑ndi)** – plugin NDI resmi komunitas & kebutuhan **NDI Runtime**.

---

_TenRusli – Ubuntu Streaming installers (selective, forward‑looking setup)._ 