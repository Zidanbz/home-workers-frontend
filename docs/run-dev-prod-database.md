# Cara Menjalankan Project dengan Database Dev dan Prod

Dokumen ini menjelaskan cara menjalankan **Home Workers Frontend** agar terhubung ke database development atau production.

## Prinsip Utama

Frontend Flutter tidak langsung terhubung ke database. Alurnya:

```text
Flutter App -> API Backend -> Firebase / Firestore
```

Artinya, frontend hanya memilih **API backend** lewat environment. Backend yang menentukan database mana yang dipakai berdasarkan Firebase project:

- Dev: `howek-dev`
- Prod: `home-workers-fa5cd`

## Frontend Environment

Kode frontend membaca `APP_ENV` dari `--dart-define` di `lib/main.dart`.

Jika `APP_ENV=sandbox`, app akan load:

- `.env.sandbox`
- `google-services-dev.json` untuk Android
- Firebase project dev: `howek-dev`
- Android application ID: `com.homeworkers.app.dev`

Jika `APP_ENV` tidak diisi atau bernilai `prod`, app akan load:

- `.env`
- `google-services-prod.json` untuk Android
- Firebase project prod: `home-workers-fa5cd`
- Android application ID: `com.homeworkers.app`

Application ID dev sengaja dibedakan agar OAuth Android development dan
production memiliki pasangan package + SHA yang unik. Ini juga memungkinkan
kedua aplikasi terpasang bersamaan pada perangkat yang sama.

## Menjalankan Frontend ke Database Dev

Gunakan mode sandbox:

```bash
cd /Users/zidanbsa/Documents/HOME_WORKERS/home-workers-frontend
flutter pub get
flutter run --dart-define=APP_ENV=sandbox
```

Environment yang dipakai:

```text
APP_ENV=sandbox
ENV_FILE=.env.sandbox
API_BASE_URL=https://us-central1-howek-dev.cloudfunctions.net/api/api
FIREBASE_PROJECT=howek-dev
```

Mode ini cocok untuk:

- pengembangan fitur baru
- testing internal
- testing payment sandbox
- testing data dummy/dev

## Menjalankan Frontend ke Database Prod

Gunakan mode prod:

```bash
cd /Users/zidanbsa/Documents/HOME_WORKERS/home-workers-frontend
flutter pub get
flutter run --dart-define=APP_ENV=prod
```

Environment yang dipakai:

```text
APP_ENV=prod
ENV_FILE=.env
API_BASE_URL=https://api-eh5nicgdhq-uc.a.run.app/api
FIREBASE_PROJECT=home-workers-fa5cd
```

Mode ini hanya untuk:

- validasi production
- build release
- upload ke Play Store

## Build Release Production

Untuk build APK production:

```bash
cd /Users/zidanbsa/Documents/HOME_WORKERS/home-workers-frontend
flutter build apk --release --dart-define=APP_ENV=prod
```

Untuk build AAB production:

```bash
cd /Users/zidanbsa/Documents/HOME_WORKERS/home-workers-frontend
flutter build appbundle --release --dart-define=APP_ENV=prod
```

Pastikan build yang di-upload ke Play Store selalu memakai:

```text
--dart-define=APP_ENV=prod
```

## Backend Environment

Backend ada di:

```text
/Users/zidanbsa/Documents/HOME_WORKERS/home-workers-backend
```

Backend memilih env berdasarkan Firebase project di `functions/src/index.js`:

- Project `howek-dev` memakai env dev.
- Project selain itu memakai env prod.

## Deploy Backend Dev

```bash
cd /Users/zidanbsa/Documents/HOME_WORKERS/home-workers-backend/functions
firebase deploy --only functions --project howek-dev
```

Atau dari script:

```bash
cd /Users/zidanbsa/Documents/HOME_WORKERS/home-workers-backend/functions
npm run deploy:dev
```

Backend dev akan memakai:

```text
FIREBASE_PROJECT=howek-dev
DATABASE=Firestore howek-dev
```

## Deploy Backend Prod

```bash
cd /Users/zidanbsa/Documents/HOME_WORKERS/home-workers-backend/functions
firebase deploy --only functions --project home-workers-fa5cd
```

Atau dari script:

```bash
cd /Users/zidanbsa/Documents/HOME_WORKERS/home-workers-backend/functions
npm run deploy:prod
```

Backend prod akan memakai:

```text
FIREBASE_PROJECT=home-workers-fa5cd
DATABASE=Firestore home-workers-fa5cd
```

## Menjalankan Backend Lokal dengan Dev Database

Jika ingin menjalankan emulator functions lokal tetapi tetap memakai konfigurasi dev:

```bash
cd /Users/zidanbsa/Documents/HOME_WORKERS/home-workers-backend/functions
ENV_FILE=.env.howek.dev firebase emulators:start --only functions --project howek-dev
```

Jika file env dev sudah disamakan namanya menjadi `.env.howek-dev`, perintah bisa menjadi:

```bash
cd /Users/zidanbsa/Documents/HOME_WORKERS/home-workers-backend/functions
firebase emulators:start --only functions --project howek-dev
```

Untuk mengarahkan frontend ke emulator lokal, ubah sementara `API_BASE_URL` di `.env.sandbox` ke URL emulator functions.

Contoh umum:

```text
API_BASE_URL=http://127.0.0.1:5001/howek-dev/us-central1/api/api
```

Lalu jalankan frontend:

```bash
cd /Users/zidanbsa/Documents/HOME_WORKERS/home-workers-frontend
flutter run --dart-define=APP_ENV=sandbox
```

## Catatan Penting Nama File Env Backend

Di `functions/src/index.js`, backend mencari file env dev bernama:

```text
.env.howek-dev
```

Namun di folder backend saat ini terdapat file:

```text
.env.howek.dev
```

Supaya otomatis terbaca saat project `howek-dev`, samakan nama file dev menjadi:

```text
home-workers-backend/functions/.env.howek-dev
```

Atau jalankan backend lokal dengan override:

```bash
ENV_FILE=.env.howek.dev firebase emulators:start --only functions --project howek-dev
```

## Ringkasan Cepat

| Kebutuhan | Perintah |
| --- | --- |
| Frontend dev | `flutter run --dart-define=APP_ENV=sandbox` |
| Frontend prod | `flutter run --dart-define=APP_ENV=prod` |
| Build APK prod | `flutter build apk --release --dart-define=APP_ENV=prod` |
| Build AAB prod | `flutter build appbundle --release --dart-define=APP_ENV=prod` |
| Deploy backend dev | `firebase deploy --only functions --project howek-dev` |
| Deploy backend prod | `firebase deploy --only functions --project home-workers-fa5cd` |

## Checklist Sebelum Rilis

- Pastikan frontend build production memakai `APP_ENV=prod`.
- Pastikan `.env` frontend mengarah ke API production.
- Pastikan backend production sudah deploy ke `home-workers-fa5cd`.
- Pastikan data testing tidak masuk ke database production.
- Pastikan payment production tidak tertukar dengan Midtrans sandbox.
