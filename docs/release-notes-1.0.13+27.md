# Catatan Rilis 1.0.13+27

- **Nama rilis Play Console:** `1.0.13 — Kompatibilitas Android 16`
- **Version name:** `1.0.13`
- **Version code:** `27`
- **Target SDK:** Android 16 / API 36
- **Target:** Android Production
- **Tanggal build:** 24 Agustus 2026

## Catatan Google Play (Bahasa Indonesia)

```text
• [Peningkatan] Aplikasi kini mendukung persyaratan Android 16 dan target API 36.
• [Peningkatan] Navigasi kembali pada halaman pembayaran diperbarui agar lebih konsisten pada Android terbaru.
• [Stabilitas] Kompatibilitas tampilan, notifikasi, lokasi, dan alur transaksi ditingkatkan untuk perangkat Android terbaru.
```

## Ringkasan internal untuk QA

- `compileSdk` dan `targetSdk` menggunakan API 36.
- Navigasi kembali pada halaman pembayaran memakai `PopScope` agar kompatibel
  dengan predictive back Android 16 tanpa mengubah aturan transaksi selesai.
- Pembatasan portrait untuk tablet dan foldable dipertahankan sementara melalui
  `PROPERTY_COMPAT_ALLOW_RESTRICTED_RESIZABILITY` sampai layout adaptif selesai
  diuji. Opt-out ini harus dihapus sebelum target API 37.
- Tidak ada perubahan endpoint, skema database, autentikasi, pembayaran, atau
  data pengguna dalam rilis kompatibilitas ini.

## Checklist QA Android 16

- Uji cold start, login email/Google, logout, dan pemulihan sesi.
- Uji permission serta alur lokasi, peta, galeri/kamera, dan notifikasi.
- Uji predictive back pada login, dashboard, detail order, dan pembayaran.
- Uji pembayaran fixed dan survey sampai status diverifikasi backend.
- Uji notifikasi foreground/background serta suara order masuk.
- Uji tampilan pada ponsel, tablet/foldable, mode split-screen, dan keyboard.
- Jalankan smoke test perangkat Android 16 untuk seluruh flow di atas sebelum
  promosi Production.

## Verifikasi otomatis

- Seluruh `122` Flutter test lulus.
- Analyzer terarah tidak menemukan error; hanya lint nama file lama
  `snapPayment_page.dart` yang belum mengikuti `lower_case_with_underscores`.
- Build Production selesai dan merged manifest terverifikasi memakai package
  `com.homeworkers.app`, version `1.0.13+27`, minimum SDK 24, dan target SDK 36.
- Firebase build menunjuk ke project Production `home-workers-fa5cd`.
- Tanda tangan AAB valid dan fingerprint signer cocok dengan build 26.
- Build menghasilkan warning roadmap non-blocking untuk upgrade Gradle, AGP,
  Kotlin, serta migrasi Built-in Kotlin. Upgrade tersebut dipisahkan dari rilis
  ini agar perubahan toolchain tidak memperbesar risiko menjelang deadline.

## Rollout Play Store

- Unggah build 27 ke Internal Testing dan selesaikan smoke test Android 16.
- Promosikan secara bertahap ke Production setelah hasil QA disetujui.
- Setelah build 27 benar-benar tersedia bagi seluruh pengguna, atur
  **Build terbaru = 27**.
- Atur **Build minimum = 27** hanya setelah ketersediaan Play Store diverifikasi
  dari akun pengguna umum; pengaturan lebih awal dapat mengunci pengguna.

## Artefak Android

- **AAB:** `build/app/outputs/bundle/release/home-workers-1.0.13-build27.aab`
- **Ukuran:** 82.595.762 byte (sekitar 82,6 MB)
- **SHA-256:** `ecc96fd351df15fd5b0fa947538ca888c93fd2bd71fe43d65e7a391a741efe3a`
- **Package:** `com.homeworkers.app`
- **Environment:** `prod`
- **Firebase:** `home-workers-fa5cd`
- **Signing:** upload keystore release
