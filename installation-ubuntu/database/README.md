# 🗄️ Ubuntu Database – Basic & Pro

Skrip ini menyiapkan **database server & tools** di Ubuntu **22.04 (Jammy)** dan **24.04 (Noble)** dengan mode **pilih‑pasang (selective)**. Anda *memilih sendiri* komponen apa yang mau diinstal — skrip **tidak** memasang semuanya sekaligus.

> Folder: `installation-ubuntu/database/`  
> Berisi: `basic.sh`, `pro.sh`, dan `README.md` ini.

---

## ✨ Ringkas
- **basic.sh** → Pasang cepat dari **repo Ubuntu** (stabil, minim konfigurasi). Opsi: PostgreSQL, MySQL, MariaDB, Redis, SQLite, serta klien CLI.  
- **pro.sh** → Pasang “power user”: tambah **repo resmi vendor** (PGDG, MariaDB, MongoDB, Redis), dan **GUI/alat** seperti **pgAdmin 4** & **DBeaver CE**; opsi pasang **SQL Server CLI (sqlcmd)**. Semua tetap **pilih‑pasang**.

> Catatan kompatibilitas:
> - **SQL Server engine**: di Ubuntu 22.04 stabil untuk SQL Server 2022; **Ubuntu 24.04 baru dukung pratinjau (2025 Preview)**. Di skrip *Pro* hanya disediakan **alat CLI** (`sqlcmd`), bukan engine.
> - **MongoDB**: tersedia di skrip *Pro* dari repo resmi (versi 8.x bila tersedia untuk rilis Ubuntu Anda).

---

## ✅ Prasyarat
- Ubuntu 22.04 atau 24.04.
- Akses `sudo` & koneksi internet.
- **Tidak** berjalan di WSL untuk layanan yang memerlukan systemd penuh (PostgreSQL, MySQL, dsb).

---

## 🚀 Cara Pakai

```bash
# 1) Jadikan executable
chmod +x basic.sh pro.sh

# 2) Mode Basic (repo Ubuntu)
./basic.sh

# 3) Mode Pro (repo vendor + GUI)
./pro.sh
```

Kedua skrip akan menampilkan **menu checklist**. Gunakan tombol **Space** untuk memilih beberapa komponen, lalu **Tab → OK** untuk memulai instalasi.

### Mode non-interaktif (opsional)
Anda bisa mengotomatisasi pilihan dengan variabel lingkungan `CHOICES` berisi kode komponen yang dipisahkan spasi:
```bash
# contoh: pasang PostgreSQL + Redis via Basic
CHOICES="POSTGRES REDIS" ./basic.sh

# contoh: Pro dengan PostgreSQL (PGDG) + pgAdmin + DBeaver + MongoDB + Redis
CHOICES="PGDG_PG PGADMIN DBEAVER MONGODB REDIS" ./pro.sh
```

---

## 🧩 Komponen yang Tersedia

### BASIC
- **POSTGRES**: `postgresql`, `postgresql-contrib`
- **MYSQL**: `mysql-server`
- **MARIADB**: `mariadb-server`
- **REDIS**: `redis-server`
- **SQLITE**: `sqlite3`
- **CLIENTS**: `postgresql-client`, `mysql-client`, `mariadb-client`, `sqlite3` (CLI)

> Basic memakai repo Ubuntu: cukup stabil untuk pemakaian umum / dev lokal.

### PRO
- **PGDG_PG**: PostgreSQL **terbaru** dari repo **PGDG** + `postgresql-contrib`
- **PGADMIN**: GUI administrasi PostgreSQL (APT resmi pgAdmin)
- **MARIADB_OFFICIAL**: MariaDB dari repo **mariadb.org**
- **MYSQL**: MySQL dari repo Ubuntu (opsi yang simpel & non‑interaktif)
- **MONGODB**: MongoDB Community (repo **repo.mongodb.org**, seri 8.x bila tersedia)
- **REDIS**: Redis dari repo **packages.redis.io**
- **SQLITE**: `sqlite3`
- **DBEAVER**: DBeaver CE (repo **dbeaver.io**)
- **SQLSERVER_TOOLS**: `mssql-tools18` (**sqlcmd** & **bcp**) + ODBC driver

> Semua komponen **opsional**: centang hanya yang Anda perlukan.

---

## 🔍 Verifikasi Cepat
```bash
# PostgreSQL
psql --version && systemctl status postgresql --no-pager

# MySQL / MariaDB
mysql --version && systemctl status mysql --no-pager || systemctl status mariadb --no-pager

# Redis
redis-server --version && systemctl status redis-server --no-pager

# SQLite
sqlite3 --version

# MongoDB (Pro)
mongod --version && systemctl status mongod --no-pager

# pgAdmin (Pro, desktop mode)
pgadmin4 --version || true

# DBeaver (Pro)
dbeaver -help | head -n 1 || true

# SQL Server CLI (Pro)
sqlcmd -? | head -n 1 || true
```

---

## 🛡️ Keamanan & Tips
- Jalankan **`mysql_secure_installation`** setelah memasang MySQL/MariaDB.
- Untuk **PostgreSQL** akses jarak jauh, atur `listen_addresses` dan `pg_hba.conf` dengan hati‑hati (default hanya lokal).
- **Redis** default hanya lokal; jika dibuka ke jaringan, aktifkan autentikasi, TLS, firewall, dan bind alamat spesifik.
- **MongoDB**: aktifkan autentikasi & role bila dipakai produksi; backup rutin dengan `mongodump`/`mongorestore` atau alat lain.
- Gunakan **user non-root** untuk aplikasi, serta **backup otomatis** sesuai kebutuhan.

---

## ❓ Troubleshooting
- **Port sudah dipakai**: periksa `ss -tulpn | grep -E ':(5432|3306|6379|27017)'`.
- **Layanan gagal start**: lihat log `journalctl -u <service> -b --no-pager`.
- **Repo kunci GPG**: bila error `NO_PUBKEY`/`SIGNATURE`, pastikan direktori `/etc/apt/keyrings/` dan file `.gpg` sudah ada & berizin benar.
- **Ubuntu 24.04 + SQL Server**: engine penuh belum stabil; gunakan container/Docker atau tetap di 22.04 untuk produksi. Skrip Pro hanya memasang **CLI**.

---

## 📄 Lisensi & Etika
- Gunakan pada aset sendiri atau dengan izin tertulis.
- Patuhi lisensi vendor (MariaDB, MongoDB, Redis, dll.).
- Kontribusi via PR/Issue dipersilakan.

_TenRusli – Ubuntu Database installers (selective, forward‑looking setup)._ 