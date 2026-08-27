# Catatan Rilis 1.0.11+25

- **Nama rilis Play Console:** `1.0.11 — Lokasi, transaksi & voucher`
- **Version name:** `1.0.11`
- **Version code:** `25`
- **Target:** Android Production
- **Tanggal build:** 17 Agustus 2026

## Catatan Google Play (Bahasa Indonesia)

```text
• [Fitur baru] Pilih lokasi pengerjaan lain langsung melalui peta agar titik layanan lebih akurat.
• [Peningkatan] Detail transaksi Worker kini menampilkan pembayaran, voucher, biaya layanan, dan pendapatan bersih dengan lebih jelas.
• [Perbaikan] Pesanan yang refund-nya selesai masuk ke Riwayat dan tidak lagi mengunci jadwal Worker.
• [Peningkatan] Klaim voucher kini mendukung batas klaim per akun dan kuota pengguna.
• [Antarmuka] Logo aplikasi dan splash screen diperbarui.
```

## Ringkasan internal untuk QA

### Booking dan lokasi

- Mode `Lokasi lain` menampilkan Google Map, marker yang dapat dipindahkan,
  pencarian alamat, dan reverse geocoding.
- Booking ditolak bila koordinat lokasi lain kosong, nol, tidak valid, atau di
  luar rentang latitude/longitude.

### Refund dan jadwal

- Refund aktif atau selesai membuat order keluar dari Antrean Worker dan masuk
  ke Riwayat.
- Order refund tidak dapat melanjutkan pekerjaan atau pembayaran final dan
  tidak lagi memblokir slot jadwal Worker.
- Refund ditolak tetap mengembalikan order ke alur operasional sebelumnya;
  `rework_in_progress` tetap dianggap pekerjaan aktif.

### Wallet dan voucher

- Detail ledger Worker menampilkan nilai layanan, pembayaran Customer, subsidi
  voucher aplikasi, biaya platform, pendapatan Worker, status, dan ID transaksi.
- Voucher `User Claimed` mendukung total stok, batas klaim per user, dan batas
  jumlah user unik. Klaim dilindungi transaksi backend agar kuota tidak dapat
  terlewati oleh request bersamaan.
- Aplikasi menampilkan progres klaim voucher per akun setelah klaim berhasil.

### Branding

- Launcher icon Android/iOS memakai `assets/logo.png`.
- Native splash Android, iOS, dan Web memakai logo baru dengan background navy
  `#1A374D` dan ukuran logo yang telah disesuaikan dengan safe area Android 12.

## Artefak Android

- **AAB:** `build/app/outputs/bundle/release/home-workers-1.0.11-build25.aab`
- **SHA-256:** `92ee6f7c0f2cef17c278ad0e51cc7f11c07e77e0cf20f0ae330a865ee8436563`
- **Package:** `com.homeworkers.app`
- **Environment:** `prod`
- **Signing:** upload keystore release

## Checklist sebelum rilis Production

- Deploy backend terbaru ke Firebase Production sebelum AAB dipromosikan.
  Saat dokumen ini dibuat, aturan refund/jadwal dan kuota klaim voucher terbaru
  baru terverifikasi pada Firebase Development `howek-dev`.
- Deploy dashboard Admin jika pengaturan Total Voucher, Max Claims per User,
  dan Max Claiming Users akan digunakan oleh tim operasional.
- Uji pada Internal Testing: login, booking lokasi tersimpan/lokasi lain,
  pembayaran fixed/survey, klaim voucher berulang, refund, riwayat order, wallet,
  serta cold start splash.
- Setelah build 25 tersedia di Play Store, set `Build terbaru` ke 25. Naikkan
  `Build minimum` hanya setelah rollout aman dan build lama memang harus diblokir.
- Gunakan staged rollout dan pantau error pembayaran, refund, voucher, serta
  transaksi wallet.
