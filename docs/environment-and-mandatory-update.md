# Lingkungan API (Dev / Prod) & Pembaruan Wajib Aplikasi

Dokumen ini merangkum **cara menyambungkan frontend ke backend** saat ada lebih dari satu lingkungan (development vs production), dan **cara memaksa pengguna versi lama memperbarui** lewat Play Store—tanpa menyentuh kode di sini; ini panduan arsitektur dan operasional.

---

## 1. Prinsip: frontend tidak menyambung ke database

Aplikasi Flutter hanya berkomunikasi dengan **URL API backend** (HTTP/HTTPS). Backend-lah yang memilih **database dev atau prod** lewat variabel lingkungan (misalnya file `.env` di Cloud Functions / deployment).

Alur singkat:

```text
App Flutter  →  base URL API  →  Backend  →  DB (dev atau prod)
```

Dengan begitu, memisahkan “mode dev” vs “mode prod” di mobile sama artinya dengan **mengarahkan base URL** ke deployment backend yang sudah memakai DB yang sesuai.

---

## 2. Memisahkan dev dan prod di frontend

Tujuan: saat mengembangkan fitur baru, build lokal / internal mengarah ke **API + DB dev**; rilis ke pengguna mengarah ke **API + DB prod**, tanpa mengganti string URL secara manual di source setiap kali.

### 2.1 Pendekatan yang umum dipakai

| Pendekatan | Kelebihan | Catatan singkat |
|------------|-----------|-----------------|
| **`--dart-define`** | Cepat, tanpa dependency tambahan | Nilai disuntik saat `flutter run` / `flutter build` |
| **Flutter flavors** | Dua ikon app (dev & prod), konfigurasi jelas per platform | Setup Gradle / Xcode sedikit lebih panjang |
| **`flutter_dotenv` + file `.env*`** | Mirip pola backend | Pastikan file sensitif tidak ikut ke repo / build store |

### 2.2 Contoh ide dengan `dart-define`

- Satu konstanta di kode membaca `String.fromEnvironment('API_BASE_URL', defaultValue: '...')`.
- Develop: `flutter run --dart-define=API_BASE_URL=https://api-dev-anda/...`
- Rilis prod: `flutter build apk --dart-define=API_BASE_URL=https://api-prod-anda/...`

Skrip shell kecil (`run_dev.sh`, `build_prod.sh`) mengurangi risiko salah ketik.

### 2.3 Aturan keamanan operasional

- Build yang diunggah ke **Play Store / App Store** harus selalu memakai **URL produksi**.
- Jangan menyematkan kunci rahasia di client; yang boleh beda antar environment biasanya hanya **base URL** (dan konfigurasi publik seperti Firebase project jika Anda memang memisahkan project dev/prod).

---

## 3. Alur kerja: fitur baru di dev, lalu ke prod

1. **Backend dev**: deploy ke URL dev dengan env yang memakai **DB dev**. Jalankan migrasi skema di dev terlebih dahulu jika ada.
2. **Frontend dev**: jalankan app dengan base URL mengarah ke **API dev** (flavor dev atau `dart-define`).
3. Uji fitur end-to-end di lingkungan dev.
4. **Backend prod**: deploy dengan migrasi yang sama ke **DB prod**.
5. **Frontend prod**: naikkan `version` / build number di `pubspec.yaml`, build dengan URL **API prod**, unggah ke store.

Dokumentasi alur ngoding backend (branch, env, Firestore dev) ada di repositori backend: `home-workers-backend/docs/dev-workflow.md`.

---

## 4. Memaksa pengguna memperbarui (versi lama tidak boleh dipakai)

### 4.1 Tujuan

Pengguna yang masih memasang APK/AAB dengan **build lama** melihat pesan bahwa versi baru tersedia dan **tidak bisa melanjutkan** sampai membuka Play Store (atau setidaknya diarahkan ke sana).

### 4.2 Pola yang disarankan

1. **Sumber kebenaran “versi minimum”** yang bisa diubah **tanpa** merilis ulang aplikasi:
   - **Firebase Remote Config**, atau
   - Dokumen **Firestore**, atau
   - **Endpoint backend** (misalnya `GET /app/config`).

2. **Di aplikasi**, saat startup (setelah layanan siap):
   - Baca **versi terpasang** (disarankan memakai **build number** / `versionCode` pada Android, yaitu angka setelah `+` di `pubspec`, contoh `1.0.2+13` → `13`).
   - Bandingkan dengan **nilai minimum** dari Remote Config (atau sumber lain).
   - Jika `build saat ini < minimum`: tampilkan layar atau dialog **non-dismissible** (pengguna tidak bisa kembali ke app utama) dan tombol **Buka Play Store**.

3. **URL Play Store** (ganti `applicationId` sesuai `android/app/build.gradle`):

   `https://play.google.com/store/apps/details?id=com.homeworkers.app`

   Membuka URL ini dari app biasanya memakai paket seperti `url_launcher` dengan mode aplikasi eksternal.

### 4.3 Konvensi Remote Config (contoh)

Di Firebase Console: aktifkan **Remote Config** untuk project yang sama dengan app, lalu tambahkan parameter berikut (tipe sesuai nama di bawah).

- Kunci bilangan bulat, misalnya `force_update_min_build_android`.
  - Nilai `0` (atau tidak mengaktifkan paksa) = **tidak** memblokir berdasarkan build.
  - Nilai `15` = hanya app dengan **build number ≥ 15** yang boleh lanjut.
- Opsional: kunci string untuk **pesan** yang ditampilkan ke pengguna (bahasa Indonesia, penjelasan singkat).

Setiap kali Anda merilis build baru ke Play Store, **naikkan build number** di `pubspec`, lalu di konsol Remote Config set **minimum** ke build yang Anda anggap paling rendah yang masih boleh dipakai (biasanya sama dengan build rilis terbaru, atau lebih tinggi jika Anda ingin memutus semua yang di bawahnya).

**Implementasi di repo:** logika ini ada di `lib/core/widgets/app_version_gate.dart` dan `MaterialApp` memuat `AppVersionGate` mengelilingi `AuthWrapper` di `lib/main.dart`. Hanya **Android** yang dicek; gagal fetch Remote Config → app tetap jalan (kebijakan longgar).

**Panduan operasional Firebase (form parameter, arti angka, contoh):** [`force-update-remote-config.md`](force-update-remote-config.md).

### 4.4 Kasus gagal fetch (offline / error jaringan)

Kebijakan umum:

- **Longgar**: jika gagal membaca config, biarkan app jalan (hindari “brick” total).
- **Ketat**: tetap blokir (jarang dipakai kecuali kebutuhan compliance).

Pilih satu dan dokumentasikan untuk tim.

### 4.5 iOS

Jika nanti ada rilis App Store, pola sama (bandingkan build), dengan URL App Store untuk app ID Anda. Play Store hanya untuk Android.

### 4.6 Alternatif resmi Google: In-App Updates

Google menyediakan **Play In-App Updates** (fleksibel atau langsung). Itu melengkapi, bukan mengganti, kebutuhan “versi minimum” dari server/Remote Config jika Anda ingin tetap bisa memutus klien yang sangat lama.

---

## 5. Checklist singkat sebelum rilis

- [ ] `pubspec.yaml`: `version` dan build number (`+`) sudah naik sesuai kebijakan rilis.
- [ ] Build store memakai **base URL API produksi**.
- [ ] Jika memakai paksa update: nilai minimum di Remote Config (atau sumber lain) selaras dengan build yang diunggah.
- [ ] Uji satu perangkat dengan build lama (atau turunkan sementara minimum di RC untuk tes internal).

---

## 6. Referensi di repo ini

- Indeks dokumentasi frontend: [`docs/README.md`](README.md)
- Catatan rilis Play Store: [`docs/play-store-release-notes.md`](play-store-release-notes.md)
- Alur dev backend: `home-workers-backend/docs/dev-workflow.md`

Jika implementasi kode (gate versi, `dart-define`, dll.) dibutuhkan, lakukan di branch terpisah dan uji di perangkat nyata serta dengan akun internal Play Store bila memungkinkan.
