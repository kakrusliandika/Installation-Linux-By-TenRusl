# ☁️ Ubuntu Cloud – Basic & Pro

Skrip pada folder **installation-ubuntu/cloud** membantu menyiapkan ekosistem *cloud & container* di Ubuntu **22.04/24.04** dengan dua mode:

- `basic.sh` → Toolkit umum untuk *cloud developers* (AWS/Azure/GCP CLI, Docker, Terraform, kubectl, Helm, rclone).
- `pro.sh` → Tambahan *power tools* untuk workflow Kubernetes/DevOps (Minikube, kind, k9s, kubectx/kubens, Podman+Buildah+Skopeo, eksctl, doctl, plugin auth GKE/AKS).

Semua pemasangan bersifat **selective** (Anda memilih komponen yang ingin diinstal). Skrip **idempotent** semampunya (skip jika sudah terpasang) dan mencatat proses ke log.

---

## ✅ Prasyarat

- Ubuntu 22.04 LTS (Jammy) atau 24.04 LTS (Noble).
- Akses `sudo` dan koneksi internet stabil.
- Disarankan: ruang kosong ≥ 5–10 GB (image/container & SDK).

---

## 🚀 Cara Pakai

> Letakkan `basic.sh` dan `pro.sh` di direktori:
>
> `C:\laragon\www\Installation-Linux-By-TenRusl\installation-ubuntu\cloud\`

```bash
# jadikan eksekusi
chmod +x basic.sh pro.sh

# jalankan (mode interaktif pilih komponen)
./basic.sh
# atau
./pro.sh
```

Skrip akan menampilkan menu **checkbox** untuk memilih komponen yang diinstal. Proses akan berjalan *best-effort* (mencoba lanjut walau beberapa langkah gagal).

---

## 📦 Cakupan Komponen

### Basic
- **AWS CLI v2** – manajemen AWS dari terminal.
- **Azure CLI** – manajemen Azure & AKS.
- **Google Cloud SDK (gcloud, gsutil, bq)** – manajemen GCP.
- **kubectl** – klien Kubernetes (repo `pkgs.k8s.io`).
- **Helm** – package manager Kubernetes.
- **Terraform** – IaC HashiCorp melalui repo resmi.
- **Docker Engine + Compose plugin** – container runtime umum.
- **rclone** – sinkronisasi/backup ke berbagai cloud storage.

### Pro
- **Minikube** – klaster K8s lokal (dev/test).
- **kind** – K8s in Docker (alternatif Minikube).
- **k9s** – *TUI* untuk Kubernetes.
- **kubectx/kubens** – ganti *context/namespace* cepat.
- **Podman + Buildah + Skopeo** – toolchain container *daemonless*.
- **eksctl** – *one‑stop CLI* untuk Amazon EKS.
- **doctl** – CLI resmi DigitalOcean.
- **GKE auth plugin** – `google-cloud-sdk-gke-gcloud-auth-plugin`.
- **AKS kubelogin** – via `az aks install-cli` (mengunduh `kubelogin`).

> Catatan: Beberapa komponen Pro memerlukan Docker/VM driver yang sudah siap (mis. untuk Minikube/kind).

---

## ⚙️ Opsi & Variabel Lingkungan

- **Versi minor kubectl**: `K8S_MINOR=v1.34 ./basic.sh`  
  (default `v1.34`; sesuaikan dengan versi cluster Anda ±1 minor).
- **Channel Docker**: `DOCKER_CHANNEL=stable|test` (default: `stable`).
- **Nonaktifkan penambahan grup docker**: `SKIP_DOCKER_GROUP=1`.

---

## 🔍 Verifikasi Cepat

```bash
aws --version        # AWS CLI
az version           # Azure CLI
gcloud version       # Google Cloud SDK
kubectl version --client
helm version
terraform -version
docker --version && docker compose version
rclone version
# (Pro)
minikube version || kind version
k9s version || true
kubectx -h && kubens -h || true
podman --version && buildah --version && skopeo --version || true
eksctl version || true
doctl version || true
```

---

## ❓ Troubleshooting

- **Kunci GPG / repository APT**  
  Jika terjadi error *NO_PUBKEY* atau *signature verification*, hapus ulang keyring terkait pada `/etc/apt/keyrings/` lalu jalankan skrip lagi.

- **kubectl tidak cocok versi cluster**  
  Gunakan `K8S_MINOR` untuk menarget minor version yang sesuai (mis. `v1.33` atau `v1.34`).

- **Minikube/kind gagal start**  
  Pastikan *container runtime* (Docker/Podman) aktif dan user Anda sudah tergabung di grup `docker` (logout/login).

- **Snap (k9s / doctl / kubectx)**  
  Beberapa paket Pro memakai Snap. Pastikan `snapd` aktif dan lakukan koneksi interface yang dibutuhkan (skrip akan mengupayakan otomatis).

---

## 🔐 Keamanan & Etika

- Perintah `curl | bash` hanya dipakai untuk installer resmi (rclone, dsb). Tinjau skrip sebelum eksekusi di lingkungan sensitif.
- Jalankan hanya pada mesin yang Anda kelola/izinkan.
- Simpan kredensial cloud secara aman (AWS/Azure/GCP/DO).

---


## 📚 Referensi Resmi (ringkas)

- AWS CLI v2 – *Installing or updating* (aws.amazon.com)
- Azure CLI di Linux/Ubuntu (learn.microsoft.com)
- Google Cloud SDK & GKE auth plugin (cloud.google.com)
- Docker Engine di Ubuntu (docs.docker.com)
- kubectl Linux & repo `pkgs.k8s.io` (kubernetes.io)
- Helm (helm.sh)
- Terraform via repo HashiCorp (developer.hashicorp.com)
- rclone install (rclone.org)
- Minikube (minikube.sigs.k8s.io)
- kind (kind.sigs.k8s.io)
- k9s (github.com/derailed/k9s)
- kubectx/kubens (github.com/ahmetb/kubectx)
- Podman/Buildah/Skopeo (podman.io)
- eksctl (docs.aws.amazon.com / github.com/eksctl-io/eksctl)
- doctl (docs.digitalocean.com)

---

_TenRusli – Ubuntu Cloud installers (selective, forward‑looking setup)._ 