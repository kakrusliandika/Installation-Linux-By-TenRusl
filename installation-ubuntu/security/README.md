# 🛡️ Ubuntu Security – Basic & Pro

Modul **security** ini menyiapkan **keamanan host** di Ubuntu **22.04 (Jammy)** & **24.04 (Noble)**. Semua skrip **selektif** (pilih‑pasang), bukan memasang semuanya.

> Folder: `installation-ubuntu/security/`  
> Berisi: `basic.sh`, `pro.sh`, dan README ini.

---

## ✨ Ringkas
- **basic.sh** → dasar-dasar defensif: firewall (**UFW/Gufw**), **Fail2ban**, **ClamAV**, **Lynis** (audit), **rkhunter** & **chkrootkit**, **AppArmor tools**, **unattended‑upgrades**, **needrestart** (opsional), serta util keamanan umum.
- **pro.sh** → observabilitas & hardening lanjut: **osquery**, **CrowdSec** (IPS/IDS kolaboratif), **Falco** (runtime security), **AIDE** (file‑integrity), **auditd**, tool keamanan tambahan; semuanya **opsional** dan bisa dikombinasikan.

Semua pemasangan **best‑effort**: skrip akan lanjut walau ada paket yang gagal, lalu merangkum hasilnya.

---

## ✅ Prasyarat
- Ubuntu 22.04/24.04, akses `sudo`, koneksi internet.
- Untuk opsi repo pihak ketiga, pastikan koneksi HTTPS ke repositori resmi dapat diakses.
- (Opsional) `snapd` bila memilih metode Snap di komponen tertentu.

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

3) **Mode non‑interaktif** – tetapkan pilihan melalui `CHOICES` (dipisah spasi) + variabel opsional:
```bash
# BASIC: UFW + Gufw + Fail2ban + ClamAV + Lynis
CHOICES="UFW GUFW FAIL2BAN CLAMAV LYNIS" ./basic.sh

# PRO: Osquery + CrowdSec + Falco + AIDE + auditd
CHOICES="OSQUERY CROWDSEC FALCO AIDE AUDITD" ./pro.sh

# PRO (contoh metode alternatif)
CROWDSEC_METHOD=repo CHOICES="CROWDSEC" ./pro.sh
```

4) **Log & Ringkasan**  
- Log: `~/security-install.log`  
- Ringkasan: `~/security-summary.txt`

---

## 🧩 Pilihan Komponen

### BASIC (repo Ubuntu)
- `UFW` → **Uncomplicated Firewall** (CLI firewall host).  
- `GUFW` → GUI untuk UFW.  
- `FAIL2BAN` → pencegah brute‑force (baca log, ban IP sementara).  
- `CLAMAV` → antivirus FOSS (`clamav`, opsional `clamav-daemon`).  
- `LYNIS` → audit & hardening rekomendasi.  
- `RKHUNTER` / `CHKROOTKIT` → pemeriksaan indikasi rootkit.  
- `APPARMOR_TOOLS` → `apparmor-utils` + profil tambahan.  
- `UNATTENDED_UPGRADES` → update keamanan otomatis.  
- `NEEDRESTART` (opsional) → cek service yang perlu restart setelah update.

### PRO (lanjutan/enterprise)
- `OSQUERY` → telemetry & query OS seperti SQL.  
- `CROWDSEC` → engine & repo resmi (alternatif script resmi cepat).  
- `FALCO` → deteksi aktivitas mencurigakan (kernel/eBPF).  
- `AIDE` → deteksi perubahan berkas (file‑integrity).  
- `AUDITD` → audit Linux (syscalls, policy auditing).

> Semua **opsional** — centang sesuai kebutuhan. Untuk alat tertentu, skrip menambahkan repo resmi & key‑ring.

---

## 🔍 Verifikasi Cepat
```bash
# Firewall & hardening
ufw status verbose || true
gufw --version || true
sudo fail2ban-client status || true
freshclam --version || true
lynis show version || true
rkhunter --versioncheck || true
chkrootkit -V || true
aa-status || true

# Update otomatis & restart info
sudo unattended-upgrades --dry-run --debug || true
needrestart -v || true

# Pro / observabilitas
osqueryi --version || true
sudo systemctl status crowdsec --no-pager || true
falco --version || true
aide -v || true
auditctl -s || true
```

> **Catatan:** beberapa komponen (mis. **ClamAV daemon**, **Falco**, **CrowdSec**) menjalankan layanan systemd; cek status/versinya seperti contoh di atas.

---

## 🛡️ Tips Keamanan Singkat
- Batasi port yang dibuka; gunakan UFW rule minimal (mis. hanya SSH/VPN yang diperlukan).
- Ganti port default **bukan** satu‑satunya proteksi — tetap gunakan **Fail2ban** & kunci SSH.
- Jalankan **Lynis** secara berkala dan tinjau rekomendasi hardening.
- Terapkan **unattended‑upgrades** untuk patch keamanan rutin; tinjau **needrestart** sebelum/sesudah upgrade.
- Segmentasi jaringan & gunakan VPN untuk akses admin.

---

## ❓ Troubleshooting
- **ClamAV**: update DB pertama kali bisa memakan waktu; jika `clamav-freshclam` tidak jalan, coba `sudo systemctl restart clamav-freshclam`.
- **Falco**: pada kernel tertentu dibutuhkan headers/driver; ikuti prompt installer, atau pasang `linux-headers-$(uname -r)` sebelum instal.
- **CrowdSec**: jika memakai skrip cepat dan gagal, pakai opsi `CROWDSEC_METHOD=repo` untuk menambahkan repo `packagecloud` resmi.
- **UFW/Gufw**: jika mengonfigurasi dari jarak jauh, pastikan rule `ufw allow 22/tcp` **sebelum** `ufw enable`.
- **rkhunter/chkrootkit**: output peringatan perlu dievaluasi manual; bukan indikasi kompromi otomatis.

---

## ⚠️ Etika & Legal
Gunakan alat-alat ini **hanya** pada sistem/asset yang Anda miliki atau memiliki izin tertulis. Output audit/deteksi dapat berisi data sensitif — simpan dan bagikan secara aman.

---

_TenRusli – Ubuntu Security installers (selective, forward‑looking setup)._ 