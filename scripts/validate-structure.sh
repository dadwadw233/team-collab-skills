#!/usr/bin/env bash
set -euo pipefail

required_files=(
  ".claude-plugin/marketplace.json"
  ".claude-plugin/plugin.json"
  ".agents/plugins/marketplace.json"
  ".codex-plugin/plugin.json"
  "skills/protocol/SKILL.md"
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

echo "team-collab-skills structure ok"
