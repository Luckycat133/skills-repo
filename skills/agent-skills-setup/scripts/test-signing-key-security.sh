#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

native_path() {
    if command -v cygpath >/dev/null 2>&1; then
        cygpath -w "$1"
    else
        printf '%s' "$1"
    fi
}

PYTHONDONTWRITEBYTECODE=1 python3 - "$(native_path "$SCRIPT_DIR")" <<'PY'
import os
import stat
import subprocess
import sys
import tempfile
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, sys.argv[1])
from acb.key_security import create_key_file, read_private_file


def refused(path: Path) -> None:
    try:
        read_private_file(path)
    except (OSError, ValueError):
        return
    raise AssertionError("accepted an unsafe private key fixture")


def write_key(path: Path, data: bytes) -> None:
    descriptor = create_key_file(path)
    try:
        assert not os.get_inheritable(descriptor), "private key handle is inheritable"
        with os.fdopen(descriptor, "wb") as stream:
            descriptor = -1
            stream.write(data)
            stream.flush()
            os.fsync(stream.fileno())
    finally:
        if descriptor >= 0:
            os.close(descriptor)


with tempfile.TemporaryDirectory(prefix="signing-key-security-") as temporary:
    root = Path(temporary)
    payload = bytes(range(32))
    private = root / "private.key"
    write_key(private, payload)
    assert read_private_file(private) == payload
    try:
        create_key_file(private)
    except FileExistsError:
        pass
    else:
        raise AssertionError("overwrote an existing key file")
    assert private.read_bytes() == payload
    print("OK private creation/read, non-inheritable handle and exclusive no-overwrite")

    long_key = root / "long.key"
    write_key(long_key, bytes(range(64)))
    assert read_private_file(long_key) == bytes(range(33)), "private key read is not bounded"
    empty = root / "empty.key"
    os.close(create_key_file(empty))
    assert read_private_file(empty) == b""
    print("OK helper limits reads to 33 bytes and leaves length validation to the caller")

    directory = root / "directory.key"
    directory.mkdir()
    refused(directory)
    refused(root / "missing.key")
    try:
        create_key_file(directory)
    except (OSError, ValueError):
        pass
    else:
        raise AssertionError("created a key over a directory")
    assert directory.is_dir() and private.read_bytes() == payload
    link = root / "linked.key"
    try:
        link.symlink_to(private)
    except OSError:
        print("SKIP symlink fixture: host does not allow temporary symlinks")
    else:
        refused(link)
        try:
            create_key_file(link)
        except (OSError, ValueError):
            pass
        else:
            raise AssertionError("created a key over a symlink")
        assert private.read_bytes() == payload
    print("OK non-regular, missing and existing non-file paths fail without target changes")

    if os.name == "nt":
        def icacls(path: Path, *arguments: str) -> None:
            result = subprocess.run(
                ["icacls", str(path), *arguments],
                capture_output=True, text=True, check=False,
            )
            assert result.returncode == 0, "could not configure the isolated ACL fixture"

        wide = root / "wide.key"
        write_key(wide, payload)
        icacls(wide, "/grant", "*S-1-1-0:R")
        refused(wide)
        assert wide.read_bytes() == payload
        unprotected = root / "unprotected.key"
        write_key(unprotected, payload)
        icacls(unprotected, "/inheritance:e")
        refused(unprotected)
        assert unprotected.read_bytes() == payload
        refused(root / "NUL")
        failed_creation = root / "failed-creation.key"
        with patch("acb.key_security._WindowsAPI.assert_private_handle", side_effect=PermissionError("injected ACL refusal")):
            try:
                create_key_file(failed_creation)
            except PermissionError:
                pass
            else:
                raise AssertionError("created a key despite failed ACL verification")
        assert not failed_creation.exists(), "failed private creation leaked an empty file"
        write_key(failed_creation, payload)
        assert read_private_file(failed_creation) == payload
        print("OK Windows denies World-readable/unprotected/non-disk keys and cleans failed creation")
    else:
        assert stat.S_IMODE(private.stat().st_mode) == 0o600
        for mode in (0o640, 0o604, 0o644, 0o666):
            private.chmod(mode)
            try:
                read_private_file(private)
            except ValueError as error:
                assert "group/world accessible; chmod 600 before use" in str(error)
            else:
                raise AssertionError("accepted group/world key permissions")
            assert private.read_bytes() == payload
        private.chmod(0o600)
        assert read_private_file(private) == payload
        fifo = root / "pipe.key"
        os.mkfifo(fifo, 0o600)
        refused(fifo)
        print("OK POSIX creates mode 600, refuses group/world bits and never reads a FIFO")

print("Signing key security tests passed; all key files are synthetic temporary fixtures")
PY
