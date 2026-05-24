# MediaTube Pro

MediaTube Pro is a Flutter desktop/mobile downloader for YouTube-style media workflows. It uses `yt-dlp` for extraction, supports a queue-based download experience, and keeps history, settings, and logs inside the app.

## Features
- Download queue with progress, status, retry, pause, and cancel actions
- Download history with filters, search, thumbnails, and channel info
- Dedicated download details view
- Collapsible sidebar navigation
- Settings for save location, quality, concurrency, notifications, and binaries
- Log viewer for troubleshooting downloads

## File Structure
```text
lib/
├── core/
│   ├── constants/
│   ├── errors/
│   ├── theme/
│   └── utils/
├── data/
│   ├── datasources/
│   ├── models/
│   └── repositories/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
├── presentation/
│   ├── bindings/
│   ├── controllers/
│   ├── pages/
│   └── widgets/
└── routes/

assets/
├── bin/
└── ...

yt/
├── download_material_symbols.py
├── yt.py
└── icons/
```

## Requirements
- Flutter SDK 3.11 or newer
- `yt-dlp`
- `ffmpeg`

## Setup
1. Install Flutter dependencies:

```bash
flutter pub get
```

2. Make sure `yt-dlp` and `ffmpeg` are available, or configure their paths in the app settings.

3. Run the app:

```bash
flutter run
```

## Build
```bash
flutter build apk
flutter build ios
flutter build windows
flutter build macos
flutter build linux
```

## Project Notes
- Download tasks are stored with `GetStorage`.
- Download metadata is parsed from `yt-dlp` output.
- The app currently supports playlist-oriented workflows and is being extended for single-video support.

## Structure
- `lib/data` — process spawning, repository logic, and models
- `lib/domain` — entities and business rules
- `lib/presentation` — pages, controllers, and reusable widgets
- `lib/routes` — app routing
- `yt/` — helper scripts and assets related to yt-dlp tooling

## License
This project does not currently include a license file.