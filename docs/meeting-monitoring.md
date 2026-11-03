# Monitoring kondisi rapat

Mobile menerima label kondisi dari API pada dashboard, kartu rapat, dan hasil pencarian. Overtime tidak mengubah identitas meeting atau mengeksekusi tindakan meeting. Badge riwayat menjadi `JADWAL TERLEWATI`, bukan konfirmasi `SELESAI`.

Halaman dashboard/jadwal diperbarui setiap 30 detik selama terlihat dan aplikasi berada di foreground. Timer dibersihkan saat widget dilepas dan pembaruan dilanjutkan saat aplikasi kembali aktif. Permintaan otomatis tidak ditumpuk jika pembaruan sebelumnya belum selesai. Pencarian tetap melalui tindakan pengguna; informasi live di hasil pencarian adalah snapshot pemeriksaan tersebut.

Data yang berumur 90 detik ditandai belum terverifikasi. Umur dihitung dari selisih waktu server/observasi ditambah waktu sejak respons diterima, sehingga beda zona/jam awal perangkat tidak menentukan overtime. Kegagalan pembaruan dashboard/jadwal menampilkan keadaan gagal beserta tindakan coba lagi.

Jadwal tanpa waktu valid tidak diganti dengan waktu sekarang atau durasi default untuk monitoring. Label `not_live` tidak berarti rapat belum pernah berlangsung. Akhir sesi aktual hanya ditampilkan jika BE menerima bukti riwayat Zoom yang cocok; berakhirnya satu sesi tidak berarti reservasi dilepas.

## Bukti pengujian

`test/monitoring_test.dart` menguji pemetaan API, umur data, penggantian label lama, riwayat tanpa klaim selesai, dan jeda polling ketika aplikasi background. Uji widget pada layar 320 px dengan skala teks 2 memverifikasi label panjang membungkus tanpa exception/overflow. Uji responsif yang sudah ada tetap dijalankan.

Gate tampilan untuk perubahan ini:

- Hard gate PASS: label adalah teks yang membungkus; uji layar sempit/skala teks 2 lulus; tidak menambah tindakan meeting.
- Purpose gate PASS: amber menandai kondisi perhatian, dengan teks yang menjelaskan alasannya.
- Liveliness PASS: desain aplikasi dipertahankan, ENERGY 1 / RHYTHM 2 / MOTION 1; tidak menambah animasi atau struktur navigasi.
- Craftsmanship PASS: uji widget dan seluruh uji Flutter lulus; analyzer tanpa masalah; lifecycle polling dan label data lama diuji tanpa koneksi Zoom.

## Reservasi yang pernah live

Mobile menampilkan label riwayat dari BE dan peringatan jadwal tetap dicadangkan pada hasil pencarian. Modal booking meminta konfirmasi terpisah bahwa rapat sebelumnya tidak akan dilanjutkan sebelum mengizinkan force booking. Checkbox tidak dipilih otomatis. Jika BE baru mendeteksi kondisi tersebut saat submit, kode error 409 ditangani dengan menampilkan konfirmasi yang wajib dipenuhi.

Payload booking menyertakan `booking_user_id`, `date`, `time` dalam WIB, dan `confirm_reserved_schedule`. Konversi waktu menggunakan UTC eksplisit agar tidak bergantung pada zona waktu perangkat.

`test/reservation_test.dart` memeriksa field API, konfirmasi default false, pergantian tanggal WIB, serta notice/checkbox pada layar 320 px dengan teks skala 2. Gate tambahan: Hard PASS (tanpa overflow/konfirmasi otomatis), Purpose PASS (peringatan menjelaskan reservasi), Liveliness PASS (desain dipertahankan), Craftsmanship PASS (uji dan analyzer lulus).
