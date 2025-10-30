#!/usr/bin/env bash
# Orchestrator • Installation-Linux-By-TenRusl • Ubuntu (22.04/24.04)
# Fungsi: launcher semua modul (audio, browser, cloud, dst.)
# Mode: interaktif TUI (whiptail) & headless/CI (argumen + env).
# Prinsip: idempoten, best-effort, logging & summary konsisten.

set -u -o pipefail
export LC_ALL=C
export DEBIAN_FRONTEND=noninteractive

# ===== Konfigurasi umum =====
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
REPO_ROOT="$SCRIPT_DIR"    # folder 'installation-ubuntu'
LOG_DEFAULT="$HOME/orchestrator-install.log"
SUMMARY_DEFAULT="$HOME/orchestrator-summary.txt"

LOG="${LOG_DEFAULT}"
SUMMARY="${SUMMARY_DEFAULT}"
FAILED_STEPS=()

# ===== Util logging =====
ts() { date +"%Y-%m-%d %H:%M:%S"; }
log()  { printf "[%s] 🔧 %s\n" "$(ts)" "$*" | tee -a "$LOG"; }
ok()   { printf "[%s] ✅ %s\n" "$(ts)" "$*" | tee -a "$LOG"; }
warn() { printf "[%s] ⚠️  %s\n" "$(ts)" "$*" | tee -a "$LOG"; }

run() {
  local desc="$1"; shift
  printf "[%s] ⏳ %s ...\n" "$(ts)" "$desc" | tee -a "$LOG"
  if ! "$@" >>"$LOG" 2>&1; then
    warn "Gagal: $desc"
    FAILED_STEPS+=("$desc")
    return 1
  fi
  ok "OK: $desc"
}

# ===== APT helpers =====
APT_UPDATED=""
apt_update_once() {
  if [ -z "$APT_UPDATED" ]; then
    run "apt-get update" sudo -n true 2>/dev/null || true
    run "apt-get update (noninteractive)" sudo apt-get update -y || true
    APT_UPDATED=1
  fi
}
apt_install() {
  local pkg="$1"
  apt_update_once
  dpkg -s "$pkg" >/dev/null 2>&1 && { ok "APT: $pkg sudah ada"; return 0; }
  if sudo apt-get install -y "$pkg"; then
    ok "APT: $pkg terpasang"
  else
    warn "APT gagal: $pkg"
    FAILED_STEPS+=("apt:$pkg")
    return 1
  fi
}

# ===== Preflight =====
have_cmd() { command -v "$1" >/dev/null 2>&1; }

check_sudo() {
  if [ "$(id -u)" -eq 0 ]; then
    ok "Berjalan sebagai root"
  else
    if sudo -v >/dev/null 2>&1; then ok "sudo siap"
    else warn "sudo diperlukan untuk memasang paket"; exit 1; fi
  fi
}

detect_os() {
  local id= unknown=0 ver=
  if [ -r /etc/os-release ]; then
    # os-release: gunakan ID & VERSION_ID (sesuai spesifikasi)
    # Lihat: freedesktop.org os-release (gunakan ID/VERSION_ID untuk deteksi)
    # dan manpages Ubuntu tentang os-release.
    # (Rujukan: di README root)
    # shellcheck disable=SC1091
    . /etc/os-release
    id="${ID:-}"
    ver="${VERSION_ID:-}"
    if [ "$id" != "ubuntu" ]; then
      warn "OS terdeteksi: $PRETTY_NAME (ID=$id). Target skrip: Ubuntu 22.04/24.04."
    fi
    case "$ver" in
      22.04|24.04) ok "Dukungan OS: Ubuntu $ver";;
      *) warn "Versi OS: ${ver:-tidak terdeteksi}. Lanjut best-effort.";;
    esac
  else
    warn "Tidak menemukan /etc/os-release; lanjut best-effort."
  fi
}

check_network() {
  if ping -c1 -W2 8.8.8.8 >/dev/null 2>&1 || curl -fsI https://archive.ubuntu.com >/dev/null 2>&1; then
    ok "Koneksi jaringan OK"
  else
    warn "Koneksi jaringan bermasalah — instalasi bisa gagal."
  fi
}

# ===== UI (whiptail) =====
ensure_whiptail() {
  if have_cmd whiptail; then return 0; fi
  # pasang whiptail bila belum ada (interaktif), bila gagal tetap fallback headless
  apt_install whiptail || true
}

tui_choose_modules() {
  ensure_whiptail
  if ! have_cmd whiptail; then echo ""; return 0; fi
  local out
  out=$(whiptail --title "TenRusli • Ubuntu Orchestrator" --checklist "Pilih modul yang ingin dijalankan" 22 110 16 \
    audio          "Audio desktop/studio"                        OFF \
    browser        "Peramban & codec"                            OFF \
    cloud          "CLI/SDK cloud"                               OFF \
    database       "Klien DB & util"                             OFF \
    editor         "Editor & SDK"                                OFF \
    image          "Alat pengolah gambar"                        OFF \
    messaging      "Chat/VoIP"                                   OFF \
    office         "Office suite & PDF"                          OFF \
    pentest        "Pentest (best-effort + etika)"               OFF \
    remote         "SSH/RDP/VNC & klien remote"                  OFF \
    security       "Hardening & scanner"                         OFF \
    servers        "Server stack dasar"                          OFF \
    storage        "Disk/backup/sync"                            OFF \
    streaming      "OBS/FFmpeg/GStreamer"                        OFF \
    tools          "CLI modern (jq, fzf, gh, yq, ...)"           OFF \
    utilities      "Util desktop & sistem (TLP, Timeshift...)"   OFF \
    virtualization "KVM/libvirt, Boxes, Multipass, VBox, LXD"    OFF \
    3>&1 1>&2 2>&3) || { echo ""; return 0; }
  echo "$out" | tr -d '"'
}

tui_choose_mode() {
  ensure_whiptail
  if ! have_cmd whiptail; then echo "basic"; return 0; fi
  local out
  out=$(whiptail --title "TenRusli • Mode Instalasi" --radiolist "Pilih mode:" 15 70 3 \
    basic  "Mode BASIC untuk semua modul terpilih"  ON \
    pro    "Mode PRO   untuk semua modul terpilih"  OFF \
    prompt "Pilih BASIC/PRO per modul"              OFF \
    3>&1 1>&2 2>&3) || { echo "basic"; return 0; }
  echo "$out" | tr -d '"'
}

tui_choose_mode_per_module() {
  local module="$1"; ensure_whiptail
  if ! have_cmd whiptail; then echo "basic"; return 0; fi
  local out
  out=$(whiptail --title "Modul: $module" --radiolist "Pilih mode untuk modul '$module':" 15 70 2 \
    basic "Mode BASIC" ON \
    pro   "Mode PRO"   OFF \
    3>&1 1>&2 2>&3) || { echo "basic"; return 0; }
  echo "$out" | tr -d '"'
}

# ===== Argumen =====
MODULES=""
GLOBAL_MODE=""
ASSUME_YES=0
GLOBAL_CHOICES=""
PER_MODULE_CHOICES=""
SHOW_HELP=0

print_help() {
cat <<'HLP'
Usage: ./basic.sh [opsi] [--] [ENV=...]
  -m, --module <list>            Daftar modul dipisah koma (audio,tools,virtualization,...)
  -M, --mode <basic|pro|prompt>  Mode untuk modul; 'prompt' = pilih per modul
  -y, --yes                      Non-interaktif penuh (lewati TUI)
      --choices "<STR>"          CHOICES global untuk semua modul
      --module-choices "mod=STR;mod2=STR2"  CHOICES spesifik per modul
      --log <PATH>               Lokasi log (default: ~/orchestrator-install.log)
      --summary <PATH>           Lokasi ringkasan (default: ~/orchestrator-summary.txt)
  -h, --help                     Tampilkan bantuan

Contoh:
  ./basic.sh                                # TUI penuh
  ./basic.sh -m tools,utilities -M pro -y --choices "GH_CLI YQ EZA ZOXIDE"
  ./basic.sh -m virtualization -M prompt -y --module-choices "virtualization=KVM_CORE VIRT_MANAGER OVMF CLOUD_IMAGE"
HLP
}

while [ $# -gt 0 ]; do
  case "$1" in
    -m|--module)         MODULES="$2"; shift 2;;
    -M|--mode)           GLOBAL_MODE="$2"; shift 2;;
    -y|--yes)            ASSUME_YES=1; shift;;
    --choices)           GLOBAL_CHOICES="$2"; shift 2;;
    --module-choices)    PER_MODULE_CHOICES="$2"; shift 2;;
    --log)               LOG="$2"; shift 2;;
    --summary)           SUMMARY="$2"; shift 2;;
    -h|--help)           SHOW_HELP=1; shift;;
    --) shift; break;;
    *)  # dukung juga gaya ENV=... setelah --
        break;;
  esac
done

[ "$SHOW_HELP" = "1" ] && { print_help; exit 0; }

# ===== Start =====
: >"$LOG"
log "================= Orchestrator start ================="
check_sudo
detect_os
check_network

# ===== Kumpulan modul yang valid =====
ALL_MODULES=(audio browser cloud database editor image messaging office pentest remote security servers storage streaming tools utilities virtualization)

is_valid_module() {
  local m="$1"
  for x in "${ALL_MODULES[@]}"; do [ "$x" = "$m" ] && return 0; done
  return 1
}

# ===== Dapatkan pilihan modul =====
SELECTED_MODULES=()

if [ -n "$MODULES" ]; then
  IFS=',' read -r -a tmp <<<"$MODULES"
  for m in "${tmp[@]}"; do
    m="${m//[[:space:]]/}"
    if is_valid_module "$m"; then SELECTED_MODULES+=("$m"); else warn "Modul tidak dikenal: $m"; fi
  done
else
  if [ "$ASSUME_YES" -eq 0 ]; then
    sel="$(tui_choose_modules)"
    if [ -z "$sel" ]; then
      warn "Tidak ada modul dipilih. Keluar."
      exit 0
    fi
    for token in $sel; do SELECTED_MODULES+=("$token"); done
  else
    warn "Mode --yes tapi tanpa --module: tidak ada yang dijalankan."
    exit 0
  fi
fi

# ===== Tentukan mode (basic/pro/prompt) =====
declare -A MODULE_MODE
if [ -n "$GLOBAL_MODE" ]; then
  case "$GLOBAL_MODE" in
    basic|pro) for m in "${SELECTED_MODULES[@]}"; do MODULE_MODE["$m"]="$GLOBAL_MODE"; done ;;
    prompt)
      if [ "$ASSUME_YES" -eq 1 ]; then
        warn "--mode=prompt tapi --yes dipakai → fallback ke 'basic' untuk semua."
        for m in "${SELECTED_MODULES[@]}"; do MODULE_MODE["$m"]="basic"; done
      else
        for m in "${SELECTED_MODULES[@]}"; do
          MODULE_MODE["$m"]="$(tui_choose_mode_per_module "$m")"
        done
      fi
      ;;
    *) warn "Mode tidak dikenal: $GLOBAL_MODE"; exit 1;;
  esac
else
  if [ "$ASSUME_YES" -eq 0 ]; then
    chosen="$(tui_choose_mode)"
    if [ "$chosen" = "prompt" ]; then
      for m in "${SELECTED_MODULES[@]}"; do
        MODULE_MODE["$m"]="$(tui_choose_mode_per_module "$m")"
      done
    else
      for m in "${SELECTED_MODULES[@]}"; do MODULE_MODE["$m"]="$chosen"; done
    fi
  else
    for m in "${SELECTED_MODULES[@]}"; do MODULE_MODE["$m"]="basic"; done
  fi
fi

# ===== Parsers CHOICES per modul =====
# --choices -> global; --module-choices "tools=GH_CLI YQ;virtualization=KVM_CORE VIRT_MANAGER"
declare -A MODULE_CHOICES
if [ -n "$GLOBAL_CHOICES" ]; then
  for m in "${SELECTED_MODULES[@]}"; do MODULE_CHOICES["$m"]="$GLOBAL_CHOICES"; done
fi
if [ -n "$PER_MODULE_CHOICES" ]; then
  IFS=';' read -r -a pairs <<<"$PER_MODULE_CHOICES"
  for pair in "${pairs[@]}"; do
    # bentuk: name=CHOICES STRING
    mod="${pair%%=*}"
    val="${pair#*=}"
    mod="${mod//[[:space:]]/}"
    [ -n "$mod" ] && MODULE_CHOICES["$mod"]="$val"
  done
fi

# ===== Eksekusi modul =====
failcount=0
for m in "${SELECTED_MODULES[@]}"; do
  mode="${MODULE_MODE[$m]}"
  script_path="$REPO_ROOT/$m/${mode}.sh"
  if [ ! -x "$script_path" ]; then
    [ -f "$script_path" ] && chmod +x "$script_path" || true
  fi
  if [ ! -f "$script_path" ]; then
    warn "Skrip tidak ditemukan: $script_path"
    FAILED_STEPS+=("$m:$mode (script missing)")
    failcount=$((failcount+1))
    continue
  fi

  log "▶️  Jalankan modul '$m' (mode: $mode)"
  if [ -n "${MODULE_CHOICES[$m]:-}" ]; then
    CHOICES="${MODULE_CHOICES[$m]}" bash -lc "exec \"$script_path\"" >>"$LOG" 2>&1 || { warn "Modul '$m' gagal (lihat log)"; FAILED_STEPS+=("$m:$mode"); failcount=$((failcount+1)); continue; }
  else
    bash -lc "exec \"$script_path\"" >>"$LOG" 2>&1 || { warn "Modul '$m' gagal (lihat log)"; FAILED_STEPS+=("$m:$mode"); failcount=$((failcount+1)); continue; }
  fi
  ok "Selesai modul '$m' (mode: $mode)"
done

# ===== Ringkasan =====
{
  echo "🎯 Orchestrator selesai."
  echo "📦 Modul dipilih : ${SELECTED_MODULES[*]}"
  echo "🔧 Mode per modul: "
  for m in "${SELECTED_MODULES[@]}"; do printf " - %s: %s\n" "$m" "${MODULE_MODE[$m]}"; done
  if [ "${#FAILED_STEPS[@]}" -gt 0 ]; then
    echo "⚠️  Langkah gagal:"
    for x in "${FAILED_STEPS[@]}"; do echo "   • $x"; done
  else
    echo "✅ Tidak ada kegagalan terdeteksi."
  fi
  echo "📄 Log   : $LOG"
  echo "🧾 Resume: $SUMMARY"
} >"$SUMMARY"

echo
echo "======================================================"
echo "✅ Selesai. Ringkasan: $SUMMARY"
echo "🪵 Log: $LOG"
echo "ℹ️  Catatan: Jika modul menambah Anda ke grup (mis. docker/libvirt), lakukan logout/login."
echo "======================================================"
