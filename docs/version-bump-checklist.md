# Checklist: menaikkan versi aplikasi

Panduan singkat **di mana** mengubah versi dan **urutan langkah** yang disarankan sebelum unggah ke Play Store (dan iOS jika dipakai).

---

## 1. Sumber utama: `pubspec.yaml`

File: **`home-workers-frontend/pubspec.yaml`** (di root project Flutter, bukan folder `android/` atau `ios/`).

Cari baris **`version:`**, contoh:

```yaml
version: 1.0.2+13
```

Format: **`namaVersi+buildNumber`**

| Bagian | Arti | Contoh |
|--------|------|--------|
| Sebelum `+` | **versionName** (Android) / **CFBundleShortVersionString** (iOS) — angka semver yang biasanya tampil ke pengguna | `1.0.2` |
| Setelah `+` | **versionCode** (Android) / **CFBundleVersion** (iOS) — bilangan bulat yang **harus naik** tiap unggahan baru ke Play Store | `13` |

### Langkah yang disarankan

1. Buka `pubspec.yaml`.
2. Putuskan apakah ini **perbaikan kecil** (patch), **fitur** (minor), atau **perubuan besar** (major), lalu sesuaikan angka sebelum `+` (misalnya `1.0.2` → `1.0.3` atau `1.1.0`).
3. **Selalu naikkan** angka setelah `+` untuk setiap build yang akan diunggah ke Play Store (misalnya `13` → `14`). Google Play menolak jika **versionCode** tidak lebih tinggi dari rilis sebelumnya.
4. Simpan file, commit bersama perubahan kode rilis Anda.

Saat menjalankan `flutter build appbundle` / `flutter build apk` tanpa override, Flutter mengisi Android dan iOS dari nilai `version` ini. **Biasanya Anda tidak perlu** mengedit manual `build.gradle` atau `Info.plist` untuk angka versi.

---

## 2. (Opsional) Override saat build dari CLI

Jika CI atau skrip build mengisi versi dari luar:

```bash
flutter build appbundle --build-name=1.0.3 --build-number=14
```

`--build-name` mengganti bagian sebelum `+`, `--build-number` mengganti bagian setelah `+`. Hanya pakai jika alur Anda memang mengandalkan ini; kalau tidak, cukup `pubspec.yaml`.

---

## 3. Setelah naikkan versi: pembaruan wajib (Remote Config)

Jika fitur **paksa update** aktif (lihat [`force-update-remote-config.md`](force-update-remote-config.md) dan [`environment-and-mandatory-update.md`](environment-and-mandatory-update.md)):

1. Di **Firebase Console → Remote Config**, parameter **`force_update_min_build_android`** memakai **build number** (angka setelah `+`).
2. Setelah rilis build baru ke pengguna, sesuaikan nilai minimum jika Anda ingin memutus pengguna yang masih di build lama (misalnya set minimum ke `14` agar yang masih `13` diminta update).

Urutan praktis: naikkan dulu `pubspec` → build AAB → unggah Play Store → lalu publish perubahan Remote Config jika ingin mulai memaksa dari build tersebut.

---

## 4. Play Console

1. Buat rilis baru / tambahkan AAB ke trek (internal, closed, production, dll.).
2. Pastikan **versi** yang terbaca di konsol cocok dengan yang Anda set (`versionName` + `versionCode` dari `pubspec` atau override build).
3. Isi **catatan rilis** pengguna mengikuti [`play-store-release-notes.md`](play-store-release-notes.md).

---

## 5. iOS (jika Anda merilis ke App Store)

Versi dan build tetap mengikuti **`pubspec.yaml`** saat build lewat Flutter, kecuali Anda mengubah project Xcode secara manual (hindari duplikasi kecuali ada kebutuhan khusus).

---

## Ringkasan satu baris

**Ubah hampir selalu cukup di `pubspec.yaml` pada baris `version: x.y.z+build` — naikkan `build` wajib tiap unggahan Play Store; sesuaikan `x.y.z` menurut jenis rilis; sinkronkan Remote Config jika memakai paksa update.**
