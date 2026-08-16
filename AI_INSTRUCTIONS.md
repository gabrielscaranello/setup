# AI Instructions - Desktop Setup Project

IMPORTANT: This file is the authoritative guidance for AI assistants and maintainers about repository conventions, automation checks, and developer expectations. For user-facing project description and quick usage, see README.md (canonical). Do not duplicate README content here — reference it.

Summary
-------

This repository provides cross-distro Linux desktop setup scripts under scripts/*.sh. AI_INSTRUCTIONS.md documents the internal conventions, developer guidance, and documentation requirements for contributors.

AI operational requirements
--------------------------

- Always call the `fetch_copilot_cli_documentation` tool (or equivalent configured documentation fetch) at the start of any interaction asking about repository tooling or capabilities. Use the returned documentation to inform actions.
- Before implementing new setup scripts or modifying orchestration (main.sh, Makefile, scripts/*), read this AI_INSTRUCTIONS.md file and README.md.
- Do not duplicate high-level project information already present in README.md. Keep AI_INSTRUCTIONS.md focused on developer/AI guidance, conventions, and checks.
- When adding or changing public-facing behavior (new Makefile target, changed CLI, new scripts), update AI_INSTRUCTIONS.md to explain the change for future AIs.

Documentation requirements
--------------------------

When the following paths are modified, AI_INSTRUCTIONS.md must be updated accordingly:

- main.sh
- Makefile
- scripts/**

This ensures developers and AI assistants have current documentation of conventions and the orchestration flow.

How to implement changes (AI checklist)
--------------------------------------

When adding a new feature or setup script, follow this checklist:

1. Read README.md for user-facing details. Keep user docs there.
2. Read AI_INSTRUCTIONS.md (this file) for developer conventions.
3. Implement the script under `scripts/` (use the template pattern in this repo).
4. Add the script to `main.sh` orchestration if it should run in full setup.
5. Add a Makefile target if convenient for manual invocation.
6. Update AI_INSTRUCTIONS.md describing the change (why it exists, where to find it, any distro or package mapping details). Keep descriptions concise and avoid duplicating README.md content.
7. Run `shellcheck -x scripts/*.sh` to validate shell syntax.
8. Verify that AI_INSTRUCTIONS.md has been updated when required (if main.sh, Makefile, or scripts/* were modified), then open a PR.

Developer conventions (short)
----------------------------

- scripts/_utils.sh: package-manager abstraction ONLY — no package-specific logic.
- scripts/setup-*.sh: each script MUST be self-contained and follow this canonical structure:
  1. Shebang and strict mode: start with `#!/bin/bash` and `set -e`.
  2. Source helpers: `source "$(dirname "$0")/_utils.sh"` near the top.
  3. Private helpers: implement functionality in `_`-prefixed private functions (e.g. `_install_from_repo`, `_install_from_source`, `_install_packages`).
  4. Use `_install_packages` to install distro packages and `_get_package_manager` to branch logic by package manager.
  5. Provide a `main()` function that orchestrates steps and finish with `main "$@"`.
  6. Avoid global side effects; keep variables local where appropriate and export only when necessary.
- Use `/tmp/<package>` for build dirs and ensure Makefile `clean` removes them.
- Scripts must be idempotent and ShellCheck-clean (`shellcheck -x`). Aim for clear logging, graceful errors, and explicit user prompts only when needed.

Reference and non-duplication
-----------------------------

- For end-user installation steps, target usage examples, and quick commands, prefer README.md. Link to it from AI_INSTRUCTIONS.md where needed.
- Keep this file concise and focused on conventions, AI rules, and documentation requirements.

Where to look next
------------------

- README.md — user-facing documentation and quick usage (canonical)
- scripts/_utils.sh — package manager abstraction and mappings
- scripts/setup-neovim.sh — example of a full setup script
- scripts/setup-terminal.sh — template/stub for terminal setup
- scripts/setup-nvm.sh — manages nvm/node installation (Arch uses the nvm pacman package; Debian/Fedora/openSUSE use the upstream nvm install script), enables corepack, and installs global npm packages

Feedback loop
-------------

If a change legitimately cannot update AI_INSTRUCTIONS.md (e.g., tiny typo fix), add a short note in the PR description explaining why and tag reviewers.

This file should be kept minimal and actionable. Update it when processes or conventions change.

---

**For questions**: See README.md
