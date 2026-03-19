# Tetris Pro 🧱

A premium, wooden-themed Tetris game built with Flutter.

## Features

- **Classic Gameplay**: 10x20 Grid, SRS-inspired rotation (simplified for MVP).
- **Dark Wooden Theme**: Aesthetically pleasing dark wood UI.
- **Progress System**: Levels, Score, High Score persistence.
- **Economy**: Earn coins (mocked) and "Shop" (Architecture ready).
- **Lives System**: 3 Hearts mechanic with "Revive" option.
- **Ads Integration**: Placeholder widgets for AdMob.
- **Backend Ready**: Supabase integration hooks ready.

## Getting Started

1.  **Install Flutter**: Ensure you have Flutter installed.
2.  **Dependencies**: Run `flutter pub get`.
3.  **Run**:
    - iOS: `./start_ios`
    - Android: `./start_android`
    - Manual (iOS Simulator): `open -a Simulator` then `flutter run`
    - Manual (Android Emulator): `flutter emulators --launch <emulator_id>` then `flutter run`

## Supabase & AdMob Configuration

To enable real backend and ads:

1.  Uncomment Supabase initialization in `lib/main.dart` and add your URL/Key.
2.  Uncomment AdMob initialization in `lib/main.dart` and `ios/Runner/Info.plist` / `android/app/src/main/AndroidManifest.xml` (add App ID).

## Project Structure

- `lib/core`: Theme and Constants.
- `lib/models`: Data models (Block).
- `lib/providers`: State management (`GameProvider`).
- `lib/screens`: UI Screens.
- `lib/widgets`: Reusable components.

## Development

- **State Management**: `Provider` package.
- **Audio**: `audioplayers` (Added to pubspec, available for use).
