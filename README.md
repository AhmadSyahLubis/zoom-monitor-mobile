# Zoom Monitor Mobile

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Riverpod](https://img.shields.io/badge/Riverpod-2.5-blueviolet?style=for-the-badge)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey?style=for-the-badge)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)

**A modern, corporate-grade mobile client for orchestrating, scheduling, and monitoring enterprise Zoom Premium accounts in real-time.**

</div>

---

## 📌 Overview

**Zoom Monitor Mobile** is an enterprise-oriented Flutter application designed for managing, booking, and monitoring pooled Zoom Premium accounts. Built with a focus on restrained corporate aesthetics, responsive performance, and robust security, it provides IT administrators and employees with instant visibility into account usage, seamless room scheduling, conflict resolution, recurring meeting planning, and centralized cloud recordings access.

---

## ✨ Key Features

### 1. 📊 Real-Time Account Monitoring
- **Live Status Feed**: Real-time visibility into all corporate Zoom accounts (e.g., Idle, In-Meeting, Waiting Room).
- **Active Meeting Telemetry**: View current host, participant headcount, topic, and live duration.
- **Account Specifications**: Track licensed tier capabilities, participant limits, and cloud storage quotas.

### 2. 📅 Smart Booking & Conflict Resolution
- **Instant Availability Search**: Find vacant Zoom accounts for specific meeting dates and times.
- **Conflict Prevention**: Automatic validation to prevent overlapping schedules across shared accounts.
- **One-Tap Meeting Launch**: Open Zoom directly via deep links (`zoomus://` or browser URL) from the app.
- **Instant Invitation Sharing**: Format and copy meeting credentials (Meeting ID, Passcode, Join URL) to clipboard or share via native channels.

### 3. 🔁 Recurring Meetings with Date Range Limits
- **Flexible Recurrence Patterns**: Schedule Daily, Weekly, or Monthly repeating sessions.
- **Strict Date Range Boundary**: Define explicit Start Date and End Date boundaries with instant session count estimates.

### 4. ✏️ Reschedule & Edit Meetings
- **In-Place Modification**: Update meeting topics, dates, start times (WIB / UTC), duration, and recurrence settings without deleting and re-booking.
- **Emergency Meeting Termination**: Force-end ongoing meetings directly from the mobile app when needed.

### 5. ☁️ Cloud Recordings Library
- **Centralized Cloud Archive**: Browse completed recordings across all corporate accounts.
- **Playback & Download Links**: Stream recordings directly or share password-protected playback URLs with team members.
- **Size & Format Transparency**: Inspect MP4/M4A file sizes, recording dates, and duration.

### 6. 🔐 Enterprise Security & Hardware Biometrics
- **Multi-Factor Device Auth**: Secure login via corporate credentials, 6-digit Device PIN, or Hardware Biometrics (Fingerprint / Face ID).
- **Encrypted Local Storage**: Sensitive tokens stored via `FlutterSecureStorage` using hardware keystore/keychain (AES-256).
- **Auto-Lock & Session Invalidation**: Automatic token refresh with defensive interceptors and secure logout.

### 7. 🎨 Apple-Style Frosted Glass UI & Smooth Performance
- **Frosted Glass Navigation**: Floating, blur-treated bottom navigation bar designed with proper safe-area padding.
- **60 / 120 FPS Fluid Scrolling**: Zero-stutter scroll experience using in-memory RAM caching, deduplicated network fetches, and eager cache invalidation on mutations.
- **Theme Consistency**: High-contrast, restrained enterprise color palette adhering to professional accessibility standards.

---

## 🛠️ Technology Stack

| Layer | Technology |
|---|---|
| **Framework** | [Flutter](https://flutter.dev) (v3.22+) / [Dart](https://dart.dev) (v3.4+) |
| **State Management** | [Flutter Riverpod](https://pub.dev/packages/flutter_riverpod) (v2.5) |
| **Navigation & Routing** | [GoRouter](https://pub.dev/packages/go_router) (v14.1) |
| **Networking** | [Dio](https://pub.dev/packages/dio) (v5.4) with custom cache & auth interceptors |
| **Local Storage** | [FlutterSecureStorage](https://pub.dev/packages/flutter_secure_storage) & [SharedPreferences](https://pub.dev/packages/shared_preferences) |
| **Biometric Auth** | [Local Auth](https://pub.dev/packages/local_auth) & [Device Info Plus](https://pub.dev/packages/device_info_plus) |
| **Icons & Typography** | [Phosphor Icons](https://pub.dev/packages/phosphor_icons) & [Google Fonts (Inter)](https://pub.dev/packages/google_fonts) |

---

## 📂 Project Structure

The project follows a **Feature-First Clean Architecture**:

```
lib/
├── core/
│   ├── config/          # App configurations & route declarations
│   ├── constants/       # Storage keys, timeouts, and business constants
│   ├── network/         # Dio client, RAM cache manager, auth interceptors
│   ├── providers/       # Global core providers (storage, API client)
│   ├── storage/         # Secure storage & preferences service wrappers
│   ├── theme/           # Corporate color schemes, text styles, glass surfaces
│   ├── utils/           # Date formatting (Asia/Jakarta), invite generators
│   └── widgets/         # Reusable glass nav bar, empty/error state widgets
├── features/
│   ├── accounts/        # Zoom accounts list & specification screens
│   ├── auth/            # Login, PIN setup, and biometric lock screens
│   ├── booking/         # Schedules screen, booking dialog, edit meeting modal
│   ├── dashboard/       # Real-time room status, quick stats, active meetings
│   └── recordings/      # Cloud recording explorer, filter, and detail views
└── main.dart            # Application bootstrap & ProviderScope initialization
```

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.22.0 or newer)
- Android Studio / VS Code with Flutter extensions
- Android device or emulator (API 26+) / iOS Simulator (iOS 14+)
- Running instance of backend API ([API-ZoomMonitor](https://github.com/AhmadSyahLubis/API-ZoomMonitor) or [zoom-monitor](https://github.com/AhmadSyahLubis/zoom-monitor))

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/AhmadSyahLubis/zoom-monitor-mobile.git
   cd zoom-monitor-mobile
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure API Base URL:**
   By default, the app connects to the local development server. You can specify a custom API URL using `--dart-define`:
   ```bash
   # Running on physical Android device connected via Wi-Fi:
   flutter run --dart-define=API_BASE_URL=http://<YOUR_LOCAL_IP>:8080/api/v1

   # Running with ADB reverse port forwarding (USB):
   adb reverse tcp:8080 tcp:8080
   flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8080/api/v1
   ```

---

## 📦 Building for Production

### Android APK
```bash
# Build universal Release APK
flutter build apk --release

# Output path:
# build/app/outputs/flutter-apk/app-release.apk
```

### Android App Bundle (AAB)
```bash
flutter build appbundle --release
```

---

## 🧪 Testing & Code Quality

Run the unit test suite:
```bash
flutter test
```

Perform static analysis:
```bash
flutter analyze
```

---

## 🔗 Related Repositories
- [API-ZoomMonitor](https://github.com/AhmadSyahLubis/API-ZoomMonitor) - High-performance Go Backend API
- [zoom-monitor](https://github.com/AhmadSyahLubis/zoom-monitor) - Laravel Backend & Web Administration Dashboard

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).

---

## 👤 Author

Developed and maintained by **Ahmad Syah** ([@AhmadSyahLubis](https://github.com/AhmadSyahLubis)).
