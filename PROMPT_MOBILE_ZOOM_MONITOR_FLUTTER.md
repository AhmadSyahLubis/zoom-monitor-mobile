# 📱 MASTER PROMPT: Pembangunan Mobile App — Zoom Monitor (Flutter)

> **DOKUMEN INI ADALAH MASTER BLUEPRINT & ARSITEKTUR DEFINITIF UNTUK AI AGENT.**
> Gunakan seluruh instruksi di bawah ini untuk membangun aplikasi mobile Flutter Zoom Monitor dari NOL hingga siap rilis (production-ready).
> Aplikasi ini mengonsumsi backend **Zoom Monitor API (Go 1.22+ / Chi / PostgreSQL / Redis)** yang sudah selesai dibangun, teruji, dan aktif berjalan di port `8080`.

---

## 🧭 Konteks Progres Backend & Environment Kerja

Backend API telah selesai diimplementasikan 100% dengan status:
- **Server:** Berjalan di `http://localhost:8080` (API Base: `/api/v1`).
- **Database:** PostgreSQL (Port 5432) & Redis (Port 6379).
- **Timezone Server:** `Asia/Jakarta` (WIB / UTC+7).
- **Akun Dev/Seeded Tersedia:**
  - **Username:** `admin`
  - **Password:** `password123`
  - **PIN 6-Digit:** `123456`
  - **Device ID Contoh:** `flutter-dev-device-01`
- **Fitur Enterprise Backend:**
  - Enterprise Defense-in-Depth Authentication (Password Utama + PIN 6-Digit Terikat Perangkat + Hardware Biometric + Refresh Token Rotation + Redis Blacklist).
  - Zoom S2S OAuth Client dengan singleflight & semaphore concurrency limiter (anti HTTP 429).
  - Search Availability & Conflict Detection (mencegah double booking antar akun virtual).
  - Meeting Lifecycle (Create, Update, Delete per-occurrence/all, Force End live meeting, Host Key retrieval).
  - Cloud Recordings viewer dengan filter tanggal dan URL streaming/download.
  - CRUD Zoom Accounts dengan validasi koneksi langsung ke Zoom API.

---

## 📋 Daftar Isi

1. [Spesifikasi Teknis & Dependensi (`pubspec.yaml`)](#1-spesifikasi-teknis--dependensi-pubspecyaml)
2. [Arsitektur Folder (Feature-First Clean Architecture)](#2-arsitektur-folder-feature-first-clean-architecture)
3. [Katalog Lengkap API Endpoints & Kontrak Data](#3-katalog-lengkap-api-endpoints--kontrak-data)
4. [Sistem Keamanan & Alur Autentikasi Defense-in-Depth](#4-sistem-keamanan--alur-autentikasi-defense-in-depth)
5. [Spesifikasi Layar & UI/UX Design System](#5-spesifikasi-layar--uiux-design-system)
6. [Core Infrastructure (Dio, Interceptor, Storage & WIB Time)](#6-core-infrastructure-dio-interceptor-storage--wib-time)
7. [Data Models & DTOs Lengkap (Sesuai Backend Go)](#7-data-models--dtos-lengkap-sesuai-backend-go)
8. [State Management & Provider Architecture (Riverpod)](#8-state-management--provider-architecture-riverpod)
9. [Format Salin Undangan Rapat (PTPN IV Standard)](#9-format-salin-undangan-rapat-ptpn-iv-standard)
10. [Roadmap Pengerjaan 7 Fase Modular (Panduan Eksekusi AI)](#10-roadmap-pengerjaan-7-fase-modular-panduan-eksekusi-ai)

---

## 1. Spesifikasi Teknis & Dependensi (`pubspec.yaml`)

Gunakan Flutter versi stable (Flutter 3.22+ / Dart 3.4+). Inisialisasi dependensi berikut:

```yaml
name: zoom_monitor_mobile
description: "Aplikasi Mobile Enterprise Zoom Monitor PTPN IV Regional 1"
publish_to: "none"
version: 1.0.0+1

environment:
  sdk: ">=3.4.0 <4.0.0"
  flutter: ">=3.22.0"

dependencies:
  flutter:
    sdk: flutter

  # State Management & Reactive UI
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5

  # HTTP Client & Network
  dio: ^5.4.3+1

  # Keamanan & Local Storage
  flutter_secure_storage: ^9.2.2
  shared_preferences: ^2.2.3

  # Hardware Biometrics & Hardware Identification
  local_auth: ^2.2.0
  device_info_plus: ^10.1.0

  # Routing & Deep Linking
  go_router: ^14.1.4

  # Date, Time & Localization (WIB Asia/Jakarta)
  intl: ^0.19.0

  # UI Enhancement, Icons & Typography
  google_fonts: ^6.2.1
  shimmer: ^3.0.0
  flutter_svg: ^2.0.10+1

  # Actions, Clipboard & External Launchers
  url_launcher: ^6.3.0
  share_plus: ^9.0.0
  fluttertoast: ^8.2.6

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  build_runner: ^2.4.9
  riverpod_generator: ^2.4.0

flutter:
  uses-material-design: true
  assets:
    - assets/images/
    - assets/icons/
```

### Konfigurasi Izin Native:
- **Android (`android/app/src/main/AndroidManifest.xml`)**:
  ```xml
  <uses-permission android:name="android.permission.INTERNET"/>
  <uses-permission android:name="android.permission.USE_BIOMETRIC"/>
  ```
- **iOS (`ios/Runner/Info.plist`)**:
  ```xml
  <key>NSFaceIDUsageDescription</key>
  <string>Aplikasi memerlukan Face ID untuk membuka akses Zoom Monitor secara aman dan instan.</string>
  ```

---

## 2. Arsitektur Folder (Feature-First Clean Architecture)

Susun struktur project di folder `lib/` dengan pembagian fitur terisolasi:

```
lib/
├── app.dart                                # MaterialApp, GoRouter builder, Theme binding
├── main.dart                               # Entry point, WidgetsFlutterBinding, ProviderScope
├── core/
│   ├── config/
│   │   ├── app_config.dart                 # Base URL (Emulator vs Real Device), Envs
│   │   └── app_routes.dart                 # Route constants & path definitions
│   ├── constants/
│   │   └── app_constants.dart              # Timeout durations, storage keys
│   ├── network/
│   │   ├── api_client.dart                 # Dio singleton, timeout options
│   │   ├── api_endpoints.dart              # URL string path constants
│   │   ├── api_response.dart               # Envelope generic ApiResponse<T>
│   │   └── auth_interceptor.dart           # QueuedInterceptor, Silent Refresh Token Rotation
│   ├── storage/
│   │   ├── secure_storage_service.dart     # Wrapper flutter_secure_storage
│   │   └── preferences_service.dart        # Wrapper SharedPreferences
│   ├── theme/
│   │   ├── app_colors.dart                 # Emerald PTPN IV Palette, dark/light colors
│   │   └── app_theme.dart                  # ThemeData, Typography, CardTheme, ButtonTheme
│   └── utils/
│       ├── date_time_util.dart             # WIB Parser, Formatter, Relative Time
│       ├── device_helper.dart              # device_info_plus UUID extractor
│       ├── invite_formatter.dart           # Generator teks undangan rapat rapi
│       └── ui_feedback.dart                # SnackBar, Loading Dialog, Alert Confirmation
└── features/
    ├── auth/
    │   ├── data/
    │   │   ├── auth_repository.dart        # Implements Auth API calls
    │   │   └── models/
    │   │       ├── auth_response.dart      # UserProfile, TokenResponse
    │   │       └── login_request.dart      # DTOs request login & pin
    │   └── presentation/
    │       ├── controllers/
    │       │   └── auth_controller.dart    # StateNotifier auth state & session
    │       ├── screens/
    │       │   ├── login_screen.dart       # Master Password login
    │       │   ├── pin_login_screen.dart   # Keypad PIN 6-digit & Biometric button
    │       │   └── pin_setup_screen.dart   # Setup/Change PIN & password confirm
    │       └── widgets/
    │           ├── numeric_keypad.dart     # Keypad custom modern 0-9 & del
    │           └── pin_dots_indicator.dart # 6 Bulatan indikator PIN terisi
    ├── dashboard/
    │   ├── data/
    │   │   ├── dashboard_repository.dart   # GetDashboard, GetStatus, GetSpecs
    │   │   └── models/
    │   │       └── dashboard_account.dart  # Account monitoring specs & status
    │   └── presentation/
    │       ├── controllers/
    │       │   └── dashboard_controller.dart
    │       ├── screens/
    │       │   └── dashboard_screen.dart   # Overview status seluruh akun Zoom
    │       └── widgets/
    │           ├── account_card.dart       # Card akun + status badge realtime
    │           ├── stats_overview_bar.dart # Ringkasan Total, Available, Busy
    │           └── status_badge.dart       # 🟢 Available, 🔴 In Meeting, 🟡 Scheduled
    ├── booking/
    │   ├── data/
    │   │   ├── booking_repository.dart     # Search, Book, Update, Delete, End
    │   │   └── models/
    │   │       ├── availability_result.dart# Ketersediaan akun + conflict summary
    │   │       ├── booking_request.dart    # DTO BookMeetingRequest
    │   │       └── schedule_item.dart      # Live, Upcoming, Past meetings
    │   └── presentation/
    │       ├── controllers/
    │       │   ├── booking_controller.dart
    │       │   └── schedules_controller.dart
    │       ├── screens/
    │       │   ├── search_screen.dart      # Form cari waktu kosong + hasil ketersediaan
    │       │   └── schedules_screen.dart   # Tab view: Live, Upcoming, Riwayat
    │       └── widgets/
    │           ├── booking_dialog.dart     # Form input topik, durasi & recurring
    │           ├── booking_success_dialog.dart # Tampilan ID, passcode & Host Key
    │           ├── meeting_card.dart       # Card rapat + quick actions
    │           └── conflict_banner.dart    # Informasi tabrakan jadwal
    ├── recording/
    │   ├── data/
    │   │   ├── recording_repository.dart   # List cloud recordings
    │   │   └── models/
    │   │       └── recording_item.dart     # RecordingItem & RecordingFile
    │   └── presentation/
    │       ├── controllers/
    │       │   └── recording_controller.dart
    │       ├── screens/
    │       │   └── recordings_screen.dart  # Filter tanggal, search topic, play/share
    │       └── widgets/
    │           └── recording_card.dart
    └── account/
        ├── data/
        │   ├── account_repository.dart     # CRUD Zoom accounts + test connection
        │   └── models/
        │       └── zoom_account.dart       # ZoomAccountModel, CheckConnectionResponse
        └── presentation/
            ├── controllers/
            │   └── account_controller.dart
            ├── screens/
            │   ├── accounts_screen.dart    # List akun S2S & test connection button
            │   └── account_form_screen.dart# Form tambah/edit akun Zoom
            └── widgets/
                └── test_connection_dialog.dart
```

---

## 3. Katalog Lengkap API Endpoints & Kontrak Data

Semua response dari backend dibungkus dalam format seragam (*Response Envelope*):

```json
// Format Sukses:
{
  "success": true,
  "message": "Deskripsi sukses",
  "data": { ... } // atau array [ ... ]
}

// Format Gagal:
{
  "success": false,
  "message": "Pesan error untuk user",
  "error_code": "KODE_ERROR_SERVER",
  "errors": null // atau detail validasi field
}
```

### Tabel Rute Lengkap API Backend:

| Modul | Method | Endpoint Path | Auth? | Deskripsi Singkat |
|---|---|---|---|---|
| **Health** | `GET` | `/health` | No | Cek koneksi server, DB Postgres, dan Redis |
| **Auth** | `POST` | `/api/v1/auth/login` | No | Login Master Password + daftarkan device |
| **Auth** | `POST` | `/api/v1/auth/pin/setup` | **Yes** | Pasang / ganti PIN 6-digit (butuh pass lama) |
| **Auth** | `POST` | `/api/v1/auth/pin/login` | No | Login cepat dengan PIN 6-digit |
| **Auth** | `POST` | `/api/v1/auth/biometric/enable` | **Yes** | Aktifkan sensor biometrik untuk perangkat ini |
| **Auth** | `POST` | `/api/v1/auth/biometric/disable` | **Yes** | Matikan biometrik pada perangkat ini |
| **Auth** | `POST` | `/api/v1/auth/biometric/login` | No | Login cepat menggunakan hardware biometric |
| **Auth** | `POST` | `/api/v1/auth/refresh` | No | Silent Refresh Token Rotation (RTR) |
| **Auth** | `POST` | `/api/v1/auth/logout` | **Yes** | Logout & blacklist token di Redis |
| **Auth** | `GET` | `/api/v1/auth/me` | **Yes** | Ambil profil user login & daftar device aktif |
| **Dashboard** | `GET` | `/api/v1/dashboard` | **Yes** | Ringkasan monitoring realtime seluruh akun Zoom |
| **Dashboard** | `GET` | `/api/v1/dashboard/{id}/status` | **Yes** | Status spesifik satu akun (available/meeting/dll) |
| **Dashboard** | `GET` | `/api/v1/dashboard/{id}/specs` | **Yes** | Kapasitas peserta & tipe lisensi (Basic/Licensed) |
| **Booking** | `GET` | `/api/v1/bookings/search` | **Yes** | Cari ketersediaan ruang rapat (`date`, `start_time`, `duration`) |
| **Booking** | `POST` | `/api/v1/bookings` | **Yes** | Buat meeting baru (sekali / recurring) via Zoom API |
| **Booking** | `GET` | `/api/v1/bookings` | **Yes** | Ambil daftar jadwal (Live, Upcoming, Past) |
| **Booking** | `GET` | `/api/v1/bookings/{accountId}/{meetingId}/details` | **Yes** | Ambil detail meeting langsung dari Zoom API |
| **Booking** | `PUT` | `/api/v1/bookings/{meetingId}` | **Yes** | Perbarui jadwal / topik meeting |
| **Booking** | `DELETE`| `/api/v1/bookings/{meetingId}` | **Yes** | Hapus/Batalkan meeting (`delete_option=occurrence/all`) |
| **Booking** | `POST` | `/api/v1/bookings/{meetingId}/end` | **Yes** | Paksa akhiri rapat live yang sedang berlangsung |
| **Recordings**| `GET` | `/api/v1/recordings` | **Yes** | Daftar rekaman cloud Zoom terpusat |
| **Accounts** | `GET` | `/api/v1/accounts` | **Yes** | Daftar akun S2S Zoom korporat |
| **Accounts** | `POST` | `/api/v1/accounts` | **Yes** | Tambah akun Zoom baru (Client ID/Secret) |
| **Accounts** | `GET` | `/api/v1/accounts/{id}` | **Yes** | Detail satu akun Zoom |
| **Accounts** | `PUT` | `/api/v1/accounts/{id}` | **Yes** | Perbarui kredensial akun Zoom |
| **Accounts** | `DELETE`| `/api/v1/accounts/{id}` | **Yes** | Hapus akun Zoom |
| **Accounts** | `GET` | `/api/v1/accounts/{id}/check`| **Yes** | Uji koneksi S2S OAuth ke server Zoom |

---

## 4. Sistem Keamanan & Alur Autentikasi Defense-in-Depth

### Diagram Alur Startup & Routing Guard:

```
                      [ Aplikasi Dibuka ]
                              │
                    Cek Secure Storage
              (access_token & refresh_token)
              ├── Tidak Ada Token ──────────────► [ Screen: Login Password ]
              └── Ada Token
                    │
           Cek status preferensi Biometrik
           ├── Aktif & Sensor Tersedia ────────► [ Prompt Sensor Biometrik ]
           │                                             │
           │                                     ├── Sukses ──► POST /auth/biometric/login ──► [ Dashboard ]
           │                                     └── Gagal / Batal ─────────────────────────► [ Screen: PIN Login ]
           └── Tidak Aktif
                 ├── Apakah User Memiliki PIN?
                 │     ├── YA ─────────────────────────────────────────────────────────────► [ Screen: PIN Login ]
                 │     └── TIDAK ──► Coba Silent Refresh Token ──► Sukses?
                 │                     ├── YA ─────────────────────────────────────────────► [ Dashboard ]
                 │                     └── TIDAK ──────────────────────────────────────────► [ Screen: Login Password ]
```

### Aturan Proteksi PIN 6-Digit:
1. PIN harus tepat 6 karakter angka numerik (`0-9`).
2. Setiap percobaan salah dicatat oleh server.
3. Jika salah 5 kali berturut-turut:
   - Server mengembalikan status **HTTP 423 Locked** (`error_code: "PIN_LOCKED"`).
   - Tampilkan pesan penguncian dan countdown timer 15 menit.
   - Sediakan tombol pintas: *"Login dengan Password Utama"* untuk membuka kembali tanpa menunggu jika user ingat passwordnya.

---

## 5. Spesifikasi Layar & UI/UX Design System

### 5.1 Tema Warna (Emerald Corporate PTPN IV)
```dart
class AppColors {
  // Brand Emerald
  static const Color primary = Color(0xFF059669);       // Emerald 600
  static const Color primaryDark = Color(0xFF047857);   // Emerald 700
  static const Color primaryLight = Color(0xFFD1FAE5);  // Emerald 100
  static const Color primaryAccent = Color(0xFF10B981); // Emerald 500

  // Realtime Status Badges
  static const Color statusAvailable = Color(0xFF10B981); // Hijau Emerald
  static const Color statusMeeting = Color(0xFFEF4444);   // Merah Coral
  static const Color statusScheduled = Color(0xFFF59E0B); // Kuning Amber
  static const Color statusError = Color(0xFF6B7280);     // Abu-abu Netral

  // Background & Surface
  static const Color scaffoldLight = Color(0xFFF8FAFC);
  static const Color surfaceCard = Colors.white;
  static const Color textMain = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color borderLight = Color(0xFFE2E8F0);
}
```

### 5.2 Katalog Layar Utama:
1. **Login Password (`/login`)**:
   - Field Username & Password dengan eye toggle.
   - Auto-detect `device_name` dan `device_id` via `device_info_plus`.
   - Loading indicator pada tombol "Masuk".
   - Jika `has_pin == false` setelah login sukses → auto-redirect ke `/pin-setup`.
2. **PIN Setup (`/pin-setup`)**:
   - Input PIN 6-digit pertama + konfirmasi ulang PIN.
   - Field konfirmasi Password Utama untuk verifikasi otorisasi.
   - Dialog opsional setelah sukses: *"Aktifkan Biometrik untuk login lebih cepat?"*.
3. **PIN Login (`/pin-login`)**:
   - Keypad angka sentuh (1–9, 0, Backspace, Biometric icon).
   - Indikator 6 bulatan dinamis (animasi fill).
   - Handle lockout 5x (HTTP 423) dengan dialog peringatan dan opsi fallback ke password.
4. **Dashboard Screen (`/dashboard`)**:
   - Salam personalisasi ("Selamat Pagi/Siang, [Nama User]") + Waktu WIB.
   - Status Ringkasan: Total Akun, Akun Available, Akun In Meeting.
   - Grid/List kartu akun dengan indikator badge warna dinamis (Available, Meeting, Scheduled, Error).
   - Pull-to-refresh & Shimmer loading skeleton.
5. **Search & Book Screen (`/search`)**:
   - Date picker (default: hari ini WIB), Time picker (default: jam sekarang + 10 menit), Dropdown durasi (30, 60, 90, 120, 180, 240 mnt).
   - Hasil ketersediaan instan: Akun AVAILABLE di atas, Akun BUSY menampilkan rapat yang bertabrakan.
   - Tombol "📅 Book Rapat" membuka modal dialog booking:
     - Topik rapat (wajib).
     - Switch Rapat Berulang (*Recurring*): Harian, Mingguan, Bulanan.
     - Switch "Abaikan Benturan" (*Ignore Conflict* - opsional).
   - **Dialog Sukses**: Menampilkan Meeting ID, Passcode, **Host Key** (6-digit), Tombol *"📋 Salin Undangan"* dan *"🔗 Buka Zoom"*.
6. **Schedules Screen (`/schedules`)**:
   - 3 Tab navigasi: **Live (Sedang Rapat)**, **Upcoming (Mendatang)**, **Riwayat (Selesai)**.
   - Quick action: Join meeting via Zoom app/browser, Copy invitation text, End Meeting (untuk rapat live), Edit & Delete Meeting.
   - Saat hapus rapat recurring: pilihan dialog *"Hapus pertemuan ini saja"* atau *"Hapus seluruh seri rapat"*.
7. **Cloud Recordings Screen (`/recordings`)**:
   - Filter rentang tanggal (30 hari terakhir) & textfield search.
   - List rekaman dengan info ukuran MB, durasi, host, dan tanggal.
   - Tombol "▶ Putar Rekaman" (`play_url`) dan "🔗 Bagikan Link".
8. **Zoom Accounts Screen (`/accounts`)**:
   - Manajemen akun Zoom korporat (Admin).
   - Form Tambah / Edit: Nama Akun, Email, Zoom Account ID, Host Key, Client ID, Client Secret.
   - Tombol "Uji Koneksi" untuk validasi OAuth langsung ke Zoom server.

---

## 6. Core Infrastructure (Dio, Interceptor, Storage & WIB Time)

### 6.1 `AppConfig`:
```dart
class AppConfig {
  // Untuk Android Emulator gunakan 10.0.2.2:8080
  // Untuk Real Device gunakan IP Wi-Fi Komputer Anda, contoh: 192.168.1.10:8080
  // Untuk Web/Desktop gunakan localhost:8080
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080/api/v1',
  );

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 45); // Zoom API butuh waktu paralel
}
```

### 6.2 `AuthInterceptor` (Silent Refresh Token Rotation):
```dart
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';

class AuthInterceptor extends QueuedInterceptor {
  final FlutterSecureStorage secureStorage;
  final Dio dio;

  AuthInterceptor({required this.secureStorage, required this.dio});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await secureStorage.read(key: 'access_token');
    final deviceId = await secureStorage.read(key: 'device_id');

    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    if (deviceId != null && deviceId.isNotEmpty) {
      options.headers['X-Device-ID'] = deviceId;
    }
    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Jika menerima 401 Unauthorized dan bukan dari endpoint auth itu sendiri
    if (err.response?.statusCode == 401 && !err.requestOptions.path.contains('/auth/')) {
      final refreshToken = await secureStorage.read(key: 'refresh_token');
      final deviceId = await secureStorage.read(key: 'device_id');

      if (refreshToken != null && deviceId != null) {
        try {
          final refreshDio = Dio(BaseOptions(
            baseUrl: AppConfig.baseUrl,
            connectTimeout: AppConfig.connectTimeout,
            receiveTimeout: AppConfig.receiveTimeout,
          ));

          final response = await refreshDio.post('/auth/refresh', data: {
            'refresh_token': refreshToken,
            'device_id': deviceId,
          });

          if (response.statusCode == 200 && response.data['success'] == true) {
            final data = response.data['data'];
            final newAccessToken = data['access_token'] as String;
            final newRefreshToken = data['refresh_token'] as String;

            // Simpan token baru hasil rotasi
            await secureStorage.write(key: 'access_token', value: newAccessToken);
            await secureStorage.write(key: 'refresh_token', value: newRefreshToken);

            // Perbarui header request asli dan retry
            err.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
            final retryResponse = await dio.fetch(err.requestOptions);
            return handler.resolve(retryResponse);
          }
        } catch (_) {
          // Token rotasi gagal / dicabut -> Hapus token lokal untuk paksa login
          await secureStorage.delete(key: 'access_token');
          await secureStorage.delete(key: 'refresh_token');
        }
      }
    }
    return handler.next(err);
  }
}
```

### 6.3 WIB Time Utility (`Asia/Jakarta`):
```dart
import 'package:intl/intl.dart';

class DateTimeUtil {
  static final DateFormat dateWibFormat = DateFormat('dd MMM yyyy', 'id_ID');
  static final DateFormat timeWibFormat = DateFormat('HH:mm', 'id_ID');
  static final DateFormat fullWibFormat = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');

  /// Parse ISO 8601 string dan konversi ke WIB (UTC+7)
  static DateTime parseToWib(String isoString) {
    final utc = DateTime.parse(isoString).toUtc();
    return utc.add(const Duration(hours: 7));
  }

  static String formatWib(String isoString) {
    try {
      final wib = parseToWib(isoString);
      return '${fullWibFormat.format(wib)} WIB';
    } catch (_) {
      return isoString;
    }
  }

  static String formatTimeOnlyWib(String isoString) {
    try {
      final wib = parseToWib(isoString);
      return '${timeWibFormat.format(wib)} WIB';
    } catch (_) {
      return isoString;
    }
  }
}
```

---

## 7. Data Models & DTOs Lengkap (Sesuai Backend Go)

Perhatikan mapping field JSON di bawah ini agar 100% cocok dengan Go struct backend:

### 7.1 Model Autentikasi:
```dart
class UserProfile {
  final int id;
  final String name;
  final String username;
  final String? email;
  final bool hasPin;
  final bool biometricEnabled;

  UserProfile({
    required this.id,
    required this.name,
    required this.username,
    this.email,
    required this.hasPin,
    required this.biometricEnabled,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as int,
      name: json['name'] as String,
      username: json['username'] as String,
      email: json['email'] as String?,
      hasPin: json['has_pin'] as bool? ?? false,
      biometricEnabled: json['biometric_enabled'] as bool? ?? false,
    );
  }
}

class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresIn;
  final UserProfile user;
  final bool hasPin;
  final bool biometricEnabled;

  AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
    required this.user,
    required this.hasPin,
    required this.biometricEnabled,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      tokenType: json['token_type'] as String? ?? 'Bearer',
      expiresIn: json['expires_in'] as int? ?? 900,
      user: UserProfile.fromJson(json['user'] as Map<String, dynamic>),
      hasPin: json['has_pin'] as bool? ?? false,
      biometricEnabled: json['biometric_enabled'] as bool? ?? false,
    );
  }
}
```

### 7.2 Model Dashboard Monitoring:
```dart
class DashboardAccount {
  final int id;
  final String accountName;
  final String? email;
  final String? hostKey;
  final String status; // 'available', 'meeting', 'scheduled', 'error'
  final String? currentTopic;
  final int meetingCapacity;
  final String planType;
  final DateTime lastUpdated;

  DashboardAccount({
    required this.id,
    required this.accountName,
    this.email,
    this.hostKey,
    required this.status,
    this.currentTopic,
    required this.meetingCapacity,
    required this.planType,
    required this.lastUpdated,
  });

  factory DashboardAccount.fromJson(Map<String, dynamic> json) {
    return DashboardAccount(
      id: json['id'] as int,
      accountName: json['account_name'] as String,
      email: json['email'] as String?,
      hostKey: json['host_key'] as String?,
      status: json['status'] as String? ?? 'available',
      currentTopic: json['current_topic'] as String?,
      meetingCapacity: json['meeting_capacity'] as int? ?? 300,
      planType: json['plan_type'] as String? ?? 'Licensed',
      lastUpdated: DateTime.tryParse(json['last_updated'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
```

### 7.3 Model Ketersediaan & Booking:
```dart
class AccountRef {
  final int id;
  final String name;

  AccountRef({required this.id, required this.name});

  factory AccountRef.fromJson(Map<String, dynamic> json) {
    return AccountRef(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}

class MeetingSummary {
  final String topic;
  final String startTime;
  final String endTime;

  MeetingSummary({required this.topic, required this.startTime, required this.endTime});

  factory MeetingSummary.fromJson(Map<String, dynamic> json) {
    return MeetingSummary(
      topic: json['topic'] as String,
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
    );
  }
}

class AvailabilityResult {
  final String id;
  final AccountRef account;
  final String userName;
  final String email;
  final String bookingUserId; // 'me' atau user ID Zoom
  final String status; // 'AVAILABLE', 'BUSY', 'ERROR'
  final String details;
  final MeetingSummary? conflictingMeeting;
  final MeetingSummary? liveMeeting;
  final MeetingSummary? scheduledNow;

  AvailabilityResult({
    required this.id,
    required this.account,
    required this.userName,
    required this.email,
    required this.bookingUserId,
    required this.status,
    required this.details,
    this.conflictingMeeting,
    this.liveMeeting,
    this.scheduledNow,
  });

  factory AvailabilityResult.fromJson(Map<String, dynamic> json) {
    return AvailabilityResult(
      id: json['id'].toString(),
      account: AccountRef.fromJson(json['account'] as Map<String, dynamic>),
      userName: json['user_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      bookingUserId: json['booking_user_id'] as String? ?? 'me',
      status: json['status'] as String? ?? 'AVAILABLE',
      details: json['details'] as String? ?? '',
      conflictingMeeting: json['conflicting_meeting'] != null
          ? MeetingSummary.fromJson(json['conflicting_meeting'] as Map<String, dynamic>)
          : null,
      liveMeeting: json['live_meeting'] != null
          ? MeetingSummary.fromJson(json['live_meeting'] as Map<String, dynamic>)
          : null,
      scheduledNow: json['scheduled_now'] != null
          ? MeetingSummary.fromJson(json['scheduled_now'] as Map<String, dynamic>)
          : null,
    );
  }
}
```

### 7.4 Model Schedules (Live, Upcoming, Past):
```dart
class ScheduleItem {
  final int id;
  final int meetingId;
  final int accountId;
  final String accountName;
  final String? hostKey;
  final String host;
  final String topic;
  final String password;
  final String startTime;
  final String endTime;
  final int duration;
  final String joinUrl;
  final int type;
  final String? occurrenceId;

  ScheduleItem({
    required this.id,
    required this.meetingId,
    required this.accountId,
    required this.accountName,
    this.hostKey,
    required this.host,
    required this.topic,
    required this.password,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.joinUrl,
    required this.type,
    this.occurrenceId,
  });

  factory ScheduleItem.fromJson(Map<String, dynamic> json) {
    return ScheduleItem(
      id: json['id'] as int,
      meetingId: json['meeting_id'] as int,
      accountId: json['account_id'] as int,
      accountName: json['account_name'] as String,
      hostKey: json['host_key'] as String?,
      host: json['host'] as String? ?? '',
      topic: json['topic'] as String,
      password: json['password'] as String? ?? '',
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      duration: json['duration'] as int? ?? 60,
      joinUrl: json['join_url'] as String,
      type: json['type'] as int? ?? 2,
      occurrenceId: json['occurrence_id'] as String?,
    );
  }
}

class SchedulesData {
  final List<ScheduleItem> liveMeetings;
  final List<ScheduleItem> upcomingMeetings;
  final List<ScheduleItem> pastMeetings;

  SchedulesData({
    required this.liveMeetings,
    required this.upcomingMeetings,
    required this.pastMeetings,
  });

  factory SchedulesData.fromJson(Map<String, dynamic> json) {
    return SchedulesData(
      liveMeetings: (json['live_meetings'] as List? ?? [])
          .map((e) => ScheduleItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      upcomingMeetings: (json['upcoming_meetings'] as List? ?? [])
          .map((e) => ScheduleItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      pastMeetings: (json['past_meetings'] as List? ?? [])
          .map((e) => ScheduleItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
```

### 7.5 Model Cloud Recordings:
```dart
class RecordingFile {
  final String fileType;
  final String fileExtension;
  final int fileSize;
  final String downloadUrl;
  final String playUrl;
  final String recordingType;
  final String status;

  RecordingFile({
    required this.fileType,
    required this.fileExtension,
    required this.fileSize,
    required this.downloadUrl,
    required this.playUrl,
    required this.recordingType,
    required this.status,
  });

  factory RecordingFile.fromJson(Map<String, dynamic> json) {
    return RecordingFile(
      fileType: json['file_type'] as String? ?? '',
      fileExtension: json['file_extension'] as String? ?? '',
      fileSize: json['file_size'] as int? ?? 0,
      downloadUrl: json['download_url'] as String? ?? '',
      playUrl: json['play_url'] as String? ?? '',
      recordingType: json['recording_type'] as String? ?? '',
      status: json['status'] as String? ?? '',
    );
  }
}

class RecordingItem {
  final int meetingId;
  final String uuid;
  final String topic;
  final String startTime;
  final int duration;
  final int totalSize;
  final String shareUrl;
  final int recordingCount;
  final List<RecordingFile> recordingFiles;
  final String accountName;
  final int accountId;
  final String hostName;
  final String hostEmail;

  RecordingItem({
    required this.meetingId,
    required this.uuid,
    required this.topic,
    required this.startTime,
    required this.duration,
    required this.totalSize,
    required this.shareUrl,
    required this.recordingCount,
    required this.recordingFiles,
    required this.accountName,
    required this.accountId,
    required this.hostName,
    required this.hostEmail,
  });

  factory RecordingItem.fromJson(Map<String, dynamic> json) {
    return RecordingItem(
      meetingId: json['meeting_id'] as int,
      uuid: json['uuid'] as String,
      topic: json['topic'] as String,
      startTime: json['start_time'] as String,
      duration: json['duration'] as int? ?? 0,
      totalSize: json['total_size'] as int? ?? 0,
      shareUrl: json['share_url'] as String? ?? '',
      recordingCount: json['recording_count'] as int? ?? 0,
      recordingFiles: (json['recording_files'] as List? ?? [])
          .map((e) => RecordingFile.fromJson(e as Map<String, dynamic>))
          .toList(),
      accountName: json['account_name'] as String? ?? '',
      accountId: json['account_id'] as int? ?? 0,
      hostName: json['host_name'] as String? ?? '',
      hostEmail: json['host_email'] as String? ?? '',
    );
  }
}
```

---

## 8. State Management & Provider Architecture (Riverpod)

Gunakan pembagian StateNotifier / AsyncNotifier terpisah agar clean dan modular:

```dart
// 1. Storage & Dio Providers
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) => const FlutterSecureStorage());
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) => throw UnimplementedError());
final dioClientProvider = Provider<Dio>((ref) {
  final storage = ref.watch(secureStorageProvider);
  final dio = Dio(BaseOptions(
    baseUrl: AppConfig.baseUrl,
    connectTimeout: AppConfig.connectTimeout,
    receiveTimeout: AppConfig.receiveTimeout,
    headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
  ));
  dio.interceptors.add(AuthInterceptor(secureStorage: storage, dio: dio));
  return dio;
});

// 2. Auth State & Controller
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(dioClientProvider), ref.watch(secureStorageProvider));
});

final authStateProvider = StateNotifierProvider<AuthController, AsyncValue<UserProfile?>>((ref) {
  return AuthController(ref.watch(authRepositoryProvider), ref.watch(secureStorageProvider));
});

// 3. Dashboard Realtime Controller
final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(ref.watch(dioClientProvider));
});

final dashboardAccountsProvider = StateNotifierProvider<DashboardController, AsyncValue<List<DashboardAccount>>>((ref) {
  return DashboardController(ref.watch(dashboardRepositoryProvider));
});

// 4. Booking & Schedules Provider
final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return BookingRepository(ref.watch(dioClientProvider));
});

final schedulesProvider = FutureProvider.autoDispose.family<SchedulesData, SchedulesFilter>((ref, filter) async {
  return ref.watch(bookingRepositoryProvider).listSchedules(filter);
});
```

---

## 9. Format Salin Undangan Rapat (PTPN IV Standard)

Ketika pengguna menekan tombol *"📋 Salin Undangan Rapat"*, buat teks clipboard dengan format seragam korporat:

```dart
class InviteFormatter {
  static String formatInvite({
    required String topic,
    required String startTimeWib,
    required String endTimeWib,
    required String accountName,
    required String meetingId,
    required String passcode,
    String? hostKey,
    required String joinUrl,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('📋 UNDANGAN RAPAT VIRTUAL — PTPN IV REGIONAL 1');
    buffer.writeln('--------------------------------------------------');
    buffer.writeln('📌 Topik: $topic');
    buffer.writeln('🕒 Waktu: $startTimeWib - $endTimeWib WIB');
    buffer.writeln('🏢 Ruang/Akun: $accountName');
    buffer.writeln('');
    buffer.writeln('🔗 Link Zoom Meeting:');
    buffer.writeln(joinUrl);
    buffer.writeln('');
    buffer.writeln('🆔 Meeting ID: $meetingId');
    buffer.writeln('🔑 Passcode: $passcode');
    if (hostKey != null && hostKey.isNotEmpty) {
      buffer.writeln('🛡️ Host Key: $hostKey (Gunakan untuk klaim host)');
    }
    buffer.writeln('--------------------------------------------------');
    buffer.writeln('Mohon hadir 5 menit sebelum rapat dimulai. Terima kasih.');
    return buffer.toString();
  }
}
```

---

## 10. Roadmap Pengerjaan 7 Fase Modular (Panduan Eksekusi AI)

Instruksi kepada AI Agent yang mengeksekusi proyek Flutter:
**Jangan melompati fase! Selesaikan fase demi fase secara berurutan dan verifikasi bahwa setiap fase bebas error (`flutter analyze`).**

### 📍 Fase 1: Setup Proyek & Core Infrastructure
1. Inisialisasi proyek Flutter (nama: `zoom_monitor_mobile`).
2. Masukkan seluruh dependensi di bagian `pubspec.yaml` lalu jalankan `flutter pub get`.
3. Buat direktori dan file pada `lib/core/` (`app_config.dart`, `app_routes.dart`, `app_colors.dart`, `app_theme.dart`).
4. Implementasikan `DateTimeUtil` (WIB converter) dan `DeviceHelper` (UUID extractor dari `device_info_plus`).
5. Buat `ApiClient` Dio beserta `AuthInterceptor` untuk Authorization header dan Silent Refresh Token Rotation.
6. Buat `SecureStorageService` dan `PreferencesService`.

### 📍 Fase 2: Enterprise Authentication & Security Layer
1. Buat DTOs autentikasi (`AuthResponse`, `UserProfile`, `LoginRequest`).
2. Implementasikan `AuthRepository` (menghubungkan ke `/auth/login`, `/auth/pin/setup`, `/auth/pin/login`, `/auth/biometric/login`, `/auth/logout`, `/auth/me`).
3. Buat `AuthController` menggunakan Riverpod.
4. Buat UI Layar Login Master Password (`login_screen.dart`).
5. Buat UI Layar Setup PIN 6-Digit (`pin_setup_screen.dart`) dengan konfirmasi password utama.
6. Buat UI Layar Login PIN (`pin_login_screen.dart`) dengan widget custom keypad numerik, bulatan indikator, serta integrasi tombol biometrik (`local_auth`).
7. Implementasikan penanganan status **HTTP 423 Locked** (jika PIN salah 5x) dengan dialog lockout dan opsi fallback ke password.
8. Konfigurasi `GoRouter` guard untuk redirect otomatis (auth redirect logic).

### 📍 Fase 3: Realtime Monitoring Dashboard
1. Buat model `DashboardAccount` sesuai response `GET /dashboard`.
2. Implementasikan `DashboardRepository` dan `DashboardController`.
3. Buat Layar Utama Dashboard (`dashboard_screen.dart`):
   - Header salam & tanggal WIB.
   - Quick stats bar (Total, Available, In Meeting).
   - Card list akun Zoom dengan badge status realtime warna cerah (Available, Meeting, Scheduled, Error).
   - Shimmer skeleton loading saat request berlangsung.
   - Pull-to-refresh untuk reload data.

### 📍 Fase 4: Smart Search Availability & Instant Booking
1. Buat model `AvailabilityResult`, `MeetingSummary`, dan DTO `BookMeetingRequest`.
2. Implementasikan `BookingRepository` untuk `GET /bookings/search` dan `POST /bookings`.
3. Buat UI Layar Pencarian (`search_screen.dart`):
   - Input tanggal (Date Picker), jam mulai (Time Picker WIB), durasi rapat.
   - Hasil ketersediaan terpisah (Akun AVAILABLE vs Akun BUSY dengan detail tabrakan).
4. Buat Modal Bottom Sheet Booking Rapat:
   - Input topik rapat.
   - Opsi switch meeting berulang (*recurring*).
   - Opsi switch *ignore conflict*.
5. Buat Dialog Sukses Rapat:
   - Menampilkan Meeting ID, Passcode, dan **Host Key**.
   - Tombol salin undangan rapi (*Copy formatted invite*) dan *Join Meeting* via `url_launcher`.

### 📍 Fase 5: Schedules Management & Meeting Lifecycle
1. Buat model `ScheduleItem` dan `SchedulesData` sesuai format 3 list (live, upcoming, past).
2. Buat UI Layar Jadwal (`schedules_screen.dart`) dengan 3 Tab:
   - Tab 1: **Live Meetings** (Rapat aktif) → Tombol *Join*, *Copy Invite*, dan *End Meeting* (paksa selesai).
   - Tab 2: **Upcoming Meetings** → Tombol *Join*, *Edit Jadwal*, dan *Delete Meeting*.
   - Tab 3: **Riwayat Rapat**.
3. Implementasikan dialog konfirmasi saat menghapus rapat berulang:
   - *"Hapus Pertemuan Ini Saja"* (`occurrence`).
   - *"Hapus Seluruh Seri Rapat"* (`all`).
4. Implementasikan aksi *Force End Meeting* (`POST /bookings/{id}/end`).

### 📍 Fase 6: Cloud Recordings & Zoom Accounts Management
1. Buat model `RecordingItem` dan `RecordingFile`.
2. Buat Layar Cloud Recordings (`recordings_screen.dart`):
   - Filter tanggal & pencarian berdasarkan topik.
   - List rekaman dengan total MB dan durasi.
   - Tombol putar rekaman (*Play URL* via browser) dan bagikan link.
3. Buat Layar Kelola Akun Zoom (`accounts_screen.dart` & `account_form_screen.dart`):
   - Daftar seluruh akun Zoom korporat.
   - Form Tambah / Edit akun Zoom (Client ID, Client Secret, Zoom Account ID, Host Key).
   - Tombol "Uji Koneksi" (`GET /accounts/{id}/check`) yang menampilkan dialog status aktif dan jumlah user Zoom.

### 📍 Fase 7: Testing, Polishing & Rilis
1. Lakukan pengujian end-to-end seluruh flow menggunakan akun dev:
   - Login `admin` / `password123`.
   - Setup / Login PIN `123456`.
   - Cek dashboard, cari ruangan kosong, lakukan booking, salin undangan berformat Host Key, uji hapus jadwal, dan putar rekaman.
2. Pastikan `flutter analyze` menghasilkan nol error dan nol warning.
3. Handle kasus jaringan offline / connection timeout dengan banner UX yang ramah.
4. Siapkan build APK rilis (`flutter build apk --release`).

---

> **SIAP DIEKSEKUSI:** Serahkan dokumen master ini ke AI Agent di workspace project Flutter Anda. AI Agent dapat langsung mengikuti langkah-langkah di atas dari Fase 1 hingga Fase 7 tanpa kebingungan kontrak API atau ketidakcocokan data.
