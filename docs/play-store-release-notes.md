# Panduan catatan rilis Google Play Store

Dokumen ini mengatur **nama rilis**, **penamaan**, dan **format teks** yang dipakai di **Play Console** (nama rilis di dasbor rilis dan kolom catatan publik / “What’s new”), selaras dengan praktik tim.

## Beda dengan changelog internal

| | `docs/changelog` (internal) | Catatan Play Store |
|---|-----------------------------|---------------------|
| Pembaca | Developer, QA | Pengguna akhir |
| Isi | Added / Changed / Fixed, detail teknis boleh | Manfaat singkat, bahasa sehari-hari |
| Format | Satu file per tanggal | Teks per bahasa di Play Console |

Gunakan changelog sebagai sumber kebenaran, lalu **ringkas dan ubah tonenya** sebelum tempel ke Play Console.

## Nama rilis

**Nama rilis** di Play Console adalah label untuk **mengenali rilis di dasbor** (Production / testing track). Biasanya **tidak tampil ke pengguna** di halaman toko; yang pengguna lihat adalah **versi** aplikasi dan **catatan rilis** per bahasa.

- **Fungsi**: membedakan build di Play Console, mencocokkan dengan tag Git / `version` di `pubspec`, dan komunikasi singkat antar tim.
- **Batas panjang**: ikuti petunjuk di formulir (umumnya pendek; hindari teks panjang).
- **Disarankan konsisten** dengan salah satu pola berikut (pilih satu untuk seluruh proyek):

| Pola | Contoh | Cocok jika |
|------|--------|------------|
| Versi semver + tanggal | `1.4.2 — 2026-04-11` | ingin jejak waktu jelas |
| Versi + tema singkat | `1.4.2 — perbaikan login` | satu tema utama rilis |
| Hanya versi | `1.4.2` | minimal, versi sudah unik |

Hindari nama yang hanya berisi kode internal (`fix/HW-99`) tanpa versi; gabungkan jika perlu: `1.4.2 — HW-99 checkout`.

## Batasan di Play Console

- Panjang catatan rilis **per bahasa** dibatasi (umumnya sekitar **500 karakter**; cek petunjuk di layar saat mengisi formulir rilis).
- Jika mendukung beberapa bahasa, siapkan teks terpisah per bahasa dengan batas yang sama.
- Rilis bertahap (staged rollout) memakai **catatan rilis yang sama** untuk semua persentase rollout kecuali Anda mengubahnya manual di rilis berikutnya.

## Kategori dan kapan memakainya

Gunakan label konsisten agar pengguna cepat memindai isi rilis.

| Kategori | Kapan dipakai | Contoh inti |
|----------|----------------|-------------|
| **Perbaikan** | Bug, crash, data salah, alur gagal | “Memperbaiki error saat …” |
| **Fitur baru** | Kemampuan baru yang terlihat atau bisa dipilih pengguna | “Menambahkan …” |
| **Peningkatan** | Kinerja, kecepatan, penggunaan data, stabilitas tanpa fitur baru | “Mempercepat …”, “Mengurangi …” |
| **Keamanan** | Otentikasi, izin, privasi, pembaruan dependensi keamanan | “Memperkuat …” |
| **Antarmuka** | Tata letak, teks, ikon, aksesibilitas, alur UI | “Mempermudah …”, “Tampilan … lebih jelas” |

Satu poin bisa masuk satu kategori utama; jika campuran (misalnya fitur + perbaikan), pisah menjadi dua bullet.

## Gaya penulisan

- **Kalimat aktif**, subjek jelas (misalnya “Aplikasi sekarang …”, “Anda dapat …”).
- **Satu bullet = satu ide**; hindari paragraf panjang.
- Fokus **manfaat pengguna**, bukan implementasi (tanpa nama library, tanpa ID ticket/Jira/Git).
- Hindari jargon internal (“refactor”, “endpoint”, “schema”) kecuali memang istilah yang dipakai di UI aplikasi.

## Format bullet (pilih satu gaya untuk tim)

**Gaya A — prefix kategori (disarankan untuk konsistensi cepat)**

```text
• [Perbaikan] …
• [Fitur baru] …
• [Peningkatan] …
```

**Gaya B — heading pendek + bullet**

```text
Perbaikan
• …
• …

Fitur baru
• …
```

Gaya A lebih hemat karakter untuk batas 500; Gaya B lebih terbaca jika item sedikit.

## Template siap tempel (sesuaikan isi)

```text
• [Perbaikan] Memperbaiki masalah saat [aksi pengguna] di [layar/modul].
• [Fitur baru] Menambahkan [fitur] agar Anda bisa [manfaat].
• [Peningkatan] Mempercepat [proses] dan mengurangi [masalah pengguna].
```

## Alur kerja singkat

1. Update `docs/changelog` untuk rilis yang sama (internal).
2. Tentukan **nama rilis** di Play Console sesuai pola tim (biasanya sama dengan `versionName` / semver rilis ini).
3. Pilih poin yang **layak diketahui pengguna**; gabungkan atau buang detail teknis.
4. Tulis catatan Play dalam **Bahasa Indonesia** (dan bahasa lain jika listing mendukung).
5. Hitung karakter; potong bullet paling tidak penting jika melebihi batas.
6. Isi nama rilis + catatan rilis pada langkah **Production** / **Testing** sesuai saluran rilis Anda.

## Referensi

- Changelog internal: [docs/changelog/README.md](changelog/README.md)
