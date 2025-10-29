# 🧰 Ubuntu Tools – Basic & Pro

Modul **tools** ini menyiapkan **alat CLI & util modern** untuk Ubuntu **22.04 (Jammy)** & **24.04 (Noble)**. Semua skrip **selektif** (checklist) — hanya komponen yang Anda centang yang dipasang. Fokus pada *developer‑friendly tools* seperti `ripgrep`, `fd`, `bat`, `fzf`, `jq/yq`, `eza`, `zoxide`, `gh (GitHub CLI)`, dsb.

> Folder: `installation-ubuntu/tools/`  
> Berkas: `basic.sh`, `pro.sh`, dan README ini.

---

## ✨ Ringkas
- **basic.sh** → util inti dari repo Ubuntu: core CLI (curl/wget/git/zip), editor (vim/neovim/nano), terminal (tmux), pencarian modern (**ripgrep**, **fd-find**, **bat**, **fzf**, **tldr**), jaringan (**httpie**, **iperf3**, **socat**, **dnsutils**, **net-tools**), monitoring (**htop**, **btop**), kompresi (`zstd`, `pigz`), JSON (`jq`). Termasuk **symlink kenyamanan**: `fd → fdfind`, `bat → batcat` bila perlu.
- **pro.sh** → opsi lanjut: **GitHub CLI (gh)** dari repo resmi, **yq** (snap atau URL tarball), **eza** (DEB upstream atau APT), **zoxide**, **Starship** prompt, **Oh My Zsh**, **glow** (Markdown TUI). Semua bersifat **opsional**.

Instalasi **best‑effort** — proses lanjut walau ada paket gagal, dengan **log** dan **ringkasan**.

---

## ✅ Prasyarat
- Ubuntu 22.04/24.04, akses `sudo`, koneksi internet.
- Untuk komponen **upstream** (mis. `eza`, `yq`), skrip menyediakan *environment variable* agar Anda mengontrol sumber/versi.

---

## 🚀 Cara Pakai

1) **Jadikan eksekusi**
```bash
chmod +x basic.sh pro.sh
```

2) **Mode interaktif** (checklist)
```bash
./basic.sh
./pro.sh
```
Gunakan **Space** untuk memilih, **Tab → OK** untuk lanjut.

3) **Mode non‑interaktif** — pakai `CHOICES` (pisah spasi) + variabel opsional:

```bash
# BASIC: core + editors + pencarian modern + jaringan + symlink fd/bat
CHOICES="CORE EDITORS TERMINAL FIND NET MONITOR COMPRESSION JSON TOOLS_SYMLINKS" ./basic.sh

# PRO: gh dari repo resmi + eza dari .deb upstream + yq dari URL tarball + zoxide + starship
EZA_DEB_URL="https://github.com/eza-community/eza/releases/download/v0.18.24/eza_ubuntu_jammy_amd64.deb" \
YQ_URL="https://github.com/mikefarah/yq/releases/download/v4.44.5/yq_linux_amd64.tar.gz" \
CHOICES="GH_CLI EZA YQ ZOXIDE STARSHIP" ./pro.sh

# PRO alternatif (snap): yq & glow via Snap
YQ_USE_SNAP=1 GLOW_USE_SNAP=1 CHOICES="YQ GLOW" ./pro.sh

# PRO: Oh My Zsh (non-interaktif), Starship + auto-inject ke ~/.bashrc
RUNZSH=no CHSH=no KEEP_ZSHRC=yes STARSHIP_INIT=1 CHOICES="OHMYZSH STARSHIP" ./pro.sh
```

4) **Log & Ringkasan**
- Log: `~/tools-install.log`  
- Ringkasan: `~/tools-summary.txt`

---

## 🧩 Pilihan Komponen

### BASIC (repo Ubuntu, stabil)
- `CORE` → `curl`, `wget`, `git`, `ca-certificates`, `gnupg2`, `zip`, `unzip`, `p7zip-full`, `rsync`, `tree`, `aria2`.
- `EDITORS` → `vim`, `neovim`, `nano`.
- `TERMINAL` → `tmux`.
- `FIND` → **ripgrep** (`ripgrep`), **fd** (`fd-find` → binary `fdfind`), **bat** (`bat` → binary `batcat`), **fzf**, **tldr`**.
- `JSON` → `jq`.
- `NET` → `httpie`, `iperf3`, `socat`, `dnsutils`, `net-tools`.
- `MONITOR` → `htop`, `btop`.
- `COMPRESSION` → `zstd`, `pigz`.
- `TOOLS_SYMLINKS` → Buat symlink kenyamanan: `fd` → `fdfind` dan/atau `bat` → `batcat` bila `fd`/`bat` belum ada.

> Catatan: Pada Ubuntu/Debian, `fd-find` memasang binary bernama **`fdfind`**; `bat` memasang **`batcat`**. Symlink disediakan agar perintah menjadi konsisten lintas distro.

### PRO (lanjutan)
- `GH_CLI` → **GitHub CLI** (`gh`) dari repo resmi (APT source + keyring).
- `YQ` → **yq** (YAML/JSON CLI): *default* via **Snap**; alternatif via **URL tarball** (`YQ_URL=...`) atau `apt` jika tersedia.
- `EZA` → **eza** (modern `ls`): *default* via APT (`eza` bila tersedia, fallback `exa`), atau via **DEB upstream** (`EZA_DEB_URL=...`).
- `ZOXIDE` → **zoxide** (smarter `cd`).
- `STARSHIP` → **Starship prompt** (script resmi). Opsi `STARSHIP_INIT=1` untuk menambahkan baris init ke `~/.bashrc` & `~/.zshrc` jika ada.
- `OHMYZSH` → **Oh My Zsh** (non-interaktif jika `RUNZSH=no CHSH=no KEEP_ZSHRC=yes` diset).
- `GLOW` → **glow** (Markdown TUI) via Snap (`GLOW_USE_SNAP=1`) atau APT.

---

## 🔍 Verifikasi Cepat
```bash
# pencarian modern
rg --version
fdfind --version || fd --version
batcat --version || bat --version
fzf --version

# CLI lainnya
jq --version
http --version        # httpie
iperf3 --version
tmux -V
btop -v || htop --version

# pro
gh --version
eza --version || exa --version
yq --version
zoxide --version
starship --version
glow --version
```

---

## ❓ Troubleshooting
- **`fd` tidak ditemukan** → di Ubuntu/Debian, package **fd-find** memasang binary `fdfind`. Skrip membuat **symlink `fd`** jika Anda pilih `TOOLS_SYMLINKS`.  
- **`bat` tidak ditemukan** → di Ubuntu/Debian, package `bat` memasang binary `batcat`. Skrip membuat **symlink `bat`** jika Anda pilih `TOOLS_SYMLINKS`.  
- **Snap diblokir** → gunakan opsi URL (`YQ_URL=`) untuk `yq`, atau pasang `glow` via APT jika tersedia.  
- **Starship/Oh-My-Zsh** → instalasi tidak mengubah shell default kecuali Anda mengaktifkan sendiri (`chsh`) atau menaruh init ke rc-file (`STARSHIP_INIT=1`).

---

## 🛡️ Catatan
- Skrip ini **tidak** mengubah dotfiles secara agresif; inisialisasi (`eval "$(zoxide init bash)"`, dsb.) silakan dilakukan manual atau aktifkan opsi terkait.
- Pastikan meninjau lisensi & kebijakan perusahaan sebelum memasang repo pihak ketiga.

---

_TenRusli – Ubuntu Tools installers (selective, forward‑looking setup)._ 