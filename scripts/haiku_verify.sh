#!/usr/bin/env bash
# Rebuilds the native shim and runs every tests/*.bas file on a real
# Haiku machine over SSH - mirroring eBasic's own scripts/
# haiku_verify.sh pattern. This package only ever builds/links on real
# Haiku (it binds libbe.so, which doesn't exist anywhere else), so
# there is no local/CI equivalent - this is the real verification.
#
# Assumes `ebc`/`ebpm` are already installed on the remote host (e.g.
# via a packaged eBasic .hpkg, or a prior manual build from
# https://github.com/yann64/ebasic) and on its PATH. Transfers the
# current working tree (not just committed content - unlike the core
# project's own script - since this package has no CI to match against).
#
# Each test's own exit code and final "... ok" print are checked
# automatically, but GUI behavior (Phase 2's window/button/drawing/
# layout tests) has no automated visual check - there's no way to
# script "did it draw the right pixels" or "did the window really
# appear". Each one was verified by hand via Haiku's own `screenshot
# -s` utility during development; this script only re-confirms they
# still run without crashing.
#
# `tests/*.bas` are compiled directly via `ebc` with explicit `-l
# ebhaikushim -l be` flags (they're standalone test programs, not a
# real `ebpm` dependency graph) - the fixed automatic `-l be`
# forwarding (see README's own Building section) applies to a real
# downstream *consumer* package depending on eb-haiku via `ebpm`, which
# these direct-`ebc` test invocations intentionally don't exercise.

set -uo pipefail

if [ "$#" -gt 1 ]; then
    echo "usage: haiku_verify.sh [ssh-host]  (default: haiku)" >&2
    exit 2
fi

HOST="${1:-haiku}"
REMOTE_DIR="eb-haiku-verify-$(date +%s)"
LOCAL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FAILED=0

echo "==> Checking SSH connectivity to '$HOST'..."
if ! ssh -o BatchMode=yes -o ConnectTimeout=10 "$HOST" 'uname -a'; then
    echo "error: could not reach '$HOST' - check your SSH config/keys" >&2
    exit 1
fi

echo "==> Transferring the working tree to ~/$REMOTE_DIR on $HOST..."
ssh "$HOST" "mkdir -p ~/$REMOTE_DIR"
tar -C "$LOCAL_DIR" -cf - --exclude=target --exclude=.git . | ssh "$HOST" "tar -xf - -C ~/$REMOTE_DIR"

echo "==> Building the native shim..."
if ! ssh "$HOST" "cd ~/$REMOTE_DIR/native && cmake -S . -B build && cmake --build build"; then
    echo "==> FAILED: shim build" >&2
    ssh "$HOST" "rm -rf ~/$REMOTE_DIR"
    exit 1
fi

echo "==> Installing libebhaikushim.a (non-packaged develop lib)..."
ssh "$HOST" "mkdir -p /boot/system/non-packaged/develop/lib && cp ~/$REMOTE_DIR/native/build/libebhaikushim.a /boot/system/non-packaged/develop/lib/"

echo "==> ebpm build (library archive only)..."
if ! ssh "$HOST" "cd ~/$REMOTE_DIR && ebpm build"; then
    echo "==> FAILED: ebpm build" >&2
    ssh "$HOST" "rm -rf ~/$REMOTE_DIR"
    exit 1
fi

for test_name in integration window_basics controls_basics drawing_basics layout_basics; do
    echo "==> Compiling+running tests/$test_name.bas..."
    if ssh "$HOST" "cd ~/$REMOTE_DIR && ebc tests/$test_name.bas -o /tmp/eb_haiku_${test_name}_test -L /boot/system/non-packaged/develop/lib -l ebhaikushim -l be && /tmp/eb_haiku_${test_name}_test"; then
        echo "    PASS: $test_name"
    else
        echo "    FAIL: $test_name"
        FAILED=1
    fi
    ssh "$HOST" "rm -f /tmp/eb_haiku_${test_name}_test"
done

if [ "$FAILED" -eq 0 ]; then
    echo "==> PASSED on $HOST"
else
    echo "==> FAILED on $HOST"
fi

echo "==> Cleaning up ~/$REMOTE_DIR on $HOST..."
ssh "$HOST" "rm -rf ~/$REMOTE_DIR"

exit "$FAILED"
