# Contributing

Contributions are welcome, and translations are the easiest way to help: a new language, or a fix to a string that reads wrong. Bug reports and small fixes are welcome too. For larger changes, please open an issue first to agree on the approach.

Security problems are not reported in issues: see [SECURITY.md](SECURITY.md).

## Running the app locally

Requires Xcode 16 or later and [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`). The Xcode project is generated from `project.yml` and is not in the repository.

```sh
make run        # generate the project, build and launch
make test       # run the unit tests of NetworkMenuBarKit
make generate   # only generate NetworkMenuBar.xcodeproj, e.g. to open it in Xcode
make release    # build, sign ad-hoc and package a .dmg into dist/
```

The network detection lives in the `NetworkMenuBarKit` package and can be checked without the menu with `nmb-dump`, which prints what the app sees: the system state, the menu rows and the public IP. `--watch` keeps printing every change (plugging a cable, switching Wi‑Fi, connecting a VPN), and `--raw` adds the dynamic store keys, useful for a VPN client that is not recognised:

```sh
swift run --package-path NetworkMenuBarKit nmb-dump --watch
```

A bug report about a network that shows wrongly is much easier to act on with its `nmb-dump` output (IP addresses can be masked).

## Translations

All the UI text is in the String Catalog [`NetworkMenuBar/Localizable.xcstrings`](NetworkMenuBar/Localizable.xcstrings). English (`en`) is the base language: the keys are the English strings, and a missing translation falls back to English.

### Fixing a string

Find the English key in the catalog, either in Xcode's String Catalog editor or in the JSON, and change only the language's `value`. Check the result in the app (see [Checking a translation](#checking-a-translation)).

### Adding a language

A new language touches four places; the steps below use French (`fr`) as the example.

1. **`project.yml`**: add the code to `knownRegions`, then run `make generate`.

   ```yaml
   knownRegions: [en, es, fr]
   ```

2. **`NetworkMenuBar/Localizable.xcstrings`**: translate every key, either in Xcode's String Catalog editor (open the project, select the catalog, add French with **+**) or by hand in the JSON, adding an entry like this to each string:

   ```json
   "fr" : { "stringUnit" : { "state" : "translated", "value" : "Actualiser" } }
   ```

3. **`NetworkMenuBar/AppSettings.swift`**: add a case to `AppLanguage`. The Settings picker lists every case by its own name ("Français"), so nothing else changes in code.

   ```swift
   case french = "fr"
   ```

4. **`README.md`**: update the "English and Spanish" feature line and the Language row of the Settings table.

### Rules for strings

- **Every key** in the catalog has a translation in the new language.
- **Placeholders** such as `%@` stay as they are (not translated); they can move within the sentence (`via %@`, `Version %@`).
- **Not in the catalog**: the app name, IP addresses, interface names (`en0`, `utun4`) and adapter names such as "Thunderbolt Bridge" or "USB 10/100/1G LAN", which come from macOS in the system language.
- **Length**: the menu grows from 280 to 400 pt and wraps long text to two lines, and Settings labels share their row with a control; a translation much longer than the English one may need a shorter wording.
- **Tone**: short and impersonal, as in the English and Spanish texts ("Waiting for approval in System Settings.", "Quit Network Menu Bar").

### Checking a translation

Build and launch the app in the language without changing the system one:

```sh
make build
open "build/Build/Products/Release/Network Menu Bar.app" --args -AppleLanguages '(fr)'
```

Choosing the language in Settings and relaunching works too. Check both menu layouts, with network icons on and off, and both Settings tabs.

## Commits and pull requests

1. Fork the repository and create a branch from `master` (e.g. `feat/i18n-french`).
2. Keep each pull request to one change, and run `make test` before opening it.
3. Open the pull request against `master`, describing what changes and how it was checked. For UI changes, a screenshot helps.

Commit messages and pull request titles follow [Conventional Commits](https://www.conventionalcommits.org/): a single line, in English, in the imperative (`fix: keep the VPN name when the tunnel reconnects`). [Release Please](docs/releasing.md) reads them to decide the next version and write the [changelog](CHANGELOG.md):

| Type | Use | Release |
| --- | --- | --- |
| `feat` | New feature (e.g. `feat(i18n): add French`) | minor (`x.Y.0`) |
| `fix` | Bug fix (e.g. `fix(i18n): shorten the Refresh label in German`) | patch (`x.y.Z`) |
| `perf` | Performance improvement | patch |
| `revert` | Reverts an earlier commit | patch |
| `docs`, `style`, `refactor`, `test`, `build`, `ci`, `chore` | Changes that users don't see | none on their own |

A breaking change adds `!` after the type (`feat!: …`). While the version is below 1.0 it makes a minor release; from 1.0 on, a major one (`X.0.0`).

## License

Contributions are licensed under the project's [MIT License](LICENSE).
