# 🖥️ Ubuntu Remote – Basic & Pro

Modul **remote** ini menyiapkan akses jarak jauh di Ubuntu **22.04/24.04**. Semua skrip **selektif**: Anda memilih apa yang ingin dipasang (bukan semuanya).

> Folder: `installation-ubuntu/remote/`  
> Berisi: `basic.sh`, `pro.sh`, dan README ini.

---

## ✨ Ringkas
- **basic.sh** → Komponen _built‑in_ dan FOSS: **OpenSSH** (client/server), **Mosh**, **AutoSSH**, **RDP client** (Remmina/FreeRDP), **RDP server** (xRDP), **VNC** (TigerVNC server & viewer).
- **pro.sh** → Remote _power‑user/enterprise_: **Tailscale** (mesh VPN, repo resmi), **ZeroTier** (mesh VPN), **WireGuard** (tools), **OpenVPN** (client), **AnyDesk**, **TeamViewer**, **RustDesk**, **NoMachine**.

Semua pemasangan **best‑effort** (melanjutkan walau satu paket gagal), dengan **log** & **ringkasan** setelah selesai.

---

## ✅ Prasyarat
- Ubuntu 22.04 LTS (Jammy) atau 24.04 LTS (Noble).
- Akses `sudo` dan koneksi internet.
- Untuk opsi Snap/Flatpak, pastikan `snapd`/`flatpak` aktif bila dipilih.

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

3) **Mode non‑interaktif** — tetapkan komponen via `CHOICES` (pisah spasi) + variabel opsional:
```bash
# BASIC: SSH server + Mosh + Remmina (RDP) + TigerVNC viewer
CHOICES="SSH_SERVER MOSH RDP_CLIENT VNC_VIEWER" ./basic.sh

# PRO: Tailscale (repo), WireGuard, OpenVPN, AnyDesk (repo), RustDesk (.deb)
CHOICES="TAILSCALE WIREGUARD OPENVPN ANYDESK RUSTDESK" ./pro.sh

# Atur metode/URL khusus (opsional)
ZEROTIER_METHOD=snap CHOICES="ZEROTIER" ./pro.sh
TEAMVIEWER_DEB_URL="https://download.teamviewer.com/download/linux/teamviewer_amd64.deb" CHOICES="TEAMVIEWER" ./pro.sh
RUSTDESK_DEB_URL="https://example.com/rustdesk-<ver>-amd64.deb" CHOICES="RUSTDESK" ./pro.sh
NOMACHINE_DEB_URL="https://download.nomachine.com/download/8.14/Linux/nomachine_8.x_amd64.deb" CHOICES="NOMACHINE" ./pro.sh
```

4) **Log & Ringkasan**  
- Log: `~/remote-install.log`  
- Ringkasan: `~/remote-summary.txt`

---

## 🧩 Pilihan Komponen

### BASIC (repo Ubuntu)
- `SSH_CLIENT` → `openssh-client` (biasanya sudah ada).  
- `SSH_SERVER` → `openssh-server` (daemon `sshd`).  
- `MOSH` → `mosh` (shell UDP tahan roaming/putus‐sambung).  
- `AUTOSSH` → `autossh` (monitor & auto‑restart tunnel SSH).  
- `RDP_CLIENT` → `remmina` + `remmina-plugin-rdp` + `freerdp2-x11`.  
- `RDP_SERVER` → `xrdp`.  
- `VNC_SERVER` → `tigervnc-standalone-server`.  
- `VNC_VIEWER` → `tigervnc-viewer`.

### PRO (lanjutan/enterprise)
- `TAILSCALE` → repo **Tailscale (stable)**, paket `tailscale`.  
- `ZEROTIER` → **ZeroTier** (default: skrip repo resmi; opsional `ZEROTIER_METHOD=snap`).  
- `WIREGUARD` → `wireguard-tools` (`wg`, `wg-quick`).  
- `OPENVPN` → `openvpn` (+ `easy-rsa` opsional).  
- `ANYDESK` → repo APT resmi `deb.anydesk.com`.  
- `TEAMVIEWER` → `.deb` resmi (set `TEAMVIEWER_DEB_URL` bila perlu).  
- `RUSTDESK` → `.deb` resmi (set `RUSTDESK_DEB_URL`).  
- `NOMACHINE` → `.deb` resmi (set `NOMACHINE_DEB_URL`).

> Semua **opsional** — pilih sesuai kebutuhan.

---

## 🔍 Verifikasi Cepat
```bash
# SSH/Mosh/AutoSSH
sshd -T 2>/dev/null | head -n1 || true
mosh --version || true
autossh -V || true

# RDP & VNC
xfreerdp --version || true
remmina --version || true
xrdp --version || systemctl status xrdp --no-pager || true
vncviewer -h | head -n1 || true

# VPN/Remote
tailscale version || true
zerotier-cli -v || true
wg --version || true
openvpn --version | head -n1 || true
anydesk --version || true
teamviewer --version || true
rustdesk --version || true
/usr/NX/bin/nxserver --version || true
```

---

## 🛡️ Tips Keamanan Singkat
- Batasi akses jaringan (mis. `sudo ufw allow 22/tcp`, `3389/tcp`, `5901/tcp` **hanya dari IP tepercaya**).
- Gunakan autentikasi kunci SSH, matikan login password bila memungkinkan.
- Untuk xRDP/VNC, pertimbangkan tunnel via SSH/VPN.
- Jaga sistem tetap terbarui (`sudo apt update && sudo apt upgrade`).

---

## 📚 Rujukan Resmi (ringkas)
- Ubuntu: **OpenSSH server/client**.  
- Mosh.  
- Remmina/FreeRDP.  
- xRDP.  
- TigerVNC.  
- WireGuard.  
- OpenVPN.  
- Tailscale.  
- ZeroTier.  
- AnyDesk.  
- TeamViewer.  
- RustDesk.  
- NoMachine.

---

_TenRusli – Ubuntu Remote installers (selective, forward‑looking setup)._ 