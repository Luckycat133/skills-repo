"""Detection probes for products / profiles.

A probe returns an :class:`InstallState` based on the available
evidence on the local device.  Probes are pure-Python where possible
(``shutil.which`` + filesystem inspection) and never reach the
network.
"""

from __future__ import annotations

import os
import shutil
import subprocess
from dataclasses import dataclass
from enum import Enum
from pathlib import Path
from typing import Iterable


class InstallState(str, Enum):
    INSTALLED = "installed"
    CONFIGURED_ONLY = "configured-only"
    COMPATIBILITY_ONLY = "compatibility-only"
    CLOUD_CONNECTED = "cloud-connected"
    LEGACY = "legacy"
    AMBIGUOUS = "ambiguous"
    NOT_DETECTED = "not-detected"


@dataclass(frozen=True)
class ProbeResult:
    product: str
    profile: str
    state: InstallState
    evidence: tuple[str, ...]

    def to_dict(self) -> dict[str, str]:
        return {
            "product": self.product,
            "profile": self.profile,
            "state": self.state.value,
            "evidence": list(self.evidence),
        }


def probe_binary(
    product: str,
    profile: str,
    binary_names: Iterable[str],
    *,
    version_command: Iterable[str] | None = None,
) -> ProbeResult:
    """Locate a binary in ``$PATH`` and capture its version."""
    names = list(binary_names)
    if not names:
        return ProbeResult(product, profile, InstallState.NOT_DETECTED, ())
    for name in names:
        path = shutil.which(name)
        if path:
            evidence = [f"binary:{path}"]
            if version_command:
                try:
                    proc = subprocess.run(
                        list(version_command),
                        capture_output=True,
                        text=True,
                        timeout=2,
                        check=False,
                    )
                    stdout = proc.stdout.strip() or proc.stderr.strip()
                    if stdout:
                        evidence.append(f"version:{stdout.splitlines()[0][:64]}")
                except (OSError, subprocess.SubprocessError):
                    pass
            return ProbeResult(product, profile, InstallState.INSTALLED, tuple(evidence))
    return ProbeResult(product, profile, InstallState.NOT_DETECTED, ())


def probe_file_signature(
    product: str,
    profile: str,
    candidate_paths: Iterable[Path],
) -> ProbeResult:
    """Check whether any of the candidate paths exists on disk."""
    for path in candidate_paths:
        if path.exists():
            state = (
                InstallState.INSTALLED
                if path.is_dir() or path.is_file()
                else InstallState.CONFIGURED_ONLY
            )
            return ProbeResult(product, profile, state, (f"file:{path}",))
    return ProbeResult(product, profile, InstallState.NOT_DETECTED, ())


def probe_app_bundle(
    product: str,
    profile: str,
    *,
    darwin_bundle_id: str | None = None,
) -> ProbeResult:
    """Best-effort macOS app-bundle probe using ``mdls`` / ``lsappinfo``."""
    if not darwin_bundle_id or sys.platform != "darwin":
        return ProbeResult(product, profile, InstallState.NOT_DETECTED, ())
    try:
        proc = subprocess.run(
            ["mdls", "-name", "kMDItemCFBundleIdentifier", darwin_bundle_id],
            capture_output=True,
            text=True,
            timeout=2,
            check=False,
        )
    except (OSError, subprocess.SubprocessError):
        proc = None
    if proc and proc.returncode == 0 and "kMDItemCFBundleIdentifier" in proc.stdout:
        return ProbeResult(
            product, profile, InstallState.INSTALLED,
            (f"app-bundle:{darwin_bundle_id}",),
        )
    return ProbeResult(product, profile, InstallState.NOT_DETECTED, ())


# Local import to keep the top of the module focused on data classes.
import sys  # noqa: E402


def resolve_home(home: Path | None) -> Path:
    """Pick the home directory honoring ``HOME`` overrides."""
    if home is not None:
        return home.resolve()
    env_home = os.environ.get("HOME")
    if env_home:
        return Path(env_home).resolve()
    return Path.home().resolve()


def detect_product(
    product: str,
    profile: str,
    *,
    binary: Iterable[str] | None = None,
    version_command: Iterable[str] | None = None,
    file_signature: Iterable[Path] | None = None,
    home: Path | None = None,
    app_bundle_id: str | None = None,
) -> ProbeResult:
    """Run a small, deterministic detection probe for one product."""
    if binary:
        result = probe_binary(
            product, profile, binary, version_command=version_command
        )
        if result.state is InstallState.INSTALLED:
            return result
    if file_signature:
        candidates: list[Path] = []
        for path in file_signature:
            p_str = str(path)
            if home is not None and p_str.startswith("~"):
                rel_part = p_str.lstrip("~").lstrip("/\\")
                candidates.append(home / rel_part)
            elif p_str.startswith("~"):
                candidates.append(Path(p_str).expanduser())
            else:
                candidates.append(Path(p_str))
        result = probe_file_signature(product, profile, candidates)
        if result.state is not InstallState.NOT_DETECTED:
            return result
    if app_bundle_id:
        result = probe_app_bundle(product, profile, darwin_bundle_id=app_bundle_id)
        if result.state is InstallState.INSTALLED:
            return result
    return ProbeResult(product, profile, InstallState.NOT_DETECTED, ())


def detect_profile(
    product: str,
    profile: str,
    *,
    binaries: Iterable[str] = (),
    version_command: Iterable[str] | None = None,
    file_signatures: Iterable[str] = (),
    home: Path | None = None,
    app_bundle_id: str | None = None,
) -> ProbeResult:
    """Convenience wrapper that accepts string paths and expands ``~``."""
    sigs = [Path(p) for p in file_signatures]
    return detect_product(
        product,
        profile,
        binary=binaries,
        version_command=version_command,
        file_signature=sigs,
        home=home,
        app_bundle_id=app_bundle_id,
    )