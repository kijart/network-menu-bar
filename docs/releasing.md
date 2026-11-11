# Releasing

Releases are automated with [release-please](https://github.com/googleapis/release-please-action) from the [Conventional Commits](https://www.conventionalcommits.org) on `master`.

## How a release happens

1. Every push to `master` updates an open release pull request with the next version, the `CHANGELOG.md` entry and `MARKETING_VERSION` in `project.yml`. Only `feat`, `fix`, `perf` and `revert` commits are listed in the changelog and start a release; other types (`docs`, `refactor`, `style`, `test`, `build`, `ci`, `chore`) ship with the next release without a changelog entry.
2. Merging that pull request (with **Rebase and merge** or **Squash and merge**, to keep the history linear) creates the tag `X.Y.Z` (no `v` prefix) and the GitHub Release.
3. Publishing the release starts the **Release build** workflow on macOS: it runs `make test` and `make release` on the tag, uploads `Network-Menu-Bar-X.Y.Z.dmg` and its checksum `Network-Menu-Bar-X.Y.Z.dmg.sha256` to the release, and prints the SHA-256 in the job summary.
4. The same workflow then bumps `version` and `sha256` in `Casks/network-menu-bar.rb` of [kijart/homebrew-tap](https://github.com/kijart/homebrew-tap) with a commit on its default branch. A tag older than the cask's version leaves the tap untouched.

To rebuild an existing release (for example after a failed upload), run **Release build** from the Actions tab with the tag; the disk image and checksum are replaced and the cask gets the new checksum.

Before 1.0.0, `feat` bumps the minor version and breaking changes do too.

## One-time setup

The release pull request, the tag and the release are created with a GitHub App token, so that they can trigger other workflows such as **Release build** (events created with the default `GITHUB_TOKEN` cannot). The same app commits the cask bump to the tap, scoped to that repository only.

1. Create a GitHub App (Settings → Developer settings → GitHub Apps) with webhooks disabled and these repository permissions:
   - Contents: read and write
   - Pull requests: read and write
2. Install the app on `kijart/network-menu-bar` and `kijart/homebrew-tap`.
3. Note the app's **Client ID** and generate a private key.
4. In the repository settings (Secrets and variables → Actions), add:
   - variable `RELEASE_APP_CLIENT_ID`: the app's Client ID
   - secret `RELEASE_APP_PRIVATE_KEY`: the contents of the `.pem` private key

Actions are pinned to commit SHAs; Dependabot opens a weekly pull request to update them.
