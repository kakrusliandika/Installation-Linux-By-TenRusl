#!/usr/bin/env bash
# Ubuntu Tools • PRO (22.04/24.04)
# Komponen: GitHub CLI (repo resmi), yq (snap/URL), eza (deb/apt), zoxide, Starship, Oh My Zsh, glow.
# Contoh non-interaktif:
#   CHOICES="GH_CLI YQ EZA ZOXIDE STARSHIP OHMYZSH GLOW" ./pro.sh
#   EZA_DEB_URL="https://github.com/eza-community/eza/releases/download/v0.18.24/eza_ubuntu_jammy_amd64.deb" CHOICES="EZA" ./pro.sh
#   YQ_USE_SNAP=1 CHOICES="YQ" ./pro.sh
#   YQ_URL="https://github.com/mikefarah/yq/releases/download/v4.44.5/yq_linux_amd64.tar.gz" CHOICES="YQ" ./pro.sh
#   RUNZSH=no CHSH=no KEEP_ZSHRC=yes STARSHIP_INIT=1 CHOICES="OHMYZSH STARSHIP" ./pro.sh

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
    out=$(whiptail --title "Ubuntu Tools • PRO" --checklist "Pilih komponen:" 22 110 14 \
      GH_CLI   "GitHub CLI (repo resmi cli.github.com)"                         ON  \
      YQ       "yq (Snap v4 atau URL tarball via YQ_URL)"                      ON  \
      EZA      "eza (APT jika ada, atau EZA_DEB_URL)"                          ON  \
      ZOXIDE   "zoxide (smarter cd)"                                           OFF \
      STARSHIP "Starship prompt (script resmi; STARSHIP_INIT=1 untuk auto-init)" OFF \
      OHMYZSH  "Oh My Zsh (RUNZSH=no CHSH=no KEEP_ZSHRC=yes untuk non-interaktif)" OFF \
      GLOW     "glow (Markdown TUI) via Snap (GLOW_USE_SNAP=1) atau APT"       OFF \
      3>&1 1>&2 2>&3) || { echo ""; return; }
    echo "$out" | tr -d '"'
  else
    echo "${CHOICES:-GH_CLI}"
  fi
}

install_GH_CLI() {
  # Repo resmi GitHub CLI
  apt_install curl; apt_install ca-certificates; apt_install gnupg
  $SUDO install -d -m 0755 /usr/share/keyrings >>"$LOG" 2>&1 || true
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | \
    $SUDO gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg >>"$LOG" 2>&1 \
    || { warn "gpg key gh gagal"; FAILED+=("gh-key"); return; }
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | \
    $SUDO tee /etc/apt/sources.list.d/github-cli.list >/dev/null
  APT_UPDATED=""
  apt_update_once
  apt_install gh
}

install_YQ() {
  local use_snap="${YQ_USE_SNAP:-0}"
  if [ "$use_snap" = "1" ] && command -v snap >/dev/null 2>&1; then
    $SUDO snap install yq --channel=v4/stable >>"$LOG" 2>&1 || { warn "snap yq gagal"; FAILED+=("yq"); }
    return
  fi
  if [ -n "${YQ_URL:-}" ]; then
    local tmpd; tmpd="$(mktemp -d)"
    curl -fsSL "$YQ_URL" -o "$tmpd/yq.tgz" >>"$LOG" 2>&1 || { warn "unduh yq gagal"; FAILED+=("yq"); return; }
    tar -xzf "$tmpd/yq.tgz" -C "$tmpd" >>"$LOG" 2>&1 || { warn "ekstrak yq gagal"; FAILED+=("yq"); return; }
    # cari binary bernama 'yq' atau 'yq_*'
    local bin; bin="$(find "$tmpd" -maxdepth 2 -type f -name 'yq*' | head -n1 || true)"
    if [ -n "$bin" ]; then
      $SUDO install -m 0755 "$bin" /usr/local/bin/yq >>"$LOG" 2>&1 || { warn "install yq gagal"; FAILED+=("yq"); return; }
      ok "yq terpasang (/usr/local/bin/yq)"
    else
      warn "binary yq tidak ditemukan"; FAILED+=("yq")
    fi
    return
  fi
  # fallback apt
  apt_install yq || { warn "yq APT mungkin tidak tersedia"; FAILED+=("yq"); }
}

install_EZA() {
  if [ -n "${EZA_DEB_URL:-}" ]; then
    local tmp="/tmp/eza.deb"
    curl -fsSL "$EZA_DEB_URL" -o "$tmp" >>"$LOG" 2>&1 || { warn "unduh eza .deb gagal"; FAILED+=("eza"); return; }
    $SUDO dpkg -i "$tmp" >>"$LOG" 2>&1 || { warn "dpkg eza gagal (coba perbaiki dep)"; $SUDO apt-get -f install -y >>"$LOG" 2>&1 || true; }
    ok "eza terpasang dari .deb"
  else
    apt_install eza || apt_install exa || { warn "eza/exa APT gagal"; FAILED+=("eza"); }
  fi
}

install_ZOXIDE() { apt_install zoxide || { warn "zoxide APT gagal"; FAILED+=("zoxide"); }; }

install_STARSHIP() {
  curl -sS https://starship.rs/install.sh | sh -s -- -y >>"$LOG" 2>&1 || { warn "install starship gagal"; FAILED+=("starship"); return; }
  if [ "${STARSHIP_INIT:-0}" = "1" ]; then
    local line_b='eval "$(starship init bash)"'
    local line_z='eval "$(starship init zsh)"'
    grep -Fq "$line_b" "$HOME/.bashrc" 2>/dev/null || echo "$line_b" >> "$HOME/.bashrc"
    if [ -f "$HOME/.zshrc" ]; then
      grep -Fq "$line_z" "$HOME/.zshrc" 2>/dev/null || echo "$line_z" >> "$HOME/.zshrc"
    fi
    ok "starship init ditambahkan ke shell rc"
  fi
}

install_OHMYZSH() {
  apt_install zsh
  RUNZSH="${RUNZSH:-no}" CHSH="${CHSH:-no}" KEEP_ZSHRC="${KEEP_ZSHRC:-yes}" \
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" >>"$LOG" 2>&1 \
    || { warn "oh-my-zsh gagal"; FAILED+=("oh-my-zsh"); return; }
  ok "Oh My Zsh terpasang (non-interaktif)"
}

install_GLOW() {
  local use_snap="${GLOW_USE_SNAP:-0}"
  if [ "$use_snap" = "1" ] && command -v snap >/dev/null 2>&1; then
    $SUDO snap install glow >>"$LOG" 2>&1 || { warn "snap glow gagal"; FAILED+=("glow"); }
  else
    apt_install glow || { warn "glow APT gagal"; FAILED+=("glow"); }
  fi
}

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
