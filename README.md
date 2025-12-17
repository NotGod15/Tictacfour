# Tictacfour

tictacfour project for final test.

## Overview

This Flutter app implements Tic Tac Four with Firebase auth (Google + guest), Firestore leaderboard, and a simple bot opponent.

## Running

```bash
flutter pub get
flutter run
```

## Building APK

```bash
flutter build apk --debug
```

## Notes
- Scores are saved only for authenticated users.
- Guest mode does not store leaderboard entries.
