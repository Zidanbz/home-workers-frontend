# Checklist Rilis Play Store — Home Workers

Tujuan: menyiapkan aplikasi agar comply dengan kebijakan Play terbaru (target API wajib dalam rentang 1 tahun sejak rilis Android terbaru) dan siap build .aab untuk rilis.

Status ikon:

- [ ] Belum dikerjakan
- [x] Selesai

## 1) Target API & Gradle

- [x] Set eksplisit compileSdk = 34
- [x] Set eksplisit targetSdk = 34
- [x] Pastikan minSdk = 26 (tetap)
- [ ] Pastikan build lulus dan plugin kompatibel

## 2) Identitas Aplikasi & Signing

- [x] Ganti applicationId ke: com.homeworkers.app
- [x] Pastikan `namespace` Gradle sesuai: com.homeworkers.app
- [ ] Siapkan keystore & key.properties (instruksi di bawah)
- [ ] Verifikasi google-services.json sesuai package baru (lihat Catatan Firebase)

## 3) Optimasi Rilis (Size/Perf)

- [x] Aktifkan R8 shrinker (`isMinifyEnabled=true`)
- [x] Aktifkan shrink resources (`isShrinkResources=true`)
- [x] Tambahkan proguard-rules.pro dan referensi di buildTypes.release

## 4) Izin & Kepatuhan

- [x] Hapus izin sensitif yang tidak diperlukan: `SCHEDULE_EXACT_ALARM`
- [x] Pertahankan `POST_NOTIFICATIONS` dan permission runtime
- [ ] Pastikan alasan izin lokasi (penggunaan Google Maps) jelas di UX/privasi

## 5) Keamanan Kunci/API

- [x] Pindahkan Google Maps API Key dari AndroidManifest ke manifestPlaceholders
- [ ] Ambil `MAPS_API_KEY` dari `local.properties` (jangan commit ke repo)
- [x] Pastikan tidak ada API key hard-coded tersisa di repo

## 6) Versioning

- [x] Bump versi ke 1.0.0+2 di pubspec.yaml

## 7) Build & Uji

- [ ] Build bundle: `flutter clean && flutter pub get && flutter build appbundle --release`
- [ ] Verifikasi output: `build/app/outputs/bundle/release/app-release.aab`
- [ ] Uji fungsional: Notifikasi (Android 13+ prompt), Google Maps, login/registrasi, flow utama

## 8) Listing Play & Kebijakan

- [ ] Siapkan Privacy Policy URL dan isi Formulir Data Safety
- [ ] Siapkan deskripsi, ikon, feature graphic, screenshot
- [ ] Pastikan deklarasi izin sesuai (tanpa exact alarm)

---

# Panduan Pembuatan Keystore & key.properties (Lokal — jangan di-commit)

1. Buat keystore release (jalankan di terminal):

```
keytool -genkey -v -keystore release.keystore -alias release -keyalg RSA -keysize 2048 -validity 10000
```

- Simpan file `release.keystore` di: `android/app/keystore/release.keystore`

2. Buat file `key.properties` di root project Flutter (`home_workers_fe/key.properties`) dengan isi:

```
storeFile=android/app/keystore/release.keystore
storePassword=ISI_PASSWORD_STORE
keyAlias=release
keyPassword=ISI_PASSWORD_KEY
```

Pastikan `key.properties` tidak di-commit (tambahkan ke .gitignore bila perlu).

---

# Menyimpan Google Maps API Key (lokal — jangan di-commit)

1. Tambahkan `MAPS_API_KEY` ke file `local.properties` (di root Android: `home_workers_fe/android/local.properties`):

```
MAPS_API_KEY=ISI_API_KEY_GOOGLE_MAPS
```

2. Gradle akan meng-inject nilai ini ke AndroidManifest via `manifestPlaceholders`.

---

# Catatan Firebase (Sangat Penting)

Karena `applicationId` berubah menjadi `com.homeworkers.app`, maka:

- File `google-services.json` pada `android/app/` harus cocok dengan package baru.
- Masuk ke Firebase Console, tambahkan aplikasi Android baru dengan package `com.homeworkers.app`, unduh `google-services.json` yang baru, dan ganti file lama.
- Jalankan ulang build setelah mengganti file.

---

# Catatan Build

- Gunakan JDK yang sesuai untuk toolchain Android Anda (Android Studio rekomendasi).
- Perintah build rilis:

```
flutter clean
flutter pub get
flutter build appbundle --release
```
