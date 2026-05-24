# MediaTube Pro

MediaTube Pro is a Flutter app for downloading YouTube-style media with a desktop-friendly interface. It uses `yt-dlp` for extraction and download handling, keeps a reactive queue in the UI, and stores history, settings, and logs locally.

## What It Does
- Manages a live download queue with progress, status, retry, pause, cancel, and open-folder actions
- Saves completed items in a searchable history with channel, thumbnail, and format data
- Shows a dedicated download details view for individual tasks and playlist items
- Provides a collapsible sidebar layout with a compact desktop-style shell
- Lets you control save location, quality, concurrency, notifications, and binary paths
- Captures logs for troubleshooting failed or incomplete downloads

## Core Workflow
1. Paste a URL into the downloader page.
2. Add the task to the queue.
3. The app launches `yt-dlp` through the repository layer.
4. Progress updates stream back into the queue UI.
5. Successful downloads are written to history with metadata.
6. You can inspect details, retry failures, or open the output folder.

## Project Architecture
- `lib/domain` defines the core entities and use cases.
- `lib/data` talks to `yt-dlp`, parses output, and persists data.
- `lib/presentation` contains the pages, controllers, and reusable widgets.
- `lib/routes` defines named routes used by `GetX` navigation.
- `lib/core` keeps shared constants, theme, errors, and utilities.

## Features
- Queue-based downloads with live progress updates
- Playlist handling and item-level detail views
- Download history with filters, search, and per-item metadata
- Collapsible navigation shell for wider screens
- Settings for download quality, output folder, concurrency, and notifications
- Built-in logs page for debugging binary and process issues
- Local storage for queue and history state

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

## Local Binaries
The repository does not include the large executable files for `assets/bin/`.

If you want to use the bundled binary path, place these files in that folder locally:
- `assets/bin/yt-dlp.exe`
- `assets/bin/ffmpeg.exe`

If you prefer, you can point the app to your own `yt-dlp` and `ffmpeg` paths from the Settings screen.

## Setup
1. Get the Dart/Flutter dependencies.

```bash
flutter pub get
```

2. Provide the binaries.
- Either place `yt-dlp.exe` and `ffmpeg.exe` under `assets/bin/`
- Or configure the executable paths in Settings

3. Launch the app.

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

## Usage Tips
- Use the downloader page for new tasks.
- Use the history page to search completed downloads.
- Use Settings to change the default save location or binary paths.
- Open a download’s detail page to inspect playlist children and status.

## Project Notes
- Download tasks are stored with `GetStorage`.
- Download metadata is parsed from `yt-dlp` output.
- The app currently supports playlist-oriented workflows and is being extended for single-video support.

## Troubleshooting
- If downloads do not start, confirm `yt-dlp` is installed or its path is configured.
- If merging fails, confirm `ffmpeg` is available.
- If a large file is missing, check whether `assets/bin/` is populated locally.
- Review the Logs page for runtime errors and process output.

## License
This project does not currently include a license file.