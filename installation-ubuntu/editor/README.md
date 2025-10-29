# 📝 Ubuntu Editor – Basic & Pro

Skrip ini menyiapkan **editor & IDE** di Ubuntu **22.04 (Jammy)** dan **24.04 (Noble)** dengan mode **pilih‑pasang (selective)**. Anda tinggal **centang** komponen yang ingin dipasang — skrip **tidak** memasang semuanya.

> Folder: `installation-ubuntu/editor/`  
> Berisi: `basic.sh`, `pro.sh`, dan `README.md` ini.

---

## ✨ Ringkas
- **basic.sh** → Editor dari **repo Ubuntu** (stabil & ringan): Vim, Neovim, Emacs, Micro, Gedit/Kate, dsb.  
- **pro.sh** → “Power user”: tambah **repo resmi/vendor** (VS Code, Sublime Text/Merge, VSCodium), **JetBrains Toolbox**, **Helix**, **Zed**; opsi **Neovim AppImage (latest)**. Semua tetap **pilih‑pasang**.

> Referensi resmi:
> - VS Code untuk Linux (APT/.deb auto-repo).  
> - Sublime Text/Merge repo APT.  
> - VSCodium repo APT (third‑party yang direkomendasikan proyek).  
> - Neovim (wiki resmi).  
> - Helix (docs resmi + Snap).  
> - Zed (docs resmi, install script).  
> - Microsoft Linux repository (repo config `.deb` untuk paket Microsoft).

---

## ✅ Prasyarat
- Ubuntu 22.04 atau 24.04.
- Akses `sudo` & koneksi internet.
- Untuk opsi **Snap** (Helix/Code Insiders opsional), pastikan `snapd` aktif.

---

## 🚀 Cara Pakai

```bash
# 1) Jadikan executable
chmod +x basic.sh pro.sh

# 2) Mode Basic (repo Ubuntu)
./basic.sh

# 3) Mode Pro (repo vendor + editor modern)
./pro.sh
```

Kedua skrip akan menampilkan **menu checklist**. Gunakan **Space** untuk memilih beberapa komponen, lalu **Tab → OK** untuk mulai instalasi.

### Mode non‑interaktif (opsional)
Set variabel `CHOICES` berisi **kode komponen** dipisah spasi:
```bash
# Basic: pasang Vim + Neovim + Emacs + Micro
CHOICES="VIM NEOVIM EMACS MICRO" ./basic.sh

# Pro: VS Code + Sublime Text + VSCodium + Helix + Zed + Neovim AppImage
CHOICES="CODE SUBLIME_TEXT VSCODIUM HELIX ZED NEOVIM_APPIMAGE" ./pro.sh
```

---

## 🧩 Opsi Komponen

### BASIC (repo Ubuntu)
- `VIM` → `vim`
- `NEOVIM` → `neovim`
- `EMACS` → `emacs` (GUI)  
- `EMACS_NOX` → `emacs-nox` (terminal only)
- `MICRO` → `micro` (CLI editor)
- `GEDIT` → `gedit`
- `KATE` → `kate`

### PRO (vendor & modern)
- `CODE` → **Visual Studio Code** (Microsoft repo)
- `CODE_INSIDERS` → **VS Code Insiders** (Snap)
- `SUBLIME_TEXT` → **Sublime Text** (APT resmi)
- `SUBLIME_MERGE` → **Sublime Merge** (APT resmi)
- `VSCODIUM` → **VSCodium** (APT resmi proyek)
- `HELIX` → **Helix** (Snap)
- `ZED` → **Zed** (install script resmi)
- `NEOVIM_APPIMAGE` → **Neovim (latest)** via AppImage

> Semua **opsional** — centang hanya yang Anda perlukan.

---

## 🔍 Verifikasi Cepat
```bash
vim --version | head -n1 || true
nvim --version | head -n1 || true
emacs --version | head -n1 || true
micro --version || true
gedit --version || true
kate --version || true
code --version || true
codium --version || true
subl --version || true            # Sublime Text
smerge --version || true          # Sublime Merge
hx --version || true              # Helix
zed --version || true             # Zed
```

---

## ❓ Troubleshooting
- **GPG key / `signed-by`**: kalau muncul error repo, pastikan file keyring ada di `/etc/apt/keyrings/` dan izin **644**; jalankan `sudo apt-get update` ulang.
- **Snap tidak ada**: `sudo apt install snapd` lalu re‑login; jalankan ulang opsi Snap (Helix/Insiders).
- **VS Code**: `.deb` Microsoft biasanya **otomatis** menambahkan repo; atau gunakan paket repo config `packages-microsoft-prod.deb` (lihat dokumen Microsoft).
- **JetBrains Toolbox**: saat pertama jalan, dia akan **instal diri** ke `~/.local/share/JetBrains/Toolbox/bin` dan menambahkan shortcut desktop otomatis.
- **Neovim AppImage**: butuh izin eksekusi (`chmod +x`) & **FUSE** di distro lama; di Ubuntu modern biasanya langsung jalan.

---

## 📄 Lisensi & Catatan
- Gunakan sesuai lisensi vendor dan kebijakan organisasi.
- Beberapa paket (Sublime Text/Merge) **proprietary** namun tersedia via repo resmi.
- Skrip dirancang **idempotent**; aman dijalankan ulang untuk melengkapi instalasi.

_TenRusli – Ubuntu Editor installers (selective, forward‑looking setup)._ 