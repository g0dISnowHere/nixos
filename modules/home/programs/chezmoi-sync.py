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
HOSTS = {"albaldah", "alhena", "centauri", "karaka", "mirach"}
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
    secret = Path("/run/secrets/djoolz-gh-hosts")
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
        run(["ps", "-u", str(os.getuid()), "-o", "comm="], check=True)
        .stdout.splitlines()
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


def targets_for(source, host, data):
    names = list(data.get("sharedPaths", []))
    if host in data.get("desktopHosts", []):
        names.extend(data.get("desktopPaths", []))
    return names


def source_target_map(source, targets):
    mapping = {}
    for target in targets:
        result = chezmoi(source, "source-path", str(Path.home() / target), check=False)
        if result.returncode:
            continue
        path = Path(result.stdout.strip())
        try:
            relative = (
                path.resolve(strict=False)
                .relative_to(Path(source).resolve())
                .as_posix()
            )
        except ValueError:
            raise RuntimeError("chezmoi source path escapes its source directory")
        # `.tmpl` sources and credential-bearing destinations are never captured.
        if relative.endswith(".tmpl") or target in SENSITIVE_CAPTURE_TARGETS:
            continue
        mapping[relative] = target
    return mapping


def is_credential_placeholder(value):
    return isinstance(value, str) and re.fullmatch(
        r"\$\{[A-Za-z_][A-Za-z0-9_]*\}|\$[A-Za-z_][A-Za-z0-9_]*|"
        r"\{env:[A-Za-z_][A-Za-z0-9_]*\}",
        value.strip(),
        re.IGNORECASE,
    ) is not None


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




def runtime_secret_paths(host, data):
    paths = list(data.get("sharedSecrets", []))
    if host in data.get("desktopHosts", []):
        paths.extend(data.get("desktopSecrets", []))
    return paths


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
                if isinstance(item, str) and item and not is_credential_placeholder(item):
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


def runtime_secret_values(host, data):
    values = []
    for secret_path in runtime_secret_paths(host, data):
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


def check_secrets(host, data):
    missing = [
        path
        for path in runtime_secret_paths(host, data)
        if not os.path.isfile(path) or not os.access(path, os.R_OK)
    ]
    if missing:
        raise RuntimeError(f"required runtime secrets unavailable ({len(missing)})")


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
def check_publisher_branch(source):
    branch = git(source, "rev-parse", "--abbrev-ref", "HEAD").stdout.strip()
    if branch != "main":
        raise RuntimeError("Centauri publisher must use the main branch")
    if upstream(source) != "origin/main":
        raise RuntimeError("Centauri publisher must track origin/main")
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
    host = run(["hostname", "-s"]).stdout.strip().lower()
    if host not in HOSTS or os.environ.get("USER") != "djoolz":
        log("skip: unsupported host or user")
        return 0

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
        if host == "centauri":
            raise RuntimeError(
                "Centauri source is absent; refusing to initialize its authority"
            )
        clone_remote(str(source))
        log("bootstrapped an absent source from the private remote")
    if not (source / ".git").exists():
        raise RuntimeError("source exists without Git metadata; preserving it")

    data = read_metadata(source)
    targets = targets_for(source, host, data)
    mapping = source_target_map(source, targets)
    allowed_sources = set(mapping)
    check_secrets(host, data)
    check_remote(source)
    check_auth()
    # A pre-existing, uncommitted source is user-owned state; never stash or clean it.
    if status(source):
        raise RuntimeError("source tree is dirty; refusing to modify it")

    if host == "centauri":
        git(source, "fetch", "origin")
        origin_ref = check_publisher_branch(source)
        head = git(source, "rev-parse", "HEAD").stdout.strip()
        remote_head = git(source, "rev-parse", origin_ref).stdout.strip()
        if git(
            source,
            "merge-base",
            "--is-ancestor",
            origin_ref,
            "HEAD",
            check=False,
        ).returncode:
            raise RuntimeError(
                "origin/main is ahead of or diverged from Centauri; refusing incoming changes"
            )

        processes = active_processes()
        runtime_secrets = runtime_secret_values(host, data)
        candidates = []
        for target in mapping.values():
            destination = Path.home() / target
            if (
                target not in busy_targets([target], processes)
                and destination.is_file()
                and not destination.is_symlink()
            ):
                candidates.append((target, destination))
        for _, destination in candidates:
            check_capture_bytes(destination.read_bytes(), runtime_secrets)
        for _, destination in candidates:
            chezmoi(source, "re-add", str(destination))

        changed = set(
            git(source, "diff", "--name-only", "-z").stdout.rstrip("\0").split("\0")
        ) - {""}
        if not changed:
            if head != remote_head:
                git(source, "push", "origin", check=True)
                set_applied(marker, head)
                log("published previously committed managed settings from Centauri")
            else:
                log("no managed plain-file changes to publish")
            return 0
        if not changed <= allowed_sources:
            raise RuntimeError(
                "capture changed a template, script, metadata, or unexpected source entry"
            )
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
        git(source, "push", "origin", check=True)
        revision = git(source, "rev-parse", "HEAD").stdout.strip()
        set_applied(marker, revision)
        log("published managed plain-file changes from Centauri")
        return 0

    if git(source, "rev-parse", "--verify", "HEAD", check=False).returncode:
        raise RuntimeError(
            "uninitialized local source preserved; refusing bootstrap overwrite"
        )

    git(source, "fetch", "origin")
    remote_ref = upstream(source)
    head = git(source, "rev-parse", "HEAD").stdout.strip()
    remote_head = git(source, "rev-parse", remote_ref).stdout.strip()
    previous = marker.read_text(encoding="ascii").strip() if marker.exists() else None
    bootstrap = previous is None
    recovery = previous is not None and previous != head
    if previous is not None and git(
        source,
        "merge-base",
        "--is-ancestor",
        previous,
        remote_ref,
        check=False,
    ).returncode:
        raise RuntimeError("applied source marker is not in remote history")
    if git(
        source,
        "merge-base",
        "--is-ancestor",
        "HEAD",
        remote_ref,
        check=False,
    ).returncode:
        raise RuntimeError(
            "private source is not a fast-forward; preserving local history"
        )
    if head == remote_head and previous == head:
        log("skip: source revision already applied")
        return 0

    base = previous or head
    changed = set(
        git(source, "diff", "--name-only", "-z", f"{base}..{remote_ref}")
        .stdout.rstrip("\0")
        .split("\0")
    ) - {""}
    if not bootstrap and not changed <= allowed_sources:
        raise RuntimeError(
            "remote update changes templates, scripts, metadata, or unexpected source entries"
        )
    changed_targets = [mapping[path] for path in sorted(changed) if path in mapping]
    if not bootstrap and len(changed_targets) != len(changed):
        raise RuntimeError("remote update contains an unmanaged source change")
    affected = targets if bootstrap or recovery else changed_targets

    sources_by_target = {target: path for path, target in mapping.items()}
    apply_targets = []
    preserved = 0
    for target in affected:
        state = target_state(source, target)
        if recovery and state == "diverged" and target in changed_targets:
            original = git(
                source, "rev-parse", f"{previous}:{sources_by_target[target]}", check=False
            )
            current = git(
                source,
                "hash-object",
                "--no-filters",
                "--",
                str(home / target),
                check=False,
            )
            if (
                not original.returncode
                and not current.returncode
                and original.stdout == current.stdout
            ):
                state = "previous"
        if state == "diverged":
            preserved += 1
        elif state in {"missing", "previous"} or (
            state == "matches" and target in changed_targets and head != remote_head
        ):
            apply_targets.append(target)
    if preserved:
        raise RuntimeError(
            f"native destinations differ from the current source; preserving local edits ({preserved})"
        )

    check_other_logins(apply_targets)
    check_secrets(host, data)
    check_auth()
    processes = active_processes()
    busy = busy_targets(apply_targets, processes)
    if busy:
        log(f"skip: affected application is running ({len(busy)} managed targets)")
        return 0

    if head != remote_head:
        git(source, "merge", "--ff-only", remote_ref)
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
    revision = git(source, "rev-parse", "HEAD").stdout.strip()
    set_applied(marker, revision)
    log("applied the fast-forwarded private source")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as error:
        # Error messages intentionally omit subprocess output and file contents.
        log(f"skip: {error}")
        sys.exit(1)
