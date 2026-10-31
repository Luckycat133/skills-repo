#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if command -v cygpath >/dev/null 2>&1; then
    SCRIPT_DIR="$(cygpath -w "$SCRIPT_DIR")"
fi

PYTHONDONTWRITEBYTECODE=1 python3 - "$SCRIPT_DIR" <<'PY'
import argparse
import importlib.util
import os
from pathlib import Path
import stat
import sys
import tempfile
from types import SimpleNamespace
from unittest.mock import patch

try:
    from cryptography.hazmat.primitives import serialization
    from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey
except ImportError:
    print("SKIP keygen transaction: optional cryptography dependency is unavailable")
    raise SystemExit(0)

scripts = Path(sys.argv[1])
sys.path.insert(0, str(scripts))
spec = importlib.util.spec_from_file_location("keygen_transaction_cli", scripts / "context-migrator.py")
assert spec is not None and spec.loader is not None
cli = importlib.util.module_from_spec(spec)
spec.loader.exec_module(cli)
import acb.key_security as key_security


def invoke(private: Path, public: Path, create=None):
    output = []
    arguments = argparse.Namespace(out_private=private, out_public=public, json=True)
    with patch.object(cli, "emit", side_effect=lambda result, *args: output.append(result)):
        if create is None:
            status = cli.run_bundle_keygen(arguments)
        else:
            with patch.object(cli, "create_key_file", side_effect=create):
                status = cli.run_bundle_keygen(arguments)
    assert len(output) == 1
    return status, output[0]


with tempfile.TemporaryDirectory(prefix="keygen-transaction-") as temporary:
    root = Path(temporary).resolve()
    creation_failure = root / "creation-guard-failure"
    creation_failure.mkdir()
    private, public = creation_failure / "private.key", creation_failure / "public.key"
    closed_handles = []

    class FailingCreationAPI:
        def current_user(self):
            return b"synthetic SID buffer", 0, "synthetic SID"

        def private_descriptor(self, user):
            return None

        def open_key(self, path, **arguments):
            return os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)

        def assert_regular_handle(self, handle):
            pass

        def assert_private_handle(self, handle, user):
            raise PermissionError("original creation guard failure")

        def delete_created_handle(self, handle):
            raise OSError("secondary creation cleanup failure")

        def close_handle(self, handle):
            os.close(handle)
            closed_handles.append(handle)
            return True

        def local_free(self, descriptor):
            pass

    # This control-flow fixture runs on every host. Native Windows handle/ACL
    # behavior is checked separately by test-signing-key-security.sh and below.
    synthetic_os = SimpleNamespace(name="nt")
    synthetic_crt = SimpleNamespace(open_osfhandle=lambda handle, flags: handle)
    with patch.object(key_security, "os", synthetic_os), \
            patch.object(key_security, "_WindowsAPI", FailingCreationAPI), \
            patch.dict(sys.modules, {"msvcrt": synthetic_crt}):
        status, output = invoke(private, public)
    assert status == 1 and output["error"] == "original creation guard failure"
    assert output["outputs_requiring_review"] == [str(private)]
    assert output["cleanup_errors"] == ["secondary creation cleanup failure"]
    assert private.is_file() and private.stat().st_size == 0 and not public.exists()
    assert len(closed_handles) == 1
    try:
        os.fstat(closed_handles[0])
    except OSError:
        pass
    else:
        raise AssertionError("creation guard failure leaked its handle")
    print("PASS creation-stage cleanup errors preserve the original guard and report retained output")

    private, public = root / "success.private", root / "success.public"
    status, output = invoke(private, public)
    assert status == 0 and output["ok"]
    generated = Ed25519PrivateKey.from_private_bytes(private.read_bytes())
    assert generated.public_key().public_bytes(
        serialization.Encoding.Raw, serialization.PublicFormat.Raw,
    ) == public.read_bytes()
    status, output = invoke(private, public)
    assert status == 1 and not output["ok"]
    assert "already exist" in output["error"]
    print("PASS real keypair and existing-output refusal")

    original_write = cli.os.write
    original_create = cli.create_key_file
    for failure in ("short-write", "no-progress", "write-error", "cleanup-error"):
        base = root / failure
        base.mkdir()
        private, public = base / "private.key", base / "public.key"
        descriptors = []

        def track_create(path):
            descriptor = original_create(path)
            descriptors.append(descriptor)
            return descriptor

        def controlled_write(descriptor, data):
            if failure == "short-write":
                return original_write(descriptor, data[:3])
            if failure == "no-progress":
                return 0
            raise OSError("synthetic key write failure")

        with patch.object(cli.os, "write", side_effect=controlled_write):
            if failure == "cleanup-error":
                with patch.object(cli, "discard_created_key_file", side_effect=OSError("synthetic cleanup failure")):
                    status, output = invoke(private, public, track_create)
            else:
                status, output = invoke(private, public, track_create)
        for descriptor in descriptors:
            try:
                os.fstat(descriptor)
            except OSError:
                pass
            else:
                raise AssertionError("key creation descriptor leaked")
        if failure == "short-write":
            assert status == 0 and output["ok"]
            generated = Ed25519PrivateKey.from_private_bytes(private.read_bytes())
            assert generated.public_key().public_bytes(
                serialization.Encoding.Raw, serialization.PublicFormat.Raw,
            ) == public.read_bytes()
        else:
            assert status == 1 and not output["ok"]
            if failure == "no-progress":
                assert output["error"] == "key output write made no progress"
            else:
                assert output["error"] == "synthetic key write failure"
            if failure == "cleanup-error":
                assert output["cleanup_errors"] == ["synthetic cleanup failure"]
                assert str(private) in output["outputs_requiring_review"]
                assert private.exists()
            elif os.name == "nt":
                assert not private.exists()
            else:
                assert private.exists()
                assert stat.S_IMODE(private.stat().st_mode) == 0o600
                assert str(private) in output["outputs_requiring_review"]
        print("PASS " + failure + " and creation descriptor release")

    original_close = cli.os.close
    for write_error in (False, True):
        base = root / ("close-after-error" if write_error else "close-after-success")
        base.mkdir()
        private, public = base / "private.key", base / "public.key"
        closed = []

        def close_then_report_error(descriptor):
            original_close(descriptor)
            closed.append(descriptor)
            raise OSError("synthetic close failure")

        with patch.object(cli.os, "close", side_effect=close_then_report_error):
            if write_error:
                with patch.object(cli.os, "write", side_effect=OSError("original write failure")):
                    status, output = invoke(private, public)
            else:
                status, output = invoke(private, public)
        assert status == 1 and not output["ok"]
        assert len(closed) == (1 if write_error else 2)
        assert output["cleanup_errors"] == ["synthetic close failure"] * len(closed)
        assert str(private) in output["outputs_requiring_review"]
        assert output["error"] == (
            "original write failure" if write_error else "closing generated key outputs failed"
        )
        print("PASS close error reporting preserves the original failure; write_error=" + str(write_error))

    for replace_private in (False, True):
        base = root / ("replacement" if replace_private else "collision")
        base.mkdir()
        private, public = base / "private.key", base / "public.key"
        saved = base / "generated.saved"
        replacement = b"concurrent unrelated fixture"
        original_create = cli.create_key_file
        state = {"interleaved": False, "rename_blocked": False}

        def interleave(path):
            if path == public:
                state["interleaved"] = True
                if replace_private:
                    try:
                        private.rename(saved)
                    except PermissionError:
                        state["rename_blocked"] = True
                    else:
                        private.write_bytes(replacement)
                public.write_bytes(b"concurrent public fixture")
            return original_create(path)

        status, output = invoke(private, public, interleave)
        assert state["interleaved"] and status == 1 and not output["ok"]
        assert public.read_bytes() == b"concurrent public fixture"
        if os.name == "nt":
            assert not private.exists(), "original held Windows file was not removed"
            if replace_private:
                assert state["rename_blocked"], "Windows key handle closed before pair completion"
                assert not saved.exists()
        else:
            assert private.exists(), "POSIX failure performed unsafe path-based cleanup"
            assert str(private) in output["outputs_requiring_review"]
            if replace_private:
                assert private.read_bytes() == replacement, "removed an unrelated replacement"
                assert len(saved.read_bytes()) == 32
            else:
                assert len(private.read_bytes()) == 32
                assert stat.S_IMODE(private.stat().st_mode) == 0o600
        print("PASS concurrent collision preserves unrelated files; replacement=" + str(replace_private))

    if os.name != "nt":
        base = root / "changed-success-path"
        base.mkdir()
        private, public = base / "private.key", base / "public.key"
        original_create = cli.create_key_file

        def replace_before_second_create(path):
            if path == public:
                private.rename(base / "generated.saved")
                private.write_bytes(b"replacement that must remain")
            return original_create(path)

        with patch.object(Path, "unlink", side_effect=AssertionError("unsafe path deletion")):
            status, output = invoke(private, public, replace_before_second_create)
        assert status == 1 and not output["ok"], "reported success for a replaced key path"
        assert private.read_bytes() == b"replacement that must remain"
        assert len(public.read_bytes()) == 32
        print("PASS replaced POSIX output is detected without any path unlink")

print("Keygen transaction regression passed; only temporary synthetic keys were used")
PY
