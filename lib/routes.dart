import 'package:flutter/material.dart';

import 'features/tracking/presentation/capture_screen.dart';
import 'features/tracking/presentation/pages/gallery_page.dart';
import 'features/tracking/presentation/pages/photo_detail_page.dart';
import 'features/tracking/presentation/pages/map_page.dart';
import 'features/tracking/presentation/pages/export_page.dart';
import 'features/tracking/presentation/pages/home_page.dart';
import 'features/tracking/presentation/pages/camera_tracking_page.dart';
import 'features/tracking/presentation/pages/history_page.dart';
import 'features/tracking/presentation/pages/tracking_detail_page.dart';
import 'features/tracking/presentation/pages/settings_page.dart';

/// Route path constants
class AppRoutes {
  static const String home = '/';
  static const String camera = '/camera';
  static const String cameraTracking = '/camera-tracking';  // Demo layout
  static const String gallery = '/gallery';
  static const String history = '/history';  // History/Log page
  static const String detail = '/detail';
  static const String trackingDetail = '/tracking-detail';  // Tracking detail page
  static const String map = '/map';
  static const String export = '/export';
  static const String settings = '/settings';
}

/// Route generator - maps route paths ke widget pages
Map<String, WidgetBuilder> getAppRoutes() {
  return {
    // =========================================================================
    // HOME PAGE (Dashboard)
    // =========================================================================
    AppRoutes.home: (context) => const HomePage(),

    // =========================================================================
    // CAMERA PAGE (Take Photo - Original)
    // =========================================================================
    AppRoutes.camera: (context) => const CaptureScreen(),

    // =========================================================================
    // CAMERA TRACKING PAGE (Demo layout only)
    // =========================================================================
    AppRoutes.cameraTracking: (context) => const CameraTrackingPage(),

    // =========================================================================
    // GALLERY PAGE (List of Photos)
    // =========================================================================
    AppRoutes.gallery: (context) => const GalleryPage(),

    // =========================================================================
    // HISTORY PAGE (Tracking Log)
    // =========================================================================
    AppRoutes.history: (context) => const HistoryPage(),

    // =========================================================================
    // PHOTO DETAIL PAGE (View Single Photo + Metadata)
    // =========================================================================
    // NOTE: Arguments dapat diterima melalui:
    //   1. ModalRoute.of<T>(context).settings.arguments
    //   2. Atau gunakan onGenerateRoute untuk parsing arguments
    AppRoutes.detail: (context) => const PhotoDetailPage(),

    // =========================================================================
    // TRACKING DETAIL PAGE (View Tracking Detail)
    // =========================================================================
    AppRoutes.trackingDetail: (context) => const TrackingDetailPage(),

// =========================================================================
    // MAP PAGE (View Locations on Map)
    // =========================================================================
    AppRoutes.map: (context) => const MapPage(),

    // =========================================================================
    // EXPORT PAGE (Export/Share Data)
    // =========================================================================
    AppRoutes.export: (context) => const ExportPage(),

    // =========================================================================
    // SETTINGS PAGE (App Settings)
    // =========================================================================
AppRoutes.settings: (context) => const SettingsPage(),
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
