#!/usr/bin/env bash
set -euo pipefail

required_files=(
  ".claude-plugin/marketplace.json"
  ".claude-plugin/plugin.json"
  ".agents/plugins/marketplace.json"
  ".codex-plugin/plugin.json"
  "skills/protocol/SKILL.md"
  "skills/protocol/references/startup-and-audit.md"
  "skills/protocol/references/handoff.md"
  "skills/protocol/references/checkpoint.md"
  "skills/protocol/references/git-policy.md"
  "skills/protocol/references/docs-standards.md"
  "skills/protocol/references/todo-ownership.md"
  "skills/protocol/references/docs-refresh.md"
  "skills/protocol/references/team-progress.md"
  "skills/handoff/SKILL.md"
  "skills/checkpoint/SKILL.md"
  "skills/team-progress/SKILL.md"
  "skills/team-progress/agents/openai.yaml"
  "skills/docs-refresh/SKILL.md"
  "skills/docs-refresh/agents/openai.yaml"
  "adapters/cursor/.cursor/rules/team-collab.mdc"
  "adapters/vscode/.github/copilot-instructions.md"
  "adapters/vscode/.github/instructions/team-collab.instructions.md"
  "adapters/cline/.clinerules/team-collab.md"
  "adapters/opencode/AGENTS.md"
  "adapters/opencode/opencode.json"
  "adapters/continue/.continue/rules/team-collab.md"
  "adapters/gemini/GEMINI.md"
  "adapters/gemini/.gemini/commands/handoff.toml"
  "adapters/gemini/.gemini/commands/checkpoint.toml"
  "adapters/gemini/.gemini/commands/team-progress.toml"
  "adapters/gemini/.gemini/commands/docs-refresh.toml"
)

for path in "${required_files[@]}"; do
  if [ ! -f "$path" ]; then
    echo "missing required file: $path" >&2
    exit 1
  fi
done

python3 -m json.tool .claude-plugin/marketplace.json >/dev/null
python3 -m json.tool .claude-plugin/plugin.json >/dev/null
python3 -m json.tool .agents/plugins/marketplace.json >/dev/null
python3 -m json.tool .codex-plugin/plugin.json >/dev/null
python3 -m json.tool adapters/opencode/opencode.json >/dev/null

grep -R "team-collab-playbook.git" .agents .codex-plugin .claude-plugin skills adapters >/dev/null 2>&1 && {
  echo "runtime files must not point at team-collab-playbook.git" >&2
  exit 1
}

python3 - <<'PY'
import json
from pathlib import Path

PROTOCOL_VERSION = "0.5.0"
PROTOCOL_RANGE = ">=0.5.0,<0.6.0"

def frontmatter(path):
    text = Path(path).read_text(encoding="utf-8")
    if not text.startswith("---\n"):
        raise SystemExit(f"{path} missing skill frontmatter")
    end = text.find("\n---\n", 4)
    if end == -1:
        raise SystemExit(f"{path} missing skill frontmatter terminator")
    metadata = {}
    for line in text[4:end].splitlines():
        if ":" not in line:
            continue
        key, value = line.split(":", 1)
        value = value.strip()
        if len(value) >= 2 and value[0] == value[-1] and value[0] in {"'", '"'}:
            value = value[1:-1]
        metadata[key.strip()] = value
    return metadata

protocol_meta = frontmatter("skills/protocol/SKILL.md")
if protocol_meta.get("version") != PROTOCOL_VERSION:
    raise SystemExit("team-collab-protocol skill version metadata is missing or stale")
for wrapper in ["handoff", "checkpoint", "team-progress", "docs-refresh"]:
    metadata = frontmatter(f"skills/{wrapper}/SKILL.md")
    if metadata.get("requires_protocol") != PROTOCOL_RANGE:
        raise SystemExit(f"{wrapper} wrapper must declare requires_protocol: \"{PROTOCOL_RANGE}\"")

for path in [".codex-plugin/plugin.json", ".claude-plugin/plugin.json"]:
    version = json.loads(Path(path).read_text(encoding="utf-8")).get("version")
    if version != PROTOCOL_VERSION:
        raise SystemExit(f"{path} version must match protocol version {PROTOCOL_VERSION}")
marketplace = json.loads(Path(".claude-plugin/marketplace.json").read_text(encoding="utf-8"))
versions = [plugin.get("version") for plugin in marketplace.get("plugins", []) if plugin.get("name") == "team-collab"]
if versions != [PROTOCOL_VERSION]:
    raise SystemExit(".claude-plugin/marketplace.json team-collab version must match protocol version")

skill = Path("skills/protocol/SKILL.md")
text = skill.read_text(encoding="utf-8")
if len(text.split()) > 620 or len(text) > 5200 or text.count("\n") > 120:
    raise SystemExit("skills/protocol/SKILL.md entrypoint is too large; move details to references/")
if "Context budget" not in text:
    raise SystemExit("SKILL.md must define the runtime context budget")
required_refs = [
    "references/startup-and-audit.md",
    "references/handoff.md",
    "references/checkpoint.md",
    "references/git-policy.md",
    "references/docs-standards.md",
    "references/todo-ownership.md",
    "references/docs-refresh.md",
    "references/team-progress.md",
]
missing = [ref for ref in required_refs if ref not in text]
if missing:
    raise SystemExit(f"SKILL.md does not route to references: {missing}")
startup = Path("skills/protocol/references/startup-and-audit.md").read_text(encoding="utf-8")
if "Do not scan the whole Obsidian vault" not in startup:
    raise SystemExit("startup-and-audit.md must prevent whole-vault loading")
docs_refresh = Path("skills/protocol/references/docs-refresh.md").read_text(encoding="utf-8")
for phrase in ["staleness audit", "archive-first", "Mermaid", "active docs"]:
    if phrase not in docs_refresh:
        raise SystemExit(f"docs-refresh.md must mention {phrase}")
docs_standards = Path("skills/protocol/references/docs-standards.md").read_text(encoding="utf-8")
for phrase in ["short current-state caches", "standard Markdown links", "PR lists", "80-150"]:
    if phrase not in docs_standards:
        raise SystemExit(f"docs-standards.md must mention state hygiene phrase: {phrase}")
todo_ownership = Path("skills/protocol/references/todo-ownership.md").read_text(encoding="utf-8")
if "15-20" not in todo_ownership:
    raise SystemExit("todo-ownership.md must cap completed TODO retention")
wrapper = Path("skills/docs-refresh/SKILL.md").read_text(encoding="utf-8")
if "$docs-refresh" not in wrapper or "references/docs-refresh.md" not in wrapper:
    raise SystemExit("docs-refresh wrapper must expose the Codex command and route to the protocol reference")
team_progress = Path("skills/protocol/references/team-progress.md").read_text(encoding="utf-8")
for phrase in ["time window", "PRs/MRs", "成员进展", "需要你处理"]:
    if phrase not in team_progress:
        raise SystemExit(f"team-progress.md must mention {phrase}")
wrapper = Path("skills/team-progress/SKILL.md").read_text(encoding="utf-8")
if "$team-progress" not in wrapper or "references/team-progress.md" not in wrapper:
    raise SystemExit("team-progress wrapper must expose the Codex command and route to the protocol reference")
for adapter in [
    "adapters/cursor/.cursor/rules/team-collab.mdc",
    "adapters/vscode/.github/copilot-instructions.md",
    "adapters/cline/.clinerules/team-collab.md",
    "adapters/continue/.continue/rules/team-collab.md",
    "adapters/opencode/AGENTS.md",
    "adapters/gemini/GEMINI.md",
]:
    content = Path(adapter).read_text(encoding="utf-8")
    if "Context budget" not in content:
        raise SystemExit(f"{adapter} must include a context budget reminder")
    if "docs-refresh" not in content:
        raise SystemExit(f"{adapter} must mention docs-refresh trigger")
    if "team-progress" not in content:
        raise SystemExit(f"{adapter} must mention team-progress trigger")
PY

echo "team-collab-skills structure ok"
