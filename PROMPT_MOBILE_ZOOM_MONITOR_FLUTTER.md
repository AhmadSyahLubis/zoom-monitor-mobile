# Prompt redesign Zoom Monitor untuk Google Stitch

Dokumen ini menggambarkan **aplikasi Flutter yang sudah ada** per 15 Oktober 2026. Gunakan sebagai brief desain visual dan interaksi. Jangan menafsirkan dokumen ini sebagai permintaan membangun aplikasi baru, mengganti arsitektur, atau menambah fitur backend.

## Prompt utama untuk Stitch

Rancang ulang antarmuka mobile **Zoom Monitor**, aplikasi internal satu pintu untuk mengelola beberapa akun Zoom Premium perusahaan. Pengguna utama adalah administrator yang perlu melihat akun yang siap dipakai, mencari slot rapat, membuat booking, mengelola jadwal, membuka rekaman, dan memeriksa koneksi akun Zoom.

Buat desain yang terasa **tenang, presisi, modern, dan korporat**. Ambil prinsip antarmuka Apple yang menempatkan material glass pada lapisan navigasi dan kontrol penting. Ini tetap aplikasi **Flutter lintas platform**, bukan tiruan piksel iOS atau klaim memakai API native Liquid Glass. Pertahankan konten kerja sebagai permukaan solid yang mudah dibaca. Hindari neon, gradien biru-ungu, glow, kartu transparan di seluruh layar, dan ilustrasi dekoratif yang tidak berkaitan dengan rapat atau pengelolaan akun.

Fokus pada desain layar yang benar-benar ada di proyek. Pertahankan lima destinasi utama pada navigasi bawah: **Beranda, Cari, Jadwal, Rekaman, Akun**. Desain untuk penggunaan satu tangan, layar portrait, data padat, jaringan lokal yang bisa gagal, dan teks bahasa Indonesia.

## Batas proyek yang harus dipertahankan

- Produk ini mengelola **akun Zoom**, bukan ruangan fisik. Bila memakai istilah "ruang" pada desain, jelaskan bahwa itu akun rapat virtual. Usulkan copy yang lebih tepat bila perlu.
- Backend saat ini **berjalan lokal**, belum di-deploy. Jangan tampilkan status online global atau menjanjikan sinkronisasi lintas internet.
- Redesign hanya mengubah pengalaman dan presentasi FE. Jangan membuat endpoint, alur persetujuan, dashboard analitik, notifikasi, chat, atau fitur kolaborasi baru.
- Jangan menampilkan `client_secret`, token, Host Key, atau kredensial nyata pada mockup daftar. Field sensitif pada form harus tersamarkan. ID dan passcode rapat boleh ditampilkan hanya dalam konteks detail rapat atau dialog hasil booking yang memang memerlukannya.
- Angka ketersediaan, daftar akun, jadwal, dan rekaman berasal dari API. Untuk mockup, pakai placeholder bertanda **"Data contoh"**. Jangan membuat angka operasional yang tampak sebagai data produksi.
- Aksi penting harus jelas: cari waktu rapat, booking akun tersedia, gabung rapat, salin undangan, edit atau batalkan jadwal, buka rekaman, uji koneksi akun.
- Sediakan keadaan awal, memuat, kosong, gagal tersambung, dan berhasil untuk alur yang relevan. Error harus memberi tindakan lanjutan seperti **Coba lagi**.

## Kondisi aplikasi saat ini

### Platform dan arsitektur FE

| Bagian | Implementasi yang ada |
|---|---|
| Framework | Flutter, Dart, Material 3; orientasi aplikasi dikunci portrait |
| Navigasi | `go_router` dengan rute tetap di `lib/core/config/app_routes.dart` |
| State | `flutter_riverpod`; provider dan controller per fitur |
| API | `dio`, repository per fitur, interceptor autentikasi, cache memori |
| Penyimpanan | `flutter_secure_storage` untuk data sensitif; `shared_preferences` untuk preferensi |
| Login perangkat | `local_auth` dan `device_info_plus` |
| Visual | Font lokal Inter; `phosphor_icons`; `shimmer` |
| Aksi perangkat | `url_launcher` untuk tautan rapat/rekaman; `share_plus` untuk berbagi |

Struktur kode memakai modul `lib/features/auth`, `dashboard`, `booking`, `recording`, dan `account`. Tiap modul mempunyai lapisan `data` serta `presentation`; UI memakai repository dan controller yang sudah ada. Komponen bersama ada di `lib/core/theme` dan `lib/core/widgets`. Jangan minta Stitch merombak struktur ini.

API memakai base path `/api/v1`. Nilai bawaan di `lib/core/config/app_config.dart` saat ini adalah `http://10.70.0.153:8080/api/v1`, dapat diganti lewat `API_BASE_URL` atau pengaturan server pada layar login. Alamat itu hanya konfigurasi jaringan lokal saat ini, **bukan URL produksi dan bukan bagian dari desain**. Jangan menaruhnya pada mockup utama.

### Rute dan peta layar

| Rute | Layar dan fungsi yang sudah ada |
|---|---|
| `/` | Splash, memeriksa sesi tersimpan |
| `/login` | Username, password, opsi konfigurasi URL API lokal |
| `/pin-login` | Login PIN enam digit, opsi biometrik, penanganan PIN terkunci |
| `/pin-setup` | Buat atau ganti PIN dengan konfirmasi password |
| `/dashboard` | Beranda, ringkasan akun, daftar status, pintasan cari waktu |
| `/search` | Pilih tanggal, jam WIB, durasi; lihat akun tersedia atau bentrok; buka form booking |
| `/schedules` | Tab `Live Rapat`, `Mendatang`, `Riwayat` dan tindakan per rapat |
| `/recordings` | Daftar rekaman cloud, pencarian dan filter tanggal |
| `/accounts` | Daftar akun Zoom, status aktif, uji koneksi, tambah, edit, hapus |
| `/accounts/form` | Form tambah atau edit akun Zoom S2S OAuth |

Lima rute dari `/dashboard` sampai `/accounts` muncul di bottom navigation. Splash, login, PIN, dan form akun bukan tab baru. Top bar Beranda menampilkan ikon **Keamanan & biometrik** dan **Keluar** secara langsung, masing-masing dengan tooltip dan aksi yang sudah ada.

### Data yang menentukan isi layar

Jangan menggambar UI yang membutuhkan data di luar bentuk berikut:

| Area | Data dari aplikasi yang ada |
|---|---|
| Beranda | `GET /dashboard`: `account_name`, `status`, `current_topic`, `meeting_capacity`, `plan_type`, `last_updated`. Jumlah total, tersedia, dan sedang rapat dihitung di FE dari daftar akun. |
| Cari | `GET /bookings/search?date=...&start_time=...&duration=...`: akun, pengguna, status `AVAILABLE`/`BUSY`/`ERROR`, detail benturan bila ada. |
| Booking | `POST /bookings`: topik, akun terpilih, waktu WIB, durasi, opsi berulang. Hasil booking menampilkan informasi rapat yang dapat disalin atau dibagikan. |
| Jadwal | `GET /bookings`: kelompok live, mendatang, dan riwayat; topik, akun, jam, durasi, tautan gabung, dan informasi rapat. Edit, batal, dan akhiri rapat sudah ada. |
| Rekaman | `GET /recordings`: topik, akun, waktu, durasi, ukuran, format file, dan tautan putar/unduh bila tersedia. Filter memakai `from`, `to`, `search`. |
| Akun | `GET /accounts`: `account_name`, `email`, `zoom_account_id`, `is_active`. CRUD dan `GET /accounts/{id}/check` sudah ada. Kredensial S2S hanya muncul pada form yang sesuai. |

Status dashboard yang sekarang dikenali: `available`, `meeting`/`in_meeting`/`busy`, `scheduled`, dan kondisi error. Warna status harus selalu disertai teks; jangan bergantung pada titik warna saja. Bila backend tidak dapat diakses, tampilkan error jaringan, bukan status akun seolah-olah semuanya tersedia.

## Alur yang perlu divisualkan

1. **Masuk**: username dan password, validasi, loading, error, lalu PIN setup jika akun belum mempunyai PIN. Pengaturan URL API lokal adalah aksi sekunder.
2. **Buka kembali aplikasi**: layar PIN enam digit dengan biometrik jika tersedia. Sediakan jalan kembali ke login password saat PIN terkunci atau biometrik gagal.
3. **Pantau akun**: pada Beranda, lihat ringkasan berdasarkan data API dan daftar akun. Setiap akun menunjukkan nama, status, topik aktif bila ada, kapasitas atau paket bila tersedia, serta waktu pembaruan. Tarik untuk menyegarkan.
4. **Cari dan booking**: pilih tanggal, jam mulai WIB, dan durasi; tekan **Cek ketersediaan**; pisahkan akun tersedia dari akun bentrok atau error. Hanya akun yang tersedia menawarkan aksi booking. Bottom sheet booking menampilkan akun dan slot terpilih, input topik, opsi rapat berulang, serta hasil sukses.
5. **Kelola jadwal**: tab live, mendatang, riwayat. Aksi yang mungkin mencakup gabung Zoom, salin undangan, edit, batalkan, dan akhiri rapat live. Aksi destruktif memerlukan konfirmasi yang menjelaskan dampaknya.
6. **Temukan rekaman**: cari topik, filter tanggal, baca metadata yang relevan, lalu buka tautan putar atau unduh bila tersedia.
7. **Kelola akun**: lihat daftar akun aktif/nonaktif dan Zoom Account ID, uji koneksi S2S, tambah, edit, atau hapus akun. Tindakan hapus memerlukan konfirmasi.

## Arah visual yang sudah disepakati

Ikuti `DESIGN.md` di repo sebagai sumber identitas. Rangkuman untuk Stitch:

- **Karakter**: alat operasional harian yang rapi dan ramah. Energi **2**, ritme **2**, gerak **1**. Satu fokus jelas pada setiap layar.
- **Warna**: dasar biru abu muda `#EEF2F7`, navy `#182640`, biru slate `#2B4C86`, dan biru lembut `#E8EEFA`. Ketersediaan memakai teal `#146F96`; merah dan amber hanya untuk status yang benar. Token implementasi ada di `lib/core/theme/app_colors.dart`.
- **Tipografi**: Inter untuk seluruh UI, dengan hierarki berat dan ukuran yang jelas untuk judul, angka, label, dan metadata. Font dibundel secara lokal.
- **Ikon**: lima ikon navigasi digambar khusus dengan stroke dan ujung konsisten, lengkap dengan label. Ikon aksi lain boleh memakai Phosphor dengan berat seragam. Hindari ikon sparkle dan kamera Zoom sebagai identitas produk.
- **Motif merek**: monogram **M** abstrak yang mewakili Monitor, berwarna putih kebiruan di atas navy, dengan aperture kecil di simpul tengah sebagai aksen lensa kamera. Sumber vektor ada di `tool/design_assets/zoom_monitor_mark.svg`; jangan kembali ke simbol dua jendela hijau.
- **Glass**: gunakan efek frosted hanya untuk bottom navigation yang mengambang dan, bila beralasan, satu kontrol navigasi lain. Kartu data, form, tab isi, dan dialog utama tetap solid. Blur harus mempertahankan kontras teks serta tidak menutup konten.
- **Permukaan**: latar biru abu muda, kartu putih untuk data, border tipis, bayangan hanya bila menandai lapisan yang mengambang. Hindari semua elemen berbentuk pil.
- **Foto**: Beranda dan Login memakai foto ruang rapat. Cari, Jadwal, Rekaman, dan Akun masing-masing memakai banner foto ringkas yang sesuai tugas halaman. Semua aset ada di `assets/images` dan prompt pembuatannya tercatat di `ASSET_SOURCES.md`. Data dan aksi tetap dominan.
- **Gerak**: transisi singkat yang menjelaskan pergantian keadaan. Tidak ada shimmer permanen, bounce berlebihan, atau animasi dekoratif tanpa fungsi.

Aset aktif: `assets/images/meeting_console_hero.png`, `assets/images/hybrid_desk_login.png`, `assets/images/search_availability.png`, `assets/images/schedule_room.png`, `assets/images/recordings_console.png`, `assets/images/accounts_workstation.png`, serta ikon di `assets/icons`. Jangan menyalin identitas atau logo Zoom. Ikon aplikasi dikonfigurasi untuk Android, iOS, dan web lewat `flutter_launcher_icons.yaml`.

### Rujukan desain yang dipakai sebagai prinsip

- [Apple HIG: Materials](https://developer.apple.com/design/human-interface-guidelines/materials): material glass ditempatkan di lapisan kontrol dan navigasi, tidak memenuhi lapisan konten.
- [Apple HIG: Tab bars](https://developer.apple.com/design/human-interface-guidelines/tab-bars): tab untuk destinasi utama, berlabel dan konsisten.
- [Apple HIG: Toolbars](https://developer.apple.com/design/human-interface-guidelines/toolbars): aksi dikelompokkan menurut fungsi dan frekuensi penggunaan.
- [Apple WWDC25: Build a UIKit app with the new design](https://developer.apple.com/videos/play/wwdc2025/284/): contoh Maps memakai glass pada tombol yang melayang di atas konten, bukan pada seluruh konten.
- [Apple HIG: App icons](https://developer.apple.com/design/human-interface-guidelines/app-icons/): ikon harus mudah dikenali pada ukuran kecil dan memiliki identitas sendiri.

Ambil struktur dan kadar pemakaian glass dari rujukan ini. Jangan menyalin tampilan Apple Maps, ikon Apple, atau kontrol iOS secara literal.

## Keluaran yang diminta dari Stitch

1. **Artboard mobile portrait** untuk Login, PIN login, Beranda, Cari sebelum pencarian, Cari dengan hasil, Jadwal, Rekaman, dan Akun. Tunjukkan juga bottom sheet Booking dan form Tambah/Edit Akun. Jika ruang keluaran terbatas, dahulukan lima tab utama dan satu alur booking lengkap.
2. **Varian keadaan** minimal: Beranda berisi dan gagal memuat, Cari tersedia dan bentrok, daftar kosong, form dengan error validasi, serta sukses booking. Tandai semua konten buatan sebagai **Data contoh**.
3. **Sistem komponen**: token warna dan tipografi, hirarki permukaan, status chip, kartu akun, kartu jadwal, field, tombol, tab, bottom navigation, dan dialog konfirmasi. Jelaskan komponen mana yang memakai glass dan alasannya.
4. **Catatan handoff ke Flutter**: ukuran sentuh minimal sekitar 44 px, safe area atas/bawah, ruang agar konten terakhir tidak tertutup bottom navigation, keyboard pada form dan search, teks panjang, serta perilaku pada lebar ponsel sekitar 360 sampai 430 px. Pastikan rancangan dapat dibuat dengan widget Flutter dan dependensi yang ada.
5. **Usulan aset** hanya bila relevan: fungsi aset, rasio atau ukuran, posisi pakai, dan sumber/lisensi yang perlu dipastikan. Jangan menyisipkan foto acak atau mockup laptop ke layar aplikasi.

Sajikan desain yang dapat dipakai sebagai referensi implementasi ulang FE yang sudah berjalan. Keputusan visual boleh baru, tetapi fungsi, navigasi, sumber data, dan batas backend lokal di atas tetap menjadi acuan.
