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
  "skills/handoff/SKILL.md"
  "skills/checkpoint/SKILL.md"
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
from pathlib import Path

skill = Path("skills/protocol/SKILL.md")
text = skill.read_text(encoding="utf-8")
if len(text.split()) > 1600 or len(text) > 7000 or text.count("\n") > 140:
    raise SystemExit("skills/protocol/SKILL.md entrypoint is too large; move details to references/")
required_refs = [
    "references/startup-and-audit.md",
    "references/handoff.md",
    "references/checkpoint.md",
    "references/git-policy.md",
    "references/docs-standards.md",
    "references/todo-ownership.md",
]
missing = [ref for ref in required_refs if ref not in text]
if missing:
    raise SystemExit(f"SKILL.md does not route to references: {missing}")
PY

echo "team-collab-skills structure ok"
