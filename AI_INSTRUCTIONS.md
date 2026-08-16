# AI Instructions - Desktop Setup Project

IMPORTANT: This file is the authoritative guidance for AI assistants and maintainers about repository conventions, automation checks, and developer expectations. For user-facing project description and quick usage, see [README.md](README.md) (canonical). For developer conventions and the canonical script template, see [CONTRIBUTING.md](CONTRIBUTING.md). Do not duplicate README or CONTRIBUTING content here — reference them.

Summary
-------

This repository provides cross-distro Linux desktop setup scripts under scripts/*.sh. AI_INSTRUCTIONS.md documents the internal conventions, developer guidance, and documentation requirements for contributors.

AI operational requirements
--------------------------

- Always call the `fetch_copilot_cli_documentation` tool (or equivalent configured documentation fetch) at the start of any interaction asking about repository tooling or capabilities. Use the returned documentation to inform actions.
- Before implementing new setup scripts or modifying orchestration (main.sh, Makefile, scripts/*), read this AI_INSTRUCTIONS.md file and [README.md](README.md).
- Do not duplicate high-level project information already present in [README.md](README.md). Keep AI_INSTRUCTIONS.md focused on developer/AI guidance, conventions, and checks.
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

See [CONTRIBUTING.md](CONTRIBUTING.md) for the canonical script template, implementation checklist, and style rules. AI assistants and contributors must read [CONTRIBUTING.md](CONTRIBUTING.md), [README.md](README.md), and the Makefile before adding or modifying scripts. Follow [CONTRIBUTING.md](CONTRIBUTING.md) for implementation details and quality checks (e.g., shellcheck).

Developer conventions (short)
----------------------------

Developer conventions and the script template are documented in [CONTRIBUTING.md](CONTRIBUTING.md) — consult that file for concrete examples and the authoritative checklist (examples: scripts/setup-neovim.sh, scripts/setup-nvm.sh).

Reference and non-duplication
-----------------------------

- For end-user installation steps, target usage examples, and quick commands, prefer [README.md](README.md). Link to it from AI_INSTRUCTIONS.md where needed.
- Keep this file concise and focused on conventions, AI rules, and documentation requirements.

Where to look next
------------------

- [README.md](README.md) — user-facing documentation and quick usage (canonical)
- [CONTRIBUTING.md](CONTRIBUTING.md) — canonical script template and developer checklist (see examples: scripts/setup-neovim.sh, scripts/setup-nvm.sh)
- scripts/_utils.sh — package manager abstraction and mappings
- scripts/setup-neovim.sh — example of a full setup script
- scripts/setup-terminal.sh — template/stub for terminal setup
- scripts/setup-nvm.sh — manages nvm/node installation (Arch uses the nvm pacman package; Debian/Fedora/openSUSE use the upstream nvm install script), enables corepack, and installs global npm packages

Feedback loop
-------------

If a change legitimately cannot update AI_INSTRUCTIONS.md (e.g., tiny typo fix), add a short note in the PR description explaining why and tag reviewers.

This file should be kept minimal and actionable. Update it when processes or conventions change.

Additional project directives
-----------------------------

To ensure consistent discoverability by both humans and AIs, the following documentation rules must be followed for every new setup script added under scripts/:

- The new script must be documented in [README.md](README.md) "Quick usage" section and [README-pt-br.md](README-pt-br.md) "Como usar (rápido)" section.
- Entries in those sections must be ordered alphabetically by target name, with `make help` and `make all` appearing first (in that order), and `make clean` appearing last.
- The Makefile must be updated to include the new `make <target>` entry and its description. The Makefile's help output should follow the same ordering rule.
- AI assistants must read AI_INSTRUCTIONS.md, [README.md](README.md) and [README-pt-br.md](README-pt-br.md) before modifying or adding scripts and ensure these documentation updates are present in the same commit/PR as code changes.

Follow-up notes
--------------

- Tiny edits that do not change orchestration (e.g., spelling fixes) may be exempt from updating this file; explain the exemption in the PR description.
- Keep documentation concise and avoid duplicating the user-facing README content inside AI_INSTRUCTIONS.md.

---

**For questions**: See [README.md](README.md)
