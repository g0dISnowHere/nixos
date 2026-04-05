#!/usr/bin/env python3

import argparse
import json
import os
import pathlib
import re
import sys


def load_policy():
    try:
        return json.loads(os.environ["SECRETS_POLICY_JSON"])
    except KeyError as exc:
        raise SystemExit("SECRETS_POLICY_JSON is required") from exc


def managed_secret_files(repo_root):
    secrets_root = pathlib.Path(repo_root) / "secrets"
    if not secrets_root.exists():
        return []

    files = []
    for path in secrets_root.rglob("*"):
        if not path.is_file():
            continue
        if path.suffix not in {".yaml", ".json", ".env", ".ini"}:
            continue
        if path.name.endswith(".example"):
            continue
        files.append(path)
    return sorted(files)


def relpath(path, repo_root):
    return path.relative_to(repo_root).as_posix()


def scope_owners(policy, relative_path):
    owners = []
    match = re.match(r"^secrets/users/([^/]+)/.+\.yaml$", relative_path)
    if match:
        name = match.group(1)
        if name in policy["scopes"]["users"]:
            owners.append(f"users.{name}")

    match = re.match(
        r"^secrets/services/([^/]+)/.+\.(yaml|json|env|ini)$", relative_path
    )
    if match:
        name = match.group(1)
        if name in policy["scopes"]["services"]:
            owners.append(f"services.{name}")

    match = re.match(
        r"^secrets/machines/([^/]+)/.+\.(yaml|json|env|ini)$", relative_path
    )
    if match:
        host = match.group(1)
        if host in policy["hosts"]:
            owners.append(f"machines.{host}")

    return owners


def relevant_files(policy, repo_root, host):
    paths = []

    for name, scope in policy["scopes"]["users"].items():
        if host in scope["hosts"]:
            scope_dir = pathlib.Path(repo_root) / "secrets" / "users" / name
            if scope_dir.exists():
                paths.extend(
                    path
                    for path in scope_dir.rglob("*")
                    if path.is_file() and path.suffix == ".yaml"
                )

    for name, scope in policy["scopes"]["services"].items():
        if host in scope["hosts"]:
            scope_dir = pathlib.Path(repo_root) / "secrets" / "services" / name
            if scope_dir.exists():
                paths.extend(
                    path
                    for path in scope_dir.rglob("*")
                    if path.is_file()
                    and path.suffix in {".yaml", ".json", ".env", ".ini"}
                    and not path.name.endswith(".example")
                )

    machine_dir = pathlib.Path(repo_root) / "secrets" / "machines" / host
    if machine_dir.exists():
        paths.extend(
            path
            for path in machine_dir.rglob("*")
            if path.is_file() and path.suffix in {".yaml", ".json", ".env", ".ini"}
        )

    unique_paths = sorted({path.resolve() for path in paths})
    return [str(path) for path in unique_paths]


def validate_policy(policy, repo_root):
    errors = []
    hosts = set(policy["hosts"])

    for scope_kind in ("users", "services"):
        for name, scope in policy["scopes"][scope_kind].items():
            for host in scope["hosts"]:
                if host not in hosts:
                    errors.append(f"{scope_kind}.{name} references unknown host {host}")

    for host, data in policy["hosts"].items():
        recipient = data.get("recipient", "")
        if not recipient.startswith("age1"):
            errors.append(f"host {host} is missing a valid recipient")

    operator_recipients = policy["operator"].get("recipients", [])
    if not operator_recipients:
        errors.append("operator recipients list is empty")

    for path in managed_secret_files(repo_root):
        relative = relpath(path, repo_root)
        owners = scope_owners(policy, relative)
        if len(owners) != 1:
            errors.append(
                f"{relative} must map to exactly one scope, found {len(owners)}"
            )

    return errors


def shell_quote(value):
    return value.replace("\\", "\\\\").replace('"', '\\"')


def replace_policy_host(policy_path, host, recipient, create):
    text = pathlib.Path(policy_path).read_text(encoding="utf-8")
    host_pattern = re.compile(
        rf"(?ms)^    {re.escape(host)} = \{{\n"
        r'      recipient = "([^"]+)";\n'
        r'(?:      class = "([^"]+)";\n)?'
        r"    \};\n"
    )
    match = host_pattern.search(text)
    if match:
        class_name = match.group(2) or "workstation"
    else:
        if not create:
            raise SystemExit(f"host {host} is missing from policy")
        class_name = "workstation"

    host_block = (
        f"    {host} = {{\n"
        f'      recipient = "{recipient}";\n'
        f'      class = "{class_name}";\n'
        "    };\n"
    )

    hosts_pattern = re.compile(r"(?ms)^  hosts = \{\n(.*?)^  \};\n")
    hosts_match = hosts_pattern.search(text)
    if not hosts_match:
        raise SystemExit("could not locate hosts block")

    blocks = {}
    block_pattern = re.compile(
        r"(?ms)^    ([A-Za-z0-9_-]+) = \{\n"
        r'      recipient = "([^"]+)";\n'
        r'(?:      class = "([^"]+)";\n)?'
        r"    \};\n"
    )
    for block_match in block_pattern.finditer(hosts_match.group(1)):
        alias = block_match.group(1)
        existing_class = block_match.group(3) or "workstation"
        blocks[alias] = (
            f"    {alias} = {{\n"
            f'      recipient = "{block_match.group(2)}";\n'
            f'      class = "{existing_class}";\n'
            "    };\n"
        )

    blocks[host] = host_block
    rendered_hosts = "".join(blocks[name] for name in sorted(blocks))
    updated = text[: hosts_match.start(1)] + rendered_hosts + text[hosts_match.end(1) :]

    users_pattern = re.compile(r"(?ms)^    users = \{\n(.*?)^    \};\n")
    users_match = users_pattern.search(updated)
    if not users_match:
        raise SystemExit("could not locate users block")

    def add_host_to_scope(scope_text):
        host_list_pattern = re.compile(r"hosts = \[ ([^\]]*) \];")
        host_list_match = host_list_pattern.search(scope_text)
        if not host_list_match:
            return scope_text
        host_names = [
            item.strip().strip('"')
            for item in host_list_match.group(1).split()
            if item.strip()
        ]
        if host not in host_names:
            host_names.append(host)
        host_names = sorted(host_names)
        rendered_hosts_list = " ".join(f'"{name}"' for name in host_names)
        return host_list_pattern.sub(f"hosts = [ {rendered_hosts_list} ];", scope_text)

    user_scope_pattern = re.compile(
        r"(?ms)^      ([A-Za-z0-9_-]+) = \{\n"
        r"        hosts = \[ [^\]]* \];\n"
        r"      \};\n"
    )
    rebuilt_users = "".join(
        add_host_to_scope(scope_match.group(0))
        for scope_match in user_scope_pattern.finditer(users_match.group(1))
    )
    updated = (
        updated[: users_match.start(1)] + rebuilt_users + updated[users_match.end(1) :]
    )

    pathlib.Path(policy_path).write_text(updated, encoding="utf-8")


def replace_operator_recipients(policy_path, recipient):
    text = pathlib.Path(policy_path).read_text(encoding="utf-8")
    pattern = re.compile(
        r'(?ms)^  operator = \{\n    alias = "([^"]+)";\n    recipients = \[\n.*?^    \];\n  \};\n'
    )
    match = pattern.search(text)
    if not match:
        raise SystemExit("could not locate operator block")

    replacement = (
        "  operator = {\n"
        f'    alias = "{match.group(1)}";\n'
        "    recipients = [\n"
        f'      "{recipient}"\n'
        "    ];\n"
        "  };\n"
    )
    pathlib.Path(policy_path).write_text(
        text[: match.start()] + replacement + text[match.end() :],
        encoding="utf-8",
    )


def remove_host_from_policy(policy_path, host):
    text = pathlib.Path(policy_path).read_text(encoding="utf-8")

    host_block_pattern = re.compile(
        rf'(?ms)^    {re.escape(host)} = \{{\n'
        r'      recipient = "([^"]+)";\n'
        r'(?:      class = "([^"]+)";\n)?'
        r"    \};\n"
    )
    if not host_block_pattern.search(text):
        raise SystemExit(f"host {host} is missing from policy")
    updated = host_block_pattern.sub("", text, count=1)

    scopes_pattern = re.compile(r"(?ms)^  scopes = \{\n(.*?)^  \};\n")
    scopes_match = scopes_pattern.search(updated)
    if not scopes_match:
        raise SystemExit("could not locate scopes block")

    def remove_from_scope(scope_text):
        host_list_pattern = re.compile(r"hosts = \[ ([^\]]*) \];")
        host_list_match = host_list_pattern.search(scope_text)
        if not host_list_match:
            return scope_text
        host_names = [
            item.strip().strip('"')
            for item in host_list_match.group(1).split()
            if item.strip()
        ]
        host_names = [name for name in host_names if name != host]
        rendered_hosts_list = " ".join(f'"{name}"' for name in sorted(host_names))
        return host_list_pattern.sub(f"hosts = [ {rendered_hosts_list} ];", scope_text)

    scope_item_pattern = re.compile(
        r"(?ms)^      ([A-Za-z0-9_-]+) = \{\n"
        r"        hosts = \[ [^\]]* \];\n"
        r"      \};\n"
    )
    rebuilt_scopes = "".join(
        remove_from_scope(scope_match.group(0))
        for scope_match in scope_item_pattern.finditer(scopes_match.group(1))
    )

    pathlib.Path(policy_path).write_text(
        updated[: scopes_match.start(1)] + rebuilt_scopes + updated[scopes_match.end(1) :],
        encoding="utf-8",
    )


def main():
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest="command", required=True)

    parser_operator_alias = subparsers.add_parser("get-operator-alias")
    parser_operator_recipients = subparsers.add_parser("get-operator-recipients")
    parser_hosts = subparsers.add_parser("list-hosts")
    parser_scopes = subparsers.add_parser("list-scopes")

    parser_host_recipient = subparsers.add_parser("get-host-recipient")
    parser_host_recipient.add_argument("--host", required=True)

    parser_relevant = subparsers.add_parser("list-relevant-files")
    parser_relevant.add_argument("--repo-root", required=True)
    parser_relevant.add_argument("--host", required=True)

    parser_validate = subparsers.add_parser("validate")
    parser_validate.add_argument("--repo-root", required=True)

    parser_set_host = subparsers.add_parser("set-host-recipient")
    parser_set_host.add_argument("--policy-file", required=True)
    parser_set_host.add_argument("--host", required=True)
    parser_set_host.add_argument("--recipient", required=True)
    parser_set_host.add_argument("--create", action="store_true")

    parser_set_operator = subparsers.add_parser("set-operator-recipient")
    parser_set_operator.add_argument("--policy-file", required=True)
    parser_set_operator.add_argument("--recipient", required=True)

    parser_remove_host = subparsers.add_parser("remove-host")
    parser_remove_host.add_argument("--policy-file", required=True)
    parser_remove_host.add_argument("--host", required=True)

    args = parser.parse_args()

    if args.command in {"set-host-recipient", "set-operator-recipient", "remove-host"}:
        if args.command == "set-host-recipient":
            replace_policy_host(
                args.policy_file, args.host, args.recipient, args.create
            )
        elif args.command == "set-operator-recipient":
            replace_operator_recipients(args.policy_file, args.recipient)
        else:
            remove_host_from_policy(args.policy_file, args.host)
        return

    policy = load_policy()

    if args.command == "get-operator-alias":
        print(policy["operator"]["alias"])
        return
    if args.command == "get-operator-recipients":
        for recipient in policy["operator"].get("recipients", []):
            print(recipient)
        return
    if args.command == "list-hosts":
        for host in sorted(policy["hosts"]):
            print(host)
        return
    if args.command == "list-scopes":
        for name in sorted(policy["scopes"]["users"]):
            print(f"users.{name}")
        for name in sorted(policy["scopes"]["services"]):
            print(f"services.{name}")
        for host in sorted(policy["hosts"]):
            print(f"machines.{host}")
        return
    if args.command == "get-host-recipient":
        host = args.host
        if host not in policy["hosts"]:
            raise SystemExit(1)
        print(policy["hosts"][host]["recipient"])
        return
    if args.command == "list-relevant-files":
        for path in relevant_files(policy, args.repo_root, args.host):
            print(path)
        return
    if args.command == "validate":
        errors = validate_policy(policy, pathlib.Path(args.repo_root))
        print(json.dumps({"errors": errors}, indent=2))
        if errors:
            raise SystemExit(1)
        return


if __name__ == "__main__":
    main()
