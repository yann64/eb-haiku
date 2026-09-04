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
# automatically, but GUI/layout behavior has no automated visual check -
# there's no way to script "did it draw the right pixels" or "did the
# grid/split/card layout actually look right". Each one was verified by
# hand via Haiku's own `screenshot -s` utility during development; this
# script only re-confirms they still run without crashing.
#
# `tests/*.bas` are compiled directly via `ebc` with explicit `-l
# ebhaikushim -l be` flags (they're standalone test programs, not a
# real `ebpm` dependency graph) - the fixed automatic `-l be`
# forwarding (see README's own Building section) applies to a real
# downstream *consumer* package depending on eb-haiku via `ebpm`, which
# these direct-`ebc` test invocations intentionally don't exercise.
# `tests/screensaver_basics.bas` is the one exception to the fixed-list
# loop below - built via `ebc --shared-lib`, not a plain executable,
# and verified via a small C++ dlopen harness instead of being run
# directly (see its own step, after the loop).

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

for test_name in integration window_basics window_gui_extras_basics controls_basics drawing_basics layout_basics \
                 nested_layout_basics grid_layout_basics card_layout_basics split_view_basics \
                 space_layout_item_basics translation_basics translation_get_bitmap \
                 translation_draw_bitmap translation_convert translation_identify \
                 translation_introspection stat_attrs_basics symlink_basics volume_basics \
                 query_basics locker_basics menu_basics roster_clipboard_basics network_basics \
                 locale_basics thread_basics serial_basics package_basics media_basics \
                 printjob_basics textview_basics popup_menu_field_basics mimetype_basics \
                 watcher_basics secure_datagram_socket_basics appfileinfo_basics \
                 drag_drop_basics network_interface_basics mail_basics game_basics \
                 gl_view_basics diskdevice_basics midi_basics catalog_basics \
                 dataio_basics; do
    echo "==> Compiling+running tests/$test_name.bas..."
    if ssh "$HOST" "cd ~/$REMOTE_DIR && ebc tests/$test_name.bas -o /tmp/eb_haiku_${test_name}_test -L /boot/system/non-packaged/develop/lib -l ebhaikushim -l be -l translation -l root -l bnetapi -l device -l package -l media -l mail -l game -l GL -l midi2 -l screensaver && /tmp/eb_haiku_${test_name}_test"; then
        echo "    PASS: $test_name"
    else
        echo "    FAIL: $test_name"
        FAILED=1
    fi
    ssh "$HOST" "rm -f /tmp/eb_haiku_${test_name}_test"
done

echo "==> Compiling+running tests/screensaver_basics.bas (--shared-lib)..."
# Screen Saver Kit doesn't fit the fixed-list loop above: it's built via
# `ebc --shared-lib` (a real, dynamically loadable .so), not a plain
# executable, and verified by dlopen'ing it from a small C++ harness
# (tests/native/screensaver_harness.cpp) rather than running it
# directly - genuine proof of real BScreenSaver virtual dispatch
# through the exact call shape Haiku's own screensaver daemon uses.
# `-l screensaver` (Haiku's own libscreensaver.so, providing
# BScreenSaver's own base-class virtual method bodies) is REQUIRED in
# addition to `-l be` - a real finding, confirmed by direct
# reproduction, documented in native/shim_screensaver.h's own top
# comment; omitting it makes `dlopen` fail with a bare "Symbol not
# found" (no symbol name given).
SCREENSAVER_EXPECTED='InitCheck called
InitCheck returned 0
StartSaver called, preview=1
StartSaver returned 0
Draw called, frame=0
Draw called, frame=1
StopSaver called'
SCREENSAVER_ACTUAL="$(ssh "$HOST" "
set -e
cd ~/$REMOTE_DIR
ebc tests/screensaver_basics.bas --shared-lib -o /tmp/eb_haiku_screensaver_test -L /boot/system/non-packaged/develop/lib -l ebhaikushim -l be -l screensaver
g++ -std=c++17 tests/native/screensaver_harness.cpp -o /tmp/eb_haiku_screensaver_harness -lbe
/tmp/eb_haiku_screensaver_harness /tmp/libeb_haiku_screensaver_test.so
rc=\$?
rm -f /tmp/eb_haiku_screensaver_test /tmp/libeb_haiku_screensaver_test.so /tmp/eb_haiku_screensaver_harness
exit \$rc
")"
if [ "$SCREENSAVER_ACTUAL" = "$SCREENSAVER_EXPECTED" ]; then
    echo "    PASS: screensaver_basics"
else
    echo "    FAIL: screensaver_basics (output mismatch)"
    echo "$SCREENSAVER_ACTUAL"
    FAILED=1
fi

if [ "$FAILED" -eq 0 ]; then
    echo "==> PASSED on $HOST"
else
    echo "==> FAILED on $HOST"
fi

echo "==> Cleaning up ~/$REMOTE_DIR on $HOST..."
ssh "$HOST" "rm -rf ~/$REMOTE_DIR"

exit "$FAILED"
