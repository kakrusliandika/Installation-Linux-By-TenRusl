#!/usr/bin/env bash
# Ubuntu Database • PRO (Jammy/Noble)
# Mode pilih-pasang; sumber resmi: PGDG, MariaDB, MongoDB, Redis, pgAdmin, DBeaver, Microsoft (tools)
set -u -o pipefail
export DEBIAN_FRONTEND=noninteractive

[ "$(id -u)" -eq 0 ] && SUDO="" || SUDO="sudo"
LOG="$HOME/install-db-pro.log"
FAILED=()
CODENAME="$({ . /etc/os-release 2>/dev/null && echo "${UBUNTU_CODENAME:-}"; } || lsb_release -cs)"

log(){ printf "🔧 %s\n" "$*" | tee -a "$LOG"; }
ok(){ printf "✅ %s\n" "$*" | tee -a "$LOG"; }
warn(){ printf "⚠️  %s\n" "$*" | tee -a "$LOG"; }

apt_install(){ $SUDO apt-get install -y "$@" >>"$LOG" 2>&1 || { warn "Gagal: apt install $*"; FAILED+=("$*"); return 1; }; }

ensure_basics(){
  log "📦 apt update/upgrade + tools dasar"
  $SUDO apt-get update -y >>"$LOG" 2>&1 || true
  $SUDO apt-get upgrade -y >>"$LOG" 2>&1 || true
  apt_install ca-certificates curl gnupg lsb-release whiptail dialog
  $SUDO mkdir -p /etc/apt/keyrings
  $SUDO chmod 755 /etc/apt/keyrings
}

# ---------- Repositories ----------
add_pgdg(){
  log "🐘 Tambah repo PGDG (PostgreSQL)"
  curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor | $SUDO tee /etc/apt/keyrings/postgresql.gpg >/dev/null
  echo "deb [signed-by=/etc/apt/keyrings/postgresql.gpg] https://apt.postgresql.org/pub/repos/apt ${CODENAME}-pgdg main" | $SUDO tee /etc/apt/sources.list.d/pgdg.list >/dev/null
}

add_pgadmin_repo(){
  log "🧭 Tambah repo pgAdmin 4"
  curl -fsS https://www.pgadmin.org/static/packages_pgadmin_org.pub | gpg --dearmor | $SUDO tee /etc/apt/keyrings/packages-pgadmin-org.gpg >/dev/null
  echo "deb [signed-by=/etc/apt/keyrings/packages-pgadmin-org.gpg] https://ftp.postgresql.org/pub/pgadmin/pgadmin4/apt/${CODENAME} pgadmin4 main" | $SUDO tee /etc/apt/sources.list.d/pgadmin4.list >/dev/null
}

add_mariadb(){
  log "🟩 Jalankan mariadb_repo_setup (auto buat sumber APT)"
  curl -LsS https://r.mariadb.com/downloads/mariadb_repo_setup | $SUDO bash -s -- --os-type=ubuntu --os-version="${CODENAME}"
}

add_mongodb(){
  log "🍃 Tambah repo MongoDB (org) 8.0 (jika tersedia untuk ${CODENAME})"
  curl -fsSL https://pgp.mongodb.com/server-8.0.asc | gpg --dearmor | $SUDO tee /etc/apt/keyrings/mongodb-server-8.0.gpg >/dev/null
  echo "deb [signed-by=/etc/apt/keyrings/mongodb-server-8.0.gpg] https://repo.mongodb.org/apt/ubuntu ${CODENAME}/mongodb-org/8.0 multiverse" | $SUDO tee /etc/apt/sources.list.d/mongodb-org-8.0.list >/dev/null
}

add_redis(){
  log "🟥 Tambah repo Redis resmi (packages.redis.io)"
  curl -fsSL https://packages.redis.io/gpg | $SUDO gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg
  $SUDO chmod 644 /usr/share/keyrings/redis-archive-keyring.gpg
  echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" | $SUDO tee /etc/apt/sources.list.d/redis.list >/dev/null
}

add_dbeaver(){
  log "🪪 Tambah repo DBeaver CE"
  $SUDO wget -qO /usr/share/keyrings/dbeaver.gpg.key https://dbeaver.io/debs/dbeaver.gpg.key
  echo "deb [signed-by=/usr/share/keyrings/dbeaver.gpg.key] https://dbeaver.io/debs/dbeaver-ce /" | $SUDO tee /etc/apt/sources.list.d/dbeaver.list >/dev/null
}

add_ms_tools_repo(){
  log "🟦 Tambah repo Microsoft untuk mssql-tools18 (sqlcmd/bcp)"
  if [ "$CODENAME" = "noble" ]; then
    curl -sSL -O https://packages.microsoft.com/config/ubuntu/24.04/packages-microsoft-prod.deb
    $SUDO dpkg -i packages-microsoft-prod.deb >>"$LOG" 2>&1 || true
    rm -f packages-microsoft-prod.deb
  else
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | $SUDO tee /etc/apt/trusted.gpg.d/microsoft.asc >/dev/null
    curl -fsSL "https://packages.microsoft.com/config/ubuntu/22.04/prod.list" | $SUDO tee /etc/apt/sources.list.d/mssql-release.list >/dev/null
  fi
}

# ---------- Installers ----------
install_pgdg_pg(){ add_pgdg; $SUDO apt-get update -y >>"$LOG" 2>&1; apt_install postgresql postgresql-contrib; $SUDO systemctl enable --now postgresql >>"$LOG" 2>&1 || true; }
install_pgadmin(){ add_pgadmin_repo; $SUDO apt-get update -y >>"$LOG" 2>&1; apt_install pgadmin4 || apt_install pgadmin4-desktop || true; }
install_mariadb(){ add_mariadb; $SUDO apt-get update -y >>"$LOG" 2>&1; apt_install mariadb-server mariadb-backup; $SUDO systemctl enable --now mariadb >>"$LOG" 2>&1 || true; }
install_mysql(){ log "MySQL (Ubuntu repo)"; $SUDO apt-get update -y >>"$LOG" 2>&1; apt_install mysql-server; $SUDO systemctl enable --now mysql >>"$LOG" 2>&1 || true; }
install_mongodb(){ add_mongodb; $SUDO apt-get update -y >>"$LOG" 2>&1; apt_install mongodb-org; $SUDO systemctl enable --now mongod >>"$LOG" 2>&1 || true; }
install_redis(){ add_redis; $SUDO apt-get update -y >>"$LOG" 2>&1; apt_install redis; $SUDO systemctl enable --now redis-server >>"$LOG" 2>&1 || true; }
install_sqlite(){ log "SQLite CLI"; apt_install sqlite3; }
install_dbeaver(){ add_dbeaver; $SUDO apt-get update -y >>"$LOG" 2>&1; apt_install dbeaver-ce; }
install_sqlserver_tools(){
  add_ms_tools_repo
  $SUDO apt-get update -y >>"$LOG" 2>&1
  apt_install mssql-tools18 unixodbc-dev
  grep -q "/opt/mssql-tools18/bin" "$HOME/.bashrc" 2>/dev/null || echo 'export PATH="$PATH:/opt/mssql-tools18/bin"' >> "$HOME/.bashrc"
}

install_clients(){ log "DB clients umum"; apt_install postgresql-client mysql-client mariadb-client sqlite3; }

# ---------- UI ----------
show_menu(){
  local out
  out=$(whiptail --title "Ubuntu Database • PRO" --checklist "Pilih komponen untuk dipasang" 28 84 14 \
    PGDG_PG   "PostgreSQL (PGDG repo, latest)" OFF \
    PGADMIN   "pgAdmin 4 (GUI PostgreSQL)"     OFF \
    MARIADB   "MariaDB (repo resmi)"           OFF \
    MYSQL     "MySQL (Ubuntu repo)"            OFF \
    MONGODB   "MongoDB Community (repo resmi)" OFF \
    REDIS     "Redis (packages.redis.io)"      OFF \
    SQLITE    "SQLite CLI"                      OFF \
    DBEAVER   "DBeaver CE (multi-DB GUI)"      OFF \
    CLIENTS   "Klien umum (psql/mysql/sqlite)" ON  \
    SQLSERVER_TOOLS "SQL Server CLI (sqlcmd/bcp)" OFF \
    3>&1 1>&2 2>&3) || exit 1
  CHOICES=${out//\"/}
}

summary(){
  echo -e "\n====================================="
  if [ "${#FAILED[@]}" -gt 0 ]; then
    warn "Komponen gagal: ${FAILED[*]}"
  else
    ok "Selesai tanpa error mayor."
  fi
  echo "📄 Log: $LOG"
  echo "🔍 Cek cepat:"
  echo "  - psql --version | mysql --version | sqlite3 --version | redis-server --version | mongod --version | sqlcmd -?"
  echo "====================================="
}

main(){
  : >"$LOG"
  ensure_basics
  if [ -z "${CHOICES:-}" ]; then show_menu; fi
  $SUDO apt-get update -y >>"$LOG" 2>&1 || true
  for item in $CHOICES; do
    case "$item" in
      PGDG_PG)          install_pgdg_pg ;;
      PGADMIN)          install_pgadmin ;;
      MARIADB)          install_mariadb ;;
      MYSQL)            install_mysql ;;
      MONGODB)          install_mongodb ;;
      REDIS)            install_redis ;;
      SQLITE)           install_sqlite ;;
      DBEAVER)          install_dbeaver ;;
      CLIENTS)          install_clients ;;
      SQLSERVER_TOOLS)  install_sqlserver_tools ;;
    esac
  done
  summary
}

main "$@"
