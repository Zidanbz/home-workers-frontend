# Flow Worker (Daftar → Selesai Pekerjaan)

## Ringkasan

- **Feature**: `auth` + `worker_flow`
- **Screen utama**:
  - Auth: `SelectRolePage`, `RegisterWorkerPage`, `EmailVerificationPendingPage`, `LoginPage`
  - Worker: `MainPage (WORKER)` → `WorkerDashboardPage`, `MyJobsPage`, `WorkerOrdersPage`, `OrderDetailPage`, `WorkerWalletPage`, `WorkerWithdrawPage`
- **Tujuan dokumen**: jadi panduan alur untuk Dev/QA/Product (apa yang user lakukan, state UI, validasi, dan status order yang mengubah tombol aksi).

## Tujuan Flow (untuk user)

Worker bisa:
1) mendaftar akun worker + upload dokumen,  
2) verifikasi email + menunggu approval admin,  
3) login dan menyiapkan layanan (service) yang dijual,  
4) menerima/menolak order, menjalankan pekerjaan (fixed/survey), dan menyelesaikannya,  
5) melihat saldo dan tarik dana (opsional, pasca pekerjaan selesai).

## Entry Point

- Dari onboarding/welcome → pilih role **Worker** → `RegisterWorkerPage`
- Atau dari onboarding/welcome → `LoginPage`

## Alur Utama (End-to-End)

### 1) Daftar Worker (`RegisterWorkerPage`)

Register dibuat dalam 4 langkah (wizard): **Akun → Dokumen → Portofolio → Selesai**.

**Step 1 — Akun**
- Input: `email`, `nama`, `password`
- Validasi (SnackBar):
  - Email tidak valid → `Email tidak valid.`
  - Nama kosong → `Nama wajib diisi.`
  - Password < 6 → `Password minimal 6 karakter.`

**Step 2 — Dokumen**
- Upload wajib: `fotoDiri`, `ktp`
- Input wajib: `noKtp`
- Validasi (SnackBar):
  - Foto diri belum ada → `Foto diri wajib diunggah.`
  - Foto KTP belum ada → `Foto KTP wajib diunggah.`
  - No KTP kosong → `Nomor KTP wajib diisi.`

**Step 3 — Portofolio (opsional)**
- Input opsional: `linkPortofolio`
- Input bebas: `deskripsi`, `keahlian` (dipisah koma, contoh: `AC, Cleaning, Elektronik`)

**Step 4 — Selesai**
- Checkbox wajib: setuju S&K
- Validasi (SnackBar): jika belum setuju → `Harap setujui Syarat & Ketentuan.`

**Submit**
- Sukses:
  - Tampilkan SnackBar: `Registrasi worker berhasil! Cek email untuk verifikasi.`
  - Navigasi: `EmailVerificationPendingPage(email)`
- Gagal:
  - Tampilkan error dari `ApiService.readableError(..., action: 'Registrasi worker gagal')`

**Catatan teknis**
- Registrasi worker mengirim `multipart/form-data` + file `ktp` & `fotoDiri`.
- File `ktp` dan `fotoDiri` dienkripsi sebelum upload, dan `noKtp` di-hash sebelum dikirim (lihat dokumentasi API: `docs/api/auth-register-login.md`).

### 2) Verifikasi Email (`EmailVerificationPendingPage`)

Tujuan: memastikan user verifikasi email sebelum lanjut login.

- Action:
  - `Kirim Ulang Email Verifikasi` (via Firebase `sendEmailVerification`)
  - `Saya Sudah Verifikasi, Lanjutkan ke Login` → kembali ke `LoginPage`
- State:
  - Loading saat resend: tombol disabled + spinner
  - Error: tampil SnackBar dari `ApiService.readableError(..., action: 'Gagal mengirim ulang email')`

### 3) Login (`LoginPage`)

Flow login membedakan:
- **Belum verifikasi email** → tetap diarahkan ke `EmailVerificationPendingPage`
- **Sudah verifikasi** → masuk ke `MainPage(userRole)`

Perilaku utama:
- Panggil `authProvider.loginAndGetData(email, password, fcmToken)`
- Jika `requireEmailVerification == true`:
  - SnackBar: `Login berhasil! Silakan verifikasi email Anda.`
  - Navigasi: `EmailVerificationPendingPage(email)`
- Jika sudah verifikasi:
  - `authProvider.processLoginSuccess(result)`
  - Navigasi: `MainPage(userRole: 'WORKER')`

Catatan penting (khusus worker):
- Backend dapat menolak login worker yang masih **pending approval admin** (umumnya `403`). Saat ini akan tampil dialog error dari `ApiService.readableError(..., action: 'Login gagal')`.

### 4) Navigasi Utama Worker (`MainPage` untuk role `WORKER`)

Bottom navigation:
- **Home** → `WorkerDashboardPage`
- **Jobs** → `MyJobsPage`
- **Orders** → `WorkerOrdersPage`
- **Chat** → `ChatListPage`
- **Profile** → `ProfilePage`

Shortcut di header `WorkerDashboardPage`:
- Wallet → `WorkerWalletPage`
- Notifications → `NotificationPage`
- Chat → `ChatListPage`

### 5) Siapkan Layanan (Jobs)

#### 5.1 Lihat & cari layanan (`MyJobsPage`)

- Data: `ApiService.getMyServices(token)`
- Aksi:
  - Search lokal berdasarkan input search
  - Tambah layanan (icon `+`) → `CreateEditJobPage()` lalu refresh ketika `Navigator.pop(true)`
  - Tap item → `JobDetailPage(serviceId)` (detail, edit, hapus)

#### 5.2 Buat/Edit layanan (`CreateEditJobPage`)

Mode:
- **Create**: `CreateEditJobPage()`
- **Edit**: `CreateEditJobPage(service: service)`

Field & aturan (ringkas):
- Wajib (semua mode, via `Form` validator): `Nama layanan`, `Deskripsi`
- Wajib (khusus create, via `_validateCreateFields()`):
  - `Kategori` harus dipilih
  - Minimal 1 foto layanan (jadi `fotoUtamaUrl`)
  - Minimal 1 slot `Jadwal Ketersediaan`
  - Jika `tipeLayanan = fixed` → `Harga > 0`
  - Jika `tipeLayanan = survey` → `Biaya survei > 0`

Tipe layanan:
- `fixed`: user set harga, metode pembayaran dipaksa `Cashless`
- `survey`: worker ajukan penawaran saat order; metode pembayaran bisa `Cashless` atau `Cek Dulu`

Output saat simpan:
- Upload foto ke storage (service photo) → gabungkan dengan foto existing (edit mode)
- Panggil:
  - Create → `ApiService.createService(token, serviceData)`
  - Update → `ApiService.updateService(token, serviceId, dataToUpdate)`
- Sukses → SnackBar + `Navigator.pop(true)`
- Error → SnackBar `Gagal menyimpan layanan` (hasil normalisasi `ApiService.readableError`)

### 6) Kelola Order (Orders)

#### 6.1 Daftar order worker (`WorkerOrdersPage`)

- Data: `ApiService.getMyOrders(token)`
- Filtering di UI:
  - Order dengan status `awaiting_payment` disembunyikan dari list
  - Tab **Antrean** menampilkan status: `pending`, `accepted`, `quote_proposed`, `work_in_progress`
  - Tab **Riwayat** menampilkan status: `completed`, `cancelled`, `quote_rejected`, `rejected`
- Aksi:
  - Tarik untuk refresh (RefreshIndicator)
  - Tap order → `OrderDetailPage(orderId)`

#### 6.2 Detail order & aksi (`OrderDetailPage`)

Info yang tampil:
- Customer: nama + alamat
- Lokasi pengerjaan (Google Maps) jika `coordinates` tersedia
- Detail layanan: nama layanan, jadwal, tipe (`fixed`/`survey`), status

Tombol aksi (bergantung status + tipe):
- `pending` → **Tolak Pesanan** / **Terima Pesanan**
  - Tolak → `ApiService.rejectOrder(token, orderId)` (konfirmasi dulu)
  - Terima → `ApiService.acceptOrder(token, orderId)`
- `survey` + (`accepted` atau `quote_proposed`) → **Ajukan Penawaran** / **Ubah Penawaran**
  - Kirim quote → `ApiService.proposeQuote(token, orderId, proposedPrice)`
- `fixed` + `accepted` → **Selesaikan Pekerjaan** (langsung, dengan konfirmasi) → update status `completed`
- `quote_accepted` → **Mulai Pengerjaan** → update status `work_in_progress`
- `work_in_progress` → **Selesaikan Pekerjaan** (konfirmasi) → update status `completed`

Status update generik:
- `ApiService.updateOrderStatus(token, orderId, status)` dipakai untuk `work_in_progress` dan `completed`.

## State UI (yang paling relevan)

- Halaman list (Jobs/Orders/Wallet):
  - `loading`: `CircularProgressIndicator`
  - `error`: teks error dari `ApiService.readableError(...)`
  - `empty`: pesan empty + (di Orders tetap bisa pull-to-refresh)
- Halaman aksi (OrderDetail):
  - `_isProcessing == true` → disable tombol, tampil loading
  - Sukses → SnackBar hijau + refresh detail
  - Gagal → SnackBar merah (normalisasi `ApiService.readableError`)

## Ringkasan Status Order (versi UI Worker)

| Status | Ada di List Antrean | Ada di Riwayat | Aksi Utama di Detail |
|---|---:|---:|---|
| `pending` | ✅ | ❌ | accept / reject |
| `accepted` | ✅ | ❌ | fixed: complete, survey: propose quote |
| `quote_proposed` | ✅ | ❌ | survey: change quote |
| `quote_accepted` | ⚠️ (belum) | ⚠️ (belum) | start work (`work_in_progress`) |
| `work_in_progress` | ✅ | ❌ | complete |
| `completed` | ❌ | ✅ | - |
| `quote_rejected` | ❌ | ✅ | - |
| `rejected` | ❌ | ✅ | - |
| `cancelled` | ❌ | ✅ | - |
| `awaiting_payment` | ❌ (disembunyikan) | ❌ (disembunyikan) | - |

## Saran Perbaikan & Peningkatan

1) **Perbaiki konsistensi status di list order**
   - `quote_accepted` saat ini punya tombol aksi di `OrderDetailPage`, tapi tidak masuk tab **Antrean** maupun **Riwayat** di `WorkerOrdersPage` → berpotensi “hilang” dari list.
2) **Tambahkan tahap “Mulai Pekerjaan” untuk layanan `fixed`**
   - Sekarang `fixed` status `accepted` langsung bisa “Selesaikan Pekerjaan”. Umumnya lebih aman jadi: `accepted` → `work_in_progress` → `completed` (lebih realistis untuk tracking dan audit).
3) **Sediakan screen khusus “Menunggu Approval Admin”**
   - Saat login worker ditolak karena pending approval, sekarang hanya muncul dialog error generik. UX lebih jelas kalau ada halaman khusus (mirip `EmailVerificationPendingPage`).
4) **Standarkan mapping status → label UI**
   - Saat ini `_getFormattedStatus()` hanya cover beberapa status. Sebaiknya semua status yang mungkin muncul punya label konsisten (termasuk `cancelled`, `rejected`, `awaiting_payment`).
5) **Validasi KTP & dokumen lebih ketat**
   - Format `noKtp` (panjang/angka), batas ukuran file, dan preview file sebelum submit agar mengurangi gagal submit.
6) **Hilangkan hardcode lokasi di dashboard**
   - `WorkerDashboardPage` menampilkan lokasi `Makassar` hardcoded; sebaiknya dari profil user atau setting lokasi.

## Saran Ringkasan / Simplifikasi Flow

Jika ingin alur lebih ringkas tanpa mengurangi kontrol:
- **Registrasi**: gabungkan Step 3 (Portofolio) ke dalam Step 1 sebagai section opsional (collapse), sehingga wizard jadi 3 langkah: `Akun → Dokumen → Konfirmasi`.
- **Order**: samakan alur fixed & survey jadi 1 state machine:
  - `pending → accepted → (quote_proposed → quote_accepted hanya untuk survey) → work_in_progress → completed`
  - Dengan ini, UI tombol aksi jadi lebih konsisten dan lebih mudah dipahami user.

