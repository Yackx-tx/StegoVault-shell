#!/usr/bin/env bash

set -eu
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON_BIN="${PYTHON_BIN:-python3}"

if ! command -v "$PYTHON_BIN" >/dev/null 2>&1; then
    printf 'Python 3.10 or newer is required.\n' >&2
    exit 1
fi

"$PYTHON_BIN" -m pip install -r "$ROOT_DIR/requirements.txt"
"$PYTHON_BIN" -m pip install -e "$ROOT_DIR"
printf 'StegoVault installed. Launch it with: %s/stegovault.sh\n' "$ROOT_DIR"