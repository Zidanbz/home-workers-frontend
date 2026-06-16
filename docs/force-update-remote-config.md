# Pembaruan wajib lewat Firebase Remote Config

Panduan ini menjelaskan **cara mengatur** layar “wajib update” di app Android dan **cara membaca angka** di Firebase agar tidak tertukar. Implementasi kode: `lib/core/widgets/app_version_gate.dart`.

---

## Ringkasan

| | |
|--|--|
| **Yang dikontrol dari Firebase** | Build minimum yang masih boleh dipakai (bukan “nomor versi pengguna”). |
| **Kapan pop up muncul** | Jika **build terpasang &lt; nilai** di Remote Config (dan nilai tersebut &gt; 0). |
| **Platform** | Hanya **Android** (Play Store). |
| **Jika gagal fetch** | App **tetap jalan** (tidak diblokir). |

---

## Lokasi di Firebase Console

1. Buka [Firebase Console](https://console.firebase.google.com) → pilih **project yang sama** dengan app (satu sumber dengan `google-services.json` / `firebase_options.dart`).
2. Menu **Build** → **Remote Config** (nama menu bisa sedikit berbeda di UI baru; intinya fitur **Remote Config**).
3. Tambah parameter → **Save** → **Publish changes** (tanpa publish, perangkat tidak dapat nilai baru).

---

## Parameter yang dipakai app

Nama key **harus sama persis** dengan di kode.

### Wajib untuk logika blokir

| Field di form Firebase | Nilai |
|------------------------|--------|
| **Parameter key** | `force_update_min_build_android` |
| **Tipe data** | **Number** (bukan String) |
| **Default value** | `0` |
| **Use in-app default** | **Mati** — isi eksplisit `0` di kolom default agar tim melihat angka yang jelas di konsol. |

**Deskripsi (opsional):**  
*Minimum Android build number. App dengan build di bawah ini wajib update. 0 = fitur paksa update nonaktif.*

### Opsional: teks ke pengguna

| Field | Nilai |
|--------|--------|
| **Parameter key** | `force_update_message` |
| **Tipe data** | **String** |
| **Default value** | Kosongkan atau isi teks Indonesia. Jika kosong, app memakai teks bawaan di kode. |

---

## Arti angka `force_update_min_build_android` (penting)

Angka ini = **build minimum yang masih diizinkan**.

- App membandingkan dengan **build number** dari `pubspec.yaml` — bagian **setelah tanda `+`**, bukan `1.0.2`.

  Contoh: `version: 1.0.2+13` → build yang dipakai logika = **13**.

- Aturan di app: **blokir jika `build terpasang < nilai Remote Config`**.

Jadi ini **bukan** “versi yang ingin kamu targetkan” secara langsung, melainkan **batas bawah build yang lolos**.

### Tabel contoh

| Nilai di Firebase | Build 9 | Build 10 | Build 11 |
|-----------------|---------|----------|----------|
| `0` | Lolos | Lolos | Lolos (tidak paksa update) |
| `10` | **Blokir** | Lolos | Lolos |
| `11` | **Blokir** | **Blokir** | Lolos |

**Kalau mau:** “yang pakai build 10 juga harus update” → set minimum ke **`11`** (karena 10 &lt; 11).

---

## Alur kerja saat rilis versi baru

1. Naikkan **`version`** di `pubspec.yaml` (termasuk angka setelah `+`). Detail: [`version-bump-checklist.md`](version-bump-checklist.md).
2. Build AAB/APK dan unggah ke Play Store seperti biasa.
3. Setelah build baru live, jika ingin memutus pengguna di build lama: di Remote Config, set **`force_update_min_build_android`** ke **build terkecil yang masih boleh** (biasanya = build rilis baru, atau lebih tinggi jika ingin memaksa rentang lebih luas).
4. **Publish** perubahan Remote Config.

Urutan yang aman: rilis dulu ke store, lalu naikkan minimum di Firebase (atau sekaligus, asal build baru sudah tersedia di Play Store).

---

## Uji coba

- Di **debug**, interval fetch Remote Config di app lebih pendek sehingga perubahan di konsol relatif cepat terlihat.
- Di **release**, ada jeda cache (sekitar satu jam); untuk verifikasi cepat, ubah nilai + **publish** lagi atau tunggu refresh.

Contoh tes internal: build app saat ini misalnya **13**, sementara di Firebase set **14** → app harus menampilkan layar wajib update. Setelah tes, kembalikan ke **`0`** atau nilai produksi.

---

## Referensi di repo

| Topik | File |
|--------|------|
| Kode gate versi | `lib/core/widgets/app_version_gate.dart` |
| Pemasangan di app | `lib/main.dart` (`AppVersionGate` membungkus `AuthWrapper`) |
| Konteks arsitektur | [`environment-and-mandatory-update.md`](environment-and-mandatory-update.md) |
| Naikkan versi / build | [`version-bump-checklist.md`](version-bump-checklist.md) |

---

## Checklist cepat untuk tim baru

- [ ] Project Firebase = project yang sama dengan app.
- [ ] Parameter **`force_update_min_build_android`** ada, tipe **Number**, default **`0`** sampai sengaja dipakai.
- [ ] **Publish** setelah mengubah nilai.
- [ ] Angka di Firebase = **minimum build yang lolos** (angka setelah `+` di `pubspec`), bukan semver `1.0.x` saja.
