#!/usr/bin/env bash
# Ubuntu Cloud · BASIC
# Selective installer for common cloud & container toolchain
# Diuji pada Ubuntu 22.04/24.04 (Jammy/Noble)

set -u -o pipefail
export DEBIAN_FRONTEND=noninteractive

# ===== Konfigurasi =====
LOGFILE="$HOME/ubuntu-cloud-basic.log"
: >"$LOGFILE"
SUDO="" ; [ "$(id -u)" -eq 0 ] || SUDO="sudo"
K8S_MINOR="${K8S_MINOR:-v1.34}"         # override: K8S_MINOR=v1.33 ./basic.sh
DOCKER_CHANNEL="${DOCKER_CHANNEL:-stable}"
SKIP_DOCKER_GROUP="${SKIP_DOCKER_GROUP:-0}"

log()  { printf "🔧 %s\n" "$*" | tee -a "$LOGFILE"; }
ok()   { printf "✅ %s\n" "$*" | tee -a "$LOGFILE"; }
warn() { printf "⚠️  %s\n" "$*" | tee -a "$LOGFILE"; }
run()  {
  local desc="$1"; shift
  printf "⏳ %s ...\n" "$desc" | tee -a "$LOGFILE"
  if ! "$@" >>"$LOGFILE" 2>&1; then warn "Gagal: $desc"; return 1; fi
  ok "OK: $desc"
}


need_pkgs() {
  $SUDO apt-get update -y >>"$LOGFILE" 2>&1
  $SUDO apt-get install -y ca-certificates curl wget gnupg lsb-release \
    apt-transport-https software-properties-common unzip tar >>"$LOGFILE" 2>&1
  $SUDO install -m 0755 -d /etc/apt/keyrings
}

# ===== Komponen =====

inst_awscli() {
  if command -v aws >/dev/null 2>&1 && aws --version 2>/dev/null | grep -q "aws-cli/2"; then
    ok "AWS CLI v2 sudah ada"; return
  fi
  run "Unduh AWS CLI v2" curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
  run "Ekstrak AWS CLI v2" bash -lc 'rm -rf /tmp/aws && unzip -q /tmp/awscliv2.zip -d /tmp'
  run "Install AWS CLI v2" $SUDO /tmp/aws/install --update
}

inst_azurecli() {
  if command -v az >/dev/null 2>&1; then ok "Azure CLI sudah ada"; return; fi
  local key=/etc/apt/keyrings/microsoft.gpg
  run "Tambahkan kunci Microsoft" bash -lc "curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | $SUDO tee $key >/dev/null && $SUDO chmod go+r $key"
  local codename; codename="$(. /etc/os-release && echo "$UBUNTU_CODENAME")"
  run "Tambahkan repo Azure CLI" bash -lc "echo 'deb [arch=$(dpkg --print-architecture) signed-by=$key] https://packages.microsoft.com/repos/azure-cli/ $codename main' | $SUDO tee /etc/apt/sources.list.d/azure-cli.list >/dev/null"
  run "Install Azure CLI" $SUDO apt-get update -y && $SUDO apt-get install -y azure-cli
}

inst_gcloud() {
  if command -v gcloud >/dev/null 2>&1; then ok "Google Cloud SDK sudah ada"; return; fi
  local key=/etc/apt/keyrings/cloud.google.gpg
  run "Tambahkan kunci Google Cloud" bash -lc "curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor | $SUDO tee $key >/dev/null && $SUDO chmod go+r $key"
  run "Tambahkan repo Google Cloud" bash -lc "echo 'deb [signed-by=$key] https://packages.cloud.google.com/apt cloud-sdk main' | $SUDO tee /etc/apt/sources.list.d/google-cloud-sdk.list >/dev/null"
  run "Install Google Cloud SDK" $SUDO apt-get update -y && $SUDO apt-get install -y google-cloud-cli
}

inst_kubectl() {
  if command -v kubectl >/dev/null 2>&1; then ok "kubectl sudah ada"; return; fi
  local key=/etc/apt/keyrings/kubernetes-apt-keyring.gpg
  run "Tambahkan kunci Kubernetes" bash -lc "curl -fsSL https://pkgs.k8s.io/core:/stable:/$K8S_MINOR/deb/Release.key | gpg --dearmor | $SUDO tee $key >/dev/null && $SUDO chmod go+r $key"
  run "Tambahkan repo kubectl ($K8S_MINOR)" bash -lc "echo 'deb [signed-by=$key] https://pkgs.k8s.io/core:/stable:/$K8S_MINOR/deb/ /' | $SUDO tee /etc/apt/sources.list.d/kubernetes.list >/dev/null"
  run "Install kubectl" $SUDO apt-get update -y && $SUDO apt-get install -y kubectl
}

inst_helm() {
  if command -v helm >/dev/null 2>&1; then ok "Helm sudah ada"; return; fi
  local key=/etc/apt/keyrings/helm.gpg
  run "Tambahkan kunci Helm" bash -lc "curl -fsSL https://baltocdn.com/helm/signing.asc | gpg --dearmor | $SUDO tee $key >/dev/null && $SUDO chmod go+r $key"
  run "Tambahkan repo Helm" bash -lc "echo 'deb [signed-by=$key] https://baltocdn.com/helm/stable/debian/ all main' | $SUDO tee /etc/apt/sources.list.d/helm-stable-debian.list >/dev/null"
  run "Install Helm" $SUDO apt-get update -y && $SUDO apt-get install -y helm
}

inst_terraform() {
  if command -v terraform >/dev/null 2>&1; then ok "Terraform sudah ada"; return; fi
  local key=/etc/apt/keyrings/hashicorp.gpg
  local codename; codename="$(. /etc/os-release && echo "$VERSION_CODENAME")"
  run "Tambahkan kunci HashiCorp" bash -lc "curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor | $SUDO tee $key >/dev/null && $SUDO chmod go+r $key"
  run "Tambahkan repo HashiCorp" bash -lc "echo 'deb [arch=$(dpkg --print-architecture) signed-by=$key] https://apt.releases.hashicorp.com $codename main' | $SUDO tee /etc/apt/sources.list.d/hashicorp.list >/dev/null"
  run "Install Terraform" $SUDO apt-get update -y && $SUDO apt-get install -y terraform
}

inst_docker() {
  if command -v docker >/dev/null 2>&1; then ok "Docker sudah ada"; return; fi
  local key=/etc/apt/keyrings/docker.gpg
  local codename; codename="$(. /etc/os-release && echo "$VERSION_CODENAME")"
  run "Tambahkan kunci Docker" bash -lc "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor | $SUDO tee $key >/dev/null && $SUDO chmod go+r $key"
  run "Tambahkan repo Docker ($DOCKER_CHANNEL)" bash -lc "echo 'deb [arch=$(dpkg --print-architecture) signed-by=$key] https://download.docker.com/linux/ubuntu $codename $DOCKER_CHANNEL' | $SUDO tee /etc/apt/sources.list.d/docker.list >/dev/null"
  run "Install Docker Engine & Compose" $SUDO apt-get update -y && $SUDO apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  if [ "$SKIP_DOCKER_GROUP" != "1" ]; then
    run "Tambahkan user ke grup docker" $SUDO usermod -aG docker "$USER" || true
  fi
}

inst_rclone() {
  if command -v rclone >/dev/null 2>&1; then ok "rclone sudah ada"; return; fi
  run "Install rclone (script resmi)" bash -lc 'curl -fsSL https://rclone.org/install.sh | '"$SUDO"' bash'
}

# ===== Menu =====
menu() {
  whiptail --title "Ubuntu Cloud — BASIC" --checklist "Pilih komponen untuk dipasang" 22 78 12 \
    "awscli"     "AWS CLI v2" OFF \
    "azurecli"   "Azure CLI" OFF \
    "gcloud"     "Google Cloud SDK" OFF \
    "kubectl"    "Kubernetes CLI" ON  \
    "helm"       "Helm" ON \
    "terraform"  "Terraform" ON \
    "docker"     "Docker Engine + Compose" ON \
    "rclone"     "rclone (cloud storage)" OFF 2> /tmp/sel.$$

  SEL=$(cat /tmp/sel.$$ | tr -d '"')
  rm -f /tmp/sel.$$
}

# ===== Eksekusi =====
log "📦 Menyiapkan dependensi APT & keyrings"; need_pkgs
menu

for item in $SEL; do
  case "$item" in
    awscli)    inst_awscli ;;
    azurecli)  inst_azurecli ;;
    gcloud)    inst_gcloud ;;
    kubectl)   inst_kubectl ;;
    helm)      inst_helm ;;
    terraform) inst_terraform ;;
    docker)    inst_docker ;;
    rclone)    inst_rclone ;;
  esac
done

echo
ok "Selesai BASIC. Cek log: $LOGFILE"
[ "$SKIP_DOCKER_GROUP" != "1" ] && echo "🔁 Logout/login agar grup docker aktif."
