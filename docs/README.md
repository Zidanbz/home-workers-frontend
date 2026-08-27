# Frontend Documentation

Folder ini dipakai untuk dokumentasi project frontend.

## Struktur

- `docs/api`: dokumentasi contract API yang dipakai frontend.
- `docs/ui`: dokumentasi alur layar, state, dan behavior UI.
- `docs/changelog`: catatan perubahan per tanggal rilis.
- [`docs/play-store-release-notes.md`](play-store-release-notes.md): panduan nama rilis, penamaan, dan format catatan rilis di Google Play Store (bug fix, fitur baru, dll.).
- [`docs/environment-and-mandatory-update.md`](environment-and-mandatory-update.md): pemisahan lingkungan API (dev/prod) dan pembaruan wajib lewat backend.
- [`docs/run-dev-prod-database.md`](run-dev-prod-database.md): panduan menjalankan frontend dan backend ke database dev (`howek-dev`) atau prod (`home-workers-fa5cd`).
- [`docs/version-bump-checklist.md`](version-bump-checklist.md): langkah menaikkan versi (`pubspec.yaml`), build CLI, Backend Version Policy, dan Play Console.
- [`docs/force-update-backend.md`](force-update-backend.md): panduan pengaturan build minimum, endpoint policy, cache aplikasi, dan alur rilis wajib update.

## Aturan Singkat

- Tulis ringkas, jelas, dan update saat ada perubahan behavior.
- Simpan contoh request/response yang benar-benar dipakai di frontend.
- Untuk perubahan penting, tambahkan entry di `docs/changelog`.
