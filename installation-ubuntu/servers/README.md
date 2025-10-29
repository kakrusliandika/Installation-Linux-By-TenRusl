# 🧰 Ubuntu Servers – Basic & Pro

Modul **servers** ini menyiapkan tumpukan server populer di Ubuntu **22.04 (Jammy)** & **24.04 (Noble)**. Semua skrip **selektif** (checklist), jadi **hanya** komponen yang Anda pilih yang akan dipasang. Cocok untuk web stack umum (Nginx/Apache, PHP/Node/Python/Java), database (MySQL/MariaDB/PostgreSQL), cache (Redis/Memcached), serta container (Docker/Podman) dan TLS otomatis (Certbot/Caddy).

> Folder: `installation-ubuntu/servers/`  
> Berisi: `basic.sh`, `pro.sh`, dan README ini.

---

## ✨ Ringkas
- **basic.sh** → paket **repo Ubuntu** yang stabil: **Nginx**, **Apache**, **PHP‑FPM** (+ ekstensi umum & Composer), **MySQL**/**MariaDB**, **PostgreSQL**, **Redis**, **Memcached**, **Node.js** (repo Ubuntu), **Python** (pip/venv), **Java (OpenJDK)**, **Go**, **Certbot (snap)** opsional.
- **pro.sh** → opsi **power user / upstream**: **Docker Engine + Compose (repo resmi)**, **Podman**, **Node.js (NodeSource)**, **PostgreSQL (PGDG repo)**, **MariaDB (repo resmi)**, **Nginx (repo nginx.org)**, **Caddy (auto‑HTTPS)**, **PM2**/**Supervisor**, plus util pendukung. Semua **opsional** & dapat dikombinasikan.

Instalasi bersifat **best‑effort**: proses tetap lanjut dan membuat **log** & **ringkasan**.

---

## ✅ Prasyarat
- Ubuntu 22.04/24.04, akses `sudo`, koneksi internet.
- Untuk **Certbot**, rekomendasi resmi adalah via **Snap** (bukan APT) pada Ubuntu modern.
- Untuk repository pihak ketiga (Docker/PGDG/MariaDB/nginx.org/Caddy/NodeSource), pastikan dapat mengunduh kunci GPG & sumber APT.

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

3) **Mode non‑interaktif** – tetapkan via `CHOICES="..."` (kode dipisah spasi) + variabel opsional:
```bash
# BASIC contoh: Nginx + PHP‑FPM + MariaDB + Redis + Certbot
CHOICES="NGINX PHP_FPM MARIADB REDIS CERTBOT_SNAP" ./basic.sh

# PRO contoh: Docker + NodeSource (LTS 22) + PGDG + Caddy
NODE_MAJOR=22 CHOICES="DOCKER NODEJS_NODESOURCE PGDG CADDY" ./pro.sh

# MariaDB via repo resmi (pro)
CHOICES="MARIADB_UPSTREAM" ./pro.sh

# Nginx upstream (nginx.org) alih‑alih bawaan Ubuntu (pro)
CHOICES="NGINX_UPSTREAM" ./pro.sh
```

4) **Log & Ringkasan**  
- Log: `~/servers-install.log`  
- Ringkasan: `~/servers-summary.txt`

---

## 🧩 Pilihan Komponen

### BASIC (repo Ubuntu, aman & stabil)
- `NGINX` → `nginx` (web server/reverse proxy).  
- `APACHE` → `apache2` (web server).  
- `PHP_FPM` → `php-fpm` + ekstensi umum (`php-cli`, `php-{curl,mbstring,xml,zip,intl,gd}`) + **Composer**.  
- `MYSQL` → `mysql-server`.  
- `MARIADB` → `mariadb-server`.  
- `POSTGRESQL` → `postgresql`.  
- `REDIS` → `redis-server`.  
- `MEMCACHED` → `memcached`.  
- `NODEJS_UBUNTU` → `nodejs` dari repo Ubuntu.  
- `PYTHON_TOOLS` → `python3-pip`, `python3-venv`, `pipx` (opsional).  
- `JAVA_OPENJDK` → `default-jdk` (OpenJDK).  
- `GO` → `golang`.  
- `CERTBOT_SNAP` → Certbot via **snap** (rekomendasi).

### PRO (upstream/enterprise & komponen tambahan)
- `DOCKER` → **Docker Engine + Buildx + Compose plugin** (repo resmi Docker).  
- `PODMAN` → `podman` (container engine tanpa daemon).  
- `NODEJS_NODESOURCE` → Node.js dari **NodeSource** (`NODE_MAJOR=20/22`, default 22).  
- `PGDG` → **PostgreSQL** dari **PGDG APT** (versi terkini untuk rilis Ubuntu).  
- `MARIADB_UPSTREAM` → MariaDB dari **repo resmi MariaDB**.  
- `NGINX_UPSTREAM` → nginx dari **repo nginx.org**.  
- `CADDY` → **Caddy** (auto‑TLS) dari repo resmi.  
- `PM2_GLOBAL` → manajer proses Node.js (`npm i -g pm2`).  
- `SUPERVISOR` → `supervisor` (umum untuk daemonize skrip).

> Semua **opsional** — pilih sesuai kebutuhan **per host**.

---

## 🔍 Verifikasi Cepat
```bash
# Web
nginx -v || true
apache2 -v || true
caddy -v || true

# PHP & Composer
php -v || true
php-fpm -v || true
composer --version || true

# DB
mysql --version || mariadb --version || true
psql --version || true
redis-server --version || true
memcached -V || true

# Runtime & Container
node -v || true
python3 --version || true
java -version || true
go version || true
docker --version || true
podman --version || true
```

---

## 🛡️ Catatan & Tips
- **Pilih satu** web server utama per host (mis. Nginx **atau** Apache **atau** Caddy).  
- Untuk **TLS**, Certbot (snap) cocok untuk Nginx/Apache; **Caddy** dapat mengelola HTTPS otomatis.  
- Untuk DB, jangan pasang **MySQL & MariaDB** bersamaan pada host yang sama kecuali Anda paham konfliknya (port/socket).  
- Sesuaikan **firewall** (UFW/Security Group) untuk port 80/443/5432/6379 dst sesuai komponen yang dipakai.

---

## 📚 Rujukan Resmi
- **Docker Engine on Ubuntu (APT resmi)**.  
- **PostgreSQL Apt Repository (PGDG)** & **Ubuntu Server docs: PostgreSQL**.  
- **NodeSource Node.js binaries (Ubuntu)**.  
- **MariaDB: repository setup & APT**.  
- **Certbot di Ubuntu (snap, disarankan)**.  
- **nginx: Linux packages (nginx.org)**.  
- **Caddy: install Debian/Ubuntu**.

---

_TenRusli – Ubuntu Servers installers (selective, forward‑looking setup)._ 