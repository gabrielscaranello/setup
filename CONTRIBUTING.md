# ✨ Contributing — Script pattern & expectations

Thank you for contributing!  
This guide explains the canonical pattern for scripts in `scripts/*.sh` and the expected workflow for PRs and validations.

## 🧭 Overview

This file is the reference for contributors and tools (linters, AIs). See examples in `scripts/setup-neovim.sh` and `scripts/setup-nvm.sh`.

## 📜 Script template and rules

- Start with shebang and strict mode:

```bash
#!/bin/bash
set -euo pipefail
```

- Source helpers (near the top):

```bash
source "scripts/_utils.sh" 2>/dev/null || source "$(dirname "$0")/_utils.sh"
```

- Private functions: prefix with `_` (e.g., `_install_node`). Public functions have no prefix (e.g., `install_packages` from `_utils.sh`). Keep functions small and idempotent.

- Entrypoint: expose `main()` and finalize with:

```bash
main "$@"
```

- Branch by package manager via `_get_package_manager` from `_utils.sh` — do not hard-code.

- Use `/tmp/<package>` for temporary builds and ensure `make clean` removes artifacts.

## ✅ Idempotence and quality

- Scripts must be able to rerun without side effects.
- Clear logging and friendly error messages.
- Validate with:

```bash
shellcheck -x scripts/*.sh
```

## 🔁 Script dependencies

If a script depends on another (e.g., neovim depends on nvm), document or install the dependency programmatically.

## 🧾 Documentation and Pull Requests

Changes that add or modify scripts MUST include:

- The scripts/file added
- A Makefile target when useful (e.g., `make neovim`)
- Update to main.sh if the `make all` flow should run it
- ShellCheck output in CI or PR body

Minor edits (typos/formatting) may omit AGENTS.md — document the reason in the PR.

## 📋 PR checklist (use as template)

- [ ] Code added to scripts/
- [ ] Makefile updated (when applicable)
- [ ] main.sh updated (when applicable)
- [ ] README.md and README-pt-br.md updated (when applicable)
- [ ] AGENTS.md updated (when applicable)
- [ ] shellcheck OK
- [ ] Basic manual test documented in PR

## 🧩 Quick script example

```bash
#!/bin/bash
set -euo pipefail
source "scripts/_utils.sh" 2>/dev/null || source "$(dirname "$0")/_utils.sh"

_do_something() {
  echo "Installing foo..."
  install_packages foo
}

main() {
  _do_something
}

main "$@"
```

## ❓ Questions

Open an issue or tag reviewers when the change affects orchestration or public behavior.

---

Made with ❤️ — thank you for helping keep this project consistent!
