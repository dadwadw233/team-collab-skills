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
  "skills/protocol/references/multi-agent.md"
  "skills/protocol/references/agent-status.md"
  "skills/protocol/references/gate-check.md"
  "skills/protocol/references/claim-and-freshness.md"
  "skills/protocol/references/live-session.md"
  "skills/handoff/SKILL.md"
  "skills/checkpoint/SKILL.md"
  "skills/team-progress/SKILL.md"
  "skills/team-progress/agents/openai.yaml"
  "skills/docs-refresh/SKILL.md"
  "skills/docs-refresh/agents/openai.yaml"
  "skills/wave/SKILL.md"
  "skills/wave/agents/openai.yaml"
  "skills/gate/SKILL.md"
  "skills/gate/agents/openai.yaml"
  "skills/digest/SKILL.md"
  "skills/digest/agents/openai.yaml"
  "adapters/ADAPTER-SOURCE.md"
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
import re
from pathlib import Path

PROTOCOL_RANGE = ">=0.6.0,<0.7.0"

def frontmatter(path):
    text = Path(path).read_text(encoding="utf-8")
    if not text.startswith("---\n"):
        raise SystemExit(f"{path} missing skill frontmatter")
    end = text.find("\n---\n", 4)
    if end == -1:
        raise SystemExit(f"{path} missing skill frontmatter terminator")
    metadata = {}
    block_key = None
    for line_no, line in enumerate(text[4:end].splitlines(), start=2):
        if not line.strip():
            continue
        if block_key is not None:
            if line.startswith((" ", "\t")):
                continue
            block_key = None
        if line.startswith((" ", "\t")):
            raise SystemExit(f"{path}:{line_no} frontmatter has unsupported indentation outside a block scalar")
        if line.strip().startswith("-"):
            raise SystemExit(
                f"{path}:{line_no} frontmatter uses unsupported block-list syntax; "
                "upgrade the parser before adding lists"
            )
        if ":" not in line:
            raise SystemExit(
                f"{path}:{line_no} frontmatter line has no ':'; "
                "supported syntax is simple key: value or key: | block scalars"
            )
        key, value = line.split(":", 1)
        key = key.strip()
        if not key:
            raise SystemExit(f"{path}:{line_no} frontmatter key is empty")
        value = value.strip()
        if value in {"|", ">", "|-", ">-", "|+", ">+"}:
            metadata[key] = ""
            block_key = key
            continue
        if value.startswith(("[", "{")):
            raise SystemExit(
                f"{path}:{line_no} frontmatter uses unsupported flow syntax ({value[:1]}); "
                "upgrade the parser before adding lists or nested mappings"
            )
        if len(value) >= 2 and value[0] == value[-1] and value[0] in {"'", '"'}:
            value = value[1:-1]
        metadata[key] = value
    return metadata

protocol_meta = frontmatter("skills/protocol/SKILL.md")
PROTOCOL_VERSION = protocol_meta.get("version")
if not PROTOCOL_VERSION or not re.fullmatch(r"[0-9]+\.[0-9]+\.[0-9]+", PROTOCOL_VERSION):
    raise SystemExit("team-collab-protocol skill version metadata is missing or invalid")
for wrapper in ["handoff", "checkpoint", "team-progress", "docs-refresh", "wave", "gate", "digest"]:
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
    "references/multi-agent.md",
    "references/agent-status.md",
    "references/gate-check.md",
    "references/claim-and-freshness.md",
    "references/live-session.md",
]
missing = [ref for ref in required_refs if ref not in text]
if missing:
    raise SystemExit(f"SKILL.md does not route to references: {missing}")
new_reference_checks = {
    "skills/protocol/references/multi-agent.md": [
        "# Multi-Agent Protocol", "Activation", "Wave layout", "Read-only vs write commands"
    ],
    "skills/protocol/references/agent-status.md": [
        "# Agent Status", "agent-runs/<task-id>/<agent-id>.md", "truth_source", "Sign-off"
    ],
    "skills/protocol/references/gate-check.md": [
        "# Gate Check", "10 checks", "plan --check", "lint-multi-agent", "exit code 5"
    ],
    "skills/protocol/references/claim-and-freshness.md": [
        "# Claim And Freshness", "claims/tasks", "heartbeat", "truth_source", "stale-blocked"
    ],
    "skills/protocol/references/live-session.md": [
        "# Live Session", "Phase 4", "tmux", "STOP / PAUSE / RUN GATE", "not implemented"
    ],
}
for ref_path, phrases in new_reference_checks.items():
    ref_text = Path(ref_path).read_text(encoding="utf-8")
    for phrase in phrases:
        if phrase not in ref_text:
            raise SystemExit(f"{ref_path} must mention {phrase}")
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
adapter_files = [
    "adapters/cursor/.cursor/rules/team-collab.mdc",
    "adapters/vscode/.github/copilot-instructions.md",
    "adapters/vscode/.github/instructions/team-collab.instructions.md",
    "adapters/cline/.clinerules/team-collab.md",
    "adapters/continue/.continue/rules/team-collab.md",
    "adapters/opencode/AGENTS.md",
    "adapters/gemini/GEMINI.md",
    "adapters/gemini/.gemini/commands/handoff.toml",
    "adapters/gemini/.gemini/commands/checkpoint.toml",
    "adapters/gemini/.gemini/commands/team-progress.toml",
    "adapters/gemini/.gemini/commands/docs-refresh.toml",
    "adapters/gemini/.gemini/commands/wave.toml",
    "adapters/gemini/.gemini/commands/gate.toml",
    "adapters/gemini/.gemini/commands/digest.toml",
]
pointer_docs = [adapter for adapter in adapter_files if not adapter.endswith(".toml")]
required_marker_phrases = [
    f"team-collab-protocol-source: skills/protocol/SKILL.md@{PROTOCOL_VERSION}",
    "team-collab-required-commands: handoff, checkpoint, team-progress, docs-refresh",
    "team-collab-source-of-truth: repo AGENTS.md + installed team-collab-protocol skill",
]
required_commands = ["handoff", "checkpoint", "team-progress", "docs-refresh"]

for adapter in adapter_files:
    content = Path(adapter).read_text(encoding="utf-8")
    for phrase in required_marker_phrases:
        if phrase not in content:
            raise SystemExit(f"{adapter} missing adapter drift marker: {phrase}")
    for command in required_commands:
        if command not in content:
            raise SystemExit(f"{adapter} must mention {command}")
for adapter in pointer_docs:
    content = Path(adapter).read_text(encoding="utf-8")
    if "Context budget" not in content:
        raise SystemExit(f"{adapter} must include a context budget reminder")
PY

echo "team-collab-skills structure ok"
