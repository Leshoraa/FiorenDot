#!/usr/bin/env bash
# Delegate to comprehensive SetupPowerOptimizations.sh
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/SetupPowerOptimizations.sh" "$@"
