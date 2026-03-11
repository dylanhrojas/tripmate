import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Check if location services are enabled on the device
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Check current permission status
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Request location permission from the user
  Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  /// Handle location permission workflow
  /// Returns true if permission is granted, false otherwise
  Future<bool> handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled, cannot proceed
      return false;
    }

    // Check current permission status
    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      // Request permission
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        // Permissions are denied
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately
      // User must manually enable permissions in settings
      return false;
    }

    // Permission is granted (either while in use or always)
    return true;
  }

  /// Get detailed permission status with message
  Future<PermissionStatus> getPermissionStatus() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      return PermissionStatus(
        isGranted: false,
        message: 'Location services are disabled. Please enable them in settings.',
      );
    }

    LocationPermission permission = await Geolocator.checkPermission();

    switch (permission) {
      case LocationPermission.denied:
        return PermissionStatus(
          isGranted: false,
          message: 'Location permission is denied. Please grant permission.',
          canRequest: true,
        );

      case LocationPermission.deniedForever:
        return PermissionStatus(
          isGranted: false,
          message: 'Location permission is permanently denied. Please enable it in app settings.',
          isPermanentlyDenied: true,
        );

      case LocationPermission.whileInUse:
      case LocationPermission.always:
        return PermissionStatus(
          isGranted: true,
          message: 'Location permission granted.',
        );

      default:
        return PermissionStatus(
          isGranted: false,
          message: 'Unknown permission status.',
        );
    }
  }
}

/// Model class to represent permission status
class PermissionStatus {
  final bool isGranted;
  final String message;
  final bool canRequest;
  final bool isPermanentlyDenied;

  PermissionStatus({
    required this.isGranted,
    required this.message,
    this.canRequest = false,
    this.isPermanentlyDenied = false,
  });
}
