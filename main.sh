#!/bin/bash
set -euo pipefail

RUNNERS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/runners" && pwd)"

exec "$RUNNERS_DIR/main.sh" "$@"
