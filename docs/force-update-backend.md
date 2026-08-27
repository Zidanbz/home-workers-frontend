# Pembaruan wajib melalui Backend Version Policy

Panduan ini menjelaskan cara mengatur layar wajib update Android. Sumber
kebenaran berada di `appConfig/adminSettings` dan dikelola melalui Dashboard
Admin, bukan Firebase Remote Config.

## Konfigurasi

Buka **Dashboard Admin → Pengaturan Sistem → Kebijakan versi Android**.

| Field | Fungsi |
|---|---|
| Build minimum | Build paling rendah yang masih boleh masuk aplikasi. `0` menonaktifkan wajib update. |
| Build terbaru | Build terbaru yang sudah tersedia. Wajib sama atau lebih besar dari build minimum. |
| Pesan pembaruan | Pesan yang tampil pada layar wajib update. |
| URL Play Store | Harus mengarah ke package resmi `com.homeworkers.app`. |

Build adalah angka setelah `+` pada `pubspec.yaml`. Contoh
`version: 1.0.10+24` berarti build `24`.

Aturan aplikasi:

```text
build terpasang < build minimum → wajib update
build terpasang >= build minimum → aplikasi boleh dibuka
```

## Alur yang aman saat rilis

1. Naikkan version name dan build number di `pubspec.yaml`.
2. Build dan unggah AAB ke Play Console.
3. Tunggu sampai build baru benar-benar tersedia pada track target.
4. Atur **Build terbaru** di Dashboard Admin.
5. Jika versi lama harus dihentikan, naikkan **Build minimum**. Dashboard akan
   meminta konfirmasi karena perubahan ini langsung memblokir build lama.
6. Uji menggunakan satu build di bawah minimum dan satu build yang sama dengan
   minimum.

Jangan menaikkan build minimum sebelum build pengganti dapat diunduh. Kesalahan
urutan ini dapat mengunci semua pengguna tanpa jalur pembaruan.

## Transisi satu kali dari Remote Config

APK yang sudah terpasang sebelum migrasi tidak mengenal endpoint backend dan
masih membaca Firebase Remote Config. Backend baru tidak dapat mengubah kode
klien lama secara retroaktif.

1. Deploy endpoint version policy dan Dashboard Admin terlebih dahulu.
2. Rilis satu build migrasi yang sudah memakai Backend Version Policy.
3. Pastikan build migrasi tersedia di Play Store.
4. Jika build legacy harus dipaksa berpindah, gunakan parameter Remote Config
   lama satu kali untuk mengarahkan build legacy ke build migrasi.
5. Build migrasi dan build setelahnya mengabaikan Remote Config; seluruh policy
   berikutnya dikelola dari Dashboard Admin.

Jangan menghapus konfigurasi Remote Config lama sebelum masa transisi selesai.

## Endpoint dan cache aplikasi

Flutter memanggil endpoint publik berikut sebelum login:

```http
GET /api/app/version-policy?platform=android&build=24
```

Endpoint hanya mengembalikan policy versi yang aman untuk publik dan memiliki
cache HTTP. Flutter juga menyimpan respons terakhir secara lokal berdasarkan
`API_BASE_URL`, sehingga policy Development dan Production tidak tercampur.

- Request jaringan memiliki timeout 3 detik.
- Policy cache yang memblokir tetap memblokir ketika perangkat offline.
- Jika belum pernah menerima policy dan backend tidak dapat dihubungi, aplikasi
  tetap dibuka agar gangguan backend tidak membuat instalasi baru terkunci.
- Policy baru yang berhasil dimuat selalu menggantikan cache lama.

## Referensi kode

- Gate UI: `lib/core/widgets/app_version_gate.dart`
- Model policy: `lib/core/models/app_version_policy.dart`
- Endpoint dan cache: `lib/core/services/app_version_service.dart`
- Backend route: `functions/src/routes/appConfigRoutes.js`
- Backend policy: `functions/src/utils/appVersionPolicy.js`
