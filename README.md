# homebrew-costlike

[Homebrew](https://brew.sh/) tap for [CostLike](https://costlike.com) - a
desktop app for cloud cost management across AWS, Azure, Google Cloud, Hetzner
Cloud and GitHub, with a local cache and a built-in MCP server.

The cask lives in [`Casks/costlike.rb`](./Casks/costlike.rb); new releases are
picked up by the [`Update costlike cask`](./.github/workflows/update.yml) GitHub
Actions workflow.

## Install

```sh
brew install --cask cloudcertainty/costlike/costlike
brew upgrade --cask costlike
```

Apple silicon Macs get the native arm64 build; Intel Macs get x64. macOS 13
Ventura or later.

CostLike is not yet notarized by Apple, so macOS blocks the first launch of
each new version. Open it once, then go to **System Settings > Privacy &
Security** and choose **Open Anyway**.

To remove the app together with its local database, settings and cache:

```sh
brew uninstall --cask --zap costlike
```

A plain `brew uninstall --cask costlike` keeps the data.

## Where versions come from

The app repository is private, so nothing here talks to GitHub releases.
Everything comes from the public download proxy on costlike.com:

| URL | Used for |
|---|---|
| `https://costlike.com/api/updates.json` | `latest.version` - the release marked latest (never a draft or pre-release); also the cask's `livecheck` |
| `https://costlike.com/api/download/v<ver>/SHA256SUMS.txt` | the pinned SHA256 of each disk image |
| `https://costlike.com/api/download/v<ver>/CostLike-<ver>-arm64.dmg` | Apple silicon disk image, downloaded at install time |
| `https://costlike.com/api/download/v<ver>/CostLike-<ver>-x64.dmg` | Intel disk image |

The versioned URLs stream the file directly (no redirect) and must keep
working for as long as the cask points at that version - so a release the tap
has picked up must never be set back to draft or deleted.

A release promoted in the app repo can take up to an hour to show up in
`updates.json` (the proxy caches the release list). The daily run picks it up
the next morning; run the workflow by hand to publish sooner.

## How an update is published

1. **update** (Ubuntu): [`scripts/update.sh`](./scripts/update.sh) reads the
   version from `updates.json`, the hashes from `SHA256SUMS.txt`, then
   downloads both disk images and fails if either disagrees - a bad checksum
   file never reaches the tap.
2. **check** (macOS): `brew style`, `brew audit --strict --online`, then a real
   `brew install`, a check that the installed app reports the cask's version,
   and `brew uninstall --zap`. Runs on pull requests too.
3. **publish**: only if both passed, commits the cask and tags it.

### What ends up in git

Each published version leaves behind:

- A commit: `costlike: bump to <version>`
- An annotated tag: `v<version>`

## Setup

None. The workflow pushes with the built-in `GITHUB_TOKEN` (it needs
`contents: write`, which the workflow requests). Unlike the Chocolatey package
there is no feed to push to: the tap *is* this repository, so it must stay
public for `brew` to fetch it.

## Updating the cask locally (optional)

```sh
bash scripts/update.sh          # the latest release
bash scripts/update.sh 0.10.0   # pin a specific version ("v0.10.0" works too)
FORCE=1 bash scripts/update.sh  # re-verify even if already current
```

Needs bash 4+, `curl`, `python3` and `sha256sum` (on macOS:
`brew install bash coreutils`). To try a local edit of the cask on a Mac:

```sh
brew install --cask ./Casks/costlike.rb
brew audit --cask --strict --online costlike
```

## Notes

- The cask does **not** contain the app; Homebrew downloads the disk image
  from costlike.com and verifies it against the pinned SHA256.
- Releases are ad-hoc signed, not notarized. That is fine for a third-party
  tap. Getting into the main `homebrew/cask` repository would need a Developer
  ID signature and notarization (Homebrew now requires casks there to pass
  Gatekeeper), plus enough public use to meet its notability rules.
- When releases are notarized, remove the `caveats` block from the cask.
- CostLike is proprietary software, used under the
  [CostLike terms](https://costlike.com/terms/). This
  repository's own files (the cask and scripts) are under the Apache License
  2.0 in [`LICENSE`](./LICENSE).
