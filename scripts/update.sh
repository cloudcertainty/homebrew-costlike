#!/usr/bin/env bash
# Point Casks/costlike.rb at a CostLike release.
#
#   bash scripts/update.sh          # the release costlike.com marks latest
#   bash scripts/update.sh 0.10.0   # a specific version ("v0.10.0" works too)
#   FORCE=1 bash scripts/update.sh  # re-verify and rewrite even if already current
#
# The hashes come from the release's own SHA256SUMS.txt. Before they are pinned, both
# disk images are downloaded and hashed here, so a checksum file that disagrees with what
# the site actually serves fails the update instead of shipping a cask that cannot install.
#
# Prints the cask's version on the last line; exits 0 whether or not anything changed.
set -euo pipefail

manifest='https://costlike.com/api/updates.json'
download='https://costlike.com/api/download'
cask="$(cd "$(dirname "$0")/.." && pwd)/Casks/costlike.rb"

current=$(sed -n 's/^  version "\(.*\)"$/\1/p' "$cask")

want="${1:-${COSTLIKE_VERSION:-}}"
want="${want#v}"
if [ -z "$want" ]; then
  want=$(curl -fsSL "$manifest" | python3 -c 'import json,sys; print(json.load(sys.stdin)["latest"]["version"])')
fi
if ! printf '%s' "$want" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$'; then
  echo "Not a release version: '$want'" >&2
  exit 1
fi

if [ "$want" = "$current" ] && [ -z "${FORCE:-}" ]; then
  echo "Cask already at $current."
  echo "$current"
  exit 0
fi

echo "Updating cask: $current -> $want"
sums=$(curl -fsSL "$download/v$want/SHA256SUMS.txt")

sum_of() {
  # Lines are "<hash>  <name>" or "<hash> *<name>".
  printf '%s\n' "$sums" | awk -v f="$1" '{ n = $2; sub(/^\*/, "", n); if (n == f) print $1 }'
}

declare -A pinned
for arch in arm64 x64; do
  file="CostLike-$want-$arch.dmg"
  sum=$(sum_of "$file")
  if ! printf '%s' "$sum" | grep -Eq '^[0-9a-f]{64}$'; then
    echo "SHA256SUMS.txt for v$want has no entry for $file" >&2
    exit 1
  fi
  echo "Verifying $download/v$want/$file"
  actual=$(curl -fsSL "$download/v$want/$file" | sha256sum | cut -d' ' -f1)
  if [ "$actual" != "$sum" ]; then
    echo "Checksum mismatch for $file: SHA256SUMS.txt says $sum, download hashes to $actual" >&2
    exit 1
  fi
  pinned[$arch]=$sum
done

sed -i.bak \
  -e "s/^  version \".*\"$/  version \"$want\"/" \
  -e "s/^  sha256 arm:   \"[0-9a-f]*\",$/  sha256 arm:   \"${pinned[arm64]}\",/" \
  -e "s/^         intel: \"[0-9a-f]*\"$/         intel: \"${pinned[x64]}\"/" \
  "$cask"
rm -f "$cask.bak"

# A pattern that stopped matching would leave the old values in place and pass silently.
grep -q "^  version \"$want\"$" "$cask"
grep -q "${pinned[arm64]}" "$cask"
grep -q "${pinned[x64]}" "$cask"

echo "$want"
