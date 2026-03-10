#!/usr/bin/env bash
# Ubuntu Cloud · PRO
# Tambahan power tools untuk Kubernetes/DevOps
set -u -o pipefail
export DEBIAN_FRONTEND=noninteractive

LOGFILE="$HOME/ubuntu-cloud-pro.log"
: >"$LOGFILE"
SUDO="" ; [ "$(id -u)" -eq 0 ] || SUDO="sudo"
K8S_MINOR="${K8S_MINOR:-v1.34}"

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
  $SUDO apt-get install -y ca-certificates curl wget gnupg lsb-release apt-transport-https unzip tar >>"$LOGFILE" 2>&1
  $SUDO install -m 0755 -d /etc/apt/keyrings
}

inst_kubectl_repo() {  # dipakai beberapa utilitas
  [ -f /etc/apt/sources.list.d/kubernetes.list ] && return 0
  local key=/etc/apt/keyrings/kubernetes-apt-keyring.gpg
  run "Tambahkan repo kubectl ($K8S_MINOR)" bash -lc "curl -fsSL https://pkgs.k8s.io/core:/stable:/$K8S_MINOR/deb/Release.key | gpg --dearmor | $SUDO tee $key >/dev/null && $SUDO chmod go+r $key && echo 'deb [signed-by=$key] https://pkgs.k8s.io/core:/stable:/$K8S_MINOR/deb/ /' | $SUDO tee /etc/apt/sources.list.d/kubernetes.list >/dev/null && $SUDO apt-get update -y"
}

inst_minikube() {
  if command -v minikube >/dev/null 2>&1; then ok "Minikube sudah ada"; return; fi
  run "Install Minikube" bash -lc 'curl -fsSL https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 -o /tmp/minikube && chmod +x /tmp/minikube && '"$SUDO"' mv /tmp/minikube /usr/local/bin/minikube'
}

inst_kind() {
  if command -v kind >/dev/null 2>&1; then ok "kind sudah ada"; return; fi
  run "Install kind" bash -lc 'curl -fsSL https://kind.sigs.k8s.io/dl/latest/kind-linux-amd64 -o /tmp/kind && chmod +x /tmp/kind && '"$SUDO"' mv /tmp/kind /usr/local/bin/kind'
}

inst_k9s() {
  if command -v k9s >/dev/null 2>&1; then ok "k9s sudah ada"; return; fi
  if command -v snap >/dev/null 2>&1; then
    run "Install k9s (snap)" $SUDO snap install k9s --devmode || true
  fi
  command -v k9s >/dev/null 2>&1 || run "Install k9s (fallback .deb terbaru)" bash -lc 'ver=$(curl -fsSL https://api.github.com/repos/derailed/k9s/releases/latest | grep -Po "\"tag_name\": *\"v?\K[^\"]+") && curl -fsSL -o /tmp/k9s.deb "https://github.com/derailed/k9s/releases/download/v${ver}/k9s_linux_amd64.deb" && '"$SUDO"' apt-get install -y /tmp/k9s.deb'
}

inst_kubectx_kubens() {
  if command -v kubectx >/dev/null 2>&1 && command -v kubens >/dev/null 2>&1; then ok "kubectx/kubens sudah ada"; return; fi
  if command -v snap >/dev/null 2>&1; then
    run "Install kubectx (snap)" $SUDO snap install kubectx --classic || true
  fi
  # fallback via git
  if ! command -v kubectx >/dev/null 2>&1; then
    run "Install kubectx/kubens (git symlink)" bash -lc 'git clone --depth=1 https://github.com/ahmetb/kubectx ~/.kubectx 2>/dev/null || true; mkdir -p ~/.local/bin; ln -sf ~/.kubectx/kubectx ~/.local/bin/kubectx; ln -sf ~/.kubectx/kubens ~/.local/bin/kubens'
  fi
}

inst_podman_suite() {
  if command -v podman >/dev/null 2>&1 && command -v buildah >/dev/null 2>&1 && command -v skopeo >/dev/null 2>&1; then ok "Podman+Buildah+Skopeo sudah ada"; return; fi
  run "Install Podman+Buildah+Skopeo" $SUDO apt-get install -y podman buildah skopeo
}

inst_eksctl() {
  if command -v eksctl >/dev/null 2>&1; then ok "eksctl sudah ada"; return; fi
  run "Install eksctl" bash -lc 'curl -fsSL "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar -xz -C /tmp && '"$SUDO"' mv /tmp/eksctl /usr/local/bin/eksctl'
}

inst_doctl() {
  if command -v doctl >/dev/null 2>&1; then ok "doctl sudah ada"; return; fi
  if command -v snap >/dev/null 2>&1; then
    run "Install doctl (snap)" $SUDO snap install doctl
    run "Connect snap interfaces" bash -lc "$SUDO snap connect doctl:kube-config || true; $SUDO snap connect doctl:ssh-keys :ssh-keys || true; $SUDO snap connect doctl:dot-docker || true"
  else
    run "Install doctl (tarball)" bash -lc 'url=$(curl -fsSL https://api.github.com/repos/digitalocean/doctl/releases/latest | grep -Po "\"browser_download_url\": *\"[^\"]*linux-amd64\.tar\.gz\"" | head -1 | cut -d\" -f4); curl -fsSL "$url" -o /tmp/doctl.tgz && tar -xzf /tmp/doctl.tgz -C /tmp && '"$SUDO"' mv /tmp/doctl /usr/local/bin/doctl'
  fi
}

inst_gke_auth_plugin() {
  # membutuhkan repo cloud-sdk aktif
  if dpkg -s google-cloud-sdk-gke-gcloud-auth-plugin >/dev/null 2>&1; then ok "GKE auth plugin sudah ada"; return; fi
  run "Install GKE gcloud auth plugin" $SUDO apt-get install -y google-cloud-sdk-gke-gcloud-auth-plugin
}

inst_aks_kubelogin() {
  if command -v az >/dev/null 2>&1; then
    run "az aks install-cli (kubectl + kubelogin)" az aks install-cli || true
  else
    warn "Azure CLI belum terpasang, lewati kubelogin"
  fi
}

# ===== Menu =====
menu() {
  whiptail --title "Ubuntu Cloud — PRO" --checklist "Pilih komponen PRO" 22 78 14 \
    "minikube"   "Minikube (K8s lokal)" OFF \
    "kind"       "kind (K8s in Docker)" OFF \
    "k9s"        "Kubernetes TUI" OFF \
    "kubectx"    "kubectx/kubens" OFF \
    "podman"     "Podman + Buildah + Skopeo" OFF \
    "eksctl"     "eksctl (Amazon EKS)" OFF \
    "doctl"      "DigitalOcean CLI" OFF \
    "gkeauth"    "GKE gcloud auth plugin" OFF \
    "akskube"    "AKS kubelogin via az" OFF 2> /tmp/sel.$$

  SEL=$(cat /tmp/sel.$$ | tr -d '"')
  rm -f /tmp/sel.$$
}

# ===== Eksekusi =====
log "📦 Menyiapkan dependensi"; need_pkgs
inst_kubectl_repo || true
menu

for item in $SEL; do
  case "$item" in
    minikube) inst_minikube ;;
    kind)     inst_kind ;;
    k9s)      inst_k9s ;;
    kubectx)  inst_kubectx_kubens ;;
    podman)   inst_podman_suite ;;
    eksctl)   inst_eksctl ;;
    doctl)    inst_doctl ;;
    gkeauth)  inst_gke_auth_plugin ;;
    akskube)  inst_aks_kubelogin ;;
  esac
done


echo
ok "Selesai PRO. Cek log: $LOGFILE"
echo "ℹ️  Beberapa komponen (Minikube/kind) memerlukan Docker/driver yang aktif."
