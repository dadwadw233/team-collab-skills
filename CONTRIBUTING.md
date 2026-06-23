# Contributing

Thanks for helping improve team-collab-skills. This repo is the runtime source of truth that agents load, so changes should keep the protocol skills, adapters, and manifests consistent.

## Repository layout

```text
team-collab-skills/
├── .claude-plugin/     # Claude Code marketplace + plugin metadata
├── .agents/plugins/    # Codex marketplace metadata
├── .codex-plugin/      # Codex plugin metadata
├── adapters/           # Thin pointers for non-skill-native tools (cursor, vscode, cline, opencode, continue, gemini)
├── assets/             # README visuals
├── scripts/            # Validation and release helpers
└── skills/
    ├── protocol/       # Main entrypoint, references, templates, multi-agent wave workflows
    │   └── references/ # Startup/docs modules + multi-agent wave/status/gate/claim/live-session
    ├── handoff/        # Codex wrapper
    ├── checkpoint/     # Codex wrapper
    ├── team-progress/  # Codex wrapper
    └── docs-refresh/   # Codex wrapper
```

Keep adapter files as thin pointers back to `skills/protocol/`; do not fork the protocol text into each tool's rule file.

## Validate

```bash
scripts/validate-structure.sh
git diff --check

# Codex marketplace smoke test
CODEX_HOME="$(mktemp -d)" codex plugin marketplace add "$PWD"
```

`validate-structure.sh` checks that the required manifests and adapters are present and that runtime files stay self-contained.

## Release

```bash
scripts/bump-version.sh X.Y.Z
scripts/validate-structure.sh
```

`skills/protocol/SKILL.md` is the protocol version source of truth. The bump script rewrites the plugin manifests, adapter drift markers, wrapper protocol ranges, and validation constants, then leaves the diff for manual review.
