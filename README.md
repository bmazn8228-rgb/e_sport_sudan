# E-Sport Sudan 🎮🇸🇩

## Overview
E-Sport Sudan is the official platform for the Sudanese E-Sports Federation. It provides a comprehensive ecosystem for gamers to register teams, participate in tournaments, track live match updates, and view leaderboards. The app features real-time synchronization, an integrated digital wallet, and an admin dashboard for tournament management.

## Features
- **User Authentication:** Secure registration and login using Firebase Auth, with specialized validation for Sudanese phone numbers (+249).
- **Tournaments:** Browse upcoming tournaments, view details, and register teams.
- **Live Matches:** Watch live streams (YouTube integration) and get real-time match updates.
- **Rankings:** Global leaderboard fetching data from Firestore.
- **Digital Wallet:** Virtual currency system (E-Coins) for tournament entry fees and prize distributions.
- **Admin Dashboard:** Specialized screens for administrators to add tournaments, upload posters/logos, and manage events.
- **Real-time Notifications:** Automated push notifications when new tournaments are available or matches go live.

## Technologies
- **Framework:** Flutter (Dart)
- **Backend:** Firebase (Firestore, Auth, Storage, Cloud Functions)
- **State Management:** Flutter BLoC
- **Media & Images:** Cached Network Image, Image Picker
- **Video:** YouTube Player Flutter

## Project Structure
The project follows a clean, feature-first architecture:
```
lib/
├── core/             # Shared utilities, services, theme, and common widgets
├── features/         # Feature modules
│   ├── admin/        # Admin and referee dashboards
│   ├── auth/         # Login and registration
│   ├── main/         # Root navigation and home screen
│   ├── match/        # Live matches
│   ├── profile/      # User settings and profile
│   ├── rankings/     # Leaderboards
│   ├── splash/       # Initialization screen
│   ├── tournament/   # Tournament browsing and registration
│   └── wallet/       # Digital wallet management
└── main.dart         # Entry point
```

## Requirements
- Flutter SDK (v3.19.0 or higher recommended)
- Dart SDK (v3.3.0 or higher)
- Android Studio / Xcode for platform builds
- Firebase project setup (google-services.json / GoogleService-Info.plist required)

## Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/bmazn8228-rgb/e_sport_sudan.git
   ```
2. Get dependencies:
   ```bash
   flutter pub get
   ```
3. Run the app:
   ```bash
   flutter run
   ```

## APK Download
Download the latest Android APK from the releases page:
[Download APK](https://github.com/bmazn8228-rgb/e_sport_sudan/releases/latest)

## Developer
Developed by [bmazn8228-rgb](https://github.com/bmazn8228-rgb).
