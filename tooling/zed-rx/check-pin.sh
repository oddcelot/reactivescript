#!/bin/sh
# Fails when tooling/tree-sitter-rx is not what extension.toml's rev has. Zed only picks up grammar changes when
# rev is bumped, so a grammar change merged without the bump never reaches Zed.
#
# Compares the folder's tree at rev with HEAD's, not commits: a squash merge leaves the pinned commit out of main's
# history, and a pin made on a branch is still right when the grammar did not change after it.
set -eu
cd "$(dirname "$0")"

pin() { sed -n "/^\[grammars\.rx\]/,\$ s/^$1 = \"\(.*\)\"/\1/p" extension.toml; }
repository=$(pin repository)
path=$(pin path)
rev=$(pin rev)

# CI checks out all of history (fetch-depth: 0); a rev outside it is fetched, as check-queries.sh does
git cat-file -e "$rev^{commit}" 2>/dev/null || git fetch --quiet --depth 1 "$repository" "$rev"

# rev-parse, not git diff: needs only the two trees, whatever lies between them
pinned=$(git rev-parse -q --verify "$rev:$path" || echo none)
current=$(git rev-parse "HEAD:$path")
if [ "$pinned" != "$current" ]; then
  last=$(git log -1 --format=%H -- ":(top)$path")
  echo "$path changed since the rev extension.toml pins ($rev)." >&2
  echo "Set [grammars.rx] rev to $last (the last commit to touch it) and commit that." >&2
  echo "Changed:" >&2
  git diff --stat "$rev" HEAD -- ":(top)$path" >&2
  exit 1
fi
echo "pin: $rev has $path as HEAD does"
