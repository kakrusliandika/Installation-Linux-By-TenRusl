#!/usr/bin/env bash
# Ubuntu Editor — PRO (Ubuntu 22.04/24.04)
# Tambah repo resmi/vendor & editor modern. Pilih-pasang via menu.
# Non-interaktif contoh:
# CHOICES="CODE SUBLIME_TEXT VSCODIUM HELIX ZED NEOVIM_APPIMAGE" ./pro.sh

set -u -o pipefail
[ "$(id -u)" -eq 0 ] && SUDO="" || SUDO="sudo"
LOGFILE="$HOME/editor-pro-install.log"
FAILED=()
mkdir -p "$(dirname "$LOGFILE")" && : >"$LOGFILE"

log()  { printf "🔧 %s\n" "$*" | tee -a "$LOGFILE"; }
ok()   { printf "✅ %s\n" "$*" | tee -a "$LOGFILE"; }
warn() { printf "⚠️  %s\n" "$*" | tee -a "$LOGFILE"; }
run() {
  local desc="$1"; shift
  printf "⏳ %s ...\n" "$desc" | tee -a "$LOGFILE"
  if ! "$@" >>"$LOGFILE" 2>&1; then warn "Gagal: $desc"; FAILED+=("$desc"); return 1; fi
  ok "OK: $desc"
}

apt_install_one() {
  local pkg="$1"
  dpkg -s "$pkg" >/dev/null 2>&1 && { ok "APT: $pkg sudah ada"; return 0; }
  $SUDO apt-get install -y "$pkg" >>"$LOGFILE" 2>&1 || { warn "APT gagal: $pkg"; FAILED+=("apt $pkg"); return 1; }
  ok "APT: $pkg terpasang"
}

ensure_base() {
  run "apt-get update" $SUDO apt-get update -y
  apt_install_one curl || true
  apt_install_one wget || true
  apt_install_one gpg  || true
  apt_install_one ca-certificates || true
  apt_install_one apt-transport-https || true
  $SUDO mkdir -p /etc/apt/keyrings
}

ensure_snap() {
  if ! command -v snap >/dev/null 2>&1; then
    apt_install_one snapd || true
  fi
}

pick_choices() {
  if [ -n "${CHOICES:-}" ]; then
    echo "$CHOICES"; return 0
  fi

  local options=(
    CODE            "Visual Studio Code (Microsoft repo)"               OFF
    CODE_INSIDERS   "VS Code Insiders (Snap, side-by-side)"             OFF
    SUBLIME_TEXT    "Sublime Text (APT resmi)"                           OFF
    SUBLIME_MERGE   "Sublime Merge (APT resmi)"                          OFF
    VSCODIUM        "VSCodium (APT resmi proyek)"                        OFF
    HELIX           "Helix (Snap)"                                       OFF
    ZED             "Zed editor (install script resmi)"                  OFF
    NEOVIM_APPIMAGE "Neovim (latest) AppImage ke /usr/local/bin/nvim"    OFF
    JETBRAINS_TOOLBOX "JetBrains Toolbox (tar.gz → user)"                OFF
  )
  local sel
  sel=$(whiptail --title "Ubuntu Editor — PRO" \
        --checklist "Pilih komponen yang ingin dipasang:" 20 84 12 "${options[@]}" \
        3>&1 1>&2 2>&3) || exit 1
  echo "$sel"
}

# --------- Komponen ---------

install_code_ms_repo() {
  # Pakai paket repo-config resmi Microsoft lalu pasang 'code'
  local distro="ubuntu"
  local ver; ver="$(. /etc/os-release && echo "${VERSION_ID}")"
  run "Unduh paket repo Microsoft" bash -lc "curl -fsSLO https://packages.microsoft.com/config/${distro}/${ver}/packages-microsoft-prod.deb"
  run "Pasang repo Microsoft" $SUDO dpkg -i packages-microsoft-prod.deb
  run "Bersihkan file .deb" rm -f packages-microsoft-prod.deb
  run "apt-get update (Microsoft repo)" $SUDO apt-get update -y
  apt_install_one code
}

install_code_insiders_snap() {
  ensure_snap
  run "Snap code-insiders" $SUDO snap install code-insiders --classic
}

install_sublime_text_repo() {
  # Key → keyrings; sumber .sources (sesuai instruksi resmi)
  run "Import key Sublime" bash -lc 'wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | gpg --dearmor | '"$SUDO"' tee /etc/apt/keyrings/sublimehq-pub.gpg >/dev/null'
  run "Tambah sources Sublime Text" bash -lc 'printf "Types: deb\nURIs: https://download.sublimetext.com/\nSuites: apt/stable/\nSigned-By: /etc/apt/keyrings/sublimehq-pub.gpg\n" | '"$SUDO"' tee /etc/apt/sources.list.d/sublime-text.sources >/dev/null'
  run "apt-get update (Sublime)" $SUDO apt-get update -y
  apt_install_one sublime-text
}

install_sublime_merge_repo() {
  # Memakai key & sources yang sama
  run "Import key Sublime (merge)" bash -lc '[ -f /etc/apt/keyrings/sublimehq-pub.gpg ] || (wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | gpg --dearmor | '"$SUDO"' tee /etc/apt/keyrings/sublimehq-pub.gpg >/dev/null)'
  run "Pastikan sources Sublime ada" bash -lc '[ -f /etc/apt/sources.list.d/sublime-text.sources ] || printf "Types: deb\nURIs: https://download.sublimetext.com/\nSuites: apt/stable/\nSigned-By: /etc/apt/keyrings/sublimehq-pub.gpg\n" | '"$SUDO"' tee /etc/apt/sources.list.d/sublime-text.sources >/dev/null'
  run "apt-get update (Sublime)" $SUDO apt-get update -y
  apt_install_one sublime-merge
}

install_vscodium_repo() {
  run "Key VSCodium → keyrings" bash -lc 'wget -qO - https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg | gpg --dearmor | '"$SUDO"' tee /usr/share/keyrings/vscodium-archive-keyring.gpg >/dev/null'
  run "Repo VSCodium" bash -lc 'echo "deb [ signed-by=/usr/share/keyrings/vscodium-archive-keyring.gpg ] https://download.vscodium.com/debs vscodium main" | '"$SUDO"' tee /etc/apt/sources.list.d/vscodium.list >/dev/null'
  run "apt-get update (VSCodium)" $SUDO apt-get update -y
  apt_install_one codium
}

install_helix_snap() {
  ensure_snap
  run "Snap helix" $SUDO snap install helix --classic
}

install_zed_script() {
  run "Install Zed (user script)" bash -lc 'curl -fsSL https://zed.dev/install.sh | sh'
}

install_neovim_appimage() {
  local tmp="/tmp/nvim.appimage"
  run "Unduh Neovim AppImage (latest)" bash -lc 'curl -fL https://github.com/neovim/neovim/releases/latest/download/nvim.appimage -o '"$tmp"
  run "Beri izin eksekusi nvim.appimage" chmod +x "$tmp"
  run "Pasang ke /usr/local/bin/nvim" $SUDO install -m 0755 "$tmp" /usr/local/bin/nvim
  ok "Neovim tersedia: $(/usr/local/bin/nvim --version | head -n1 || true)"
}

install_jetbrains_toolbox() {
  # Unduh tar.gz resmi dan jalankan sekali; Toolbox akan instal diri ke $HOME/.local/share/JetBrains/Toolbox/bin
  local tmp="/tmp/jetbrains-toolbox.tar.gz"
  run "Unduh JetBrains Toolbox" bash -lc 'curl -fL "https://data.services.jetbrains.com/products/download?platform=linux&code=TBA" -o '"$tmp"
  run "Ekstrak Toolbox" bash -lc 'tar -xzf '"$tmp"' -C /tmp'
  local dir; dir="$(ls -d /tmp/jetbrains-toolbox-* 2>/dev/null | head -n1)"
  [ -z "$dir" ] && { warn "Folder Toolbox tidak ditemukan setelah ekstrak"; return 1; }
  run "Jalankan Toolbox pertama kali (user)" bash -lc '"$dir"'/jetbrains-toolbox --minimize || true
  ok "Toolbox dijalankan; aplikasi akan menyalin diri ke ~/.local/share/JetBrains/Toolbox/bin"
}

install_one() {
  case "$1" in
    CODE)               install_code_ms_repo ;;
    CODE_INSIDERS)      install_code_insiders_snap ;;
    SUBLIME_TEXT)       install_sublime_text_repo ;;
    SUBLIME_MERGE)      install_sublime_merge_repo ;;
    VSCODIUM)           install_vscodium_repo ;;
    HELIX)              install_helix_snap ;;
    ZED)                install_zed_script ;;
    NEOVIM_APPIMAGE)    install_neovim_appimage ;;
    JETBRAINS_TOOLBOX)  install_jetbrains_toolbox ;;
    *) warn "Lewati: opsi tidak dikenal: $1" ;;
  esac
}

main() {
  ensure_base
  local CHOSEN
  if [ -n "${CHOICES:-}" ]; then CHOSEN="$CHOICES"
  else
    local sel
    sel=$(whiptail --title "Ubuntu Editor — PRO" \
          --checklist "Pilih komponen yang ingin dipasang:" 20 84 12 \
          CODE "Visual Studio Code (Microsoft repo)" OFF \
          CODE_INSIDERS "VS Code Insiders (Snap)" OFF \
          SUBLIME_TEXT "Sublime Text (APT resmi)" OFF \
          SUBLIME_MERGE "Sublime Merge (APT resmi)" OFF \
          VSCODIUM "VSCodium (APT resmi proyek)" OFF \
          HELIX "Helix (Snap)" OFF \
          ZED "Zed editor (install script)" OFF \
          NEOVIM_APPIMAGE "Neovim (latest) AppImage" OFF \
          JETBRAINS_TOOLBOX "JetBrains Toolbox" OFF \
          3>&1 1>&2 2>&3) || exit 1
    CHOSEN=$(echo "$sel" | tr -d '"')
  fi

  log "Dipilih: $CHOSEN"
  for c in $CHOSEN; do install_one "$c"; done

  echo
  echo "==============================================="
  echo "✅ Selesai PRO. Log: $LOGFILE"
  if [ "${#FAILED[@]}" -gt 0 ]; then
    echo "⚠️  Komponen gagal: ${FAILED[*]}"
  else
    echo "🎉 Tidak ada kegagalan."
  fi
  echo "==============================================="
}
main "$@"
