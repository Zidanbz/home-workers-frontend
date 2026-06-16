# UAT Test Cases — Home Workers

Template mengikuti kolom pada sheet UAT: **Nama Fitur**, **Skenario Pengujian**, **Langkah Pengujian**, **Hasil yang Diharapkan**, **Hasil Aktual**, **Status (Pass/Fail)**, **Priority**, **Device**, **OS Version**, **Tester**, **Tanggal Test**.

Catatan:
- Kolom **Hasil Aktual/Status/Device/OS/Tester/Tanggal** sengaja dibiarkan kosong untuk diisi saat testing.
- Gunakan **Priority**: P0 (kritis), P1 (tinggi), P2 (menengah), P3 (rendah).

## UAT — User (Customer)

| Nama Fitur | Skenario Pengujian | Langkah Pengujian | Hasil yang Diharapkan | Hasil Aktual | Status (Pass/Fail) | Priority | Device | OS Version | Tester | Tanggal Test |
|---|---|---|---|---|---|---|---|---|---|---|
| Login | User login dengan kredensial valid | 1. Buka aplikasi<br>2. Masuk ke halaman Login<br>3. Input nomor/email (sesuai sistem) & password valid<br>4. Tap **Login** | User berhasil login dan masuk ke halaman utama (dashboard/home) |  |  | P0 |  |  |  |  |
| Login | User login dengan password salah | 1. Buka halaman Login<br>2. Input akun valid<br>3. Input password salah<br>4. Tap **Login** | Muncul pesan error yang jelas; user tetap di halaman login |  |  | P0 |  |  |  |  |
| Login | User login dengan akun tidak terdaftar | 1. Buka halaman Login<br>2. Input nomor/email yang belum terdaftar<br>3. Input password apa pun<br>4. Tap **Login** | Muncul pesan akun tidak ditemukan/harus daftar; tidak login |  |  | P1 |  |  |  |  |
| Logout | User logout dari aplikasi | 1. Login<br>2. Buka menu Profil/Settings<br>3. Tap **Logout**<br>4. Konfirmasi | User keluar dari sesi dan kembali ke halaman Login/Onboarding |  |  | P0 |  |  |  |  |
| Lupa Password | Reset password berhasil (OTP/link) | 1. Buka Login<br>2. Tap **Lupa Password**<br>3. Input nomor/email terdaftar<br>4. Submit<br>5. Masukkan OTP / buka link reset<br>6. Set password baru<br>7. Login dengan password baru | Proses reset sukses; user bisa login dengan password baru |  |  | P0 |  |  |  |  |
| Registrasi | Daftar akun baru berhasil | 1. Buka Register/Sign up<br>2. Isi data wajib (nama, nomor/email, password, dsb.)<br>3. Verifikasi OTP bila ada<br>4. Submit | Akun berhasil dibuat; user masuk ke home atau ke langkah onboarding berikutnya |  |  | P0 |  |  |  |  |
| Marketplace | Lihat daftar layanan/kategori | 1. Login<br>2. Buka halaman Marketplace<br>3. Scroll daftar kategori/layanan | Daftar kategori & layanan tampil; loading/error state tertangani |  |  | P1 |  |  |  |  |
| Marketplace | Search layanan/worker | 1. Buka Marketplace<br>2. Input keyword di search<br>3. Submit<br>4. Ubah filter/sort (jika ada) | Hasil sesuai keyword/filter; empty state tampil bila tidak ada hasil |  |  | P1 |  |  |  |  |
| Detail Layanan | Buka detail layanan | 1. Dari Marketplace pilih layanan<br>2. Tap item layanan | Halaman detail tampil (deskripsi, harga/estimasi, dsb.) tanpa crash |  |  | P1 |  |  |  |  |
| Buat Order | Buat pesanan dengan data valid | 1. Pilih layanan<br>2. Tap **Pesan/Order**<br>3. Isi alamat/lokasi<br>4. Pilih jadwal (jika ada)<br>5. Isi catatan (opsional)<br>6. Konfirmasi | Order tercipta; user melihat status order (menunggu/processing) |  |  | P0 |  |  |  |  |
| Buat Order | Validasi field wajib saat buat order | 1. Masuk flow buat order<br>2. Kosongkan field wajib (alamat/jadwal/jenis layanan)<br>3. Tap **Konfirmasi** | Muncul validasi pada field wajib; order tidak dibuat |  |  | P0 |  |  |  |  |
| Order List | Lihat daftar order (aktif/riwayat) | 1. Login<br>2. Buka Orders<br>3. Pindah tab Aktif/Riwayat | List tampil sesuai status; pagination/refresh bekerja (jika ada) |  |  | P1 |  |  |  |  |
| Order Detail | Lihat detail order | 1. Buka Orders<br>2. Tap salah satu order | Detail lengkap tampil (status, alamat, layanan, biaya, worker bila assigned) |  |  | P0 |  |  |  |  |
| Cancel Order | Batalkan order sebelum diproses | 1. Buka detail order status menunggu<br>2. Tap **Batalkan**<br>3. Pilih alasan (jika ada)<br>4. Konfirmasi | Status berubah menjadi dibatalkan; user melihat notifikasi/konfirmasi |  |  | P0 |  |  |  |  |
| Chat | User membuka chat dari order | 1. Buka Order Detail (yang sudah ada worker/room chat)<br>2. Tap **Chat** | Chat room terbuka; histori tampil; input pesan aktif |  |  | P1 |  |  |  |  |
| Chat | Kirim pesan teks | 1. Masuk chat room<br>2. Ketik pesan<br>3. Tap **Send** | Pesan terkirim dan muncul di bubble; status terkirim/terbaca (jika ada) |  |  | P1 |  |  |  |  |
| Notifikasi | Terima notifikasi perubahan status order | 1. Buat order<br>2. Pastikan ada perubahan status (mis. worker accept / on the way)<br>3. Observasi notifikasi | Notifikasi muncul; tapping notifikasi membuka halaman yang benar |  |  | P1 |  |  |  |  |
| Pembayaran | Tampilkan ringkasan biaya & metode bayar | 1. Buka Order Detail (yang membutuhkan pembayaran)<br>2. Buka section pembayaran | Ringkasan biaya benar; metode bayar dapat dipilih (jika ada) |  |  | P0 |  |  |  |  |
| Rating/Review | Beri rating setelah selesai | 1. Pastikan order selesai<br>2. Buka prompt rating atau Order Detail<br>3. Pilih bintang & isi review (opsional)<br>4. Submit | Rating tersimpan; user melihat konfirmasi; order masuk riwayat |  |  | P1 |  |  |  |  |
| Profil | Edit profil user | 1. Buka Profil<br>2. Tap **Edit**<br>3. Ubah data (nama, foto, dsb.)<br>4. Simpan | Data tersimpan dan tampil setelah refresh/reopen |  |  | P2 |  |  |  |  |
| Alamat | Tambah alamat baru | 1. Buka Profil > Alamat<br>2. Tap **Tambah**<br>3. Isi field wajib<br>4. Simpan | Alamat tersimpan; bisa dipilih saat buat order |  |  | P1 |  |  |  |  |

## UAT — Worker

| Nama Fitur | Skenario Pengujian | Langkah Pengujian | Hasil yang Diharapkan | Hasil Aktual | Status (Pass/Fail) | Priority | Device | OS Version | Tester | Tanggal Test |
|---|---|---|---|---|---|---|---|---|---|---|
| Login | Worker login dengan kredensial valid | 1. Buka aplikasi (mode Worker)<br>2. Masuk halaman Login<br>3. Input akun worker & password valid<br>4. Tap **Login** | Worker berhasil login dan masuk ke dashboard worker |  |  | P0 |  |  |  |  |
| Onboarding Worker | Lengkapi data profil & dokumen (jika ada) | 1. Login worker baru<br>2. Isi data wajib (profil, skill, area layanan)<br>3. Upload dokumen (KTP/sertifikat) bila diperlukan<br>4. Submit | Status onboarding tersimpan; worker bisa lanjut ke fitur sesuai status (aktif/menunggu verifikasi) |  |  | P0 |  |  |  |  |
| Availability | Toggle online/offline | 1. Login<br>2. Buka dashboard worker<br>3. Toggle **Online/Offline** | Saat Online worker bisa menerima order; saat Offline tidak menerima order |  |  | P0 |  |  |  |  |
| Job List | Lihat daftar job masuk | 1. Set Online<br>2. Buka daftar job/requests | Daftar job tampil; setiap item menampilkan ringkas (lokasi, waktu, layanan, estimasi) |  |  | P1 |  |  |  |  |
| Job Detail | Buka detail job | 1. Dari job list tap salah satu job | Detail job tampil lengkap tanpa crash |  |  | P1 |  |  |  |  |
| Accept Job | Terima job yang tersedia | 1. Buka Job Detail status available<br>2. Tap **Accept/Terima**<br>3. Konfirmasi | Status job berubah menjadi accepted; job masuk ke daftar aktif |  |  | P0 |  |  |  |  |
| Reject Job | Tolak job yang tersedia | 1. Buka Job Detail<br>2. Tap **Reject/Tolak**<br>3. Pilih alasan (jika ada)<br>4. Konfirmasi | Job tidak masuk daftar aktif; status sesuai aturan (rejected/expired) |  |  | P2 |  |  |  |  |
| Chat | Worker membuka chat dengan customer dari job | 1. Buka job aktif<br>2. Tap **Chat** | Chat room terbuka; bisa kirim/terima pesan |  |  | P1 |  |  |  |  |
| Progress | Update status “On the way” | 1. Buka job aktif<br>2. Tap status **On the way** / aksi setara | Customer melihat perubahan status; status tersimpan di job detail |  |  | P0 |  |  |  |  |
| Progress | Update status “Start working” | 1. Buka job aktif<br>2. Tap **Start** | Status berubah ke in-progress; timestamp/indicator tampil (jika ada) |  |  | P0 |  |  |  |  |
| Progress | Selesaikan job (Complete) | 1. Buka job in-progress<br>2. Tap **Complete/Selesai**<br>3. Isi laporan/biaya tambahan (jika ada)<br>4. Konfirmasi | Status menjadi completed; job pindah ke riwayat; invoice/summary tampil |  |  | P0 |  |  |  |  |
| Cancel Job | Batalkan job oleh worker (jika diizinkan) | 1. Buka job accepted/in-progress (sesuai aturan sistem)<br>2. Tap **Cancel**<br>3. Pilih alasan<br>4. Konfirmasi | Status menjadi cancelled; customer mendapat notifikasi; konsekuensi diterapkan (jika ada) |  |  | P1 |  |  |  |  |
| Earnings | Lihat ringkasan pendapatan | 1. Login worker<br>2. Buka menu Earnings/Wallet | Ringkasan (saldo, total, periode) tampil; nilai konsisten dengan order selesai |  |  | P1 |  |  |  |  |
| Withdrawal | Ajukan penarikan saldo | 1. Buka Wallet<br>2. Tap **Withdraw**<br>3. Isi nominal & rekening/metode<br>4. Submit | Pengajuan tercatat; status pending/success tampil sesuai proses |  |  | P1 |  |  |  |  |
| Profile Worker | Edit profil worker | 1. Buka Profil<br>2. Edit data (nama, foto, layanan, area)<br>3. Simpan | Data tersimpan dan digunakan pada tampilan publik/marketplace |  |  | P2 |  |  |  |  |
| Riwayat Job | Lihat riwayat job | 1. Buka menu Riwayat/History<br>2. Filter per status/periode (jika ada) | List riwayat tampil benar; detail bisa dibuka |  |  | P2 |  |  |  |  |

