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
chmod +x "${SOURCE_ROOT}/libiberty/configure"
find "${SOURCE_ROOT}/gcc" -type f \( -name '*.sh' -o -name 'move-if-change' -o -name 'gen*' -o -name 'mk*' \) -exec chmod +x {} +
find "${SOURCE_ROOT}/libiberty" -type f \( -name '*.sh' -o -name 'configure*' -o -name 'gen*' -o -name 'mk*' \) -exec chmod +x {} +

cat > "${SOURCE_ROOT}/config.if" <<'EOF'
libstdcxx_interface=3
EOF

mkdir -p "${SOURCE_ROOT}/gcc/intl" "${SOURCE_ROOT}/gcc/po" "${SOURCE_ROOT}/gcc/fixinc"
mkdir -p "${SOURCE_ROOT}/gcc/ginclude" "${SOURCE_ROOT}/gcc/cp"

cat > "${SOURCE_ROOT}/gcc/intl/libgettext.h" <<'EOF'
#ifndef GCC_LIBGETTEXT_H
#define GCC_LIBGETTEXT_H
#define _(String) (String)
#endif
EOF

cat > "${SOURCE_ROOT}/gcc/intl/Makefile.in" <<'EOF'
all install uninstall distdir mostlyclean clean distclean maintainer-clean:
	@true
EOF

: > "${SOURCE_ROOT}/gcc/intl/po2tbl.sed.in"

cat > "${SOURCE_ROOT}/gcc/po/Makefile.in.in" <<'EOF'
all install uninstall distdir mostlyclean clean distclean maintainer-clean:
	@true
EOF

: > "${SOURCE_ROOT}/gcc/po/POTFILES.in"

cat > "${SOURCE_ROOT}/gcc/fixinc/Makefile.in" <<'EOF'
all install uninstall distdir mostlyclean clean distclean maintainer-clean:
	@true
EOF

cat > "${SOURCE_ROOT}/gcc/fixinc/mkfixinc.sh" <<'EOF'
#!/usr/bin/env sh
cat > ../fixinc.sh <<'INNER'
#!/usr/bin/env sh
exit 0
INNER
chmod +x ../fixinc.sh
EOF
chmod +x "${SOURCE_ROOT}/gcc/fixinc/mkfixinc.sh"

for fixinc_file in fixincl.c procopen.c gnu-regex.c server.c gnu-regex.h server.h inclhack.def; do
  : > "${SOURCE_ROOT}/gcc/fixinc/${fixinc_file}"
done

for ginclude_header in \
  stdarg.h stddef.h varargs.h va-alpha.h va-h8300.h va-i860.h va-i960.h \
  va-mips.h va-m88k.h va-mn10200.h va-mn10300.h va-pa.h va-pyr.h va-sparc.h \
  va-clipper.h va-spur.h va-m32r.h va-sh.h va-v850.h va-arc.h iso646.h \
  va-ppc.h va-c4x.h proto.h stdbool.h ppc-asm.h; do
  cat > "${SOURCE_ROOT}/gcc/ginclude/${ginclude_header}" <<'EOF'
/* Stub header generated for host-only ProDG compiler builds. */
EOF
done

printf 'timestamp\n' > "${SOURCE_ROOT}/gcc/cstamp-h.in"
touch "${SOURCE_ROOT}/gcc/cexp.c"
touch "${SOURCE_ROOT}/gcc/c-gperf.h"
touch "${SOURCE_ROOT}/gcc/c-parse.c"
touch "${SOURCE_ROOT}/gcc/cp/parse.c"
cat > "${SOURCE_ROOT}/gcc/fixinc.sh" <<'EOF'
#!/usr/bin/env sh
exit 0
EOF
chmod +x "${SOURCE_ROOT}/gcc/fixinc.sh"

shopt -s nullglob
for patch_file in "${REPO_ROOT}"/*.patch; do
  patch -N -d "$SOURCE_ROOT" -p1 -i "$patch_file"
done

printf '%s\n' "$SOURCE_ROOT"
