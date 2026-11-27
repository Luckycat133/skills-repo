"""Compose the immutable tagged Skill and llms.txt into a checked release envelope."""
from __future__ import annotations

import hashlib
from pathlib import Path, PurePosixPath
import re
import stat
import subprocess
import sys
import zipfile

SLUG = "agent-skills-setup"
VERSION = "0.11.1"
TARGET = "0d8449810fe0fd857598840258aecc73e7c604f6"
STAMP = (2026, 11, 27, 0, 0, 0)
INSTALL = f"{SLUG}-{VERSION}.zip"
BUNDLE = f"skills-repo-v{VERSION}-bundle.zip"


def checksums(files: dict[str, bytes]) -> bytes:
    return "".join(f"{hashlib.sha256(files[name]).hexdigest()}  {name}\n" for name in sorted(files)).encode()


def zip_files(path: Path) -> dict[str, tuple[bytes, int]]:
    with zipfile.ZipFile(path) as archive:
        if archive.testzip() is not None:
            raise ValueError("ZIP member failed CRC")
        result = {}
        for member in archive.infolist():
            name = member.filename
            posix = PurePosixPath(name)
            mode = member.external_attr >> 16
            if (not re.fullmatch(r"[a-zA-Z0-9._/-]+", name) or posix.is_absolute()
                    or any(p.startswith(".") for p in posix.parts) or str(posix) != name
                    or name in result or not stat.S_ISREG(mode) or mode & 0o777 not in {0o644, 0o755}):
                raise ValueError("Unexpected ZIP member path or type")
            result[name] = (archive.read(member), mode)
    return result


def verify(output: Path) -> None:
    install = zip_files(output / INSTALL)
    envelope = zip_files(output / BUNDLE)
    if any(not p.startswith(f"{SLUG}/") for p in install):
        raise ValueError("Installable ZIP has a non-Skill member")
    required = {f"{SLUG}/SKILL.md", f"{SLUG}/LICENSE", f"{SLUG}/scripts/migrate_context.py"}
    if not required <= install.keys() or set(envelope) != set(install) | {"llms.txt", "SOURCE.txt", "SHA256SUMS"}:
        raise ValueError("Release envelope does not contain the precise installable Skill")
    if any(envelope[name] != member for name, member in install.items()):
        raise ValueError("Envelope does not preserve canonical payload bytes/modes")
    if sorted(k for k, (_, mode) in envelope.items() if mode & 0o111) != [f"{SLUG}/scripts/migrate_context.py"]:
        raise ValueError("Only the canonical helper may be executable")
    if not re.search(rb'^  version: "0\.11\.1"$', install[f"{SLUG}/SKILL.md"][0], re.MULTILINE):
        raise ValueError("Skill version does not match tag")
    if not re.search(rb'^SCHEMA_VERSION = "0\.11\.1"$', install[f"{SLUG}/scripts/migrate_context.py"][0], re.MULTILINE):
        raise ValueError("CLI version does not match tag")
    if b"\nSource version: 0.11.1.\n" not in envelope["llms.txt"][0]:
        raise ValueError("llms.txt version does not match tag")
    if envelope["SOURCE.txt"][0] != provenance():
        raise ValueError("Provenance does not match immutable tag")
    inner = {name: data for name, (data, _) in envelope.items() if name != "SHA256SUMS"}
    # Defense in depth over the tracked-file allowlist. Never log matched content
    # or read a source path other than an approved release payload entry.
    secret_markers = (
        rb'-----BEGIN (?:RSA |OPENSSH |EC |DSA |ENCRYPTED )?PRIVATE KEY-----',
        rb'\b(?:ghp_|gho_|github_pat_)[A-Za-z0-9_]{25,}\b',
        rb'\bsk-ant-api[0-9]+-[A-Za-z0-9_-]{25,}\b',
    )
    if any(re.search(pattern, data) for data in inner.values() for pattern in secret_markers):
        raise ValueError("Unexpected credential-like material in the allowlisted release payload")
    if envelope["SHA256SUMS"][0] != checksums(inner):
        raise ValueError("Internal SHA-256 does not match unpacked files")
    outer = {name: (output / name).read_bytes() for name in (INSTALL, BUNDLE)}
    if (output / "SHA256SUMS").read_bytes() != checksums(outer):
        raise ValueError("External SHA-256 does not match both ZIPs")
    print(f"Verified {len(install)} canonical Skill files, {len(inner)} inner checksums, and two outer SHA-256 digests")


def provenance() -> bytes:
    return f"Repository: Luckycat133/skills-repo\nTag: v{VERSION}\nCommit: {TARGET}\n".encode()


def build(src: Path, output: Path) -> None:
    if not output.is_dir() or any(output.iterdir()):
        raise ValueError("Build output must be a new empty directory")
    subprocess.run([sys.executable, "-B", str(src / "scripts/package_skill.py"), "--output",
                    str(output / INSTALL)], check=True, cwd=src)
    payload = zip_files(output / INSTALL)
    payload["llms.txt"] = ((src / "llms.txt").read_bytes(), 0o100644)
    payload["SOURCE.txt"] = (provenance(), 0o100644)
    payload["SHA256SUMS"] = (checksums({name: data for name, (data, _) in payload.items()}), 0o100644)
    with zipfile.ZipFile(output / BUNDLE, "x") as archive:
        for name, (data, mode) in sorted(payload.items()):
            info = zipfile.ZipInfo(name, STAMP)
            info.create_system = 3
            info.external_attr = mode << 16
            info.compress_type = zipfile.ZIP_STORED
            archive.writestr(info, data)
    (output / "SHA256SUMS").write_bytes(checksums({name: (output / name).read_bytes() for name in (INSTALL, BUNDLE)}))
    verify(output)


if __name__ == "__main__":
    if len(sys.argv) == 4 and sys.argv[1] == "build":
        build(Path(sys.argv[2]).resolve(), Path(sys.argv[3]).resolve())
    elif len(sys.argv) == 3 and sys.argv[1] == "verify":
        verify(Path(sys.argv[2]).resolve())
    else:
        raise SystemExit("usage: bundle_release.py build SOURCE EMPTY_OUT | verify OUT")
