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

Implementasi memakai satu sumber kebenaran:

```text
Dashboard Admin → appConfig/adminSettings → GET /api/app/version-policy
                                          → cache lokal Flutter → AppVersionGate
```

Saat startup, aplikasi membaca build number (`versionCode`) dan meminta policy
backend dengan timeout 3 detik. Jika `build saat ini < build minimum`, aplikasi
menampilkan layar **non-dismissible** dan tombol **Buka Play Store**.

URL Play Store resmi:

   `https://play.google.com/store/apps/details?id=com.homeworkers.app`

Backend dan frontend memvalidasi agar URL tetap menggunakan HTTPS, host Play
Store, dan package ID resmi.

### 4.3 Konfigurasi Dashboard Admin

Buka **Pengaturan Sistem → Kebijakan versi Android**:

- **Build minimum**: batas bawah yang boleh memakai aplikasi. `0` menonaktifkan
  wajib update.
- **Build terbaru**: build terbaru yang sudah tersedia dan tidak boleh lebih
  kecil daripada build minimum.
- **Pesan pembaruan**: teks yang tampil kepada pengguna.
- **URL Play Store**: dibatasi ke package `com.homeworkers.app`.

Setiap kali merilis build baru, naikkan build number di `pubspec.yaml`, unggah
ke Play Store, tunggu sampai tersedia, lalu baru naikkan build minimum jika
versi lama harus dihentikan.

Panduan operasional lengkap: [`force-update-backend.md`](force-update-backend.md).

### 4.4 Kasus backend gagal dihubungi

- Jika cache terakhir menyatakan build wajib update, aplikasi tetap diblokir.
- Jika cache terakhir mengizinkan build, policy cache tersebut dipakai.
- Jika belum ada cache, aplikasi dibuka agar gangguan backend tidak mengunci
  instalasi baru.
- Cache dipisahkan berdasarkan `API_BASE_URL` agar Development dan Production
  tidak saling memengaruhi.

### 4.5 iOS

Jika nanti ada rilis App Store, pola sama (bandingkan build), dengan URL App Store untuk app ID Anda. Play Store hanya untuk Android.

### 4.6 Alternatif resmi Google: In-App Updates

Google menyediakan **Play In-App Updates** (fleksibel atau langsung). Itu dapat
melengkapi, bukan mengganti, Backend Version Policy.

---

## 5. Checklist singkat sebelum rilis

- [ ] `pubspec.yaml`: `version` dan build number (`+`) sudah naik sesuai kebijakan rilis.
- [ ] Build store memakai **base URL API produksi**.
- [ ] Jika memakai paksa update: build pengganti sudah tersedia sebelum build minimum dinaikkan di Dashboard Admin.
- [ ] Uji satu perangkat dengan build lama (atau turunkan sementara minimum di RC untuk tes internal).

---

## 6. Referensi di repo ini

- Indeks dokumentasi frontend: [`docs/README.md`](README.md)
- Catatan rilis Play Store: [`docs/play-store-release-notes.md`](play-store-release-notes.md)
- Alur dev backend: `home-workers-backend/docs/dev-workflow.md`

Jika implementasi kode (gate versi, `dart-define`, dll.) dibutuhkan, lakukan di branch terpisah dan uji di perangkat nyata serta dengan akun internal Play Store bila memungkinkan.
