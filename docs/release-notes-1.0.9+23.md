# Catatan Rilis 1.0.9+23

- **Nama rilis Play Console:** `1.0.9 — Penyempurnaan pesanan & profil`
- **Version name:** `1.0.9`
- **Version code:** `23`
- **Target:** Android Production
- **Tanggal build:** 4 Agustus 2026

## Catatan Google Play (Bahasa Indonesia)

```text
• Beri rating dan ulasan langsung dari detail pesanan yang selesai.
• Detail layanan kini menampilkan nama dan galeri foto yang bisa diperbesar.
• Worker dapat memperbarui profil, portofolio, sertifikat, dan nomor WhatsApp.
• Pendaftaran Worker lebih aman dari akun ganda.
• Saldo pekerjaan selesai masuk langsung, disertai perlindungan klaim/refund.
• Perbaikan stabilitas konfirmasi pekerjaan, autentikasi, KYC, dan tampilan profil.
```

## Ringkasan internal untuk QA

### Fitur baru

- Customer dapat memberi rating dan ulasan dari kartu riwayat maupun detail pesanan yang telah selesai.
- Detail layanan menampilkan nama layanan serta viewer foto fullscreen dengan zoom dan swipe.
- Worker dapat memperbarui data profil, nomor WhatsApp, keahlian, deskripsi, area, portofolio, dan sertifikat.
- Registrasi Customer dan Worker menyimpan nomor seluler Indonesia dalam format terstandar. Upload sertifikat saat registrasi Worker bersifat opsional.
- Worker yang ditugaskan dapat menghubungi Customer melalui WhatsApp setelah pembayaran order terverifikasi.

### Perbaikan

- Mencegah registrasi Worker ganda akibat tombol daftar ditekan berulang atau identitas yang sama digunakan melalui provider berbeda.
- Memperbaiki alur konfirmasi pekerjaan selesai, logout, pengiriman ulang KYC, loading dokumen Admin, dan avatar publik Worker.
- Pendapatan Worker langsung masuk ke saldo setelah Customer mengonfirmasi pekerjaan selesai. Klaim aktif memblokir pencairan, sedangkan refund yang benar-benar disetujui dicatat sebagai debit dan dapat membuat saldo negatif.

## Artefak Android

- **AAB:** `build/app/outputs/bundle/release/home-workers-1.0.9-build23.aab`
- **SHA-256:** `953648104e841b4e9e58afca965913b0ad5454459ce32266e80309aa85900409`
- **Package:** `com.homeworkers.app`
- **Environment:** `prod`
- **Verifikasi:** build sukses, ZIP integrity lulus, dan tanda tangan upload terverifikasi.

## Checklist sebelum rilis Production

- Deploy backend yang satu kontrak dengan aplikasi sebelum mempromosikan AAB ini. Perubahan registrasi, kontak WhatsApp, rating, profil Worker, dan wallet bergantung pada endpoint terbaru.
- Jalankan smoke test Production untuk login, registrasi, detail layanan, penyelesaian order, rating, wallet, update profil, dan logout.
- Pastikan kebijakan privasi menjelaskan pemrosesan nomor telepon, dokumen sertifikat/portofolio, serta penggunaan WhatsApp.
- Gunakan staged rollout dan pantau error autentikasi, upload, order completion, serta transaksi wallet sebelum rollout penuh.
