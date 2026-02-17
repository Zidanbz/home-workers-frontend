# Auth API: Register dan Login

Dokumen ini merangkum endpoint autentikasi yang dipakai frontend untuk flow registrasi dan login.

## Ringkasan

- Base URL frontend saat ini: `https://api-eh5nicgdhq-uc.a.run.app/api`
- Prefix endpoint auth: `/auth`
- Owner feature: `features/auth`

## 1) Register Customer

- **Path**: `/auth/register/customer`
- **Method**: `POST`
- **Auth**: Tidak
- **Caller frontend**: `ApiService.registerCustomer`

### Request

Headers:

```http
Content-Type: application/json
```

Body:

```json
{
  "email": "new.customer@example.com",
  "password": "Secret123!",
  "nama": "Nama Customer",
  "fcmToken": "optional-device-token"
}
```

### Response Sukses (201)

```json
{
  "success": true,
  "message": "Customer registered successfully. Please verify your email.",
  "data": {
    "userId": "uid_value",
    "emailVerificationSent": true
  },
  "statusCode": 201,
  "timestamp": "2026-02-16T10:00:00.000Z"
}
```

### Error Yang Umum

- `400`: validasi gagal (contoh: email/password/nama kosong).
- `409`: email sudah terdaftar.
- `400`: format email tidak valid / password terlalu lemah.

## 2) Register Worker

- **Path**: `/auth/register/worker`
- **Method**: `POST`
- **Auth**: Tidak
- **Caller frontend**: `ApiService.registerWorker`

### Request

Headers:

```http
Content-Type: multipart/form-data
```

Form fields:

- `email`
- `password`
- `nama`
- `deskripsi`
- `keahlian` (JSON array string, contoh: `["AC","Cleaning"]`)
- `linkPortofolio` (opsional)
- `noKtp` (di-hash pada sisi frontend sebelum dikirim)
- `fcmToken` (opsional)
- `isEncrypted` (`true`)

Files wajib:

- `ktp`
- `fotoDiri`

Catatan frontend:

- File `ktp` dan `fotoDiri` dienkripsi sebelum upload.
- Jika backend mengirim payload error teknis (JSON + stack trace), frontend hanya menampilkan pesan inti ke user.

### Response Sukses (201)

```json
{
  "success": true,
  "message": "Worker registered successfully. Please verify your email and wait for admin approval before you can login.",
  "data": {
    "userId": "uid_value",
    "emailVerificationSent": true
  },
  "statusCode": 201,
  "timestamp": "2026-02-16T10:00:00.000Z"
}
```

### Error Yang Umum

- `400`: field wajib belum lengkap.
- `400`: file `ktp` atau `fotoDiri` tidak ada.
- `409`: email sudah terdaftar.
- `400`: validasi auth Firebase (`invalid email`, `weak password`, dan lain-lain).

## 3) Login

- **Path**: `/auth/login`
- **Method**: `POST`
- **Auth**: Tidak
- **Caller frontend**: `ApiService.loginUser`

### Request

Headers:

```http
Content-Type: application/json
```

Body:

```json
{
  "email": "user@example.com",
  "password": "Secret123!",
  "fcmToken": "optional-device-token"
}
```

### Response Sukses (200)

```json
{
  "success": true,
  "message": "Login successful.",
  "data": {
    "customToken": "firebase_custom_token",
    "idToken": "firebase_id_token",
    "refreshToken": "firebase_refresh_token",
    "expiresIn": "3600",
    "user": {
      "uid": "uid_value",
      "email": "user@example.com",
      "nama": "Nama User",
      "role": "CUSTOMER",
      "contact": null,
      "avatarUrl": null,
      "emailVerified": true
    },
    "requireEmailVerification": false
  },
  "statusCode": 200,
  "timestamp": "2026-02-16T10:00:00.000Z"
}
```

### Error Yang Umum

- `401`: email/kata sandi salah.
- `403`: akun dinonaktifkan / worker masih pending / worker ditolak.
- `404`: data user tidak ditemukan.
- `503`: gagal konek ke layanan autentikasi Firebase.

## 4) Refresh Token (Pendukung Login)

- **Path**: `/auth/refresh-token`
- **Method**: `POST`
- **Auth**: Tidak
- **Caller frontend**: `ApiService.refreshIdToken`

Body:

```json
{
  "refreshToken": "firebase_refresh_token"
}
```

Sukses (`200`) mengembalikan `idToken`, `refreshToken`, dan `expiresIn`.

## Mapping Pesan Error di Frontend

Frontend melakukan normalisasi pesan error sebelum ditampilkan ke user. Contoh mapping:

- `Email already registered` -> `Email sudah terdaftar. Gunakan email lain atau login.`
- `INVALID_LOGIN_CREDENTIALS` / `Email atau kata sandi salah` -> `Email atau kata sandi salah.`
- `Token expired` -> `Sesi Anda berakhir. Silakan login kembali.`
- payload error mentah/stack trace -> `Terjadi kesalahan pada server. Silakan coba lagi.`
