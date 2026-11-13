# Contributing

Issues and pull requests are welcome. See [Build from source](README.md#build-from-source) to set up the project, and run `make test` before opening a pull request.

Security problems are not reported in issues: see [SECURITY.md](SECURITY.md).

## Adding a language

The app is localized with a String Catalog. A new language touches four places; the steps below use French (`fr`) as the example.

1. **`project.yml`**: add the code to `knownRegions`, then run `make generate`.

   ```yaml
   knownRegions: [en, es, fr]
   ```

2. **`NetworkMenuBar/Localizable.xcstrings`**: translate every key, either in Xcode's String Catalog editor (open the project, select the catalog, add French with **+**) or by hand in the JSON, adding an entry like this to each string:

   ```json
   "fr" : { "stringUnit" : { "state" : "translated", "value" : "Actualiser" } }
   ```

   Keep `%@` placeholders as they are. Adapter names such as "Thunderbolt Bridge" or "USB 10/100/1G LAN" come from macOS in the system language and are not in the catalog.

3. **`NetworkMenuBar/AppSettings.swift`**: add a case to `AppLanguage`. The Settings picker lists every case by its own name ("Français"), so nothing else changes in code.

   ```swift
   case french = "fr"
   ```

4. **`README.md`**: update the "English and Spanish" feature line and the Language row of the Settings table.

### Checking a translation

Build and launch the app in the new language without changing the system one:

```sh
make build
open "build/Build/Products/Release/Network Menu Bar.app" --args -AppleLanguages '(fr)'
```

Choosing the language in Settings and relaunching works too. Check both menu layouts and the Settings window: the menu grows up to 400 pt and wraps long text to two lines, so overly long translations still look cramped.
