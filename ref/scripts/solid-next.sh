#!/bin/sh
# ref/ runs on Solid 2.0 built from source — `main`, where the `next` branch the async rules come from was merged — at
# the commit pinned in ref/SOLID_NEXT. The checkout lives beside this repository (../solid-next), or at $SOLID_NEXT.
#   sh ref/scripts/solid-next.sh            check out the pinned commit and build what ref/ links
#   sh ref/scripts/solid-next.sh --latest   move the pin to main's HEAD first
set -e
HERE=$(cd "$(dirname "$0")/.." && pwd)
DIR=${SOLID_NEXT:-$HERE/../../solid-next}
[ -d "$DIR/.git" ] || git clone --branch main https://github.com/solidjs/solid "$DIR"
git -C "$DIR" fetch -q origin main
if [ "$1" = "--latest" ]; then git -C "$DIR" rev-parse origin/main > "$HERE/SOLID_NEXT"; fi
git -C "$DIR" checkout -q "$(cat "$HERE/SOLID_NEXT")"
cd "$DIR"
pnpm install --frozen-lockfile
for p in signals solid web universal; do (cd "packages/$p" && pnpm run build && pnpm run --if-present types); done   # types: the JSX types the types runner checks against
(cd packages/compiler && pnpm run build)          # the native Oxc compiler (needs a Rust toolchain)
echo "solid next @ $(git rev-parse --short HEAD) built in $DIR"
