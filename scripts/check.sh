#!/usr/bin/env bash
# Smoke test for the modular nvim config.
# Runs two checks:
#   1. Lua parse validation (via nvim load() — compile without execute)
#   2. Headless nvim startup (non-Nix path: nixInfo fallback active)
#
# Usage: bash scripts/check.sh
# Exit 0 = all clear; non-zero = something failed.

set -euo pipefail

NVIM_CONFIG_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

green() { printf '\033[0;32m%s\033[0m\n' "$*"; }
red()   { printf '\033[0;31m%s\033[0m\n' "$*"; }
info()  { printf '\033[0;34m%s\033[0m\n' "$*"; }

# ── 1. Lua parse check (compile without execute) ─────────────────────────────
info "=== lua parse check (compile-only, no execute) ==="

if ! command -v nvim &>/dev/null; then
  info "nvim not found in PATH — skipping checks"
  exit 0
fi

while IFS= read -r -d '' f; do
  # Use nvim's load() which compiles but does not execute —
  # so nixInfo/vim globals being absent is not a problem.
  out=$(nvim --headless -u NORC \
    -c "lua local s=io.open('$f','r'):read('*a'); local fn,e=load(s,'$f'); if not fn then print('FAIL: '..e); vim.cmd('cq 1') end; print('OK')" \
    -c 'qa!' 2>&1 || true)
  if echo "$out" | grep -q '^FAIL'; then
    red  "PARSE FAIL  $(basename "$f")"
    echo "$out" | sed 's/^/  /'
    FAIL=$((FAIL + 1))
  else
    green "PARSE OK    $(basename "$f")"
    PASS=$((PASS + 1))
  fi
done < <(find "$NVIM_CONFIG_DIR/lua" -name '*.lua' -print0; printf '%s\0' "$NVIM_CONFIG_DIR/init.lua")

# ── 2. Headless nvim startup ─────────────────────────────────────────────────
info ""
info "=== headless nvim startup (non-Nix path) ==="

# Run with our config. vim.g.nix_info_plugin_name is unset → nixInfo uses fallback.
# --noplugin suppresses system plugins; we supply our own via rtp.
STARTUP_LOG=$(mktemp /tmp/nvim-check-XXXXXX.log)

set +e
nvim \
  --headless \
  --noplugin \
  -u "$NVIM_CONFIG_DIR/init.lua" \
  +"lua io.write('startup: OK\n'); io.flush()" \
  +qa! \
  > "$STARTUP_LOG" 2>&1
EXIT_CODE=$?
set -e

if [ "$EXIT_CODE" -eq 0 ]; then
  green "STARTUP OK  (exit 0)"
  PASS=$((PASS + 1))
else
  red  "STARTUP FAIL (exit $EXIT_CODE)"
  red  "  log:"
  sed 's/^/    /' "$STARTUP_LOG"
  FAIL=$((FAIL + 1))
fi

rm "$STARTUP_LOG"  # mktemp temp file — trash exception applies

# ── Summary ──────────────────────────────────────────────────────────────────
info ""
info "=== results: $PASS passed, $FAIL failed ==="
if [ "$FAIL" -gt 0 ]; then
  red "FAIL"
  exit 1
else
  green "ALL CLEAR"
  exit 0
fi
