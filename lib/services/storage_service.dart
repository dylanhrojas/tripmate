import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/trip.dart';
import '../models/trip_tracking.dart';

class StorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Keys for storing location data
  static const String _keyLastLat = 'lastLat';
  static const String _keyLastLng = 'lastLng';
  static const String _keyLastTimestamp = 'lastTimestamp';

  // Keys for storing user preferences
  static const String _keyTrackingEnabled = 'trackingEnabled';

  // Keys for storing distance history
  static const String _keyDistanceHistory = 'distanceHistory';

  // Keys for storing trips
  static const String _keyTrips = 'trips';

  // Keys for storing trip tracking
  static const String _keyActiveTracking = 'activeTracking';
  static const String _keyTrackingHistory = 'trackingHistory';

  /// Save last known location
  Future<void> saveLastLocation({
    required double latitude,
    required double longitude,
  }) async {
    final timestamp = DateTime.now().toIso8601String();

    await _storage.write(key: _keyLastLat, value: latitude.toString());
    await _storage.write(key: _keyLastLng, value: longitude.toString());
    await _storage.write(key: _keyLastTimestamp, value: timestamp);
  }

  /// Retrieve last known location
  Future<SavedLocation?> getLastLocation() async {
    final lat = await _storage.read(key: _keyLastLat);
    final lng = await _storage.read(key: _keyLastLng);
    final timestamp = await _storage.read(key: _keyLastTimestamp);

    if (lat == null || lng == null || timestamp == null) {
      return null;
    }

    return SavedLocation(
      latitude: double.parse(lat),
      longitude: double.parse(lng),
      timestamp: DateTime.parse(timestamp),
    );
  }

  /// Delete last known location
  Future<void> deleteLastLocation() async {
    await _storage.delete(key: _keyLastLat);
    await _storage.delete(key: _keyLastLng);
    await _storage.delete(key: _keyLastTimestamp);
  }

  /// Check if last location exists
  Future<bool> hasLastLocation() async {
    final lat = await _storage.read(key: _keyLastLat);
    return lat != null;
  }

  /// Clear all storage
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  // ========== User Preferences ==========

  /// Save tracking enabled preference
  Future<void> setTrackingEnabled(bool enabled) async {
    await _storage.write(key: _keyTrackingEnabled, value: enabled.toString());
  }

  /// Get tracking enabled preference
  Future<bool> getTrackingEnabled() async {
    final value = await _storage.read(key: _keyTrackingEnabled);
    if (value == null) {
      return false; // Default to false
    }
    return value.toLowerCase() == 'true';
  }

  // ========== Distance History ==========

  /// Save a distance calculation to history
  Future<void> saveDistanceCalculation(DistanceCalculation calculation) async {
    final history = await getDistanceHistory();
    history.insert(0, calculation); // Add to beginning

    // Keep only last 50 calculations
    if (history.length > 50) {
      history.removeRange(50, history.length);
    }

    final jsonList = history.map((calc) => calc.toJson()).toList();
    await _storage.write(key: _keyDistanceHistory, value: jsonEncode(jsonList));
  }

  /// Get all distance calculations from history
  Future<List<DistanceCalculation>> getDistanceHistory() async {
    final value = await _storage.read(key: _keyDistanceHistory);
    if (value == null) {
      return [];
    }

    try {
      final List<dynamic> jsonList = jsonDecode(value);
      return jsonList
          .map((json) => DistanceCalculation.fromJson(json))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Clear distance history
  Future<void> clearDistanceHistory() async {
    await _storage.delete(key: _keyDistanceHistory);
  }

  // ========== Trip Management ==========

  /// Save a trip
  Future<void> saveTrip(Trip trip) async {
    final trips = await getTrips();

    // Check if trip with same ID exists and update it
    final index = trips.indexWhere((t) => t.id == trip.id);
    if (index != -1) {
      trips[index] = trip;
    } else {
      trips.add(trip);
    }

    final jsonList = trips.map((t) => t.toJson()).toList();
    await _storage.write(key: _keyTrips, value: jsonEncode(jsonList));
  }

  /// Get all trips
  Future<List<Trip>> getTrips() async {
    final value = await _storage.read(key: _keyTrips);
    if (value == null) {
      return [];
    }

    try {
      final List<dynamic> jsonList = jsonDecode(value);
      return jsonList.map((json) => Trip.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get trip by ID
  Future<Trip?> getTripById(String id) async {
    final trips = await getTrips();
    try {
      return trips.firstWhere((trip) => trip.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Delete a trip
  Future<void> deleteTrip(String id) async {
    final trips = await getTrips();
    trips.removeWhere((trip) => trip.id == id);

    final jsonList = trips.map((t) => t.toJson()).toList();
    await _storage.write(key: _keyTrips, value: jsonEncode(jsonList));
  }

  /// Clear all trips
  Future<void> clearTrips() async {
    await _storage.delete(key: _keyTrips);
  }

  // ========== Trip Tracking ==========

  /// Save active trip tracking
  Future<void> saveActiveTracking(TripTracking tracking) async {
    final json = tracking.toJson();
    await _storage.write(key: _keyActiveTracking, value: jsonEncode(json));
  }

  /// Get active trip tracking
  Future<TripTracking?> getActiveTracking() async {
    final value = await _storage.read(key: _keyActiveTracking);
    if (value == null) {
      return null;
    }

    try {
      final json = jsonDecode(value);
      return TripTracking.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  /// Clear active tracking
  Future<void> clearActiveTracking() async {
    await _storage.delete(key: _keyActiveTracking);
  }

  /// Save completed trip to history
  Future<void> saveToTrackingHistory(TripTracking tracking) async {
    final history = await getTrackingHistory();
    history.insert(0, tracking); // Add to beginning

    // Keep only last 50 tracking records
    if (history.length > 50) {
      history.removeRange(50, history.length);
    }

    final jsonList = history.map((t) => t.toJson()).toList();
    await _storage.write(key: _keyTrackingHistory, value: jsonEncode(jsonList));
  }

  /// Get tracking history
  Future<List<TripTracking>> getTrackingHistory() async {
    final value = await _storage.read(key: _keyTrackingHistory);
    if (value == null) {
      return [];
    }

    try {
      final List<dynamic> jsonList = jsonDecode(value);
      return jsonList.map((json) => TripTracking.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Clear tracking history
  Future<void> clearTrackingHistory() async {
    await _storage.delete(key: _keyTrackingHistory);
  }
}

/// Model class for saved location
class SavedLocation {
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  SavedLocation({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  @override
  String toString() {
    return 'SavedLocation(lat: $latitude, lng: $longitude, time: $timestamp)';
  }
}

/// Model class for distance calculation
class DistanceCalculation {
  final double destinationLatitude;
  final double destinationLongitude;
  final double distance; // in meters
  final DateTime date;
  final double? originLatitude;
  final double? originLongitude;

  DistanceCalculation({
    required this.destinationLatitude,
    required this.destinationLongitude,
    required this.distance,
    required this.date,
    this.originLatitude,
    this.originLongitude,
  });

  Map<String, dynamic> toJson() {
    return {
      'destLat': destinationLatitude,
      'destLng': destinationLongitude,
      'distance': distance,
      'date': date.toIso8601String(),
      'originLat': originLatitude,
      'originLng': originLongitude,
    };
  }

  factory DistanceCalculation.fromJson(Map<String, dynamic> json) {
    return DistanceCalculation(
      destinationLatitude: json['destLat'],
      destinationLongitude: json['destLng'],
      distance: json['distance'],
      date: DateTime.parse(json['date']),
      originLatitude: json['originLat'],
      originLongitude: json['originLng'],
    );
  }

  String get distanceInKm => (distance / 1000).toStringAsFixed(2);
  String get distanceInMeters => distance.toStringAsFixed(0);

  @override
  String toString() {
    return 'DistanceCalculation(dest: $destinationLatitude,$destinationLongitude, distance: ${distanceInKm}km, date: $date)';
  }
}
