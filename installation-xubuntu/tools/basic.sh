#!/usr/bin/env bash
# Ubuntu Tools • BASIC (22.04/24.04)
# Komponen: core CLI, editors, tmux, ripgrep/fd/bat/fzf/tldr, jq, httpie/iperf3/socat/dnsutils/net-tools,
# htop/btop, zstd/pigz, serta symlink kenyamanan (fd→fdfind, bat→batcat).
# Contoh non-interaktif:
#   CHOICES="CORE EDITORS TERMINAL FIND JSON NET MONITOR COMPRESSION TOOLS_SYMLINKS" ./basic.sh

set -u -o pipefail
export DEBIAN_FRONTEND=noninteractive
[ "$(id -u)" -eq 0 ] && SUDO="" || SUDO="sudo"

LOG="$HOME/tools-install.log"
SUMMARY="$HOME/tools-summary.txt"
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
    out=$(whiptail --title "Ubuntu Tools • BASIC" --checklist "Pilih komponen:" 22 104 14 \
      CORE            "curl, wget, git, zip/unzip, p7zip, rsync, tree, aria2, CA/gnupg" ON  \
      EDITORS         "vim, neovim, nano"                                               ON  \
      TERMINAL        "tmux"                                                            ON  \
      FIND            "ripgrep, fd-find, bat, fzf, tldr"                                ON  \
      JSON            "jq"                                                               ON  \
      NET             "httpie, iperf3, socat, dnsutils, net-tools"                       ON  \
      MONITOR         "htop, btop"                                                       ON  \
      COMPRESSION     "zstd, pigz"                                                       ON  \
      TOOLS_SYMLINKS  "symlink: fd→fdfind, bat→batcat (jika perlu)"                      ON  \
      3>&1 1>&2 2>&3) || { echo ""; return; }
    echo "$out" | tr -d '"'
  else
    echo "${CHOICES:-CORE EDITORS TERMINAL FIND JSON NET MONITOR COMPRESSION TOOLS_SYMLINKS}"
  fi
}

# --- Implementasi komponen ---
install_CORE()         { for p in curl wget git ca-certificates gnupg2 zip unzip p7zip-full rsync tree aria2; do apt_install "$p" || true; done; }
install_EDITORS()      { apt_install vim; apt_install neovim || true; apt_install nano || true; }
install_TERMINAL()     { apt_install tmux; }
install_FIND()         { apt_install ripgrep; apt_install fd-find; apt_install bat; apt_install fzf; apt_install tldr || true; }
install_JSON()         { apt_install jq; }
install_NET()          { apt_install httpie || true; apt_install iperf3 || true; apt_install socat || true; apt_install dnsutils; apt_install net-tools; }
install_MONITOR()      { apt_install htop; apt_install btop || true; }
install_COMPRESSION()  { apt_install zstd || true; apt_install pigz || true; }
install_TOOLS_SYMLINKS() {
  # fd → fdfind
  if command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then
    $SUDO ln -sf "$(command -v fdfind)" /usr/local/bin/fd >>"$LOG" 2>&1 || warn "symlink fd gagal"
    ok "symlink fd → fdfind"
  fi
  # bat → batcat
  if command -v batcat >/dev/null 2>&1 && ! command -v bat >/dev/null 2>&1; then
    $SUDO ln -sf "$(command -v batcat)" /usr/local/bin/bat >>"$LOG" 2>&1 || warn "symlink bat gagal"
    ok "symlink bat → batcat"
  fi
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
