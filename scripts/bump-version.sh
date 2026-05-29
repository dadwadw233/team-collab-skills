#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "usage: scripts/bump-version.sh X.Y.Z" >&2
  exit 2
fi

new_version="$1"
case "$new_version" in
  [0-9]*.[0-9]*.[0-9]*)
    ;;
  *)
    echo "invalid version: $new_version" >&2
    exit 2
    ;;
esac

python3 - "$new_version" <<'PY'
import json
import re
import sys
from pathlib import Path

new_version = sys.argv[1]
if not re.fullmatch(r"[0-9]+\.[0-9]+\.[0-9]+", new_version):
    raise SystemExit(f"invalid version: {new_version}")

changed = []


def write_if_changed(path, content):
    path = Path(path)
    old = path.read_text(encoding="utf-8")
    if old != content:
        path.write_text(content, encoding="utf-8")
        changed.append(str(path))


def update_protocol_skill(path):
    path = Path(path)
    text = path.read_text(encoding="utf-8")
    content, count = re.subn(
        r"(?m)^version:\s*[0-9]+\.[0-9]+\.[0-9]+\s*$",
        f"version: {new_version}",
        text,
        count=1,
    )
    if count != 1:
        raise SystemExit(f"{path} must contain exactly one version frontmatter line")
    write_if_changed(path, content)


def update_json_version(path):
    path = Path(path)
    data = json.loads(path.read_text(encoding="utf-8"))
    if data.get("version") != new_version:
        data["version"] = new_version
    write_if_changed(path, json.dumps(data, ensure_ascii=False, indent=2) + "\n")


def update_claude_marketplace(path):
    path = Path(path)
    data = json.loads(path.read_text(encoding="utf-8"))
    matched = False
    for plugin in data.get("plugins", []):
        if plugin.get("name") == "team-collab":
            plugin["version"] = new_version
            matched = True
    if not matched:
        raise SystemExit(f"{path} does not contain team-collab plugin metadata")
    write_if_changed(path, json.dumps(data, ensure_ascii=False, indent=2) + "\n")


def update_adapter_markers(root):
    pattern = re.compile(r"(team-collab-protocol-source:\s*skills/protocol/SKILL\.md@)[0-9]+\.[0-9]+\.[0-9]+")
    for path in sorted(Path(root).rglob("*")):
        if not path.is_file():
            continue
        text = path.read_text(encoding="utf-8")
        content, count = pattern.subn(rf"\g<1>{new_version}", text)
        if count:
            write_if_changed(path, content)


update_protocol_skill("skills/protocol/SKILL.md")
update_json_version(".claude-plugin/plugin.json")
update_json_version(".codex-plugin/plugin.json")
update_claude_marketplace(".claude-plugin/marketplace.json")
update_adapter_markers("adapters")

if changed:
    print("updated version to", new_version)
    for path in changed:
        print("-", path)
else:
    print("version already", new_version)
PY
