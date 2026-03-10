# Installation Linux by TenRusl

Repositori ini berisi kumpulan skrip instalasi Linux yang **modular** untuk beberapa distro, dengan pola konsisten per modul:

- `basic.sh` → instalasi inti/pilihan aman.
- `pro.sh` → instalasi lanjutan/opsional.
- `README.md` → dokumentasi per modul.
- khusus `pentest` ada tambahan `modular.sh` dan `ultimate.sh`.

## Cakupan Distro

Distro yang tersedia saat ini:

1. `installation-arch`
2. `installation-debian`
3. `installation-fedora`
4. `installation-kali`
5. `installation-ubuntu`
6. `installation-xubuntu`

Semua distro di atas memiliki 17 kategori modul yang sama:

- `audio`
- `browser`
- `cloud`
- `database`
- `editor`
- `image`
- `messaging`
- `office`
- `pentest`
- `remote`
- `security`
- `servers`
- `storage`
- `streaming`
- `tools`
- `utilities`
- `virtualization`

## Struktur Global Repositori

- `README.md` (ringkasan utama)
- `CHANGELOG.md`
- `LICENSE`
- `installation-*/` (skrip per distro)

Untuk daftar isi **super lengkap** seluruh file, lihat:

- [`docs/INVENTORY_FULL.md`](docs/INVENTORY_FULL.md)

## Cara Pakai Singkat

1. Masuk ke distro target (contoh: `installation-ubuntu`).
2. Baca `README.md` di folder distro.
3. Jalankan orkestrator utama distro (umumnya `basic.sh`).
4. Jalankan per modul sesuai kebutuhan (`basic.sh`/`pro.sh`).

## Saran Pengembangan (Prioritas)

1. Tambahkan `CONTRIBUTING.md` agar kontribusi komunitas lebih terarah.
2. Tambahkan `CODE_OF_CONDUCT.md` untuk standar interaksi kolaborator.
3. Tambahkan pipeline CI sederhana untuk:
   - `shellcheck` semua skrip `.sh`
   - validasi executable bit (`chmod +x`)
   - smoke test parsing argumen pada orchestrator.
4. Tambahkan `SECURITY.md` untuk jalur pelaporan kerentanan.
5. Tambahkan dokumen matriks kompatibilitas versi distro per modul.

## Catatan

Dokumentasi ini sudah dirapikan agar tidak ada folder utama yang terlewat dari sisi inventaris. Jika Anda ingin, langkah berikutnya saya bisa bantu membuat:

- peta dependensi per modul,
- tabel package per distro per modul,
- dan checklist verifikasi pasca-instalasi per modul.
