#!/usr/bin/env bash
# Ubuntu Servers • BASIC (22.04/24.04)
# Pilih-pasang komponen server dari repo Ubuntu (stabil).
# Non-interaktif contoh:
#   CHOICES="NGINX PHP_FPM MARIADB REDIS CERTBOT_SNAP" ./basic.sh

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
    out=$(whiptail --title "Ubuntu Servers • BASIC" --checklist "Pilih komponen untuk dipasang:" 22 96 16 \
      NGINX           "Web server/reverse proxy (nginx)"                                     ON  \
      APACHE          "Web server (apache2)"                                                 OFF \
      PHP_FPM         "PHP-FPM + ekstensi umum + Composer"                                   ON  \
      MYSQL           "MySQL Server"                                                         OFF \
      MARIADB         "MariaDB Server"                                                       OFF \
      POSTGRESQL      "PostgreSQL (repo Ubuntu)"                                             OFF \
      REDIS           "Redis Server"                                                         ON  \
      MEMCACHED       "Memcached"                                                            OFF \
      NODEJS_UBUNTU   "Node.js dari repo Ubuntu"                                             OFF \
      PYTHON_TOOLS    "python3-pip, python3-venv, pipx (opsional)"                           OFF \
      JAVA_OPENJDK    "default-jdk (OpenJDK)"                                                OFF \
      GO              "golang (toolchain Go)"                                                OFF \
      CERTBOT_SNAP    "Certbot via Snap (rekomendasi untuk TLS di Nginx/Apache)"             OFF \
      3>&1 1>&2 2>&3) || { echo ""; return; }
    echo "$out" | tr -d '"'
  else
    echo "${CHOICES:-NGINX PHP_FPM REDIS}"
  fi
}

# --- Komponen ---
install_NGINX()      { apt_install nginx; }
install_APACHE()     { apt_install apache2; }

install_PHP_FPM() {
  apt_install php-fpm
  apt_install php-cli
  for ext in curl mbstring xml zip intl gd; do apt_install "php-$ext" || true; done
  # Composer dari repo Ubuntu (cukup untuk umum)
  apt_install composer || true
}

install_MYSQL()      { apt_install mysql-server; }
install_MARIADB()    { apt_install mariadb-server; }
install_POSTGRESQL() { apt_install postgresql; }
install_REDIS()      { apt_install redis-server; }
install_MEMCACHED()  { apt_install memcached; }
install_NODEJS_UBUNTU() { apt_install nodejs; }
install_PYTHON_TOOLS()  { apt_install python3-pip; apt_install python3-venv; apt_install pipx || true; }
install_JAVA_OPENJDK()  { apt_install default-jdk; }
install_GO()            { apt_install golang; }

install_CERTBOT_SNAP() {
  if ! command -v snap >/dev/null 2>&1; then apt_install snapd; fi
  if ! snap list certbot >/dev/null 2>&1; then
    $SUDO snap install --classic certbot >>"$LOG" 2>&1 || warn "Snap certbot gagal"; 
    $SUDO ln -sf /snap/bin/certbot /usr/bin/certbot 2>>"$LOG" || true
  fi
  ok "Certbot (snap) terpasang"
}

main() {
  log "📦 BASIC mulai. Log: $LOG"
  local selected; selected="$(choose_menu)"
  [ -z "$selected" ] && { warn "Tidak ada pilihan. Keluar."; exit 0; }

  for item in $selected; do
    fn="install_${item}"
    if declare -f "$fn" >/dev/null 2>&1; then "$fn"; else warn "Lewati opsi tidak dikenal: $item"; fi
  done

  {
    echo "🎯 BASIC selesai."
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
