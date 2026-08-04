#!/usr/bin/env bash
# Rebuilds the native shim and runs this package's own integration test
# on a real Haiku machine over SSH - mirroring eBasic's own
# scripts/haiku_verify.sh pattern. This package only ever builds/links
# on real Haiku (it binds libbe.so, which doesn't exist anywhere else),
# so there is no local/CI equivalent - this is the real verification.
#
# Assumes `ebc`/`ebpm` are already installed on the remote host (e.g.
# via a packaged eBasic .hpkg, or a prior manual build from
# https://github.com/yann64/ebasic) and on its PATH. Transfers the
# current working tree (not just committed content - unlike the core
# project's own script - since this package has no CI to match against).

set -euo pipefail

if [ "$#" -gt 1 ]; then
    echo "usage: haiku_verify.sh [ssh-host]  (default: haiku)" >&2
    exit 2
fi

HOST="${1:-haiku}"
REMOTE_DIR="eb-haiku-verify-$(date +%s)"
LOCAL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> Checking SSH connectivity to '$HOST'..."
if ! ssh -o BatchMode=yes -o ConnectTimeout=10 "$HOST" 'uname -a'; then
    echo "error: could not reach '$HOST' - check your SSH config/keys" >&2
    exit 1
fi

echo "==> Transferring the working tree to ~/$REMOTE_DIR on $HOST..."
ssh "$HOST" "mkdir -p ~/$REMOTE_DIR"
tar -C "$LOCAL_DIR" -cf - --exclude=target --exclude=.git . | ssh "$HOST" "tar -xf - -C ~/$REMOTE_DIR"

echo "==> Building the native shim..."
ssh "$HOST" "cd ~/$REMOTE_DIR/native && cmake -S . -B build && cmake --build build"

echo "==> Installing libebhaikushim.a (non-packaged develop lib)..."
ssh "$HOST" "mkdir -p /boot/system/non-packaged/develop/lib && cp ~/$REMOTE_DIR/native/build/libebhaikushim.a /boot/system/non-packaged/develop/lib/"

echo "==> ebpm build (library archive only)..."
ssh "$HOST" "cd ~/$REMOTE_DIR && ebpm build"

echo "==> Compiling+running the integration test..."
echo "    (needs -l be explicitly - libbe is a transitive dependency of"
echo "    the shim, not something any Lib clause in this package's own"
echo "    .bas source captures - see README's own Known Gaps section)"
if ssh "$HOST" "cd ~/$REMOTE_DIR && ebc tests/integration.bas -o /tmp/eb_haiku_integration_test -L /boot/system/non-packaged/develop/lib -l ebhaikushim -l be && /tmp/eb_haiku_integration_test"; then
    echo "==> PASSED on $HOST"
    RESULT=0
else
    echo "==> FAILED on $HOST"
    RESULT=1
fi

echo "==> Cleaning up ~/$REMOTE_DIR on $HOST..."
ssh "$HOST" "rm -rf ~/$REMOTE_DIR /tmp/eb_haiku_integration_test"

exit $RESULT
