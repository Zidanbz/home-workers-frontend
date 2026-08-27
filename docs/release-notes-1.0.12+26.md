# Catatan Rilis 1.0.12+26

- **Nama rilis Play Console:** `1.0.12 — Worker, notifikasi & login`
- **Version name:** `1.0.12`
- **Version code:** `26`
- **Target:** Android Production
- **Tanggal build:** 23 Agustus 2026

## Catatan Google Play (Bahasa Indonesia)

```text
• [Fitur baru] Worker kini menerima kartu pesanan baru dengan hitung mundur dan notifikasi suara khusus.
• [Peningkatan] Saldo Worker tersedia segera setelah pekerjaan selesai tanpa menunggu masa garansi.
• [Peningkatan] Hingga tiga pesanan dapat diterima pada slot jadwal yang sama.
• [Fitur baru] Customer dapat meminta revisi harga layanan survei sebelum pembayaran final.
• [Antarmuka] Dashboard Worker dan halaman login kini lebih ringkas, jelas, dan nyaman di berbagai ukuran layar.
```

## Ringkasan internal untuk QA

### Pesanan dan jadwal Worker

- Floating card pesanan baru hanya muncul setelah aplikasi memverifikasi bahwa
  order benar-benar milik Worker, pembayaran `paid`, status `pending`, akses
  Worker aktif, dan batas penerimaan belum lewat.
- Kartu menampilkan nama layanan, jadwal, nilai, antrean, dan countdown tanpa
  mengekspos alamat lengkap Customer.
- Satu rentang jadwal dapat menerima maksimal tiga order aktif. Order keempat
  harus ditolak server-side.

### Notifikasi

- Pesanan baru memakai channel Android dan sound khusus
  `notif_orderan_masuk.mp3`; notifikasi lain memakai `sound_general.mp3`.
- Saat floating card aktif, sound order berulang maksimal 30 detik dan berhenti
  saat order dibuka, ditunda, kedaluwarsa, tidak valid, atau aplikasi masuk
  background. Beberapa order tidak boleh menghasilkan audio bertumpuk.

### Pembayaran, wallet, dan garansi

- Konfirmasi pekerjaan selesai langsung mencairkan pendapatan ke saldo Worker;
  masa garansi tujuh hari tidak lagi menahan payout.
- Klaim garansi tidak mengurangi saldo Worker dan tidak memblokir penarikan.
  Refund finansial tetap mengikuti proses sengketa terpisah.
- Pembayaran final survey bersifat idempoten agar percobaan ulang tidak membuat
  transaksi ganda.

### Survey dan revisi harga

- Customer dapat meminta revisi quote survey sebelum pembayaran final, dan
  Worker dapat membalas dengan harga baru.
- Revisi quote dipisahkan dari rework pekerjaan. Rework hanya boleh digunakan
  setelah pekerjaan benar-benar dimulai dan seluruh pembayaran telah lunas.

### Antarmuka

- Home Worker memiliki hierarki baru untuk identitas, order prioritas, area
  layanan, ringkasan pekerjaan, video, dan ulasan.
- Halaman login memakai header brand, kartu form, copy Bahasa Indonesia, layout
  scrollable, dan safe-area untuk navigation bar tiga tombol serta keyboard.
- Home Worker dan Customer siap menampilkan `Video Pilihan` yang dikelola Admin.
  Section otomatis tersembunyi jika backend belum menyediakan konten.

## Artefak Android

- **AAB:** `build/app/outputs/bundle/release/home-workers-1.0.12-build26.aab`
- **SHA-256:** `2b3fe37263d73d02783ba7c980c71e1d8bd416546342084b193abbd3e230d68a`
- **Package:** `com.homeworkers.app`
- **Environment:** `prod`
- **Firebase:** `home-workers-fa5cd`
- **Signing:** upload keystore release

## Status backend Production

- Backend HTTP `api` sudah dideploy ke Firebase Production
  `home-workers-fa5cd` pada 23 Agustus 2026 sebagai revisi
  `api-00190-zer` (Node.js 22, 100% traffic).
- Regression test backend lulus 181/181. Smoke test Production menghasilkan
  HTTP 200 untuk root API dan version policy build 26. Endpoint konten video,
  revisi harga survey, dan administrasi video merespons HTTP 401 tanpa token,
  yang mengonfirmasi route aktif serta tetap dilindungi autentikasi.
- Scheduled function `expireWarrantyActions` dan `expireWorkerAcceptance` tidak
  ikut dideploy. Mode pembayaran Production tetap aktif dan secret sensitif
  tetap berasal dari Firebase Secret Manager.
- Deploy ini tidak menambah atau mengubah dokumen di database Production.
  `Video Pilihan` baru muncul setelah kontennya ditambahkan melalui Admin.

## Checklist sebelum rilis Production

- Backend Production yang kompatibel dengan revisi harga survey, payload
  notifikasi order baru, dan konten video sudah dideploy serta lulus smoke test.
  Lanjutkan pengujian memakai akun Customer dan Worker Production melalui jalur
  Internal Testing sebelum staged rollout.
- Deploy Admin web Production jika tim perlu mengelola Video Pilihan, filter
  pesanan, breakdown pembayaran, dan GMV completed/paid melalui dashboard.
- Uji Internal Testing: login email/Google, navigation bar tiga tombol, booking
  order pertama sampai keempat pada slot yang sama, pembayaran fixed/survey,
  revisi harga survey, penyelesaian pekerjaan, saldo Worker, klaim garansi,
  floating order, dan sound foreground/background.
- Setelah build 26 sudah tersedia di Play Store, ubah **Build terbaru** menjadi
  `26`. Jangan menaikkan **Build minimum** sampai staged rollout stabil dan
  keputusan force update telah disetujui.
- Gunakan staged rollout dan pantau error login, pembayaran, notifikasi, payout,
  garansi, serta crash Android sebelum rollout 100%.
