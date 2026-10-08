#!/usr/bin/env python3
"""Conservative scheduled synchronization for the native chezmoi source."""

import atexit
import fcntl
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tarfile
import tempfile
import time
import tomllib

REMOTE = "https://github.com/g0dISnowHere/dotfiles.git"
# These applications write their native configuration when running or exiting.
WRITERS = {
    ".config/btop/": {"btop"},
    ".config/zellij/": {"zellij"},
    ".config/OrcaSlicer/": {"OrcaSlicer", "orcaslicer", "orca-slicer"},
    ".var/app/com.prusa3d.PrusaSlicer/": {
        "prusa-slicer",
        "prusa-slicer-b",
        "prusa-slicer-bin",
    },
    ".var/app/org.freecad.FreeCAD/": {"FreeCAD"},
}
SENSITIVE_CAPTURE_TARGETS = {".config/gh/hosts.yml"}
SECRET_PATTERN = re.compile(
    r"(?:gh[pousr]_[A-Za-z0-9_]{20,}|github_pat_[A-Za-z0-9_]{20,}|"
    r"sk-or-v1-[A-Za-z0-9]{20,}|\bBearer\s+\S+|"
    r"(?:api[_-]?key|access[_-]?token|refresh[_-]?token|password|"
    r"authorization|cookie|secret|token)\s*[:=]\s*"
    r"(?!\$\{[A-Za-z_][A-Za-z0-9_]*\}|\$[A-Za-z_][A-Za-z0-9_]*|"
    r"\{env:[A-Za-z_][A-Za-z0-9_]*\})\S+)",
    re.IGNORECASE,
)
SECRET_VALUE_PATTERN = re.compile(
    r"""(?im)^[ \t]*["']?[A-Za-z0-9_.-]*(?:api[_-]?key|access[_-]?token|"""
    r"""refresh[_-]?token|oauth[_-]?token|password|secret|token)["']?[ \t]*[:=][ \t]*"""
    r"""(?:"([^"\r\n]*)"|'([^'\r\n]*)'|([^,\s#}\r\n]+))"""
)


def log(message):
    print(f"chezmoi-sync: {message}", flush=True)


def run(args, *, cwd=None, check=True, capture=True, env=None):
    result = subprocess.run(
        [str(arg) for arg in args],
        cwd=cwd,
        env=env,
        text=True,
        stdout=subprocess.PIPE if capture else subprocess.DEVNULL,
        stderr=subprocess.PIPE if capture else subprocess.DEVNULL,
        check=False,
    )
    if check and result.returncode:
        raise RuntimeError(f"command failed ({result.returncode}): {args[0]}")
    return result


def credential_env():
    env = os.environ.copy()
    for name in (
        "GH_TOKEN",
        "GITHUB_TOKEN",
        "GH_ENTERPRISE_TOKEN",
        "GITHUB_ENTERPRISE_TOKEN",
    ):
        env.pop(name, None)
    if AUTH_CONFIG is not None:
        env["GH_CONFIG_DIR"] = str(AUTH_CONFIG)
    return env


def setup_auth_config(state_dir):
    global AUTH_CONFIG
    secret_path = os.environ.get("CHEZMOI_GH_HOSTS")
    if not secret_path:
        return
    secret = Path(secret_path)
    if not secret.is_file() or not os.access(secret, os.R_OK):
        raise RuntimeError("runtime GitHub credential file unavailable")
    AUTH_CONFIG = Path(tempfile.mkdtemp(prefix="gh-config-", dir=state_dir))
    AUTH_CONFIG.chmod(0o700)
    os.symlink(secret, AUTH_CONFIG / "hosts.yml")
    atexit.register(shutil.rmtree, AUTH_CONFIG, ignore_errors=True)


AUTH_CONFIG = None


def git(source, *args, check=True, capture=True):
    env = credential_env()
    env.update({"GIT_TERMINAL_PROMPT": "0", "GCM_INTERACTIVE": "never"})
    return run(
        [
            "git",
            "-c",
            "credential.helper=",
            "-c",
            "credential.helper=!gh auth git-credential",
            "-C",
            source,
            *args,
        ],
        check=check,
        capture=capture,
        env=env,
    )


def clone_remote(destination):
    run(
        [
            "git",
            "-c",
            "credential.helper=",
            "-c",
            "credential.helper=!gh auth git-credential",
            "clone",
            "--origin",
            "origin",
            REMOTE,
            destination,
        ],
        capture=False,
        env={
            **credential_env(),
            "GIT_TERMINAL_PROMPT": "0",
            "GCM_INTERACTIVE": "never",
        },
    )


def chezmoi(source, *args, check=True, capture=True):
    return run(
        ["chezmoi", f"--source={source}", "--no-tty", *args],
        check=check,
        capture=capture,
    )


def status(source):
    return git(source, "status", "--porcelain=v1", "--untracked-files=all").stdout


def active_processes():
    return set(
        run(
            ["ps", "-u", str(os.getuid()), "-o", "comm="], check=True
        ).stdout.splitlines()
    )


def busy_targets(targets, processes):
    busy = []
    for target in targets:
        for prefix, names in WRITERS.items():
            if target.startswith(prefix) and processes.intersection(names):
                busy.append(target)
                break
    return busy


def read_metadata(source):
    with (Path(source) / ".chezmoidata.toml").open("rb") as metadata:
        return tomllib.load(metadata)


def plain_targets(data):
    return list(data.get("plainPaths", []))


def secret_target_map(data):
    targets = data.get("secretTargets", {})
    if not isinstance(targets, dict):
        raise RuntimeError("secretTargets must be a destination-to-paths map")
    return targets


def expected_secret_paths():
    raw = os.environ.get("CHEZMOI_EXPECTED_SECRETS")
    if raw is None:
        return None
    try:
        declared = json.loads(raw)
    except json.JSONDecodeError:
        raise RuntimeError("CHEZMOI_EXPECTED_SECRETS is not valid JSON") from None
    if not isinstance(declared, list) or any(
        not isinstance(path, str) for path in declared
    ):
        raise RuntimeError("CHEZMOI_EXPECTED_SECRETS must be a JSON string array")
    missing = [
        path
        for path in declared
        if not os.path.isfile(path) or not os.access(path, os.R_OK)
    ]
    if missing:
        raise RuntimeError(f"required runtime secrets unavailable ({len(missing)})")
    return set(declared)


def provisioned_secret_paths(data, expected):
    dependencies = {
        path
        for paths in secret_target_map(data).values()
        if isinstance(paths, list)
        for path in paths
        if isinstance(path, str)
    }
    if expected is not None:
        unmatched = expected - dependencies
        if unmatched:
            raise RuntimeError(
                "declared runtime secret paths do not match source dependencies"
            )
        return expected
    return {
        path
        for path in dependencies
        if os.path.isfile(path) and os.access(path, os.R_OK)
    }


def credential_targets(data, available_secrets):
    return [
        target
        for target, dependencies in secret_target_map(data).items()
        if isinstance(dependencies, list)
        and dependencies
        and all(path in available_secrets for path in dependencies)
    ]


def source_target_map(source, targets, *, include_templates=False):
    mapping = {}
    for target in targets:
        result = chezmoi(source, "source-path", str(Path.home() / target), check=False)
        if result.returncode:
            raise RuntimeError("declared managed target has no source entry")
        path = Path(result.stdout.strip())
        try:
            relative = (
                path.resolve(strict=False)
                .relative_to(Path(source).resolve())
                .as_posix()
            )
        except ValueError:
            raise RuntimeError("chezmoi source path escapes its source directory")
        if (
            relative.endswith(".tmpl") and not include_templates
        ) or target in SENSITIVE_CAPTURE_TARGETS:
            continue
        mapping[relative] = target
    return mapping


def is_credential_placeholder(value):
    return (
        isinstance(value, str)
        and re.fullmatch(
            r"\$\{[A-Za-z_][A-Za-z0-9_]*\}|\$[A-Za-z_][A-Za-z0-9_]*|"
            r"\{env:[A-Za-z_][A-Za-z0-9_]*\}",
            value.strip(),
            re.IGNORECASE,
        )
        is not None
    )


def contains_credential_fields(value):
    sensitive_keys = {
        "accesstoken",
        "apikey",
        "authorization",
        "cookie",
        "password",
        "refreshtoken",
        "secret",
        "token",
    }
    if isinstance(value, dict):
        for key, item in value.items():
            normalized = re.sub(r"[-_]", "", key.casefold())
            sensitive = normalized in sensitive_keys or normalized.endswith(
                (
                    "accesstoken",
                    "apikey",
                    "authorization",
                    "cookie",
                    "password",
                    "refreshtoken",
                    "secret",
                    "token",
                )
            )
            if sensitive and item not in (None, "", False):
                if not is_credential_placeholder(item):
                    return True
            if contains_credential_fields(item):
                return True
    elif isinstance(value, list):
        return any(contains_credential_fields(item) for item in value)
    return False


def check_capture_bytes(contents, runtime_secrets):
    text = contents.decode("utf-8", errors="ignore")
    if SECRET_PATTERN.search(text):
        raise RuntimeError("credential-like content found; refusing to publish")
    if contains_runtime_secret(contents, runtime_secrets):
        raise RuntimeError("runtime secret value found; refusing to publish")
    try:
        decoded = json.loads(contents)
    except (UnicodeError, json.JSONDecodeError):
        decoded = None
    if decoded is not None and contains_credential_fields(decoded):
        raise RuntimeError("credential-bearing setting found; refusing to publish")


def target_state(source, target):
    destination = Path.home() / target
    verified = chezmoi(
        source,
        "verify",
        "--",
        str(destination),
        check=False,
    )
    if verified.returncode == 0:
        return "matches"
    if destination.exists() or destination.is_symlink():
        return "diverged"
    return "missing"


def check_other_logins(targets):
    auth = Path.home() / ".local/share/opencode/auth.json"
    if ".local/share/opencode/auth.json" not in targets or not auth.exists():
        return
    try:
        document = json.loads(auth.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError):
        raise RuntimeError(
            "existing OpenCode authentication is unreadable; preserving it"
        )
    if not isinstance(document, dict) or set(document) - {"openrouter"}:
        raise RuntimeError(
            "existing OpenCode login is not the expected OpenRouter API-key entry"
        )
    serialized = json.dumps(document).lower()
    if any(
        marker in serialized for marker in ("oauth", "refresh_token", "access_token")
    ):
        raise RuntimeError(
            "existing OpenCode OAuth/login record detected; preserving it"
        )


def runtime_secret_paths(data, available_secrets):
    return [
        path
        for paths in secret_target_map(data).values()
        for path in paths
        if path in available_secrets
    ]


def credential_values(value):
    values = []
    if isinstance(value, dict):
        for key, item in value.items():
            normalized = re.sub(r"[-_]", "", key.casefold())
            if normalized == "key" or normalized.endswith(
                (
                    "apikey",
                    "accesstoken",
                    "refreshtoken",
                    "oauthtoken",
                    "password",
                    "secret",
                    "token",
                )
            ):
                if (
                    isinstance(item, str)
                    and item
                    and not is_credential_placeholder(item)
                ):
                    values.append(item.encode())
            values.extend(credential_values(item))
    elif isinstance(value, list):
        for item in value:
            values.extend(credential_values(item))
    elif isinstance(value, str):
        for match in SECRET_VALUE_PATTERN.finditer(value):
            secret = next((group for group in match.groups() if group), "")
            if secret and not is_credential_placeholder(secret):
                values.append(secret.encode())
    return values


def runtime_secret_values(data, available_secrets):
    values = []
    for secret_path in runtime_secret_paths(data, available_secrets):
        payload = Path(secret_path).read_bytes().strip()
        if not payload:
            continue
        values.append(payload)
        try:
            document = json.loads(payload)
        except (UnicodeError, json.JSONDecodeError):
            document = None
        values.extend(credential_values(document))
        text = payload.decode("utf-8", errors="ignore")
        for match in SECRET_VALUE_PATTERN.finditer(text):
            value = next((group for group in match.groups() if group), "")
            if value and not is_credential_placeholder(value):
                values.append(value.encode())
    return values


def contains_runtime_secret(contents, values):
    return any(value in contents for value in values)


def check_auth():
    result = run(
        ["gh", "auth", "status", "--hostname", "github.com"],
        check=False,
        env=credential_env(),
    )
    if result.returncode:
        raise RuntimeError("native GitHub CLI authentication unavailable")


def check_remote(source):
    url = git(source, "remote", "get-url", "origin", check=False)
    if url.returncode or url.stdout.strip() != REMOTE:
        raise RuntimeError("expected private HTTPS origin is not configured")


def upstream(source):
    ref = git(
        source,
        "rev-parse",
        "--abbrev-ref",
        "--symbolic-full-name",
        "@{upstream}",
        check=False,
    )
    if ref.returncode:
        raise RuntimeError("source branch has no configured upstream")
    return ref.stdout.strip()


def check_main_branch(source):
    branch = git(source, "rev-parse", "--abbrev-ref", "HEAD").stdout.strip()
    if branch != "main":
        raise RuntimeError("private source must use the main branch")
    if upstream(source) != "origin/main":
        raise RuntimeError("private source must track origin/main")
    return "origin/main"


def set_applied(state_file, revision):
    state_file.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
    temporary = state_file.with_suffix(".tmp")
    temporary.write_text(revision + "\n", encoding="ascii")
    temporary.chmod(0o600)
    temporary.replace(state_file)


def source_fingerprint(root):
    root = Path(root)
    entries = []
    for path in sorted(root.rglob("*")):
        relative = path.relative_to(root).as_posix()
        mode = path.lstat().st_mode
        if path.is_symlink():
            entries.append((relative, "link", mode, os.readlink(path)))
        elif path.is_dir():
            entries.append((relative, "dir", mode, ""))
        elif path.is_file():
            digest = hashlib.sha256(path.read_bytes()).hexdigest()
            entries.append((relative, "file", mode, digest))
        else:
            raise RuntimeError("source contains an unsupported filesystem entry")
    return entries


def archive_unborn_source(source, state_dir):
    remotes = git(source, "remote", check=False).stdout.splitlines()
    if any(name != "origin" for name in remotes):
        raise RuntimeError("unborn source has an unexpected remote; preserving it")
    if (
        "origin" in remotes
        and git(source, "remote", "get-url", "origin").stdout.strip() != REMOTE
    ):
        raise RuntimeError("unborn source origin is not the approved private remote")
    if git(source, "for-each-ref", "--format=%(refname)").stdout.strip():
        raise RuntimeError("existing source has refs; preserving it")
    if git(source, "rev-parse", "--verify", "HEAD", check=False).returncode == 0:
        raise RuntimeError("existing source has a commit; preserving it")

    stamp = f"{time.strftime('%Y%m%dT%H%M%S', time.gmtime())}-{time.time_ns()}"
    archive = state_dir / f"unborn-source-{stamp}.tar.gz"
    extraction = Path(tempfile.mkdtemp(prefix="source-check-", dir=state_dir))
    try:
        with tarfile.open(archive, "w:gz") as tar:
            tar.add(source, arcname="source", recursive=True)
        archive.chmod(0o600)
        with tarfile.open(archive, "r:gz") as tar:
            tar.extractall(extraction, filter="data")
        restored = extraction / "source"
        if source_fingerprint(source) != source_fingerprint(restored):
            raise RuntimeError("existing source archive recovery proof failed")
        os.replace(source, state_dir / f"unborn-source-{stamp}")
        log(
            "preserved and extraction-verified the existing uncommitted source privately"
        )
    finally:
        shutil.rmtree(extraction)


def main():
    if os.environ.get("USER") != "djoolz":
        log("skip: unsupported user")
        return 0

    expected_secrets = expected_secret_paths()
    home = Path.home()
    state_dir = home / ".local/state/chezmoi-sync"
    state_dir.mkdir(mode=0o700, parents=True, exist_ok=True)
    state_dir.chmod(0o700)
    lock = (state_dir / "worker.lock").open("a")
    try:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError:
        log("skip: another synchronization is running")
        return 0
    setup_auth_config(state_dir)

    source = home / ".local/share/chezmoi"
    marker = state_dir / "applied-revision"
    if source.exists() and (source / ".git").exists():
        if git(source, "rev-parse", "--verify", "HEAD", check=False).returncode:
            archive_unborn_source(source, state_dir)
            source.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
            clone_remote(str(source))
            log("cloned the private source after preserving the unborn local source")
    elif not source.exists():
        source.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
        clone_remote(str(source))
        log("bootstrapped an absent source from the private remote")
    if not (source / ".git").exists():
        raise RuntimeError("source exists without Git metadata; preserving it")
    data = read_metadata(source)
    available_secrets = provisioned_secret_paths(data, expected_secrets)
    plain = plain_targets(data)
    credentials = credential_targets(data, available_secrets)
    targets = list(dict.fromkeys(plain + credentials))
    mapping = source_target_map(source, plain)
    secret_mapping = source_target_map(source, credentials, include_templates=True)
    allowed_sources = set(mapping)
    check_remote(source)
    check_auth()
    # A pre-existing, uncommitted source is user-owned state; never stash or clean it.
    if status(source):
        raise RuntimeError("source tree is dirty; refusing to modify it")

    git(source, "fetch", "origin")
    remote_ref = check_main_branch(source)
    head = git(source, "rev-parse", "HEAD").stdout.strip()
    remote_head = git(source, "rev-parse", remote_ref).stdout.strip()
    base_result = git(source, "merge-base", "HEAD", remote_ref, check=False)
    if base_result.returncode:
        raise RuntimeError("private source histories have no common base")
    base = base_result.stdout.strip()
    local_changes = set(
        git(source, "diff", "--name-only", "-z", f"{base}..HEAD")
        .stdout.rstrip("\0")
        .split("\0")
    ) - {""}
    remote_changes = set(
        git(source, "diff", "--name-only", "-z", f"{base}..{remote_ref}")
        .stdout.rstrip("\0")
        .split("\0")
    ) - {""}
    previous = marker.read_text(encoding="ascii").strip() if marker.exists() else None
    if previous is not None:
        for revision in (head, remote_ref):
            if git(
                source, "merge-base", "--is-ancestor", previous, revision, check=False
            ).returncode:
                raise RuntimeError("applied source marker is not in source history")
        incoming_changes = set(
            git(source, "diff", "--name-only", "-z", f"{previous}..{remote_ref}")
            .stdout.rstrip("\0")
            .split("\0")
        ) - {""}
    else:
        incoming_changes = remote_changes

    if not local_changes <= set(mapping):
        raise RuntimeError(
            "unpublished local commits contain non-host settings; preserving source"
        )
    if not incoming_changes <= allowed_sources:
        raise RuntimeError(
            "incoming update changes templates, scripts, metadata, or unexpected source entries"
        )
    if not remote_changes <= allowed_sources:
        raise RuntimeError(
            "remote update changes templates, scripts, metadata, or unexpected source entries"
        )
    local_targets = {mapping[path] for path in local_changes}
    remote_targets = {mapping[path] for path in remote_changes if path in mapping}
    if local_changes & remote_changes or local_targets & remote_targets:
        raise RuntimeError(
            "local and remote edits target the same managed setting; preserving both"
        )
    runtime_secrets = runtime_secret_values(data, available_secrets)
    for source_file in sorted(local_changes):
        local_file = source / source_file
        if not local_file.is_file():
            raise RuntimeError(
                "unpublished local change is not a plain file; preserving source"
            )
        check_capture_bytes(local_file.read_bytes(), runtime_secrets)
    for source_file in sorted(incoming_changes):
        contents = git(source, "show", f"{remote_ref}:{source_file}").stdout
        check_capture_bytes(contents.encode(), runtime_secrets)

    bootstrap = previous is None
    incoming_targets = {
        (mapping | secret_mapping)[path]
        for path in incoming_changes
        if path in (mapping | secret_mapping)
    }
    target_states = {}
    if bootstrap and head == remote_head:
        target_states = {target: target_state(source, target) for target in targets}
        apply_targets = [
            target for target in targets if target_states[target] != "matches"
        ]
    else:
        apply_targets = targets if bootstrap else sorted(incoming_targets)
    processes = active_processes()
    busy = busy_targets(apply_targets, processes)
    if busy:
        log(f"skip: affected application is running ({len(busy)} managed targets)")
        return 0
    check_other_logins(apply_targets)
    sources_by_target = {
        target: path for path, target in (mapping | secret_mapping).items()
    }
    preserved = 0
    for target in apply_targets:
        state = target_states.get(target)
        if state is None:
            state = target_state(source, target)
            target_states[target] = state
        if state != "diverged":
            continue
        destination = home / target
        if (
            previous is None
            or target not in mapping.values()
            or destination.is_symlink()
        ):
            preserved += 1
            continue
        original = git(
            source, "rev-parse", f"{previous}:{sources_by_target[target]}", check=False
        )
        current = git(
            source,
            "hash-object",
            "--no-filters",
            "--",
            str(destination),
            check=False,
        )
        if (
            original.returncode
            or current.returncode
            or original.stdout != current.stdout
        ):
            preserved += 1
    if preserved:
        raise RuntimeError(
            f"native destinations differ from the incoming source; preserving local edits ({preserved})"
        )
    if head != remote_head:
        if head == base:
            git(source, "merge", "--ff-only", remote_ref)
        else:
            git(source, "merge", "--no-edit", remote_ref)

    if apply_targets:
        chezmoi(
            source,
            "apply",
            "--",
            str(home / "00-verified-backup.sh"),
            capture=False,
        )
        result = chezmoi(
            source,
            "apply",
            "--parent-dirs",
            "--recursive=false",
            "--exclude",
            "scripts",
            "--",
            *[str(home / target) for target in apply_targets],
            check=False,
            capture=False,
        )
        if result.returncode:
            raise RuntimeError(
                "chezmoi apply failed; no force or source reset was attempted"
            )

    processes = active_processes()
    candidates = []
    for source_file, target in mapping.items():
        destination = home / target
        source_entry = source / source_file
        try:
            source_entry.resolve(strict=True).relative_to(source.resolve())
        except (OSError, ValueError):
            raise RuntimeError(
                "managed plain source entry is missing or escapes source"
            )
        if not source_entry.is_file() or source_entry.is_symlink():
            raise RuntimeError("managed plain source entry is not a regular file")
        if (
            target not in busy_targets([target], processes)
            and destination.is_file()
            and not destination.is_symlink()
        ):
            candidates.append((source_file, destination, source_entry))
    captured = []
    for source_file, destination, source_entry in candidates:
        contents = destination.read_bytes()
        check_capture_bytes(contents, runtime_secrets)
        captured.append((source_file, source_entry, contents))
    # Sync contents only; writing existing source entries preserves their paths and permissions.
    for _, source_entry, contents in captured:
        if source_entry.read_bytes() != contents:
            source_entry.write_bytes(contents)

    changed = set(
        git(source, "diff", "--name-only", "-z").stdout.rstrip("\0").split("\0")
    ) - {""}
    if not changed <= set(mapping):
        raise RuntimeError(
            "capture changed a template, script, metadata, or unexpected source entry"
        )
    if changed:
        status_entries = git(
            source,
            "status",
            "--porcelain=v1",
            "-z",
            "--untracked-files=all",
        ).stdout.split("\0")
        status_paths = set()
        for entry in filter(None, status_entries):
            state = entry[:2]
            if state == "??":
                raise RuntimeError("capture created an unexpected source entry")
            if "R" in state or "C" in state:
                raise RuntimeError("capture unexpectedly renamed a source entry")
            status_paths.add(entry[3:])
        if status_paths != changed:
            raise RuntimeError(
                "source changes cannot be classified as managed plain files"
            )
        for source_file in changed:
            check_capture_bytes((source / source_file).read_bytes(), runtime_secrets)
        for source_file in sorted(changed):
            git(source, "add", "--", source_file)
        staged = set(
            git(source, "diff", "--cached", "--name-only", "-z")
            .stdout.rstrip("\0")
            .split("\0")
        ) - {""}
        if staged != changed:
            raise RuntimeError("staging set differs from the audited capture set")
        git(source, "commit", "-m", "capture managed native settings", capture=False)

    revision = git(source, "rev-parse", "HEAD").stdout.strip()
    if revision != remote_head or changed:
        git(source, "push", "origin", check=True)
        log("published managed plain-file changes")
    else:
        log("no managed plain-file changes to publish")
    set_applied(marker, revision)
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as error:
        # Error messages intentionally omit subprocess output and file contents.
        log(f"skip: {error}")
        sys.exit(1)
