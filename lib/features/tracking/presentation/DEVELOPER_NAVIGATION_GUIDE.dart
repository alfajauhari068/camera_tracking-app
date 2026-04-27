/// QUICK REFERENCE GUIDE - NAVIGATION PATTERNS
/// 
/// Copy-paste ready code snippets untuk berbagai use case navigation
/// Gunakan file ini sebagai referensi saat implementasi fitur

// =============================================================================
// IMPORTS YANG DIPERLUKAN
// =============================================================================

/*
Di setiap file yang ingin menggunakan navigation, tambahkan:

import 'package:flutter/material.dart';
import '../../../../routes.dart' as app_routes;  // adjust path sesuai folder
import '../../domain/entities/tracking.dart';     // jika perlu pass Tracking
*/

// =============================================================================
// USE CASE 1: SIMPLE BUTTON NAVIGATION
// =============================================================================

/*
Ketika: User tap button untuk pindah ke halaman lain (tanpa data)

Kode:
```dart
ElevatedButton(
  onPressed: () {
    Navigator.pushNamed(context, app_routes.AppRoutes.gallery);
  },
  child: const Text('Go to Gallery'),
),
```

Atau menggunakan helper:
```dart
ElevatedButton(
  onPressed: () {
    app_routes.navigateTo(context, app_routes.AppRoutes.gallery);
  },
  child: const Text('Go to Gallery'),
),
```
*/

// =============================================================================
// USE CASE 2: PASS DATA VIA ARGUMENTS (String ID)
// =============================================================================

/*
Ketika: Dari GalleryPage, user tap satu foto → buka detail dengan ID

Kode:
```dart
ListTile(
  title: Text('Photo $photoId'),
  onTap: () {
    Navigator.pushNamed(
      context,
      app_routes.AppRoutes.detail,
      arguments: photoId,  // Pass String ID
    );
  },
),
```

Di PhotoDetailPage, terima arguments:
```dart
class PhotoDetailPage extends StatelessWidget {
  final String? trackingId;  // Dari arguments

  const PhotoDetailPage({super.key, this.trackingId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail: $trackingId')),
      // ...
    );
  }
}
```
*/

// =============================================================================
// USE CASE 3: PASS DATA VIA ARGUMENTS (Object)
// =============================================================================

/*
Ketika: Pass complete Tracking object ke detail page

Kode:
```dart
GestureDetector(
  onTap: () {
    Navigator.pushNamed(
      context,
      app_routes.AppRoutes.detail,
      arguments: trackingObject,  // Pass Tracking object
    );
  },
  child: PhotoCard(tracking: trackingObject),
),
```

Di PhotoDetailPage:
```dart
class PhotoDetailPage extends StatelessWidget {
  final Tracking? tracking;  // Dari arguments

  const PhotoDetailPage({super.key, this.tracking});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Photo: ${tracking?.address}'),
      ),
      body: _buildMetadata(),
    );
  }
}
```
*/

// =============================================================================
// USE CASE 4: NESTED NAVIGATION (Detail → Map dengan highlight)
// =============================================================================

/*
Ketika: Dari detail page, tap "View on Map" → buka map dengan highlight foto

Kode di PhotoDetailPage:
```dart
ElevatedButton.icon(
  onPressed: () {
    Navigator.pushNamed(
      context,
      app_routes.AppRoutes.map,
      arguments: tracking,  // Pass tracking untuk highlight
    );
  },
  icon: const Icon(Icons.map),
  label: const Text('View on Map'),
),
```

Di MapPage, terima highlight tracking:
```dart
class MapPage extends StatelessWidget {
  final Tracking? highlightedTracking;

  const MapPage({super.key, this.highlightedTracking});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Map')),
      body: _buildMapWithMarkers(),
      // Jika ada highlightedTracking, highlight marker-nya
    );
  }
}
```
*/

// =============================================================================
// USE CASE 5: REPLACE NAVIGATION (Replace stack instead of push)
// =============================================================================

/*
Ketika: Setelah capture foto sukses, ganti screen dari camera ke gallery
        (user tidak bisa back ke camera)

Kode di CaptureScreen atau ViewModel:
```dart
if (result.isSuccess) {
  Navigator.pushReplacementNamed(
    context,
    app_routes.AppRoutes.gallery,
  );
  // Atau helper:
  // app_routes.replaceWith(context, app_routes.AppRoutes.gallery);
}
```
*/

// =============================================================================
// USE CASE 6: POP SAMPAI HOME (Reset navigation stack)
// =============================================================================

/*
Ketika: Di tengah-tengah banyak screen, user tap "Home" → kembali ke home

Kode:
```dart
FloatingActionButton(
  onPressed: () {
    app_routes.popUntilRoute(context, app_routes.AppRoutes.home);
  },
  child: const Icon(Icons.home),
),
```

Atau menggunakan Navigator.popUntil langsung:
```dart
Navigator.popUntil(
  context,
  ModalRoute.withName(app_routes.AppRoutes.home),
);
```
*/

// =============================================================================
// USE CASE 7: PUSH & WAIT FOR RESULT
// =============================================================================

/*
Ketika: Open halaman dan tunggu user untuk select sesuatu, lalu return result

Di halaman asal (misal HomePage), push dan tunggu result:
```dart
Future<void> _openExportAndWaitResult() async {
  final result = await Navigator.pushNamed<String>(
    context,
    app_routes.AppRoutes.export,
  );

  if (result != null) {
    print('Export result: $result');  // Misal path file yang di-export
    // Update UI dengan result
  }
}
```

Di ExportPage, setelah user selesai, pop dengan result:
```dart
Navigator.pop(context, exportedFilePath);  // Return String
```
*/

// =============================================================================
// USE CASE 8: MULTIPLE ARGUMENTS (Custom class)
// =============================================================================

/*
Ketika: Perlu pass multiple data ke page

Buat class untuk wrap data:
```dart
class PhotoFilterArgs {
  final DateTime startDate;
  final DateTime endDate;
  final String? currentLocation;

  PhotoFilterArgs({
    required this.startDate,
    required this.endDate,
    this.currentLocation,
  });
}
```

Push dengan custom arguments:
```dart
Navigator.pushNamed(
  context,
  app_routes.AppRoutes.gallery,
  arguments: PhotoFilterArgs(
    startDate: DateTime(2026, 1, 1),
    endDate: DateTime.now(),
    currentLocation: 'Jakarta',
  ),
);
```

Di GalleryPage, terima:
```dart
class GalleryPage extends StatelessWidget {
  final PhotoFilterArgs? filterArgs;

  const GalleryPage({super.key, this.filterArgs});

  @override
  Widget build(BuildContext context) {
    // Use filterArgs untuk filter photo list
  }
}
```

Di onGenerateRoute (routes.dart), parse custom arguments:
```dart
if (settings.arguments is PhotoFilterArgs) {
  final args = settings.arguments as PhotoFilterArgs;
  return MaterialPageRoute(
    builder: (context) => GalleryPage(filterArgs: args),
  );
}
```
*/

// =============================================================================
// COMPLETE EXAMPLE: HomePageButton → DetailPage → MapPage → Export
// =============================================================================

/*
FULL WORKFLOW dengan multiple screens:

1. HomePage → Button "View Photo"
   ```dart
   ElevatedButton(
     onPressed: () {
       Navigator.pushNamed(
         context,
         app_routes.AppRoutes.detail,
         arguments: photoObject,
       );
     },
     child: const Text('View Photo'),
   ),
   ```

2. PhotoDetailPage (received photoObject)
   ```dart
   ElevatedButton.icon(
     onPressed: () {
       Navigator.pushNamed(
         context,
         app_routes.AppRoutes.map,
         arguments: tracking,  // Pass ke map untuk highlight
       );
     },
     icon: const Icon(Icons.map),
     label: const Text('View on Map'),
   ),
   ```

3. MapPage (received tracking to highlight)
   ```dart
   // Map widget dengan marker di location tracking
   // User bisa lihat lokasi foto
   ```

4. Atau dari DetailPage, user tap "Share"
   ```dart
   OutlinedButton.icon(
     onPressed: () {
       Navigator.pushNamed(
         context,
         app_routes.AppRoutes.export,
         arguments: tracking,  // Pre-populate export filter untuk foto ini
       );
     },
     icon: const Icon(Icons.share),
     label: const Text('Share'),
   ),
   ```

5. ExportPage (received tracking as preset filter)
   ```dart
   // Form dengan date range pre-filled untuk foto ini
   // User adjust format, tap "Generate"
   // Pop dengan exported file path
   final filePath = await generateExport(...);
   Navigator.pop(context, filePath);
   ```
*/

// =============================================================================
// BEST PRACTICES & TIPS
// =============================================================================

/*
✅ DO:

1. Gunakan route constants:
   - app_routes.AppRoutes.gallery (instead of '/gallery')

2. Pass arguments secara konsisten:
   - DocumentationExample: pass tracking object, bukan ID
   - Atau standardize: selalu pass ID atau selalu pass object

3. Validate arguments di receiving page:
   ```dart
   final tracking = arguments as Tracking?;
   if (tracking == null) {
     // Handle null case, show default or error
   }
   ```

4. Use helper functions dari routes.dart:
   - app_routes.navigateTo()
   - app_routes.replaceWith()
   - app_routes.popUntilRoute()

5. Document arguments dalam widget:
   ```dart
   /// PhotoDetailPage
   /// Arguments: trackingId (String) atau tracking (Tracking object)
   ```


❌ DON'T:

1. Hardcode route names:
   ❌ Navigator.pushNamed(context, '/gallery');
   ✅ Navigator.pushNamed(context, app_routes.AppRoutes.gallery);

2. Pass complex nested objects:
   ❌ Pass nested Map/JSON
   ✅ Pass simple types (String, int) atau Dart class

3. Forget to import routes.dart:
   ❌ Will get 'AppRoutes not defined' error
   ✅ Always: import '../../../../routes.dart' as app_routes;

4. Mix push & replacement inconsistently:
   ❌ Inconsistent behavior user experience
   ✅ Be clear: push (bisa back) vs replace (tidak bisa back)

5. Ignore arguments validation:
   ❌ Assume arguments always present
   ✅ Check nullable: final id = arguments as String?;
*/

// =============================================================================
// TROUBLESHOOTING
// =============================================================================

/*
Problem: "No route definition for '/gallery'"
Solution: Pastikan route sudah ditambah di getAppRoutes() di routes.dart

Problem: "arguments tidak ter-pass ke target page"
Solution: 
- Pastikan onGenerateRoute digunakan atau constructor parameters benar
- Check PhotoDetailPage has trackingId/tracking parameter

Problem: "Black screen setelah navigate"
Solution:
- Check import path di routes.dart benar untuk page
- Check page widget tidak return null atau empty

Problem: "Can't go back / back button tidak work"
Solution:
- Pastikan menggunakan pushNamed, bukan pushReplacementNamed
- pushReplacementNamed tidak meninggalkan route untuk di-pop

Problem: "Multiple navigations trigger bersamaan"
Solution:
- Add: if (mounted) { Navigator.pushNamed(...); }
- Atau guard dengan: if (!_isNavigating) { ... }
*/

// =============================================================================
// FULL CODE EXAMPLE: HomePage Implementation
// =============================================================================

/*
import 'package:flutter/material.dart';
import '../../../../routes.dart' as app_routes;
import '../../domain/entities/tracking.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () => app_routes.navigateTo(
              context,
              app_routes.AppRoutes.gallery,
            ),
            child: const Text('Gallery'),
          ),
          ElevatedButton(
            onPressed: () => app_routes.navigateTo(
              context,
              app_routes.AppRoutes.camera,
            ),
            child: const Text('Take Photo'),
          ),
          ElevatedButton(
            onPressed: () => app_routes.navigateTo(
              context,
              app_routes.AppRoutes.map,
            ),
            child: const Text('Map'),
          ),
          ElevatedButton(
            onPressed: () => app_routes.navigateTo(
              context,
              app_routes.AppRoutes.export,
            ),
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }
}
*/
