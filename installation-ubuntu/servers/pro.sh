#!/usr/bin/env bash
# Ubuntu Servers • PRO (22.04/24.04)
# Upstream/power-user: Docker, Podman, NodeSource, PGDG, MariaDB upstream, nginx.org, Caddy, PM2, Supervisor.
# Non-interaktif contoh:
#   NODE_MAJOR=22 CHOICES="DOCKER NODEJS_NODESOURCE PGDG CADDY" ./pro.sh

set -u -o pipefail
export DEBIAN_FRONTEND=noninteractive
[ "$(id -u)" -eq 0 ] && SUDO="" || SUDO="sudo"

LOG="$HOME/servers-install.log"
SUMMARY="$HOME/servers-summary.txt"
FAILED=()
: >"$LOG"

log()  { printf "🔧 %s\n" "$*" | tee -a "$LOG"; }
ok()   { printf "✅ %s\n" "$*" | tee -a "$LOG"; }
warn() { printf "⚠️  %s\n" "$*" | tee -a "$LOG"; }

apt_update_once() {
  if [ -z "${APT_UPDATED:-}" ]; then
    $SUDO apt-get update -y >>"$LOG" 2>&1 || warn "apt update gagal (lanjut best-effort)"
    APT_UPDATED=1
  fi
}
apt_install() {
  local pkg="$1"
  apt_update_once
  if ! dpkg -s "$pkg" >/dev/null 2>&1; then
    if $SUDO apt-get install -y "$pkg" >>"$LOG" 2>&1; then ok "APT: $pkg terpasang"
    else warn "APT gagal: $pkg"; FAILED+=("$pkg"); fi
  else ok "APT: $pkg sudah ada"; fi
}

ensure_whiptail() { apt_install whiptail >/dev/null 2>&1 || true; }

choose_menu() {
  if [ -n "${CHOICES:-}" ]; then echo "$CHOICES"; return; fi
  ensure_whiptail
  if command -v whiptail >/dev/null 2>&1; then
    local out
    out=$(whiptail --title "Ubuntu Servers • PRO" --checklist "Pilih komponen untuk dipasang:" 22 100 16 \
      DOCKER            "Docker Engine + Buildx + Compose plugin (repo resmi)"             ON  \
      PODMAN            "Podman (tanpa daemon)"                                            OFF \
      NODEJS_NODESOURCE "Node.js dari NodeSource (NODE_MAJOR=20/22; default 22)"           OFF \
      PGDG              "PostgreSQL dari PGDG APT (terkini untuk rilis Ubuntu)"            OFF \
      MARIADB_UPSTREAM  "MariaDB dari repo resmi MariaDB"                                  OFF \
      NGINX_UPSTREAM    "nginx dari repo nginx.org (bukan bawaan Ubuntu)"                  OFF \
      CADDY             "Caddy (auto-HTTPS) via repo resmi"                                OFF \
      PM2_GLOBAL        "PM2 global (npm i -g pm2)"                                        OFF \
      SUPERVISOR        "Supervisor (daemonize skrip umum)"                                OFF \
      3>&1 1>&2 2>&3) || { echo ""; return; }
    echo "$out" | tr -d '"'
  else
    echo "${CHOICES:-DOCKER}"
  fi
}

# --- Upstream repos & tools ---

install_DOCKER() {
  log "🐳 Setup Docker repo & install engine"
  $SUDO install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | $SUDO gpg --dearmor -o /etc/apt/keyrings/docker.gpg >>"$LOG" 2>&1 || true
  local arch codename
  arch="$(dpkg --print-architecture)"
  codename="$(. /etc/os-release && echo "$VERSION_CODENAME")"
  echo "deb [arch=${arch} signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${codename} stable" | \
    $SUDO tee /etc/apt/sources.list.d/docker.list >/dev/null
  APT_UPDATED=""; apt_update_once
  apt_install docker-ce
  apt_install docker-ce-cli
  apt_install containerd.io
  apt_install docker-buildx-plugin
  apt_install docker-compose-plugin
  $SUDO usermod -aG docker "$USER" 2>>"$LOG" || true
}

install_PODMAN() { apt_install podman; }

install_NODEJS_NODESOURCE() {
  local major="${NODE_MAJOR:-22}"
  log "🟢 Node.js via NodeSource ${major}.x"
  curl -fsSL "https://deb.nodesource.com/setup_${major}.x" | $SUDO -E bash - >>"$LOG" 2>&1 || { warn "NodeSource setup gagal"; FAILED+=("nodesource"); return; }
  apt_install nodejs
}

install_PGDG() {
  log "🐘 Tambah PGDG repo (PostgreSQL)"
  $SUDO install -m 0755 -d /usr/share/keyrings
  curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | $SUDO gpg --dearmor -o /usr/share/keyrings/postgresql.gpg >>"$LOG" 2>&1 || true
  local codename; codename="$(. /etc/os-release && echo "$VERSION_CODENAME")"
  echo "deb [signed-by=/usr/share/keyrings/postgresql.gpg] http://apt.postgresql.org/pub/repos/apt ${codename}-pgdg main" | \
    $SUDO tee /etc/apt/sources.list.d/pgdg.list >/dev/null
  APT_UPDATED=""; apt_update_once
  # paket meta 'postgresql' akan menarik rilis PGDG default untuk OS tsb
  apt_install postgresql
}

install_MARIADB_UPSTREAM() {
  log "🪪 MariaDB upstream repo setup"
  curl -LsS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | $SUDO bash >>"$LOG" 2>&1 || { warn "mariadb_repo_setup gagal"; FAILED+=("mariadb-repo"); return; }
  APT_UPDATED=""; apt_update_once
  apt_install mariadb-server
}

install_NGINX_UPSTREAM() {
  log "🟧 nginx upstream dari nginx.org"
  $SUDO install -m 0755 -d /usr/share/keyrings
  curl -fsSL https://nginx.org/keys/nginx_signing.key | $SUDO gpg --dearmor -o /usr/share/keyrings/nginx-archive-keyring.gpg >>"$LOG" 2>&1 || true
  local codename; codename="$(. /etc/os-release && echo "$VERSION_CODENAME")"
  echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] http://nginx.org/packages/ubuntu ${codename} nginx" | \
    $SUDO tee /etc/apt/sources.list.d/nginx.list >/dev/null
  APT_UPDATED=""; apt_update_once
  apt_install nginx
}

install_CADDY() {
  log "🟦 Caddy via repo resmi"
  $SUDO install -m 0755 -d /usr/share/keyrings
  curl -fsSL https://dl.cloudsmith.io/public/caddy/stable/gpg.key | $SUDO gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg >>"$LOG" 2>&1 || true
  curl -fsSL https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt | $SUDO tee /etc/apt/sources.list.d/caddy-stable.list >/dev/null
  APT_UPDATED=""; apt_update_once
  apt_install caddy
}

install_PM2_GLOBAL() {
  if ! command -v npm >/dev/null 2>&1; then warn "npm tidak ditemukan (pasang Node.js dulu)"; FAILED+=("pm2"); return; fi
  if npm list -g pm2 >/dev/null 2>&1; then ok "PM2 sudah ada"
  else npm i -g pm2 >>"$LOG" 2>&1 && ok "PM2 terpasang" || { warn "pm2 gagal"; FAILED+=("pm2"); }
  fi
}

install_SUPERVISOR() { apt_install supervisor; }

main() {
  log "📦 PRO mulai. Log: $LOG"
  local selected; selected="$(choose_menu)"
  [ -z "$selected" ] && { warn "Tidak ada pilihan. Keluar."; exit 0; }

  apt_update_once

  for item in $selected; do
    fn="install_${item}"
    if declare -f "$fn" >/dev/null 2>&1; then "$fn"; else warn "Lewati opsi tidak dikenal: $item"; fi
  done

  {
    echo "🎯 PRO selesai."
    echo "Dipilih: $selected"
    if [ "${#FAILED[@]}" -gt 0 ]; then
      echo "⚠️  Gagal: ${FAILED[*]}"
    else
      echo "✅ Tidak ada kegagalan terdeteksi."
    fi
    echo "📄 Log: $LOG"
  } >"$SUMMARY"

  echo -e "\n✅ Selesai. Ringkasan: $SUMMARY\n"
}
main "$@"
