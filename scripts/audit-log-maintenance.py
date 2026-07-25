#!/usr/bin/env python3
"""Inspect, rotate, and prune existing auditd log files."""

from __future__ import annotations

import argparse
import os
import shutil
import re
import subprocess
import time
import sys
from dataclasses import dataclass
from pathlib import Path

DEFAULT_AUDIT_DIR = Path("/var/log/audit")
DEFAULT_AUDITD_CONF = Path("/etc/audit/auditd.conf")
FALLBACK_MAX_LOG_FILE_MIB = 256
FALLBACK_NUM_LOGS = 8


@dataclass(frozen=True)
class AuditFile:
    path: Path
    size: int
    mtime_ns: int
    is_active: bool


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Dry-run by default. With --apply, rotate an oversized active "
            "audit.log when needed and delete old rotated /var/log/audit/audit.log* "
            "files beyond the configured retention cap."
        )
    )
    parser.add_argument("--apply", action="store_true", help="delete planned old rotated logs")
    parser.add_argument("--yes", action="store_true", help="do not prompt before applying changes")
    parser.add_argument(
        "--rotate",
        action="store_true",
        help="ask auditd to rotate the active audit.log before cleanup",
    )
    parser.add_argument(
        "--audit-dir",
        type=Path,
        default=DEFAULT_AUDIT_DIR,
        help=f"audit log directory (default: {DEFAULT_AUDIT_DIR})",
    )
    parser.add_argument(
        "--auditd-conf",
        type=Path,
        default=DEFAULT_AUDITD_CONF,
        help=f"auditd.conf path used for defaults (default: {DEFAULT_AUDITD_CONF})",
    )
    parser.add_argument(
        "--keep-files",
        type=positive_int,
        default=None,
        help="maximum audit.log* files to keep, including active audit.log",
    )
    parser.add_argument(
        "--keep-size-mib",
        type=positive_int,
        default=None,
        help="maximum total audit.log* size to keep, in MiB",
    )
    return parser.parse_args()


def positive_int(value: str) -> int:
    parsed = int(value)
    if parsed <= 0:
        raise argparse.ArgumentTypeError("must be positive")
    return parsed


def parse_auditd_conf(path: Path) -> dict[str, str]:
    settings: dict[str, str] = {}
    if not path.exists():
        return settings

    for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith("#") or "=" not in stripped:
            continue
        key, value = stripped.split("=", 1)
        settings[key.strip()] = value.strip()
    return settings


def int_setting(settings: dict[str, str], key: str, fallback: int) -> int:
    raw = settings.get(key)
    if raw is None:
        return fallback
    match = re.match(r"^[0-9]+", raw)
    if match is None:
        return fallback
    parsed = int(match.group(0))
    return parsed if parsed > 0 else fallback


def discover_logs(audit_dir: Path) -> list[AuditFile]:
    if not audit_dir.exists():
        raise SystemExit(f"audit directory does not exist: {audit_dir}")
    if not audit_dir.is_dir():
        raise SystemExit(f"audit path is not a directory: {audit_dir}")

    logs: list[AuditFile] = []
    for path in audit_dir.glob("audit.log*"):
        try:
            stat = path.stat()
        except FileNotFoundError:
            continue
        if not path.is_file():
            continue
        logs.append(
            AuditFile(
                path=path,
                size=stat.st_size,
                mtime_ns=stat.st_mtime_ns,
                is_active=(path.name == "audit.log"),
            )
        )
    return sorted(logs, key=lambda item: (item.is_active, item.mtime_ns), reverse=True)


def plan_deletions(logs: list[AuditFile], keep_files: int, keep_size_bytes: int) -> list[AuditFile]:
    kept: list[AuditFile] = []
    delete: list[AuditFile] = []
    kept_size = 0

    # Keep active audit.log if present. It is still owned by auditd, so this script
    # never deletes it; use --rotate to turn it into a rotated file first.
    for log in sorted(logs, key=lambda item: (item.is_active, item.mtime_ns), reverse=True):
        if log.is_active:
            kept.append(log)
            kept_size += log.size
            continue

        would_fit_count = len(kept) < keep_files
        would_fit_size = kept_size + log.size <= keep_size_bytes
        if would_fit_count and would_fit_size:
            kept.append(log)
            kept_size += log.size
        else:
            delete.append(log)

    # Delete oldest first when applying.
    return sorted(delete, key=lambda item: item.mtime_ns)


def active_log(logs: list[AuditFile]) -> AuditFile | None:
    return next((log for log in logs if log.is_active), None)


def active_exceeds_max_log_file(logs: list[AuditFile], max_log_file_bytes: int) -> bool:
    active = active_log(logs)
    return active is not None and active.size > max_log_file_bytes


def human_size(size: int) -> str:
    units = ["B", "KiB", "MiB", "GiB", "TiB"]
    value = float(size)
    for unit in units:
        if value < 1024 or unit == units[-1]:
            if unit == "B":
                return f"{int(value)} {unit}"
            return f"{value:.1f} {unit}"
        value /= 1024
    raise AssertionError("unreachable")


def print_inventory(
    logs: list[AuditFile],
    deletions: list[AuditFile],
    keep_files: int,
    keep_size_bytes: int,
    max_log_file_bytes: int,
) -> None:
    total = sum(log.size for log in logs)
    delete_set = {log.path for log in deletions}

    print("Audit log maintenance")
    print(f"audit files: {len(logs)}")
    print(f"current size: {human_size(total)}")
    print(f"retention target: {keep_files} files, {human_size(keep_size_bytes)}")
    print()

    if not logs:
        print("No audit.log* files found.")
        return

    print("Files:")
    for log in logs:
        action = "delete" if log.path in delete_set else "keep"
        active = " active" if log.is_active else ""
        print(f"  [{action}] {log.path} ({human_size(log.size)}{active})")

    print()
    if deletions:
        delete_size = sum(log.size for log in deletions)
        print(f"Planned deletion: {len(deletions)} files, {human_size(delete_size)}")
    else:
        print("Planned deletion: none")

    active = active_log(logs)
    if active is not None and active.size > max_log_file_bytes:
        print()
        print(
            "Active audit.log exceeds max_log_file; it must be rotated before "
            "it can be pruned."
        )
        print("Run with --apply to auto-rotate and prune, or --rotate to rotate only.")


def require_root() -> None:
    if os.geteuid() != 0:
        raise SystemExit("--apply/--rotate requires root; run with sudo")


def confirm_apply(
    args: argparse.Namespace, deletions: list[AuditFile], rotate_needed: bool
) -> None:
    if args.yes:
        return

    print()
    print("This will:")
    if rotate_needed:
        reason = "oversized active audit.log" if not args.rotate else "requested --rotate"
        print(f"  - send SIGUSR1 to auditd.service to rotate active audit.log ({reason})")
    if args.apply and deletions:
        print("  - delete the old rotated audit files marked [delete]")
    elif args.apply:
        print("  - delete no files unless rotation creates files beyond retention")
    else:
        print("  - delete no files")
    print("It will never delete the active audit.log file directly.")
    answer = input("Apply audit log maintenance? [y/N] ")
    if answer not in {"y", "Y", "yes", "YES"}:
        raise SystemExit("Aborted")


def confirm_deletions_after_rotation(
    args: argparse.Namespace, deletions: list[AuditFile]
) -> None:
    if args.yes or not args.apply or not deletions:
        return

    answer = input("Delete rotated files marked [delete]? [y/N] ")
    if answer not in {"y", "Y", "yes", "YES"}:
        raise SystemExit("Aborted")


def auditctl_signal(signal: str) -> bool:
    if shutil.which("auditctl") is None:
        return False
    subprocess.run(["auditctl", "--signal", signal], check=True)
    return True


def active_rotated(audit_dir: Path, before: AuditFile | None) -> bool:
    if before is None:
        return True

    logs = discover_logs(audit_dir)
    active = active_log(logs)
    if active is None or active.size < before.size:
        return True

    return any((not log.is_active) and log.size >= before.size for log in logs)


def wait_for_rotation(audit_dir: Path, before: AuditFile | None) -> bool:
    for _ in range(20):
        if active_rotated(audit_dir, before):
            return True
        time.sleep(0.25)
    return False


def direct_auditd_usr1() -> bool:
    show = subprocess.run(
        ["systemctl", "show", "--property", "MainPID", "--value", "auditd.service"],
        check=False,
        text=True,
        capture_output=True,
    )
    pid = show.stdout.strip()
    if not pid or pid == "0":
        return False
    subprocess.run(["kill", "-USR1", pid], check=True)
    return True


def rotate_auditd(audit_dir: Path) -> None:
    before = active_log(discover_logs(audit_dir))

    if shutil.which("auditctl") is not None:
        print("Reloading auditd config")
        subprocess.run(["auditctl", "--signal", "reload"], check=True)

    print("Rotating auditd active log")
    if auditctl_signal("rotate") and wait_for_rotation(audit_dir, before):
        return

    subprocess.run(
        ["systemctl", "kill", "--signal=USR1", "auditd.service"],
        check=True,
    )
    if wait_for_rotation(audit_dir, before):
        return

    if direct_auditd_usr1() and wait_for_rotation(audit_dir, before):
        return

    raise SystemExit(
        "auditd did not rotate audit.log after reload and rotate signals; "
        "check `sudo systemctl status auditd.service` and "
        "`sudo auditctl --signal rotate`."
    )


def delete_files(deletions: list[AuditFile]) -> None:
    for log in deletions:
        try:
            log.path.unlink()
        except FileNotFoundError:
            continue
        print(f"Deleted {log.path} ({human_size(log.size)})")


def main() -> int:
    args = parse_args()
    if args.yes and not args.apply and not args.rotate:
        raise SystemExit("--yes only has an effect with --apply or --rotate")

    settings = parse_auditd_conf(args.auditd_conf)
    keep_files = args.keep_files or int_setting(settings, "num_logs", FALLBACK_NUM_LOGS)
    max_log_file_mib = int_setting(settings, "max_log_file", FALLBACK_MAX_LOG_FILE_MIB)
    keep_size_mib = args.keep_size_mib or (keep_files * max_log_file_mib)
    keep_size_bytes = keep_size_mib * 1024 * 1024
    max_log_file_bytes = max_log_file_mib * 1024 * 1024

    logs = discover_logs(args.audit_dir)
    deletions = plan_deletions(logs, keep_files, keep_size_bytes)
    rotate_needed = args.rotate or active_exceeds_max_log_file(logs, max_log_file_bytes)
    print_inventory(logs, deletions, keep_files, keep_size_bytes, max_log_file_bytes)

    if not args.apply and not args.rotate:
        print()
        print("Dry run only. Re-run with --apply to clean, or --rotate to rotate only.")
        return 0

    require_root()
    confirm_apply(args, deletions, rotate_needed)

    if rotate_needed:
        rotate_auditd(args.audit_dir)
        logs = discover_logs(args.audit_dir)
        deletions = plan_deletions(logs, keep_files, keep_size_bytes)
        print()
        print("Post-rotation deletion plan:")
        print_inventory(logs, deletions, keep_files, keep_size_bytes, max_log_file_bytes)
        confirm_deletions_after_rotation(args, deletions)

    if args.apply:
        delete_files(deletions)

    print()
    print("Post-maintenance state:")
    logs = discover_logs(args.audit_dir)
    deletions = plan_deletions(logs, keep_files, keep_size_bytes)
    print_inventory(logs, deletions, keep_files, keep_size_bytes, max_log_file_bytes)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
