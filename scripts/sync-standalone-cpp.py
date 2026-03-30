#!/usr/bin/env python3

from __future__ import annotations

import shutil
import sys
from pathlib import Path


CPP_FILES = (
    'cccp.c',
    'cexp.c',
    'intl.c',
    'intl.h',
    'mbchar.c',
    'prefix.c',
    'prefix.h',
    'sn_version.h',
    'version.c',
)


def replace_once(text: str, old: str, new: str, *, path: Path) -> str:
    if old not in text:
        raise RuntimeError(f'expected snippet not found in {path}')
    return text.replace(old, new, 1)


def main() -> int:
    if len(sys.argv) != 2:
        print(f'usage: {Path(sys.argv[0]).name} <NGC source root>', file=sys.stderr)
        return 1

    source_root = Path(sys.argv[1]).resolve()
    cpp_dir = source_root / 'CPP'
    gcc_dir = source_root / 'gcc'

    for name in CPP_FILES:
        shutil.copy2(cpp_dir / name, gcc_dir / name)

    cccp_path = gcc_dir / 'cccp.c'
    cccp_text = cccp_path.read_text()
    cccp_text = replace_once(
        cccp_text,
        '// SN-Phil: windows kludge for directory sensing\n#define WIN32_LEAN_AND_MEAN\n#include <windows.h>\n',
        '// SN-Phil: windows kludge for directory sensing\n#ifdef _WIN32\n#define WIN32_LEAN_AND_MEAN\n#include <windows.h>\n#endif\n',
        path=cccp_path,
    )
    cccp_text = replace_once(
        cccp_text,
        '#undef __STDC__\n#include "config.h"\n\n#undef __STDC__\n#include "system.h"\n',
        '#include "config.h"\n\n#include "system.h"\n',
        path=cccp_path,
    )
    cccp_text = replace_once(
        cccp_text,
        '    {\n      long int attr = GetFileAttributes(fname) ;\n      if ( attr == FILE_ATTRIBUTE_DIRECTORY ) // if its a dir\n        errno = ENOENT ;    // fake theres not a file there\n    } ;\n',
        '#ifdef _WIN32\n    {\n      long int attr = GetFileAttributes(fname) ;\n      if ( attr == FILE_ATTRIBUTE_DIRECTORY ) // if its a dir\n        errno = ENOENT ;    // fake theres not a file there\n    } ;\n#endif\n',
        path=cccp_path,
    )
    cccp_text = replace_once(
        cccp_text,
        '\tchar* vers;\n\tvers = (char*)malloc(8);\n\t_itoa( sn_num_version, vers, 10 ); //write to vers as base10\n',
        '\tchar vers[16];\n\tsprintf(vers, "%d", sn_num_version);\n',
        path=cccp_path,
    )
    cccp_text = replace_once(
        cccp_text,
        '\telse\n\t{\n\t\tchar* working_path = (char*) alloca (_MAX_PATH);\n\n\t\tunsigned int retval;\n\t\t\n\t\tretval = GetCurrentDirectory(\n\t\t\t_MAX_PATH, \n\t\t\tworking_path       \n\t\t\t);\n\n\t\tif (retval > 0)\n\t\t{\n\t\t\tstrncpy(nominal_fname, working_path, 2);\n\t\t\tstrcpy(nominal_fname + 2, input_fname);\n\t\t}\n\t\telse\n\t\t{\n\t\t\tstrcpy(nominal_fname, input_fname);\n\t\t}\n\t}\n',
        '\telse\n\t{\n\t\tchar* working_path = (char*) alloca (4096);\n#ifdef _WIN32\n\t\tunsigned int retval;\n\t\t\n\t\tretval = GetCurrentDirectory(\n\t\t\t4096, \n\t\t\tworking_path       \n\t\t\t);\n\n\t\tif (retval > 0)\n#else\n\t\tif (getcwd(working_path, 4096) != 0)\n#endif\n\t\t{\n\t\t\tstrncpy(nominal_fname, working_path, 2);\n\t\t\tstrcpy(nominal_fname + 2, input_fname);\n\t\t}\n\t\telse\n\t\t{\n\t\t\tstrcpy(nominal_fname, input_fname);\n\t\t}\n\t}\n',
        path=cccp_path,
    )
    cccp_path.write_text(cccp_text)

    version_path = gcc_dir / 'version.c'
    version_text = version_path.read_text()
    version_text = replace_once(
        version_text,
        '#ifdef SN_PS2_BUILD\nchar *version_string = "2.95.3 SN BUILD v" MAJOR_VERSION_S "." MINOR_VERSION_S " for Sony Playstation 2";\n#endif\n#ifdef SN_AGB_BUILD\nchar *version_string = "2.95.3 SN BUILD v" MAJOR_VERSION_S "." MINOR_VERSION_S " for Nintendo GameBoy Advance";\n#endif\n#ifdef SN_NGC_BUILD\nchar *version_string = "2.95.3 SN BUILD v" MAJOR_VERSION_S "." MINOR_VERSION_S " for Nintendo Gamecube";\n#endif\n#ifdef SN_IOP_BUILD\nchar *version_string = "2.95.3 SN BUILD v" MAJOR_VERSION_S "." MINOR_VERSION_S " for Sony Playstation 2 IOP";\n#endif\n\n//char *sn_version = VERSION;\nchar *sn_num_version = NUM_VERSION;\n',
        'char *version_string = "2.95.3 SN BUILD v" MAJOR_VERSION_S "." MINOR_VERSION_S " for Nintendo Gamecube";\nchar *sn_version = "v" MAJOR_VERSION_S "." MINOR_VERSION_S;\nchar *sn_num_version = NUM_VERSION;\n',
        path=version_path,
    )
    version_path.write_text(version_text)

    return 0


if __name__ == '__main__':
    raise SystemExit(main())
