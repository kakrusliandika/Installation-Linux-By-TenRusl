#!/usr/bin/env bash
# Ubuntu Database • BASIC (Jammy/Noble)
# Mode pilih-pasang via checklist; repo: Ubuntu default
set -u -o pipefail
export DEBIAN_FRONTEND=noninteractive

[ "$(id -u)" -eq 0 ] && SUDO="" || SUDO="sudo"
LOG="$HOME/install-db-basic.log"
FAILED=()

log(){ printf "🔧 %s\n" "$*" | tee -a "$LOG"; }
ok(){ printf "✅ %s\n" "$*" | tee -a "$LOG"; }
warn(){ printf "⚠️  %s\n" "$*" | tee -a "$LOG"; }

apt_install(){ $SUDO apt-get install -y "$@" >>"$LOG" 2>&1 || { warn "Gagal: apt install $*"; FAILED+=("$*"); return 1; }; }

ensure_basics(){
  log "📦 apt update/upgrade + tools dasar"
  $SUDO apt-get update -y >>"$LOG" 2>&1 || true
  $SUDO apt-get upgrade -y >>"$LOG" 2>&1 || true
  apt_install ca-certificates curl gnupg lsb-release whiptail dialog
}

show_menu(){
  local out
  out=$(whiptail --title "Ubuntu Database • BASIC" --checklist "Pilih komponen untuk dipasang" 25 72 12 \
    POSTGRES "PostgreSQL (server + contrib)" OFF \
    MYSQL    "MySQL Server (Ubuntu repo)"   OFF \
    MARIADB  "MariaDB Server (Ubuntu repo)" OFF \
    REDIS    "Redis Server (Ubuntu repo)"   OFF \
    SQLITE   "SQLite CLI"                   OFF \
    CLIENTS  "Klien: psql/mysql/sqlite3"    ON \
    3>&1 1>&2 2>&3) || exit 1
  # Hasil whiptail punya tanda kutip; bersihkan
  CHOICES=${out//\"/}
}

install_postgres(){ log "🐘 PostgreSQL (Ubuntu repo)"; apt_install postgresql postgresql-contrib; $SUDO systemctl enable --now postgresql >>"$LOG" 2>&1 || true; }
install_mysql(){ log "🟦 MySQL Server (Ubuntu repo)"; apt_install mysql-server; $SUDO systemctl enable --now mysql >>"$LOG" 2>&1 || true; }
install_mariadb(){ log "🟩 MariaDB Server (Ubuntu repo)"; apt_install mariadb-server; $SUDO systemctl enable --now mariadb >>"$LOG" 2>&1 || true; }
install_redis(){ log "🟥 Redis Server (Ubuntu repo)"; apt_install redis-server; $SUDO systemctl enable --now redis-server >>"$LOG" 2>&1 || true; }
install_sqlite(){ log "🧱 SQLite CLI"; apt_install sqlite3; }
install_clients(){ log "🧰 DB clients"; apt_install postgresql-client mysql-client mariadb-client sqlite3; }

summary(){
  echo -e "\n====================================="
  if [ "${#FAILED[@]}" -gt 0 ]; then
    warn "Komponen gagal: ${FAILED[*]}"
  else
    ok "Selesai tanpa error mayor."
  fi
  echo "📄 Log: $LOG"
  echo "🔍 Cek versi cepat:"
  echo "  - psql --version | mysql --version | sqlite3 --version | redis-server --version"
  echo "====================================="
}

main(){
  : >"$LOG"
  ensure_basics
  if [ -z "${CHOICES:-}" ]; then show_menu; fi
  for item in $CHOICES; do
    case "$item" in
      POSTGRES) install_postgres ;;
      MYSQL)    install_mysql ;;
      MARIADB)  install_mariadb ;;
      REDIS)    install_redis ;;
      SQLITE)   install_sqlite ;;
      CLIENTS)  install_clients ;;
    esac
  done
  summary
}

main "$@"
