#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd -- "${SCRIPT_DIR}/.." && pwd)

: "${PRODG_SOURCE_URL:=https://archive.org/download/GameCubeSDK/SNSystems%20ProDG%20for%20GameCube%20%2B%20Sources%20%2B.NET%20and%20more.rar/SNSystems%20ProDG%20for%20GameCube%20%2B%20Sources%20%2B%20.NET%20and%20more%2FProDGforNGCv393_Source_Code.zip}"
: "${PRODG_CONFIG_GUESS_URL:=https://git.savannah.gnu.org/cgit/config.git/plain/config.guess}"
: "${PRODG_CONFIG_SUB_URL:=https://git.savannah.gnu.org/cgit/config.git/plain/config.sub}"
: "${PRODG_INSTALL_SH_URL:=https://git.savannah.gnu.org/cgit/automake.git/plain/lib/install-sh}"

SOURCE_PARENT=${1:-"${WORKDIR:-${REPO_ROOT}/work}/source"}
DOWNLOAD_DIR=${2:-"${WORKDIR:-${REPO_ROOT}/work}/downloads"}
OUTER_ARCHIVE="${DOWNLOAD_DIR}/ProDGforNGCv393_Source_Code.zip"
INNER_ARCHIVE="${DOWNLOAD_DIR}/NGC_GNU_SRC.zip"

download_file() {
  local url=$1
  local destination=$2
  curl -L --fail --retry 5 --retry-delay 2 "$url" -o "$destination"
}

rm -rf "$SOURCE_PARENT"
mkdir -p "$SOURCE_PARENT" "$DOWNLOAD_DIR"

download_file "$PRODG_SOURCE_URL" "$OUTER_ARCHIVE"
unzip -p "$OUTER_ARCHIVE" "ProDGforNGCv393_Source_Code/GC source code/NGC_GNU_SRC.zip" > "$INNER_ARCHIVE"
unzip -q "$INNER_ARCHIVE" -d "$SOURCE_PARENT"

SOURCE_ROOT="${SOURCE_PARENT}/NGC_GNU_SRC/NGC"
chmod -R u+w "$SOURCE_ROOT"

python3 - "$SOURCE_ROOT" <<'PY'
from pathlib import Path
import sys

root = Path(sys.argv[1])
for path in root.rglob("*"):
    if not path.is_file():
        continue
    data = path.read_bytes()
    if b"\0" in data or b"\r" not in data:
        continue
    path.write_bytes(data.replace(b"\r\n", b"\n"))
PY

download_file "$PRODG_CONFIG_GUESS_URL" "${SOURCE_ROOT}/config.guess"
download_file "$PRODG_CONFIG_SUB_URL" "${SOURCE_ROOT}/config.sub"
download_file "$PRODG_INSTALL_SH_URL" "${SOURCE_ROOT}/install-sh"
chmod +x "${SOURCE_ROOT}/config.guess" "${SOURCE_ROOT}/config.sub" "${SOURCE_ROOT}/install-sh"
chmod +x "${SOURCE_ROOT}/gcc/configure"

cat > "${SOURCE_ROOT}/config.if" <<'EOF'
libstdcxx_interface=3
EOF

mkdir -p "${SOURCE_ROOT}/gcc/intl" "${SOURCE_ROOT}/gcc/po" "${SOURCE_ROOT}/gcc/fixinc"

cat > "${SOURCE_ROOT}/gcc/intl/libgettext.h" <<'EOF'
#ifndef GCC_LIBGETTEXT_H
#define GCC_LIBGETTEXT_H
#define _(String) (String)
#endif
EOF

: > "${SOURCE_ROOT}/gcc/intl/Makefile.in"
: > "${SOURCE_ROOT}/gcc/intl/po2tbl.sed.in"
: > "${SOURCE_ROOT}/gcc/po/Makefile.in.in"
: > "${SOURCE_ROOT}/gcc/po/POTFILES.in"
: > "${SOURCE_ROOT}/gcc/fixinc/Makefile.in"

shopt -s nullglob
for patch_file in "${REPO_ROOT}"/*.patch; do
  patch -N -d "$SOURCE_ROOT" -p1 -i "$patch_file"
done

printf '%s\n' "$SOURCE_ROOT"
