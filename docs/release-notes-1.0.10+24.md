# Catatan Rilis 1.0.10+24

- **Nama rilis Play Console:** `1.0.10 — Pembayaran & pengalaman lebih baik`
- **Version name:** `1.0.10`
- **Version code:** `24`
- **Target:** Android Production
- **Tanggal build:** 14 Agustus 2026

## Catatan Google Play (Bahasa Indonesia)

```text
• Pembayaran layanan survey kini mengikuti penawaran terbaru dengan nominal yang lebih akurat.
• Worker dapat merevisi penawaran sebelum disetujui Customer dan mengajukan penarikan saldo dengan informasi tujuan yang lebih lengkap.
• Menu Cari di Sekitar sekarang langsung menampilkan Worker terdekat berdasarkan lokasi.
• Tampilan dashboard Customer, proses pembayaran, dan splash screen dibuat lebih rapi dan jelas.
• Peningkatan stabilitas pembayaran, saldo Worker, dan alur pesanan.
```

## Ringkasan internal untuk QA

### Perbaikan transaksi dan pesanan

- Quote layanan survey dapat direvisi Worker sebelum disetujui Customer, lalu
  terkunci ketika pembayaran final dimulai.
- Nominal pembayaran final divalidasi terhadap snapshot quote terbaru agar
  frontend dan backend tidak menggunakan harga yang berbeda.
- Payout Worker untuk order survey dihitung dari total pembayaran awal dan
  final yang terverifikasi, dengan bagian Worker 80% dan platform 20%.
- Status pembayaran awal tidak lagi keliru dianggap sebagai pelunasan final.
- Loading pembayaran Snap dibatasi pada tombol terkait sehingga tidak menutup
  seluruh halaman atau route pembayaran.
- Form withdrawal mengirim data rekening bank atau e-wallet yang lengkap dan
  mempertahankan pesan validasi backend.

### Peningkatan pengalaman Customer

- Aksi `Cari di Sekitar` membuka tab Pekerja dengan filter jarak terdekat yang
  langsung aktif.
- Quick actions dashboard didesain ulang, ruang scroll kosong dikoreksi, dan
  header memakai gradient dengan kontras status bar yang sesuai.
- Native splash memakai satu tampilan konsisten dengan logo dan teks
  `HOME WORKERS` di dalam safe area Android 12.

## Artefak Android

- **AAB:** `build/app/outputs/bundle/release/home-workers-1.0.10-build24.aab`
- **SHA-256:** `5299e533bd70fd7850d0c21a7b3b32421d708af04ff6e26ea95b8123c11a4167`
- **Package:** `com.homeworkers.app`
- **Environment:** `prod`
- **Signing:** upload keystore release

## Deployment Firebase Development

- **Project:** `howek-dev`
- **Scope:** Cloud Functions
- **Functions:** `api`, `expireWorkerAcceptance`, `expireWarrantyActions`
- **Status:** seluruh function `ACTIVE`
- **Smoke test:** endpoint API Development merespons HTTP 200
- **Catatan:** runtime Node.js 20 perlu dimigrasikan sebelum dinonaktifkan pada
  30 Oktober 2026.

## Checklist sebelum rilis Production

- Backend yang menyertakan kontrak quote, pembayaran final, payout survey, dan
  withdrawal harus dideploy ke Production sebelum AAB dipromosikan.
- Deployment dalam pekerjaan ini hanya menuju Firebase Development
  (`howek-dev`), bukan Production.
- Smoke test Production tetap diperlukan untuk quote survey, pembayaran awal
  dan final, penyelesaian order, saldo Worker, withdrawal, serta refund.
- Gunakan staged rollout dan pantau error pembayaran serta transaksi wallet.
