# Camera Tracking GPS

Aplikasi Flutter untuk **mengambil foto sekaligus merekam lokasi GPS dan alamat**, kemudian menyimpan data tracking secara lokal pada perangkat. Project ini menggunakan pendekatan **feature-first + layered architecture**, dengan Riverpod sebagai state management dan pemisahan antara domain, data, serta presentation.

> **Status:** Functional core + UI skeleton untuk beberapa fitur lanjutan  
> **Platform utama:** Android  
> **Framework:** Flutter  
> **Language:** Dart  
> **Package:** `camera_tracking_gps`  
> **Version:** `1.0.0+1`

urlRepository GitHubhttps://github.com/alfajauhari068/camera_tracking-app

---

## 1. Gambaran Umum

**Camera Tracking GPS** dirancang untuk menghasilkan sebuah record tracking setiap kali pengguna mengambil foto.

Satu record tracking menyimpan:

- ID tracking
- path file foto
- latitude
- longitude
- alamat hasil reverse geocoding
- akurasi GPS
- timestamp pengambilan

Struktur entity `Tracking` pada project memang merepresentasikan keenam informasi tersebut. fileciteturn35file0

Alur inti aplikasi adalah:

```text
Pengguna
   │
   ▼
Request Camera + Location Permission
   │
   ▼
Camera Preview
   │
   ▼
Capture Photo
   │
   ├──────────────► GPS Location
   │                       │
   │                       ▼
   │                 Reverse Geocoding
   │                       │
   └───────────────┬───────┘
                   ▼
            Create Tracking
                   │
                   ▼
          Simpan ke tracking.json
                   │
                   ▼
          Gallery / Detail / Map
```

Implementasi use case `CaptureTracking` menjalankan proses kamera → lokasi → geocoding → pembuatan entity → penyimpanan secara berurutan. Aplikasi juga menggunakan concurrency guard agar dua proses capture tidak berjalan bersamaan. fileciteturn44file0

---

## 2. Fitur

### Fitur yang sudah memiliki implementasi utama

- 📷 Inisialisasi kamera dan live camera preview.
- 📸 Pengambilan foto dari kamera.
- 📍 Pengambilan koordinat GPS.
- 🗺️ Reverse geocoding koordinat menjadi alamat.
- 💾 Penyimpanan metadata tracking secara lokal dalam JSON.
- 🔎 Pencarian data pada Gallery berdasarkan alamat atau tanggal.
- 🖼️ Gallery berbentuk grid.
- 🧾 Detail metadata tracking.
- 🔐 Penanganan permission kamera dan lokasi.
- ⚠️ Error handling dengan tipe failure khusus.
- 🧠 State management menggunakan Riverpod.
- 🧩 Repository/use-case abstraction untuk memisahkan business logic dari storage dan service konkret.

`CaptureScreen` memiliki state flow yang jelas: `ready → initializingCamera → previewReady → capturingPhoto → complete`, termasuk state error dan retry. fileciteturn38file0 fileciteturn43file0

### Fitur yang masih berupa skeleton / placeholder

Beberapa halaman sudah tersedia dan dapat dinavigasikan, tetapi implementasinya belum sepenuhnya selesai:

- 🗺️ **Map View** — data marker dan pemilihan tracking sudah disiapkan, tetapi widget peta nyata belum terintegrasi; halaman saat ini masih menggunakan map placeholder. fileciteturn40file0
- 📤 **Export Data** — UI filter tanggal dan pilihan CSV/XLSX/PDF/JSON tersedia, tetapi proses export sebenarnya masih berupa simulasi dan ditandai TODO pada source code. fileciteturn39file0
- 🖼️ **Photo Detail** — metadata sudah ditampilkan, tetapi preview gambar pada halaman detail masih berupa placeholder icon; integrasi pembacaan `imagePath` perlu diselesaikan. fileciteturn48file0
- 🔗 Beberapa alur navigasi sudah disiapkan untuk menerima `Tracking` object atau ID, tetapi sebagian integrasi lanjutan masih berstatus TODO. fileciteturn31file0

Dengan demikian, repository **jangan dideskripsikan sebagai aplikasi tracking GPS yang seluruh fiturnya sudah production-ready**. Core capture dan local persistence sudah dibangun, sedangkan map, export, dan sebagian detail media masih dalam tahap penyempurnaan.

---

## 3. Arsitektur

Project menggunakan struktur **feature-first** dengan pemisahan layer:

```text
lib/
├── core/
│   └── error/
│       ├── failures.dart
│       └── result.dart
│
├── features/
│   └── tracking/
│       ├── data/
│       │   ├── datasources/
│       │   ├── models/
│       │   ├── repositories/
│       │   └── services/
│       │
│       ├── domain/
│       │   ├── entities/
│       │   ├── fakes/
│       │   ├── repositories/
│       │   ├── services/
│       │   └── usecases/
│       │
│       └── presentation/
│           ├── models/
│           ├── pages/
│           ├── widgets/
│           ├── capture_screen.dart
│           └── providers.dart
│
├── main.dart
└── routes.dart
```

Struktur repository secara eksplisit memisahkan `data`, `domain`, dan `presentation`, dengan `tracking` sebagai feature utama aplikasi. fileciteturn24file0 fileciteturn26file0

### Dependency flow

```text
Presentation
    │
    ▼
Riverpod Providers
    │
    ▼
Domain Use Cases
    │
    ▼
Domain Repository Interface
    │
    ▼
Data Repository Implementation
    │
    ├── Local Data Source
    └── Real Services
```

Provider configuration menghubungkan concrete implementation untuk kamera, lokasi, geocoding, permission, logger, time provider, ID generator, repository, dan use case. fileciteturn43file0

---

## 4. Teknologi dan Dependency

Berdasarkan `pubspec.yaml`, project menggunakan:

| Teknologi / Package | Peran |
|---|---|
| Flutter | Framework aplikasi |
| Dart SDK `^3.11.4` | Bahasa pemrograman/runtime |
| `camera` | Camera preview dan pengambilan foto |
| `geolocator` | Pengambilan lokasi GPS |
| `geocoding` | Reverse geocoding koordinat menjadi alamat |
| `permission_handler` | Pengelolaan permission perangkat |
| `path_provider` | Menentukan direktori penyimpanan aplikasi |
| `flutter_riverpod` | State management dan dependency injection |
| `cupertino_icons` | Icon Cupertino |
| `flutter_lints` | Static analysis/linting |
| `flutter_test` | Testing Flutter |

Dependency tersebut terdaftar langsung pada `pubspec.yaml`. fileciteturn23file0

---

## 5. Alur Capture

Proses capture merupakan bagian paling matang dari aplikasi.

### Tahap 1 — Permission

Aplikasi meminta permission:

- Camera
- Location

Jika permission ditolak permanen, pengguna diberikan opsi untuk membuka App Settings. fileciteturn38file0

### Tahap 2 — Camera Preview

Setelah permission berhasil, kamera diinisialisasi dan preview ditampilkan menggunakan `CameraPreview`.

### Tahap 3 — Capture

Ketika pengguna menekan **Capture Photo**, use case menjalankan:

```text
Camera
  ↓
Take Picture
  ↓
Get GPS
  ↓
Reverse Geocode
  ↓
Generate ID
  ↓
Create Tracking
  ↓
Save Tracking
```

Lokasi memiliki timeout 10 detik, sedangkan geocoding memiliki timeout 5 detik. Project menggunakan strict mode untuk proses geocoding: kegagalan geocoding menyebabkan keseluruhan capture gagal dan tidak menyimpan partial record. fileciteturn44file0

### Tahap 4 — Result

Jika berhasil, pengguna mendapatkan informasi:

- ID
- alamat
- latitude/longitude
- akurasi
- waktu capture

fileciteturn38file0

---

## 6. Penyimpanan Data

Aplikasi saat ini menggunakan **local JSON storage**, bukan database server.

File data utama:

```text
tracking.json
```

File tersebut ditempatkan pada application documents directory menggunakan `path_provider`. Data dibaca dan ditulis sebagai JSON array. Operasi yang tersedia pada local data source meliputi:

- `getAll()`
- `save()`
- `getById()`
- `delete()`

fileciteturn33file0

Secara konseptual:

```text
Flutter App
    │
    ▼
TrackingRepository
    │
    ▼
TrackingLocalDataSource
    │
    ▼
path_provider
    │
    ▼
tracking.json
```

### Implikasi

Pendekatan JSON cocok untuk aplikasi lokal sederhana dan prototype, tetapi memiliki keterbatasan jika jumlah data semakin besar atau membutuhkan query kompleks. Untuk skala lebih besar, storage dapat dikembangkan ke SQLite/Drift/Isar atau database lain sesuai kebutuhan.

---

## 7. Data Tracking

Model domain utama adalah `Tracking`:

```dart
class Tracking {
  final String id;
  final String imagePath;
  final double latitude;
  final double longitude;
  final String address;
  final double accuracy;
  final DateTime timestamp;
}
```

fileciteturn35file0

Contoh representasi data secara konseptual:

```json
{
  "id": "...",
  "imagePath": "...",
  "latitude": -8.123456,
  "longitude": 111.123456,
  "address": "...",
  "accuracy": 5.2,
  "timestamp": "2026-04-27T..."
}
```

---

## 8. Navigasi Aplikasi

Routing dipusatkan pada `lib/routes.dart`.

| Route | Halaman | Fungsi |
|---|---|---|
| `/` | HomePage | Dashboard utama |
| `/camera` | CaptureScreen | Capture foto + GPS |
| `/gallery` | GalleryPage | Daftar foto/tracking |
| `/detail` | PhotoDetailPage | Detail foto + metadata |
| `/map` | MapPage | Tampilan lokasi |
| `/export` | ExportPage | Export/share data |

`main.dart` menjalankan `ProviderScope`, menggunakan `MaterialApp`, dan mengatur `/` sebagai initial route. fileciteturn30file0 fileciteturn31file0

Routing juga menyediakan helper `navigateTo`, `replaceWith`, dan `popUntilRoute`, serta dukungan argument `String` atau `Tracking` pada route detail melalui `onGenerateRoute`. fileciteturn31file0

---

## 9. Android Permissions

Android Manifest mendeklarasikan permission untuk:

- `ACCESS_FINE_LOCATION`
- `ACCESS_COARSE_LOCATION`
- `CAMERA`
- `READ_EXTERNAL_STORAGE`
- `WRITE_EXTERNAL_STORAGE`
- `POST_NOTIFICATIONS`
- `READ_MEDIA_IMAGES`

fileciteturn41file0

### Catatan

Permission storage/media perlu disesuaikan dengan versi Android target dan kebutuhan aktual aplikasi. Jangan mempertahankan permission yang tidak diperlukan hanya karena template lama menyediakannya.

---

## 10. Google Maps API Key

Android Manifest menggunakan placeholder:

```xml
${GOOGLE_MAPS_API_KEY}
```

Nilainya diambil dari `local.properties` melalui konfigurasi Gradle dan disuntikkan ke `manifestPlaceholders`. fileciteturn41file0 fileciteturn42file0

Contoh konfigurasi lokal:

```properties
GOOGLE_MAPS_API_KEY=YOUR_API_KEY
```

> Jangan commit API key asli ke repository publik.

**Catatan penting:** pada kondisi source code saat ini, halaman Map masih menggunakan placeholder dan dependency peta aktual belum terlihat terintegrasi pada `pubspec.yaml`. Jadi konfigurasi API key tersebut merupakan fondasi untuk integrasi map, bukan bukti bahwa Google Maps sudah aktif di UI. fileciteturn23file0 fileciteturn40file0

---

## 11. Instalasi

### Prasyarat

Pastikan telah terpasang:

- Flutter SDK yang mendukung Dart `3.11.4`.
- Android Studio atau Android SDK.
- Android device/emulator.
- Git.
- JDK yang sesuai dengan konfigurasi Android/Flutter.

### Clone repository

```bash
git clone https://github.com/alfajauhari068/camera_tracking-app.git
cd camera_tracking-app
```

### Install dependencies

```bash
flutter pub get
```

### Cek environment

```bash
flutter doctor
```

### Jalankan aplikasi

```bash
flutter run
```

Untuk melihat device yang tersedia:

```bash
flutter devices
```

---

## 12. Konfigurasi Android Lokal

Jika menggunakan Google Maps API key, tambahkan key ke:

```text
android/local.properties
```

Contoh:

```properties
sdk.dir=C:\\Users\\USERNAME\\AppData\\Local\\Android\\Sdk
GOOGLE_MAPS_API_KEY=YOUR_API_KEY
```

**Jangan memasukkan file `local.properties` ke Git.** File tersebut seharusnya tetap lokal dan biasanya sudah dikecualikan oleh `.gitignore` Flutter.

---

## 13. Menjalankan Test dan Static Analysis

Jalankan analyzer:

```bash
flutter analyze
```

Jalankan test:

```bash
flutter test
```

Jika ingin menjalankan keduanya sebagai pemeriksaan dasar:

```bash
flutter analyze && flutter test
```

---

## 14. Build Android

### Debug APK

```bash
flutter build apk --debug
```

### Release APK

```bash
flutter build apk --release
```

### App Bundle

```bash
flutter build appbundle --release
```

> Untuk distribusi production, konfigurasi signing release harus dibuat sendiri. Source saat ini masih menggunakan debug signing untuk release build. fileciteturn42file0

---

## 15. Struktur Direktori

```text
camera_tracking-app/
├── android/                  # Konfigurasi Android
├── ios/                      # Konfigurasi iOS
├── linux/                    # Konfigurasi Linux
├── macos/                    # Konfigurasi macOS
├── web/                      # Konfigurasi Web
├── windows/                  # Konfigurasi Windows
│
├── lib/
│   ├── core/
│   │   └── error/
│   │
│   ├── features/
│   │   └── tracking/
│   │       ├── data/
│   │       ├── domain/
│   │       └── presentation/
│   │
│   ├── main.dart
│   └── routes.dart
│
├── test/
├── analysis_options.yaml
├── pubspec.yaml
├── pubspec.lock
└── README.md
```

---

## 16. Detail Layer

### `domain`

Berisi business rules dan abstraction yang tidak bergantung langsung pada framework/platform.

Contoh:

```text
domain/
├── entities/
├── repositories/
├── services/
├── usecases/
└── fakes/
```

Struktur tersebut terlihat langsung pada feature `tracking`. fileciteturn28file0

### `data`

Berisi implementasi konkret:

```text
data/
├── datasources/
├── models/
├── repositories/
└── services/
```

Local data source dan service nyata berada pada layer ini. fileciteturn27file0

### `presentation`

Berisi:

- pages
- widgets
- providers
- state capture
- UI model

fileciteturn29file0

---

## 17. Error Handling

Project memiliki abstraction `Failure` dan `Result` pada `core/error` untuk mengontrol error flow.

Jenis kegagalan yang ditangani pada use case mencakup antara lain:

- camera failure
- location failure
- location timeout
- geocoding failure
- geocoding timeout
- storage failure
- permission denied forever
- generic failure

`CaptureTracking` mengembalikan `Result<Tracking>` sehingga kegagalan capture tidak harus dilempar sebagai exception sampai ke UI. fileciteturn44file0

---

## 18. State Management

State management menggunakan **Riverpod**.

Provider utama mencakup dependency untuk:

```text
Logger
TimeProvider
PermissionService
IdGenerator
CameraService
LocationService
GeocodingService
TrackingLocalDataSource
TrackingRepository
CaptureTracking
CaptureNotifier
```

fileciteturn43file0

Pendekatan ini membuat implementation konkret dapat diganti dengan fake/mock pada testing tanpa mengubah business logic utama.

---

## 19. Kondisi Fitur Saat Ini

| Fitur | Kondisi | Catatan |
|---|---|---|
| Camera permission | ✅ | Ditangani oleh permission service |
| Location permission | ✅ | Ditangani sebelum capture |
| Camera preview | ✅ | `CameraPreview` |
| Capture photo | ✅ | Menggunakan package `camera` |
| GPS | ✅ | Menggunakan `geolocator` |
| Reverse geocoding | ✅ | Menggunakan `geocoding` |
| Local persistence | ✅ | JSON di application documents directory |
| Gallery | ✅ | Grid + search + provider |
| Photo metadata | ✅ | Timestamp, koordinat, alamat, akurasi, ID |
| Map UI | ⚠️ Skeleton | Belum memakai map widget nyata |
| Export CSV | ⚠️ Skeleton | Belum ada generator file nyata |
| Export XLSX | ⚠️ Skeleton | Belum ada generator file nyata |
| Export PDF | ⚠️ Skeleton | Belum ada generator file nyata |
| Export JSON | ⚠️ Skeleton | UI tersedia, logic belum selesai |
| Real image preview detail | ⚠️ Belum selesai | Masih placeholder |
| Release signing | ⚠️ Belum production-ready | Masih debug signing |

Status skeleton routing dan next steps juga didokumentasikan dalam repository sendiri. fileciteturn46file0

---

## 20. Batasan yang Perlu Diketahui

1. **Storage masih lokal JSON.** Data tidak otomatis tersinkron ke server/cloud.
2. **Map belum terintegrasi penuh.** UI map masih placeholder.
3. **Export belum benar-benar menghasilkan file.** Halaman export masih melakukan simulasi proses.
4. **Photo detail masih menggunakan placeholder image.** `imagePath` belum digunakan untuk menampilkan foto nyata pada halaman detail.
5. **Geocoding membutuhkan layanan platform/network yang sesuai.** Kegagalan atau timeout geocoding membuat capture gagal karena use case menggunakan strict mode.
6. **Data lokasi bersifat sensitif.** File foto dan koordinat dapat mengungkap lokasi pengguna dan harus diperlakukan sebagai data sensitif.
7. **Release Android belum siap distribusi production** sampai signing configuration diganti dari debug signing.

---

## 21. Privasi dan Keamanan Data

Aplikasi menangani data yang dapat mengidentifikasi lokasi pengguna:

- foto;
- latitude/longitude;
- alamat;
- timestamp.

Karena itu:

- jangan membagikan `tracking.json` sembarangan;
- jangan memasukkan foto/lokasi pengguna ke repository;
- jangan commit API key;
- batasi permission hanya sesuai kebutuhan;
- pertimbangkan enkripsi storage jika aplikasi digunakan untuk data sensitif;
- jika suatu saat ditambahkan backend, gunakan HTTPS dan authentication.

README ini mendokumentasikan source code dan bukan pengganti penetration test atau privacy impact assessment.

---

## 22. Pengembangan Berikutnya

Prioritas pengembangan berdasarkan kondisi source saat ini:

### Prioritas 1 — Selesaikan Map

Integrasikan salah satu:

- `google_maps_flutter`, atau
- `flutter_map`.

Kemudian:

- tampilkan marker berdasarkan latitude/longitude;
- implementasikan marker selection;
- animate camera ke lokasi terpilih;
- gunakan API key hanya jika provider map membutuhkannya.

### Prioritas 2 — Selesaikan Photo Detail

Ganti placeholder image dengan pembacaan `Tracking.imagePath`, termasuk penanganan file yang sudah tidak tersedia.

### Prioritas 3 — Selesaikan Export

Implementasikan use case export yang benar-benar:

```text
Tracking Data
     ↓
Filter Date
     ↓
Transform
     ↓
Generate CSV/XLSX/PDF/JSON
     ↓
Save File
     ↓
Share / Open
```

### Prioritas 4 — Testing

Tambahkan unit test untuk:

- `CaptureTracking`;
- repository;
- local datasource;
- geocoding failure/timeout;
- location timeout;
- ID generator;
- filter Gallery;
- export use case.

### Prioritas 5 — Production Readiness

- release signing;
- permission review berdasarkan Android version;
- secure API key restrictions;
- privacy policy bila didistribusikan publik;
- crash/error monitoring;
- backup/export strategy;
- storage migration jika volume data meningkat.

---

## 23. Dokumentasi Internal

Repository juga memiliki dokumentasi pengembangan untuk routing dan skeleton implementation, termasuk:

```text
lib/features/tracking/presentation/
├── DEVELOPER_NAVIGATION_GUIDE.dart
└── NAVIGATION_EXAMPLES.dart
```

serta:

```text
lib/features/tracking/presentation/pages/
└── SKELETON_IMPLEMENTATION_SUMMARY.md
```

Dokumen tersebut menjelaskan struktur routing, pola passing arguments, halaman yang sudah dibuat, dan pekerjaan lanjutan yang masih diperlukan. fileciteturn29file0 fileciteturn46file0

---

## 24. Status Repository

Repository menggunakan `main` sebagai default branch. Saat audit dilakukan, repository bersifat public, menggunakan Dart sebagai bahasa utama, dan belum memiliki license yang ditentukan pada metadata GitHub. fileciteturn21file0

README ini secara sengaja membedakan antara **fitur yang benar-benar sudah diimplementasikan** dan **fitur yang masih skeleton/TODO**, agar dokumentasi tidak memberikan klaim yang lebih tinggi daripada kondisi source code.

---

## 25. License

Belum ada lisensi project yang ditetapkan pada repository.

Jika project akan dipublikasikan sebagai open source, tambahkan file `LICENSE` dan tentukan lisensi yang sesuai sebelum menyatakan project sebagai open source.

---

## 26. Referensi

- Flutter: https://docs.flutter.dev/
- Dart: https://dart.dev/
- Camera plugin: https://pub.dev/packages/camera
- Geolocator: https://pub.dev/packages/geolocator
- Geocoding: https://pub.dev/packages/geocoding
- Permission Handler: https://pub.dev/packages/permission_handler
- Path Provider: https://pub.dev/packages/path_provider
- Riverpod: https://riverpod.dev/

---

## Repository

urlalfajauhari068/camera_tracking-apphttps://github.com/alfajauhari068/camera_tracking-app
