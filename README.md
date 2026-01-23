# TCamp Calendar

[![CD Workflow](https://github.com/zivmax/tcamp_calendar/actions/workflows/cd.yml/badge.svg?branch=main)](https://github.com/zivmax/tcamp_calendar/actions/workflows/cd.yml)
[![Release](https://img.shields.io/github/v/release/zivmax/tcamp_calendar?display_name=tag&sort=semver)](https://github.com/zivmax/tcamp_calendar/releases)
[![Demo](https://img.shields.io/badge/demo-GitHub%20Pages-brightgreen)](https://zivmax.github.io/tcamp_calendar/)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/zivmax/tcamp_calendar/blob/main/LICENSE)

TCamp Calendar is a Flutter calendar app with event management, recurring events, notifications, and ICS import/export support. This repository contains the production implementation used by the TCamp team.

## Key Features

- Event creation and editing with validation.
- Recurring events (RFC 5545 rules).
- Local notifications and reminders.
- ICS import/export.
- Localization and theming.
- Cross-platform targets (Android, iOS, Web, Windows, macOS, Linux).

## Tech Stack

- Flutter + Dart
- Local storage via app services
- Tests covering models, services, and screens

## Requirements

- Flutter SDK (stable)
- Dart SDK (bundled with Flutter)
- Android Studio or Xcode (for device/emulator)

## Setup

1. Clone the repository.
2. Install dependencies:

```
flutter pub get
```

3. Run the app (example for Android emulator):

```
flutter run -d emulator-5554
```

4. Run on Windows desktop:

```
flutter config --enable-windows-desktop
flutter run -d windows
```

5. Run on Web (Edge):

```
flutter run -d edge
```

## Project Structure

- lib/main.dart: app entry
- lib/screens: UI screens
- lib/models: domain models
- lib/services: data, notifications, and ICS services
- lib/widgets: shared widgets
- test: unit and widget tests
- assets: fonts and icons

## Running Tests

```
flutter test
```

## Contributing

We welcome contributions. To participate:

1. Create a feature branch from `main`.
2. Follow existing coding patterns in lib/.
3. Add or update tests under test/ for any behavior change.
4. Ensure `flutter test` passes.
5. Open a pull request with a clear summary and screenshots when relevant.

## Documentation

- Product and technical notes are in docs/.
- RFC reference used by recurrence logic: docs/rfc5545.txt

## Support

Open an issue with clear steps to reproduce, expected behavior, and logs if applicable.
