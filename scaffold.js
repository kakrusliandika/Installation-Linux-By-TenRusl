// scaffold.js
// Buat struktur folder & file kosong untuk Installation-Linux-By-TenRusl
// + README.md di setiap folder
// Author: TenRusli x ChatGPT

const fs = require("fs");
const path = require("path");

// === Konfigurasi dasar ===
const DEFAULT_BASE = "C:\\laragon\\www\\Installation-Linux-By-TenRusl";
const baseDir = path.resolve(process.argv[2] || DEFAULT_BASE);

// Ekstensi file per "platform"
const platformExtMap = {
  "installation-ubuntu": "sh",
  "installation-kali": "sh",
  "installation-xubuntu": "sh",
  "installation-debian": "sh",
  "installation-fedora": "sh",
  "installation-arch": "sh",
  "installation-macos": "sh",
  "installation-android": "sh",
  "installation-ios": "sh",
  "installation-desktop": "sh",
  "installation-website": "sh",
  "installation-arduino": "sh",
  "installation-windows": "ps1",
};

// Kategori umum (pentest punya file tambahan)
const categories = [
  "audio",
  "browser",
  "cloud",
  "database",
  "editor",
  "image",
  "messaging",
  "office",
  "pentest",
  "remote",
  "security",
  "servers",
  "storage",
  "streaming",
  "tools",
  "utilities",
  "virtualization",
];

// File top-level (kosong)
const topFiles = [
  ".editorconfig",
  ".gitattributes",
  ".gitignore",
  "CHANGELOG.md",
  "LICENSE",
  "README.md",
];

// File .vscode (kosong)
const vscodeFiles = ["settings.json", "extensions.json", "launch.json", "tasks.json"];

// === Util ===
function ensureDir(d) {
    if (!fs.existsSync(d)) {
        fs.mkdirSync(d, { recursive: true });
    }
    ensureReadme(d); // tambahkan README.md di setiap folder
}

function ensureFile(f) {
  if (!fs.existsSync(f)) {
      fs.writeFileSync(f, "");
  }
}

function ensureReadme(dirPath) {
    const readmePath = path.join(dirPath, "README.md");
    if (!fs.existsSync(readmePath)) {
        fs.writeFileSync(readmePath, "");
    }
}

function createPlatformTree(platform, ext) {
  const platDir = path.join(baseDir, platform);
  ensureDir(platDir);

  // file dasar di root setiap platform
  ensureFile(path.join(platDir, `basic.${ext}`));

  // kategori
  for (const cat of categories) {
    const catDir = path.join(platDir, cat);
    ensureDir(catDir);

    if (cat === "pentest") {
      // khusus pentest: basic/modular/pro/ultimate
      for (const name of ["basic", "modular", "pro", "ultimate"]) {
        ensureFile(path.join(catDir, `${name}.${ext}`));
      }
    } else {
      // kategori lain: basic/pro
      ensureFile(path.join(catDir, `basic.${ext}`));
      ensureFile(path.join(catDir, `pro.${ext}`));
    }
  }
}

// === Eksekusi ===
(function main() {
  console.log("➡️  Base directory:", baseDir);
  ensureDir(baseDir);

  // .vscode
  const vsDir = path.join(baseDir, ".vscode");
  ensureDir(vsDir);
  for (const f of vscodeFiles) ensureFile(path.join(vsDir, f));

  // file top-level
  for (const f of topFiles) ensureFile(path.join(baseDir, f));

  // setiap platform
  for (const [platform, ext] of Object.entries(platformExtMap)) {
    createPlatformTree(platform, ext);
  }

  console.log("✅ Struktur & README.md per-folder berhasil dibuat/di-update (idempotent).");
})();
