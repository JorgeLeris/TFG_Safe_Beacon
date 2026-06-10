# SafeBeacon

SafeBeacon is a personal safety app that allows users to send emergency alerts and share their location with trusted contacts.

## Project information

- **Flutter version:** 3.38.9
- **Sdk constraints:** sdk: ^3.10.0
- **Compatible java versions:** >17
- **Recommended java version:** 17


## Run project
PROD
```sh
flutter run --target lib/main_prod.dart --flavor prod
```

## Generate APK
PROD
```sh
flutter build apk --flavor prod --target lib/main_prod.dart
```

## Localization

Localization files are stored in `lib/core/language/l10n` directory. 

**Important:** Before modifying any localization value, always check if it's used in more than one place in the codebase. Changing a localization value may affect multiple screens or components.

## Tools

### Clean build

Cleans the project, removes generated files (`.g.dart`, `.freezed.dart`), reinstalls dependencies, and regenerates code and translations.

```sh
sh cleanBuild.sh
```

Use it when you encounter compilation errors related to generated code or after changes to models/annotations.

### Coverage

Runs tests with coverage, filters out non-relevant files, and opens the resulting HTML report.

```sh
sh coverage.sh
```

Requires `lcov` to be installed (`brew install lcov`).

## Branch convention

- `main` — production, **do not commit directly**.
- `develop` — base development branch. All branches are created from here and merged back here.
- `feature/<name>` — new features.
- `bugfix/<name>` — bug fixes.

When done, open a PR into `develop`. Only `develop` is merged into `main` for releases.
