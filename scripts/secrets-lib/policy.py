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


def parse_host_list(raw_hosts):
    return [item.strip().strip('"') for item in raw_hosts.split() if item.strip()]


def render_host_list(host_names):
    return " ".join(f'"{name}"' for name in sorted(host_names))


def parse_scope_entries(block_text, indent):
    entries = {}
    entry_pattern = re.compile(
        rf"(?m)^{re.escape(indent)}([A-Za-z0-9_-]+) = \{{ hosts = \[ ([^\]]*) \]; \}};\n?"
    )
    for match in entry_pattern.finditer(block_text):
        entries[match.group(1)] = parse_host_list(match.group(2))

    return entries


def render_scope_entries(entries, indent):
    return "".join(
        f"{indent}{name} = {{ hosts = [ {render_host_list(hosts)} ]; }};\n"
        for name, hosts in sorted(entries.items())
    )


def parse_host_entries(block_text):
    entries = {}
    block_pattern = re.compile(
        r"(?ms)^    ([A-Za-z0-9_-]+) = \{\n"
        r'      recipient =\n        "([^"]+)";\n'
        r'(?:      class = "([^"]+)";\n)?'
        r"    \};\n"
    )
    for match in block_pattern.finditer(block_text):
        entries[match.group(1)] = {
            "recipient": match.group(2),
            "class_name": match.group(3) or "workstation",
        }

    return entries


def render_host_entries(entries):
    return "".join(
        (
            f"    {name} = {{\n"
            "      recipient =\n"
            f'        "{data["recipient"]}";\n'
            f'      class = "{data["class_name"]}";\n'
            "    };\n"
        )
        for name, data in sorted(entries.items())
    )


def replace_policy_host(policy_path, host, recipient, create, class_name):
    text = pathlib.Path(policy_path).read_text(encoding="utf-8")
    host_pattern = re.compile(
        rf"(?ms)^    {re.escape(host)} = \{{\n"
        r'      recipient =\n        "([^"]+)";\n'
        r'(?:      class = "([^"]+)";\n)?'
        r"    \};\n"
    )
    match = host_pattern.search(text)
    if match:
        resolved_class_name = match.group(2) or "workstation"
    else:
        if not create:
            raise SystemExit(f"host {host} is missing from policy")
        resolved_class_name = class_name or "workstation"

    if class_name:
        resolved_class_name = class_name

    host_block = (
        f"    {host} = {{\n"
        "      recipient =\n"
        f'        "{recipient}";\n'
        f'      class = "{resolved_class_name}";\n'
        "    };\n"
    )

    hosts_pattern = re.compile(r"(?ms)^  hosts = \{\n(.*?)^  \};\n")
    hosts_match = hosts_pattern.search(text)
    if not hosts_match:
        raise SystemExit("could not locate hosts block")

    blocks = parse_host_entries(hosts_match.group(1))
    blocks[host] = {
        "recipient": recipient,
        "class_name": resolved_class_name,
    }
    rendered_hosts = render_host_entries(blocks)
    updated = text[: hosts_match.start(1)] + rendered_hosts + text[hosts_match.end(1) :]
    pathlib.Path(policy_path).write_text(updated, encoding="utf-8")


def replace_operator_recipients(policy_path, recipients):
    text = pathlib.Path(policy_path).read_text(encoding="utf-8")
    pattern = re.compile(
        r"(?ms)^  operator = \{\n"
        r'    alias = "([^"]+)";\n'
        r"    recipients =(?:\n      \[ [^\n]* \];|\n      \[\n.*?^      \];| \[\n.*?^    \];)\n"
        r"  \};\n"
    )
    match = pattern.search(text)
    if not match:
        raise SystemExit("could not locate operator block")

    rendered_recipients = "".join(f'      "{recipient}"\n' for recipient in recipients)
    replacement = (
        "  operator = {\n"
        f'    alias = "{match.group(1)}";\n'
        "    recipients = [\n"
        f"{rendered_recipients}"
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
        rf"(?ms)^    {re.escape(host)} = \{{\n"
        r'      recipient =\n        "([^"]+)";\n'
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

    scopes_text = scopes_match.group(1)
    for section_name in ("users", "services"):
        section_pattern = re.compile(
            rf"(?ms)^    {section_name} = \{{\n(.*?)^    \}};\n"
        )
        section_match = section_pattern.search(scopes_text)
        if not section_match:
            continue

        entries = parse_scope_entries(section_match.group(1), "      ")
        updated_entries = {
            name: [name_host for name_host in hosts if name_host != host]
            for name, hosts in entries.items()
        }
        rendered_section = render_scope_entries(updated_entries, "      ")
        scopes_text = (
            scopes_text[: section_match.start(1)]
            + rendered_section
            + scopes_text[section_match.end(1) :]
        )

    pathlib.Path(policy_path).write_text(
        updated[: scopes_match.start(1)] + scopes_text + updated[scopes_match.end(1) :],
        encoding="utf-8",
    )


def list_user_scopes(policy):
    for name in sorted(policy["scopes"]["users"]):
        print(name)


def get_user_scope_hosts(policy, user):
    try:
        scope = policy["scopes"]["users"][user]
    except KeyError as exc:
        raise SystemExit(1) from exc

    for host in sorted(scope.get("hosts", [])):
        print(host)


def set_user_scope_hosts(policy_path, user, hosts, create):
    text = pathlib.Path(policy_path).read_text(encoding="utf-8")
    users_pattern = re.compile(r"(?ms)^    users = \{\n(.*?)^    \};\n")
    users_match = users_pattern.search(text)
    if not users_match:
        raise SystemExit("could not locate users block")

    blocks = parse_scope_entries(users_match.group(1), "      ")

    if user not in blocks and not create:
        raise SystemExit(f"user scope {user} is missing from policy")

    blocks[user] = sorted(set(hosts))

    rebuilt_users = render_scope_entries(blocks, "      ")
    updated = text[: users_match.start(1)] + rebuilt_users + text[users_match.end(1) :]
    pathlib.Path(policy_path).write_text(updated, encoding="utf-8")


def remove_user_scope(policy_path, user):
    text = pathlib.Path(policy_path).read_text(encoding="utf-8")
    users_pattern = re.compile(r"(?ms)^    users = \{\n(.*?)^    \};\n")
    users_match = users_pattern.search(text)
    if not users_match:
        raise SystemExit("could not locate users block")

    blocks = parse_scope_entries(users_match.group(1), "      ")
    if user not in blocks:
        raise SystemExit(f"user scope {user} is missing from policy")

    del blocks[user]
    rebuilt_users = render_scope_entries(blocks, "      ")
    updated = text[: users_match.start(1)] + rebuilt_users + text[users_match.end(1) :]
    pathlib.Path(policy_path).write_text(updated, encoding="utf-8")


def main():
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest="command", required=True)

    parser_operator_alias = subparsers.add_parser("get-operator-alias")
    parser_operator_recipients = subparsers.add_parser("get-operator-recipients")
    parser_hosts = subparsers.add_parser("list-hosts")
    parser_scopes = subparsers.add_parser("list-scopes")
    parser_user_scopes = subparsers.add_parser("list-user-scopes")

    parser_host_recipient = subparsers.add_parser("get-host-recipient")
    parser_host_recipient.add_argument("--host", required=True)

    parser_user_scope_hosts = subparsers.add_parser("get-user-scope-hosts")
    parser_user_scope_hosts.add_argument("--user", required=True)

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
    parser_set_host.add_argument("--class-name")

    parser_set_operator = subparsers.add_parser("set-operator-recipient")
    parser_set_operator.add_argument("--policy-file", required=True)
    parser_set_operator.add_argument("--recipient", action="append", required=True)

    parser_set_user_scope = subparsers.add_parser("set-user-scope-hosts")
    parser_set_user_scope.add_argument("--policy-file", required=True)
    parser_set_user_scope.add_argument("--user", required=True)
    parser_set_user_scope.add_argument("--host", action="append", default=[])
    parser_set_user_scope.add_argument("--create", action="store_true")

    parser_remove_host = subparsers.add_parser("remove-host")
    parser_remove_host.add_argument("--policy-file", required=True)
    parser_remove_host.add_argument("--host", required=True)

    parser_remove_user_scope = subparsers.add_parser("remove-user-scope")
    parser_remove_user_scope.add_argument("--policy-file", required=True)
    parser_remove_user_scope.add_argument("--user", required=True)

    args = parser.parse_args()

    if args.command in {
        "set-host-recipient",
        "set-operator-recipient",
        "set-user-scope-hosts",
        "remove-host",
        "remove-user-scope",
    }:
        if args.command == "set-host-recipient":
            replace_policy_host(
                args.policy_file,
                args.host,
                args.recipient,
                args.create,
                args.class_name,
            )
        elif args.command == "set-operator-recipient":
            replace_operator_recipients(args.policy_file, sorted(set(args.recipient)))
        elif args.command == "set-user-scope-hosts":
            set_user_scope_hosts(
                args.policy_file, args.user, sorted(set(args.host)), args.create
            )
        elif args.command == "remove-user-scope":
            remove_user_scope(args.policy_file, args.user)
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
    if args.command == "list-user-scopes":
        list_user_scopes(policy)
        return
    if args.command == "get-host-recipient":
        host = args.host
        if host not in policy["hosts"]:
            raise SystemExit(1)
        print(policy["hosts"][host]["recipient"])
        return
    if args.command == "get-user-scope-hosts":
        get_user_scope_hosts(policy, args.user)
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
