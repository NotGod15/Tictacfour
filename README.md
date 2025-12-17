# About Creator
Name : Mochamad Rafie Bimantoro
NRP : 05211942000017

# Tic Tac Four

Tictacfour is a remix of the classic game of tic-tac-toe.
It turn from classic 3x3 game to 4x4 game with new concept. 
Player only have 5 tokens that can be moved around to connect sides to win.
But be careful as the bot in this game is very hard.



## Overview

This Flutter app implements Tic Tac Four with Firebase auth (Google + guest), Firestore leaderboard, and a simple bot opponent.

## Installation Steps (for source codes)

### Prerequisites
Before installing, ensure you have this following installed on your system:
- **Flutter SDK** (version 3.10.3 or higher) - [Install Flutter](https://docs.flutter.dev/get-started/install)
- **Dart SDK** (comes with Flutter)
- **Android Studio** or **VS Code** with Flutter extensions
- **Git** (for cloning the repository)

For Android development:
- Android SDK (API level 21 or higher)
- Android Emulator or physical device

### Step 1: Clone the Repository
```bash
git clone https://github.com/NotGod15/TicTacFour.git
cd TicTacFour
```

### Step 2: Install Dependencies
```bash
flutter pub get
```

### Step 3: Firebase Configuration
This project requires Firebase configuration and google cloud.

### Step 4: Run the Application

#### On Android Emulator/Device:
```bash
flutter run
```
### Step 5: Build for Release

#### Android APK:
```bash
flutter build apk --release
```
The APK will be located at: `build/app/outputs/flutter-apk/app-release.apk`


## Installation Steps (for debug release)
Download the APK files and install it on your android phone

## Firebase setup
Should not be necessary beyond firebase CLI as this is using cloud. But if you want to use your own firebase project instead of the existing one:

1. **Create a new Firebase project:**
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Click "Add project"
   - Follow the setup wizard

2. **Add Android app:**
   - Click "Add app" → Android
   - Package name: `com.example.tictacfour`
   - Download `google-services.json` and place in `android/app/`

3. **Add Web app:**
   - Click "Add app" → Web
   - Register app and copy the configuration
   - Update `lib/firebase_options.dart` with your values

4. **Enable Authentication:**
   - Go to Authentication → Sign-in method
   - Enable: Google, Email/Password, Anonymous

5. **Set up Firestore:**
   - Go to Firestore Database → Create database
   - Start in test mode (then update security rules)
   - Create the collection structure shown above

6. **Configure Google Sign-In:**
   - Add OAuth 2.0 Client ID in Google Cloud Console
   - Add SHA-1 certificate fingerprint
   - Download updated `google-services.json`

7. **Update the code:**
   - Replace values in `lib/firebase_options.dart`
   - Replace `android/app/google-services.json`

## How to Play

1. Launch the game and tap anywhere to start
2. Choose login method: Sign in with Google, create an account, or play as guest
3. Select your symbol: Choose to play as X (goes first) or O (goes second)
4. Place your tokens: Tap empty cells to place your 5 tokens
5. Move phase: After all 5 tokens are placed, your oldest token will move on each turn
6. How to win: Get 4 tokens in a row connecting the sides
7. Check leaderboard: View top scores from all players

## Game Rules

- The game is played on a 4x4 grid
- Each player has exactly 5 tokens
- X always goes first
- First 5 turns are for placing tokens
- After all tokens are placed, the oldest token moves automatically
- First player to get 4 tokens in a row wins
- Score decreases with more moves taken (encourages quick wins)
- Ties are ranked by time taken to win

## Project Structure
```
lib/
├── main.dart                 # App entry point
├── cell.dart                 # Cell state enum (archaic code before main game logic and bot logic seperated)
├── startpage.dart            # Start screen
├── tictacfourlogic.dart      # Main game logic
├── botmove.dart              # Bot logic
├── firebase_options.dart     # Firebase configuration
├── pages/
│   ├── login_page.dart       # Login page
│   ├── game_home.dart        # Game home menu
│   └── leaderboard_page.dart # Leaderboard page
└── services/
    ├── auth_service.dart     # Google authentication service
    └── db_service.dart       # Firestore database service
