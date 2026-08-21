# Auth Katalog App

Aplikasi Flutter berisi autentikasi dengan refresh token dan katalog produk,
memakai API [DummyJSON](https://dummyjson.com).

---

## Cara menjalankan

Butuh Flutter **3.44.2** (stable) atau lebih baru.

```sh
# 1. Dependency
flutter pub get

# 2. Konfigurasi — WAJIB, lihat catatan di bawah
cp .env.example .env
# lalu isi APP_API_BASE_URL=https://dummyjson.com

# 3. Code generation — WAJIB, lihat catatan di bawah
dart run build_runner build --delete-conflicting-outputs

# 4. Jalankan
flutter run
```

Verifikasi:

```sh
flutter analyze     # harus: No issues found!
flutter test        # harus: All tests passed!  (62 test)
```

### Dua langkah yang tidak boleh dilewat

Keduanya gitignored, jadi setelah `git clone` project ini **belum bisa
dikompilasi** sampai langkah 2 dan 3 dijalankan.

| Dilewat                         | Yang terjadi                                                                                  |
| ------------------------------- | --------------------------------------------------------------------------------------------- |
| `.env` tidak dibuat             | `Error: Failed to build asset bundle` — `pubspec.yaml` mendaftarkan `.env` sebagai asset      |
| `build_runner` tidak dijalankan | ±90 error analyzer — Freezed, JSON, dan Retrofit belum punya file `.g.dart` / `.freezed.dart` |

Kredensial untuk mencoba login diambil dari
[daftar user DummyJSON](https://dummyjson.com/users), misalnya `emilys` /
`emilyspass`.

---

## Cara kerja single-flight refresh

Ini bagian inti aplikasi. Seluruhnya ada di
[`lib/core/network/auth_interceptor.dart`](lib/core/network/auth_interceptor.dart).

Login memakai `expiresInMins: 1` **dengan sengaja**, supaya access token cepat
kedaluwarsa dan jalur refresh benar-benar terpakai saat aplikasi dipakai.

### Proteksi bersifat opt-in

Interceptor tidak menebak endpoint mana yang butuh token dari pola URL.
Penandaannya eksplisit di kontrak Retrofit:

```dart
@GET('/auth/me')
@Extra(<String, Object>{RequestMetadata.requiresAuthentication: true})
Future<UserResponseModel> getCurrentUser();
```

`GET /products` tidak punya anotasi itu, sehingga interceptor melewatinya begitu
saja — endpoint publik tidak pernah ikut memicu refresh.

### Mekanismenya: satu field

```dart
Future<TokenPair>? _refreshInFlight;

Future<TokenPair> _refreshSingleFlight() async {
  final active = _refreshInFlight;
  if (active != null) return active;   // request berikutnya menumpang Future yang sama

  final refresh = _performRefresh();
  _refreshInFlight = refresh;
  try {
    return await refresh;
  } finally {
    if (identical(_refreshInFlight, refresh)) _refreshInFlight = null;
  }
}
```

Saat tiga request protected kena `401` bersamaan:

```
req1 ─┐
req2 ─┼─► _refreshSingleFlight()
req3 ─┘
        req1 masuk lebih dulu → membuat Future, menyimpannya ke _refreshInFlight
        req2 & req3           → melihat slot terisi → await Future YANG SAMA
              │
        POST /auth/refresh  ← dipanggil TEPAT satu kali
              │
        TokenStorage.write(token baru)
              │
        ketiganya di-retry dengan token baru → 200
```

### Tiga detail yang menentukan benar atau tidaknya

1. **`refreshDioProvider` adalah instance Dio terpisah, tanpa `AuthInterceptor`.**
   Kalau `/auth/refresh` dipanggil dengan Dio yang sama, respons `401` darinya
   akan memicu refresh lagi — loop tak berujung.
2. **Flag `authenticationRetried`** disimpan di `RequestOptions.extra`, mencegah
   request yang sudah di-retry mencoba refresh untuk kedua kalinya.
3. **`identical()` di blok `finally`** memastikan hanya Future yang bersangkutan
   yang membersihkan slot, sehingga refresh baru yang keburu dimulai tidak
   ikut terhapus.

### Kalau refresh gagal

```
_performRefresh() gagal
   ├─ TokenStorage.clear()
   └─ SessionEvents.notifyExpired()      ← StreamController broadcast
         │
   AuthController mendengarkan stream itu → state = AsyncData(false)
         │
   GoRouter redirect → /login
```

Interceptor **tidak mengenal router maupun Riverpod** — ia hanya menyiarkan
event. Itu sebabnya ia bisa diuji murni dengan `Dio` dan `mocktail`, tanpa satu
pun widget.

### Buktinya

```
test/core/network/auth_interceptor_test.dart
  ✓ 3 concurrent 401 responses trigger one refresh and all retry
  ✓ concurrent failed refresh clears and emits expiration once
  ✓ public 401 does not attach bearer or trigger refresh
```

Test pertama mengasserikan sekaligus: ketiga respons `200`, tiga request sukses
di adapter, `refresh` dipanggil **tepat satu kali**, dan token baru tersimpan.

---

## Keputusan arsitektur

### Clean Architecture, feature-first

```
lib/
├─ app/          bootstrap, MaterialApp, GoRouter
├─ core/         infrastruktur lintas fitur (network, storage, error, formatter)
└─ features/
   ├─ auth/      data · domain · di · presentation
   ├─ product/   data · domain · di · presentation
   ├─ profile/   presentation
   └─ home/      presentation (hanya komposisi halaman)
```

Ketergantungannya satu arah: `presentation → domain ← data`. Widget hanya
bergantung pada controller; parsing JSON, HTTP, dan persistensi token tidak
pernah muncul di layer presentation.

### Keputusan dan alasannya

| Keputusan                               | Alasan                                                                                                                                                                                                                              |
| --------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Riverpod** untuk state sekaligus DI   | Provider adalah objek global, sehingga ketiadaannya ketahuan saat kompilasi, bukan runtime. Substitusi untuk test cukup lewat `overrideWithValue`.                                                                                  |
| **Dio + Retrofit**                      | Retrofit membuat kontrak API menjadi tipe, dan `@Extra` memberi tempat alami untuk menandai endpoint yang butuh autentikasi.                                                                                                        |
| **Freezed + json_serializable**         | Model wire imutabel dengan `copyWith` dan kesetaraan nilai gratis. Model API tidak pernah bocor ke UI — selalu dipetakan ke entity di repository.                                                                                   |
| **`Either<Failure, T>`** (dartz)        | Kegagalan yang terduga menjadi bagian dari tipe kembalian, bukan exception yang lolos diam-diam. `sealed class Failure` membedakan `NoInternetFailure` dari `ServerFailure`, sehingga UI bisa memberi pesan berbeda.                |
| **`flutter_secure_storage`**            | Token tidak pernah menyentuh `SharedPreferences` maupun memori proses saja. Logout menghapus dua key spesifik, bukan `deleteAll()`.                                                                                                 |
| **GoRouter dengan redirect deklaratif** | Router tidak pernah memanggil API. `authRedirect()` adalah fungsi murni `(AsyncValue<bool>, String) → String?`, sehingga bisa diuji tanpa widget.                                                                                   |
| **Dua controller untuk auth**           | `AuthController` menyatakan _punya sesi atau tidak_, `LoginController` menyatakan _submit sedang loading atau error_. Kalau digabung, login yang gagal akan membuat router melempar user ke Splash padahal ia hanya salah password. |
| **File generated gitignored**           | Menghindari konflik merge pada file yang bisa dihasilkan ulang. Konsekuensinya `build_runner` menjadi langkah wajib, termasuk di CI.                                                                                                |
| **Logger Dio sengaja buta**             | `SafeDioLogger` hanya mencetak method dan URL — tidak pernah header atau body, sehingga token dan password tidak bocor ke logcat.                                                                                                   |

### Penanganan state yang membedakan level kegagalan

Kegagalan tidak diperlakukan seragam:

- Gagal **sebelum ada data** → `AsyncError` → layar error penuh dengan "Coba Lagi"
- Gagal **setelah ada data** (paginasi/refresh) → banner di bawah grid, produk
  yang sudah ter-scroll **tetap terlihat**

Katalog dan profil sengaja berbeda di sini: `CatalogController` menyimpan
`isRefreshing` di dalam state supaya daftar produk tidak hilang saat refresh,
sementara `ProfileController` melewati `AsyncLoading` supaya tarik-refresh
menampilkan shimmer. Kehilangan satu objek profil murah; kehilangan daftar
produk yang sudah di-scroll jauh lebih mahal.

### Testing

62 test di 14 file, mencakup interceptor, repository, controller, router,
formatter, dan widget.

Beberapa test sengaja diverifikasi **gagal** lebih dulu tanpa perbaikannya, agar
terbukti benar-benar menguji sesuatu — antara lain guard retry paginasi, banner
error yang mempertahankan produk, tinggi tile terhadap `textScaler`, dan shimmer
saat tarik-refresh.

---

## Continuous integration

[`.github/workflows/ci.yml`](.github/workflows/ci.yml) berjalan pada setiap push
dan pull request ke `main`:

1. `flutter pub get`
2. tulis `.env` — dari secret `APP_API_BASE_URL`, dengan fallback
   `https://dummyjson.com` supaya fork dan clone tanpa secret tetap lolos
3. `dart run build_runner build --delete-conflicting-outputs`
4. `dart format --set-exit-if-changed` hanya untuk file tulisan tangan
5. `flutter analyze`
6. `flutter test`

Langkah 2 dan 3 ada karena `.env` dan file generated gitignored. Menghapus salah
satunya membuat seluruh langkah berikutnya gagal.

---

## Waktu pengerjaan

Dikerjakan pada **20–21 Agustus 2026**.

---

## Kalau ada waktu lebih

Diurutkan berdasarkan manfaat, bukan besarnya usaha.

### Fungsional

1. **Integration test untuk refresh sungguhan.** Test single-flight saat ini
   memakai mock adapter. Yang belum ada adalah test yang benar-benar menunggu
   lebih dari satu menit hingga token asli kedaluwarsa, lalu memicu fetch
   protected. Itu satu-satunya cara membuktikan alurnya utuh melawan API nyata.
2. **Dark theme.** `ColorScheme.fromSeed(brightness: dark)` sudah hampir cukup
   karena seluruh warna melewati `Theme.of(context)` — kecuali beberapa warna
   yang masih hardcoded di shimmer dan `errorWidget`.
3. **Animasi transisi halaman.** Sekarang masih memakai transisi bawaan
   GoRouter/Material. `CustomTransitionPage` dengan shared-element pada gambar
   produk akan terasa jauh lebih halus.

### Teknis

4. **Ganti `dartz` dengan `fpdart`.** `dartz` sudah lama tidak dirawat.
   `fpdart` aktif dan API-nya lebih modern. Perpindahannya mekanis karena
   pemakaian `Either` sudah terkurung di batas repository.
5. **Riverpod codegen (`@riverpod`).** Sudah dicoba dan **terblokir upstream**,
   bukan sekadar belum sempat. `riverpod_generator` terbaru menuntut
   `analyzer ^13`, sedangkan `freezed 3.2.5` — versi stabil terakhir — mengunci
   `analyzer >=9 <11`. Menaikkan `freezed` ke `4.0.0-dev` juga gagal karena
   bentrok dengan `build_runner` dan `test` bawaan SDK Flutter.

   Satu kombinasi memang berhasil resolve (`riverpod_generator 4.0.4` +
   `riverpod_annotation 4.0.3`), tetapi menyeret `freezed 3.2.6-dev.1` dan
   `riverpod_analyzer_utils 1.0.0-dev.10` — dua dependency prerelease — hanya
   demi menghemat sedikit boilerplate pada 24 provider yang cuma memakai satu
   `family`.

6. **`flutter build apk --debug` di CI.** Belum ditambahkan karena
   `compileSdk = 37` (workaround `flutter_secure_storage` 11) belum terverifikasi
   tersedia di runner `ubuntu-latest` tanpa langkah instalasi Android SDK
   tambahan.
