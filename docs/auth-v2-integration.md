# Integrasi autentikasi API v2

Client ini mengikuti kontrak autentikasi `API-ZoomMonitor/docs/security-upgrade.md`. Backend tetap menjadi satu-satunya penentu identitas, izin, dan keabsahan sesi. Tidak ada role lokal yang memberikan akses API. Username dan password diisi pengguna; jangan menanamkannya pada source, aset, atau parameter build.

## Perubahan alur

- Login password langsung membuka dashboard setelah respons login berhasil. PIN lama tidak dipakai; deep link PIN diarahkan ke halaman login.
- Token lama pada storage lama dibuang pada pembacaan pertama. Pengguna login password kembali setelah upgrade. Pasangan token baru ditulis sebagai satu bundle pada secure storage.
- ID instalasi acak menggantikan ID hardware/model perangkat. ID bukan secret atau bukti autentikasi. Reinstall yang menghasilkan ID baru tidak boleh memulihkan sesi dari keychain lama.
- Pendaftaran biometrik dilakukan melalui menu keamanan dengan konfirmasi password. Kunci Android Keystore atau iOS Secure Enclave P-256 dibuat di perangkat dan private key tidak diekspor. Signature adalah SHA-256/ECDSA ASN.1 DER, base64 standar. Public key adalah SPKI DER base64 standar.
- Android memakai `BIOMETRIC_STRONG` dan operasi Signature terikat CryptoObject. iOS memakai `.biometryCurrentSet` dan `.privateKeyUsage`. Perubahan pendaftaran biometrik sistem mengharuskan pendaftaran ulang kunci.
- Login biometrik meminta challenge, menandatangani string UTF-8 persis dari server, dan mengirim `challenge_id`/`signature`. Tidak ada fallback ke token biometrik statis, flag keberhasilan dari Flutter, atau PIN perangkat.
- Refresh dan login yang mengganti token diserialkan. Hanya `TOKEN_EXPIRED` boleh memicu satu refresh otomatis. Revocation, token invalid, kegagalan refresh, dan respons sesi lama tidak dapat menghidupkan kembali sesi lokal. Semua kegagalan ambigu memerlukan login kembali, bukan mengulang refresh token yang mungkin telah dikonsumsi.
- Logout selalu menghapus access/refresh token dan cache data. Jika biometrik terdaftar, mobile mengirim `keep_biometric=true`; kunci perangkat dipertahankan hanya jika respons API mengonfirmasi `data.biometric_retained=true`. Login berikutnya memakai challenge baru dan sidik jari. Bila server tidak mendukung flag atau tidak dapat dihubungi, kunci lokal dihapus dan login password diperlukan. Masa pendaftaran biometrik maksimal mengikuti backend, bukan preferensi lokal.

## Build dan penerapan

Secara bawaan, debug dan release memakai `https://zoom-api.sumutcerdas.web.id/api/v1`. Debug dapat memakai API HTTP lokal melalui `--dart-define=API_BASE_URL=http://localhost:8080/api/v1`. Release selalu memakai URL produksi; halaman login tidak menyediakan pengaturan server. Android release menolak cleartext dan tidak memakai debug signing.

Berikan kredensial signing melalui environment `ANDROID_KEYSTORE_PATH`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, dan `ANDROID_KEY_PASSWORD`. Simpan keystore di luar repository. Jangan memakai variabel build frontend untuk secret backend.

Backend yang mendukung `keep_biometric` harus dipasang sebelum login fingerprint setelah logout dapat bekerja pada host API. Aplikasi lama yang masih mengirim token biometrik statis tidak kompatibel; jangan mengaktifkan kembali protokol lama untuk mendukungnya. Pengguna yang sudah logout dengan versi API lama perlu login password dan mendaftarkan biometrik sekali lagi. Login password tetap menjadi jalur pemulihan.

## Verifikasi

`flutter analyze --no-pub` dan `flutter test --no-pub` memeriksa logika Dart, widget, storage migration, concurrency refresh, logout saat refresh, dan bentuk request biometrik dengan adapter offline. Tidak ada panggilan ke Zoom.

Build Android pada mesin ini terhambat Gradle karena `Unable to establish loopback connection`. Build iOS memerlukan macOS/Xcode. Kode native dan autentikasi hardware belum tervalidasi pada perangkat fisik Android/iOS; lakukan build, uji batal/gagal biometrik, perubahan sidik jari, expired/revoked session, beberapa perangkat, dan pendaftaran ulang sebelum rilis produksi.

Referensi platform: [Android biometric cryptographic operations](https://developer.android.com/identity/sign-in/biometric-auth), [Apple Secure Enclave](https://developer.apple.com/documentation/security/protecting-keys-with-the-secure-enclave).

## Gate UI perubahan ini

- Hard Gate PASS: tes widget mengklik validasi form kosong, tampil/sembunyi password, login biometrik gagal, buka dialog pendaftaran, batal, dan konfirmasi password. Tidak ada kontrol PIN yang tersisa pada alur tersebut. Adapter tes melarang request API tak terduga; pengujian memakai data tiruan.
- Purpose Gate PASS: kontrol baru memakai tema, warna, tipografi, dan pola dialog yang sudah ada; password diminta untuk konfirmasi pendaftaran perangkat, tanpa perubahan visual yang tidak terkait.
- Liveliness PASS: arah corporate yang sudah ada dipertahankan, ENERGY 1 / RHYTHM 2 / MOTION 1; tombol masuk tetap menjadi aksi utama dan tidak ada animasi dekoratif baru.
- Quality PASS untuk UI/Dart yang diuji: 34 tes Flutter dan analisis statis lulus. Tes layar sempit menemukan dan memperbaiki overflow judul status akun. Build Android native serta validasi iOS/perangkat fisik masih tertunda sebagaimana batas di atas.
