# Security policy

Network Menu Bar reads the Mac's network state locally and makes a single kind of request over the network: an HTTPS lookup of the public IP. It has no accounts and no analytics. Reports that help keep it that way are very welcome.

## Supported versions

Only the latest release (the newest `x.y.z` tag) gets security fixes. It is the version published as a disk image on [GitHub Releases](https://github.com/kijart/network-menu-bar/releases) and as the `network-menu-bar` cask in [kijart/homebrew-tap](https://github.com/kijart/homebrew-tap).

## Reporting a vulnerability

Please report vulnerabilities privately through GitHub: open the **Security** tab of this repository and choose **Report a vulnerability**. Do not open a public issue or pull request for a security problem.

A useful report includes:

- what an attacker can achieve and under which conditions;
- steps to reproduce it, with the app version (shown in **Settings → About**), the macOS version and how the app was installed (disk image or Homebrew).

## What to expect

This is a personal project maintained in spare time, so replies are best effort: an acknowledgement usually within a week, then updates in the private advisory until the issue is fixed or ruled out. Once a fix is released, the advisory is published, crediting the reporter if they wish.

## Scope

In scope:

- the app sending data anywhere beyond the public IP lookup described in the README's [Privacy](README.md#privacy) section, or sending it without HTTPS;
- the app writing data beyond its preferences and its login item, or exposing them to other apps;
- the release pipeline and what it publishes: the `release-build.yml` workflow, the disk image and its `.sha256` checksum, and the automatic cask update in the tap;
- the Homebrew cask removing the quarantine flag from anything other than the app it installs.

Out of scope:

- the ad‑hoc signature and the missing notarization: both are documented, and Gatekeeper asks for confirmation on first launch;
- the public IP lookup services seeing the Mac's public IP, which is how the lookup works;
- attacks that need a compromised Mac, an administrator account or physical access to an unlocked one;
- vulnerabilities in macOS or its frameworks: please report them to Apple;
- missing hardening with no practical impact.
