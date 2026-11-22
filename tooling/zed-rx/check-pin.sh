#!/bin/sh
# Compares tooling/tree-sitter-rx at extension.toml's rev with HEAD's (committed changes, not the working tree). Zed
# only picks up grammar changes when rev is bumped, so a grammar change merged without the bump never reaches Zed.
#
# Compares the folder's tree at rev, not commits: a squash merge leaves the pinned commit out of main's history, and
# a pin made on a branch is still right when the grammar did not change after it.
#
# Exit status: 0 the trees match; 1 they differ (a rev that predates the folder differs too); 2 the check could not
# run (no rev in extension.toml, rev cannot be fetched or is not a commit, HEAD has no such folder). What a status
# means for CI is the workflow's call (.github/workflows/zed.yml).
set -eu
cd "$(dirname "$0")"

fail() { echo "check-pin: $*" >&2; exit 2; }

pin() { sed -n "/^\[grammars\.rx\]/,\$ s/^$1 = \"\(.*\)\"/\1/p" extension.toml; }
repository=$(pin repository) || fail "cannot read extension.toml"
path=$(pin path) || fail "cannot read extension.toml"
rev=$(pin rev) || fail "cannot read extension.toml"
[ -n "$repository" ] && [ -n "$path" ] && [ -n "$rev" ] ||
  fail "extension.toml has no repository, path and rev under [grammars.rx]"

# CI checks out all of history (fetch-depth: 0); a rev outside it is fetched, as check-queries.sh does
git cat-file -e "$rev^{commit}" 2>/dev/null ||
  git fetch --quiet --depth 1 "$repository" "$rev" ||
  fail "cannot fetch rev $rev from $repository"
git cat-file -e "$rev^{commit}" 2>/dev/null || fail "rev $rev is not a commit"

# rev-parse, not git diff: needs only the two trees, whatever lies between them. No $path at rev counts as differing.
pinned=$(git rev-parse -q --verify "$rev:$path" || echo none)
current=$(git rev-parse "HEAD:$path") || fail "HEAD has no $path"
if [ "$pinned" != "$current" ]; then
  last=$(git log -1 --format=%H -- ":(top)$path") || fail "cannot read the history of $path"
  echo "$path differs from the pinned rev $rev. The last commit to touch it is $last." >&2
  git diff --stat "$rev" HEAD -- ":(top)$path" >&2 || true
  exit 1
fi
echo "pin: $rev has $path as HEAD does"
