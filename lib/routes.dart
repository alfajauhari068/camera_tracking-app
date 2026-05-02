import 'package:flutter/material.dart';

import 'features/tracking/presentation/capture_screen.dart';
import 'features/tracking/presentation/pages/gallery_page.dart';
import 'features/tracking/presentation/pages/photo_detail_page.dart';
import 'features/tracking/presentation/pages/map_page.dart';
import 'features/tracking/presentation/pages/export_page.dart';
import 'features/tracking/presentation/pages/home_page.dart';

/// Route path constants - semua route terpusat di sini
class AppRoutes {
  static const String home = '/';
  static const String camera = '/camera';
  static const String gallery = '/gallery';
  static const String detail = '/detail';
  static const String map = '/map';
  static const String export = '/export';
}

/// Route generator - maps route paths ke widget pages
Map<String, WidgetBuilder> getAppRoutes() {
  return {
    // =========================================================================
    // HOME PAGE (Dashboard)
    // =========================================================================
    AppRoutes.home: (context) => const HomePage(),

    // =========================================================================
    // CAMERA PAGE (Take Photo)
    // =========================================================================
    AppRoutes.camera: (context) => const CaptureScreen(),

    // =========================================================================
    // GALLERY PAGE (List of Photos)
    // =========================================================================
    AppRoutes.gallery: (context) => const GalleryPage(),

    // =========================================================================
    // PHOTO DETAIL PAGE (View Single Photo + Metadata)
    // =========================================================================
    // NOTE: Arguments dapat diterima melalui:
    //   1. ModalRoute.of<T>(context).settings.arguments
    //   2. Atau gunakan onGenerateRoute untuk parsing arguments
    AppRoutes.detail: (context) => const PhotoDetailPage(),

    // =========================================================================
    // MAP PAGE (View Locations on Map)
    // =========================================================================
    AppRoutes.map: (context) => const MapPage(),

    // =========================================================================
    // EXPORT PAGE (Export/Share Data)
    // =========================================================================
    AppRoutes.export: (context) => const ExportPage(),
  };
}

/// ON GENERATE ROUTE - untuk handling arguments & route params
/// Gunakan ini jika perlu parsing arguments yang lebih kompleks
Route<dynamic>? onGenerateRoute(RouteSettings settings) {
  switch (settings.name) {
    // =========================================================================
    // PHOTO DETAIL dengan arguments (trackingId atau Tracking object)
    // =========================================================================
    case AppRoutes.detail:
      // PhotoDetailPage akan extract arguments dari ModalRoute.of(context)
      // Arguments bisa berupa:
      // - Tracking object: Navigator.pushNamed(..., arguments: tracking)
      // - String ID: Navigator.pushNamed(..., arguments: trackingId)
      return MaterialPageRoute(
        builder: (context) => const PhotoDetailPage(),
        settings: settings,
      );

    // Untuk route lain, fallback ke getAppRoutes()
    default:
      final routes = getAppRoutes();
      if (routes.containsKey(settings.name)) {
        return MaterialPageRoute(
          builder: routes[settings.name]!,
          settings: settings,
        );
      }

      // Route tidak ditemukan
      return MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Route Not Found')),
          body: Center(
            child: Text('No route defined for ${settings.name}'),
          ),
        ),
      );
  }
}

/// HELPER FUNCTION - Push route dengan atau tanpa arguments
/// 
/// Contoh penggunaan:
/// ```
/// navigateTo(context, AppRoutes.gallery);
/// navigateTo(context, AppRoutes.detail, arguments: 'tracking_id_123');
/// navigateTo(context, AppRoutes.detail, arguments: trackingObject);
/// ```
Future<T?> navigateTo<T>(
  BuildContext context,
  String routeName, {
  Object? arguments,
}) {
  return Navigator.pushNamed<T>(
    context,
    routeName,
    arguments: arguments,
  );
}

/// HELPER FUNCTION - Replace route (pop current + push new)
/// 
/// Contoh penggunaan:
/// ```
/// replaceWith(context, AppRoutes.home);
/// ```
Future<T?> replaceWith<T>(
  BuildContext context,
  String routeName, {
  Object? arguments,
}) {
  return Navigator.pushReplacementNamed<T, T>(
    context,
    routeName,
    arguments: arguments,
  );
}

/// HELPER FUNCTION - Pop sampai ke route tertentu
/// 
/// Contoh penggunaan:
/// ```
/// popUntilRoute(context, AppRoutes.home);
/// ```
void popUntilRoute(BuildContext context, String routeName) {
  Navigator.popUntil(
    context,
    ModalRoute.withName(routeName),
  );
}
