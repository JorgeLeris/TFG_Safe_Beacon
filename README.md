# SafeBeacon

SafeBeacon is a personal safety app that allows users to send emergency alerts and share their location with trusted contacts.

## Project information

- **Flutter version:** 3.38.9
- **Sdk constraints:** sdk: ^3.10.0
- **Compatible java versions:** >17
- **Recommended java version:** 17


## Run project
DEV
```sh
flutter run --target lib/main_dev.dart --flavor dev
```
PRE
```sh
flutter run --target lib/main_pre.dart --flavor pre
```
PROD
```sh
flutter run --target lib/main_prod.dart --flavor prod
```

## Localization

Localization files are stored in `lib/core/language/l10n` directory. 

**Important:** Before modifying any localization value, always check if it's used in more than one place in the codebase. Changing a localization value may affect multiple screens or components.
