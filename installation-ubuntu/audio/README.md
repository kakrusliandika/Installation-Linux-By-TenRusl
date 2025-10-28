# 🔊 Ubuntu Audio – Basic & Pro

Skrip ini menyiapkan audio **desktop** & **studio** di Ubuntu **22.04/24.04** dengan pendekatan modern **PipeWire + WirePlumber**.

- `basic.sh` → Audio desktop siap pakai: PipeWire, pavucontrol, VLC/FFmpeg, GStreamer plugin set.
- `pro.sh` → Lingkungan studio: PipeWire-JACK, QjackCtl, Ardour, Carla, plugin LV2/LADSPA; **opsional** kernel low-latency & tuning realtime.

> Catatan:
> - Ubuntu modern menggunakan **PipeWire** sebagai audio server; `wireplumber` adalah session/policy manager.
> - `pipewire-pulse` memberi kompatibilitas PulseAudio; `pipewire-jack` memberi kompatibilitas JACK.
> - Plugin GStreamer **good/bad/ugly**: “ugly” bisa memiliki isu lisensi/paten di beberapa wilayah.
> - Varian kernel **linux-lowlatency** tersedia; pada workload real‑time (JACK) latency lebih baik, namun tidak wajib untuk semua pengguna.

---

## ✅ Prasyarat

- Ubuntu 22.04 LTS (Jammy) atau 24.04 LTS (Noble).
- Akses `sudo`. Koneksi internet stabil.

---

## 🚀 Cara Pakai

```bash
# 1) jadikan eksekusi:
chmod +x basic.sh pro.sh

# 2) mode dasar (desktop audio)
./basic.sh

# 3) mode pro (studio)
./pro.sh
```

### Opsi lanjutan (env var untuk pro.sh)

```bash
# pasang kernel low-latency
INSTALL_LOWLATENCY=1 ./pro.sh

# aktifkan repo KXStudio (plugin/app ekstra)
ENABLE_KXSTUDIO=1 ./pro.sh

# nonaktifkan tuning realtime limits (default=aktif)
TUNE_LIMITS=0 ./pro.sh
```

> **Reboot** direkomendasikan bila Anda menginstal kernel baru atau banyak paket audio sekaligus.

---

## 📦 Yang Dipasang

**Basic**
- PipeWire stack: `pipewire`, `pipewire-pulse`, `wireplumber` (juga `pipewire-audio-client-libraries` untuk Ubuntu 22.04).
- Alat & codec: `alsa-utils`, `pavucontrol`, `vlc`, `ffmpeg`, `gstreamer1.0-plugins-{good,bad,ugly}`, `gstreamer1.0-libav`.

**Pro**
- JACK kompatibel: `pipewire-jack`, `qjackctl`.
- DAW & host: `ardour`, `carla`.
- Plugin: `calf-plugins`, `lsp-plugins`, `zam-plugins`, `mda-lv2`, `swh-plugins`.
- MIDI/JACK helper: `a2jmidid`, `jack-tools`.
- Opsional: `linux-lowlatency` (butuh reboot).
- Opsional: **KXStudio** repo (membuka akses lebih banyak plugin/aplikasi).

---

## 🔍 Verifikasi Cepat

```bash
# cek layanan
systemctl --user status pipewire pipewire-pulse wireplumber

# daftar node sink/source (WirePlumber CLI)
wpctl status

# uji playback
ffplay -nodisp -autoexit /usr/share/sounds/alsa/Front_Center.wav 2>/dev/null || true

# uji JACK app via PipeWire-JACK (Pro)
qjackctl &
```

---

## ❓ Troubleshooting

- **Tidak ada suara setelah migrasi**  
  Pastikan `pipewire`, `pipewire-pulse`, dan `wireplumber` **aktif** (enable + now).

- **Butuh latensi sangat rendah**  
  Coba varian `linux-lowlatency` **atau** tetap di `generic` terbaru; gunakan `INSTALL_LOWLATENCY=1` pada `pro.sh`.

- **Aplikasi lama hanya mendukung PulseAudio**  
  `pipewire-pulse` menyediakan kompatibilitas **libpulse** sehingga aplikasi tetap berfungsi.

- **Ingin ekosistem plugin lebih banyak**  
  Aktifkan **KXStudio** (`ENABLE_KXSTUDIO=1`) lalu telusuri paket tambahannya.

---

## ⚠️ Catatan Legal

Beberapa codec/plugin (terutama GStreamer **ugly**) mungkin terikat lisensi/paten di wilayah tertentu. Instalasi mengikuti kebijakan repositori Ubuntu/KXStudio. Tinjau kebutuhan & legalitas Anda.

_TenRusli – Ubuntu Audio installers (selective, forward‑looking setup)._ 