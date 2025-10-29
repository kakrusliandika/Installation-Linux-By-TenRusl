# 💾 Ubuntu Storage – Basic & Pro

Modul **storage** ini menyiapkan utilitas **filesystem, sharing, RAID/LVM, enkripsi, backup & NAS/object storage** di Ubuntu **22.04 (Jammy)** & **24.04 (Noble)**. Semua skrip **selektif** (checklist) — hanya yang Anda pilih yang akan dipasang. Cocok untuk desktop teknis, server kecil, hingga home‑lab/NAS.

> Folder: `installation-ubuntu/storage/`  
> Berisi: `basic.sh`, `pro.sh`, dan README ini.

---

## ✨ Ringkas
- **basic.sh** → tool dasar dari repo Ubuntu: alat filesystem (ext4/xfs/btrfs/exFAT/NTFS), **LVM2**, **mdadm** (RAID software), **cryptsetup LUKS**, **Samba/NFS/SSHFS** (file sharing & mount), **restic**/**borgbackup**/**rclone** (backup & sinkronisasi), **smartmontools/nvme-cli/hdparm** (health & tuning), kompresi (`zstd`, `pigz`, `p7zip`).
- **pro.sh** → opsi lanjut: **ZFS** (OpenZFS, util `zfsutils-linux`), **mergerfs** (union FS), **SnapRAID** (parity untuk media), **iSCSI target/initiator** (`targetcli-fb`/`open-iscsi`), **GlusterFS** (server/klien), **Ceph client** (`ceph-common`), **MinIO server** (S3‑compatible), plus CLI S3 (`awscli`, `s3cmd`).

Instalasi **best‑effort** — proses lanjut walau ada paket gagal, dengan **log** & **ringkasan**.

---

## ✅ Prasyarat
- Ubuntu 22.04/24.04, akses `sudo`, koneksi internet.
- Untuk *upstream* (MinIO/mergerfs .deb, dsb), skrip memberi opsi URL/versi agar Anda kontrol sumber.
- Pastikan **backup** sebelum mengubah partisi/RAID/enkripsi.

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
# BASIC: LVM + mdadm + Samba server + NFS server + restic + smartmontools
CHOICES="LVM2 MDADM SAMBA_SERVER NFS_SERVER RESTIC SMARTMONTOOLS" ./basic.sh

# PRO: ZFS + mergerfs (.deb dari GitHub) + SnapRAID + iSCSI target + MinIO
MERGERFS_DEB_URL="https://github.com/trapexit/mergerfs/releases/download/2.36.0/mergerfs_2.36.0.ubuntu-jammy_amd64.deb" \
MINIO_TGZ_URL="https://dl.min.io/server/minio/release/linux-amd64/archive/minio_20241020.000000.0_linux_amd64.tgz" \
CHOICES="ZFS MERGERFS SNAPRAID ISCSI_TARGET MINIO_SERVER" ./pro.sh

# Alternatif GlusterFS & Ceph client
CHOICES="GLUSTERFS_SERVER GLUSTERFS_CLIENT CEPH_CLIENT" ./pro.sh
```

4) **Log & Ringkasan**
- Log: `~/storage-install.log`  
- Ringkasan: `~/storage-summary.txt`

---

## 🧩 Pilihan Komponen

### BASIC (repo Ubuntu, stabil)
- `FILESYSTEM_TOOLS` → `xfsprogs`, `btrfs-progs`, `exfatprogs`, `ntfs-3g`, `dosfstools`, `e2fsprogs`, `parted`, `gdisk`, `util-linux` (mkfs/fsck/partisi umum).  
- `LVM2` → manajemen volume fleksibel (`lvm2`).  
- `MDADM` → **software RAID** (`mdadm`).  
- `CRYPTSETUP` → enkripsi **LUKS/dm‑crypt** (`cryptsetup`).  
- `SAMBA_SERVER` / `SAMBA_CLIENT` → berbagi berkas (Server: `samba`; Client: `cifs-utils`, `smbclient`).  
- `NFS_SERVER` / `NFS_CLIENT` → berbagi via NFS (`nfs-kernel-server`, `nfs-common`).  
- `SSHFS` → mount via SSH (`sshfs`).  
- `RESTIC` → backup modern terotentikasi ke berbagai backend.  
- `BORGBACKUP` → backup deduplikasi (Borg 1.x).  
- `RCLONE` → sinkronisasi cloud & S3.  
- `SMARTMONTOOLS` / `NVME_CLI` / `HDPARM` → pemantauan & util disk.  
- `COMPRESSION_TOOLS` → `zstd`, `pigz`, `p7zip-full`.

### PRO (lanjutan/enterprise)
- `ZFS` → **OpenZFS** utilitas (`zfsutils-linux`; opsional modul DKMS).  
- `MERGERFS` → union FS (APT *atau* `.deb` upstream via `MERGERFS_DEB_URL`).  
- `SNAPRAID` → parity untuk kumpulan disk media (APT).  
- `ISCSI_TARGET` / `ISCSI_INITIATOR` → iSCSI (`targetcli-fb`, `open-iscsi`).  
- `GLUSTERFS_SERVER` / `GLUSTERFS_CLIENT` → storage terdistribusi.  
- `CEPH_CLIENT` → paket klien Ceph (`ceph-common`).  
- `MINIO_SERVER` → server object storage S3‑compatible (tarball resmi via `MINIO_TGZ_URL`).  
- `S3_TOOLS` → `awscli` dan/atau `s3cmd`.

> Semua **opsional** — pilih sesuai kebutuhan & kebijakan produksi Anda.

---

## 🔍 Verifikasi Cepat
```bash
# Filesystem & util
lsblk -f
lvm version || true
mdadm --version || true
cryptsetup --version || true

# Sharing
smbd --version || true
nfsstat -s || true
sshfs -V || true

# Backup & cloud
restic version || true
borg --version || true
rclone version || true

# Disk health
smartctl --version || true
nvme version || true

# Pro
zfs --version || true
mergerfs -v || true
snapraid --version || true
targetcli --version || true
iscsiadm --version || true
gluster --version || true
ceph --version || true
minio --version || true
```

---

## 🛡️ Catatan & Tips
- **Backup dulu** sebelum mengubah partisi/RAID/enkripsi.  
- **Samba/NFS**: pastikan firewall & UID/GID sesuai. Untuk akses publik, sandbox direktori secara ketat.  
- **ZFS** cocok untuk dataset besar/snapshots; **mdadm+LVM** tetap relevan untuk skenario sederhana.  
- **mergerfs+SnapRAID** lazim untuk arsip media (tahan beberapa kegagalan disk, bukan HA).  
- **MinIO** menyediakan API S3 di lokal; simpan kredensial dengan aman.  
- **Uji restore** backup (restic/borg) secara berkala — backup tanpa restore ≠ backup.

---

## 📚 Rujukan Resmi / Kredibel
- **OpenZFS on Ubuntu** — `zfsutils-linux` ada di Ubuntu; aktifkan *universe* lalu `apt install zfsutils-linux`. [openzfs-docs]  
- **mdadm (software RAID)** — panduan pembuatan array di Ubuntu. [digitalocean-mdadm]  
- **LVM di Ubuntu** — dokumentasi server resmi. [ubuntu-docs-lvm]  
- **LUKS/cryptsetup** — man page & docs keamanan Ubuntu. [man-cryptsetup] [ubuntu-security-luks]  
- **Samba** — tutorial resmi Ubuntu; klien `smbclient` (manpage). [ubuntu-samba] [smbclient-man]  
- **NFS** — dokumentasi Ubuntu Server. [ubuntu-nfs]  
- **SSHFS** — wiki & paket Launchpad. [ubuntu-sshfs-wiki] [sshfs-launchpad]  
- **restic** — opsi paket/binary resmi. [restic-install]  
- **BorgBackup** — instalasi. [borg-install]  
- **rclone** — instalasi & unduhan resmi. [rclone-install]  
- **SnapRAID** — situs & manual resmi (parity untuk disk array). [snapraid-home] [snapraid-manual]  
- **iSCSI** — initiator `open-iscsi` & target `targetcli-fb`. [ubuntu-iscsi-init] [serverworld-iscsi-target]  
- **GlusterFS** — quickstart/instal Ubuntu. [do-gluster]  
- **MinIO** — panduan setup & repo resmi. [do-minio] [minio-github]  
- **SMART/NVMe** — smartmontools & nvme‑cli. [smartmontools-doc] [nvme-cli-man]

[openzfs-docs]: https://openzfs.github.io/openzfs-docs/Getting%20Started/Ubuntu/index.html
[digitalocean-mdadm]: https://www.digitalocean.com/community/tutorials/how-to-create-raid-arrays-with-mdadm-on-ubuntu
[ubuntu-docs-lvm]: https://documentation.ubuntu.com/server/explanation/storage/about-lvm/
[man-cryptsetup]: https://man7.org/linux/man-pages/man8/cryptsetup.8.html
[ubuntu-security-luks]: https://documentation.ubuntu.com/security/docs/security-features/storage/encryption-full-disk/
[ubuntu-samba]: https://ubuntu.com/tutorials/install-and-configure-samba
[smbclient-man]: https://www.samba.org/samba/docs/current/man-html/smbclient.1.html
[ubuntu-nfs]: https://documentation.ubuntu.com/server/how-to/networking/install-nfs/
[ubuntu-sshfs-wiki]: https://help.ubuntu.com/community/SSHFS
[sshfs-launchpad]: https://launchpad.net/ubuntu/jammy/%2Bpackage/sshfs
[restic-install]: https://restic.readthedocs.io/en/latest/020_installation.html
[borg-install]: https://borgbackup.readthedocs.io/en/stable/installation.html
[rclone-install]: https://rclone.org/install/
[snapraid-home]: https://www.snapraid.it/
[snapraid-manual]: https://www.snapraid.it/manual
[ubuntu-iscsi-init]: https://documentation.ubuntu.com/server/how-to/storage/iscsi-initiator-or-client/
[serverworld-iscsi-target]: https://www.server-world.info/en/note?f=1&os=Ubuntu_22.04&p=iscsi
[do-gluster]: https://www.digitalocean.com/community/tutorials/how-to-create-a-redundant-storage-pool-using-glusterfs-on-ubuntu-20-04
[do-minio]: https://www.digitalocean.com/community/tutorials/how-to-set-up-minio-object-storage-server-in-standalone-mode-on-ubuntu-20-04
[minio-github]: https://github.com/minio/minio
[smartmontools-doc]: https://www.smartmontools.org/wiki/TocDoc
[nvme-cli-man]: https://manpages.ubuntu.com/manpages/noble/man1/nvme.1.html

_TenRusli – Ubuntu Storage installers (selective, forward‑looking setup)._ 