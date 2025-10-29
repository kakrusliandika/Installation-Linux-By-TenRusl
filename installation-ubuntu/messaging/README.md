# 💬 Ubuntu Messaging – Basic & Pro

Skrip ini menyiapkan **aplikasi perpesanan/kolaborasi** di Ubuntu **22.04/24.04**. Anda bisa **memilih** aplikasi yang ingin dipasang (tidak semuanya). Terdapat dua varian:

- `basic.sh` → pilihan klien FOSS/umum via **APT** (beberapa bisa otomatis menjadi Snap di 24.04). Cocok untuk desktop harian.
- `pro.sh` → klien populer & enterprise (Slack/Discord/Signal/Zoom/Skype/Element, dsb) dengan **repo resmi**, **Snap**, atau **.deb** terbaik yang tersedia, plus opsi **PWA** untuk aplikasi tanpa klien native Linux.

> Catatan singkat:
> - **Thunderbird di Ubuntu 24.04** dipaketkan sebagai **Snap**; `apt install thunderbird` akan mengarahkan ke Snap secara otomatis.
> - **WhatsApp** & **Microsoft Teams** tidak menyediakan klien Linux native. Gunakan **PWA** (shortcut aplikasi web) atau klien pihak‑ketiga (opsional).

---

## ✅ Prasyarat

- Ubuntu 22.04 LTS (Jammy) atau 24.04 LTS (Noble).
- Akses `sudo` dan koneksi internet.
- (Opsional) `snapd` bila memilih pemasangan via Snap.

---

## 📦 Cakupan Aplikasi

### BASIC (APT / bawaan distro)
- **Telegram Desktop** (`telegram-desktop`)
- **Thunderbird** (email/chat; di 24.04 sebagai Snap)
- **Pidgin** (multi‑protocol)
- **WeeChat** (IRC/TUI)

### PRO (repo resmi / Snap / .deb / PWA)
- **Slack** (Snap; opsi `.deb` via URL manual)
- **Discord** (Snap atau `.deb` resmi)
- **Signal Desktop** (repo APT resmi)
- **Element (Matrix)** (repo APT resmi **atau** Snap)
- **Zoom** (paket `.deb` resmi)
- **Skype** (repo APT resmi)
- **Mattermost Desktop** (Snap atau `.deb` rilis)
- **Rocket.Chat Desktop** (Snap)
- **Viber** (`.deb` resmi)
- **Teams (PWA)** → shortcut desktop (Edge/Chromium)
- **WhatsApp (PWA)** → shortcut desktop (Chrome/Edge/Chromium)

> Semua pemasangan bersifat **best‑effort**: bila metode utama gagal, skrip mencoba metode alternatif (mis. Snap → .deb).

---

## 🚀 Cara Pakai Cepat

1. Jadikan executable:
   ```bash
   chmod +x basic.sh pro.sh
   ```

2. **Mode interaktif (GUI terminal)** – pakai checklist untuk memilih aplikasi:
   ```bash
   ./basic.sh
   ./pro.sh
   ```

3. **Mode non‑interaktif** – pilih dengan variabel environment (contoh):
   ```bash
   # BASIC: pasang Telegram + Thunderbird + Pidgin
   CHOICES=\"telegram thunderbird pidgin\" ./basic.sh

   # PRO: pasang Discord (Snap), Signal (repo), Element (repo), Zoom, Rocket.Chat (Snap)
   CHOICES=\"discord signal element zoom rocketchat\" ./pro.sh

   # Paksa Slack via Snap
   USE_SNAP=1 CHOICES=\"slack\" ./pro.sh

   # Pakai repo untuk Element (bukan Snap)
   ELEMENT_FROM=repo CHOICES=\"element\" ./pro.sh

   # Beri URL .deb khusus (opsional) untuk Slack/Discord/Zoom/Viber
   SLACK_DEB_URL=\"https://…/slack-desktop-amd64.deb\" CHOICES=\"slack\" ./pro.sh
   DISCORD_DEB_URL=\"https://discord.com/api/download?platform=linux&format=deb\" CHOICES=\"discord\" ./pro.sh
   ZOOM_DEB_URL=\"https://zoom.us/client/latest/zoom_amd64.deb\" CHOICES=\"zoom\" ./pro.sh
   VIBER_DEB_URL=\"https://download.cdn.viber.com/cdn/desktop/Linux/viber.deb\" CHOICES=\"viber\" ./pro.sh
   ```

4. **Log & Ringkasan**  
   - Log: `~/messaging-install.log`  
   - Ringkasan: `~/messaging-summary.txt`

---

## 🧭 Rincian Per Aplikasi & Metode

- **Telegram Desktop** – paket `telegram-desktop` via APT.
- **Thunderbird** – APT (24.04 akan mengarahkan ke Snap).
- **Pidgin / WeeChat** – APT.

**Pro:**
- **Slack** – default **Snap** (`--classic`). Alternatif: berikan `SLACK_DEB_URL` `.deb` resmi.
- **Discord** – default **Snap**; alternatif `.deb` resmi via `DISCORD_DEB_URL` (redirect API).
- **Signal** – menambahkan **repo APT resmi** (file `.sources`) lalu `apt install signal-desktop`.
- **Element** – default **repo APT** `packages.element.io` (stabil). Alternatif **Snap** dengan `ELEMENT_FROM=snap`.
- **Zoom** – `.deb` resmi (opsi `ZOOM_DEB_URL`), auto‑update manual.
- **Skype** – repo APT resmi `repo.skype.com` → `apt install skypeforlinux`.
- **Mattermost Desktop** – **Snap** (stabil lintas versi) atau `.deb` rilis terbaru.
- **Rocket.Chat Desktop** – **Snap**.
- **Viber** – `.deb` resmi `viber.deb`.
- **Teams (PWA)** – opsional pasang **Microsoft Edge** repo dan buat `.desktop` shortcut ke `https://teams.microsoft.com`.
- **WhatsApp (PWA)** – buat `.desktop` shortcut ke `https://web.whatsapp.com` (opsional gunakan Chrome/Edge mode `--app=`).

---

## 🧪 Verifikasi Cepat

Setelah instalasi, jalankan:
```bash
telegram-desktop --version || true
signal-desktop --version || true
element-desktop --version || true
slack --version || true
discord --version || true
zoom --version || true
skypeforlinux --version || true
weechat --version || true
pidgin --version || true
```

Shortcut PWA (Teams/WhatsApp) akan muncul di menu aplikasi (kategori **Internet**).

---

## ⚠️ Catatan & Legal

- **WhatsApp/Teams** pada Linux berjalan via **PWA (web)**; beberapa fitur (mis. panggilan) dapat terbatas.
- Aplikasi pihak‑ketiga (WhatsApp Electron, teams-for-linux) **tidak resmi**; gunakan dengan risiko Anda.
- Beberapa aplikasi proprietary mensyaratkan akun/telepon aktif untuk pairing (Signal, Viber, WhatsApp).
- Skrip ini **tidak memodifikasi** server/perangkat Anda di luar instalasi paket dan file `.desktop` PWA.

---

## 🧾 Lisensi & Kontribusi

- Lisensi repo utama mengikuti berkas `LICENSE` Anda.
- Pull Request diterima untuk penambahan aplikasi atau perbaikan metode pemasangan.

_TenRusli – Ubuntu Messaging installers (selective, forward‑looking setup)._ 