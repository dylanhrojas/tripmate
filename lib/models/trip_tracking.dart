class TripTracking {
  final String tripId;
  final String tripName;
  final DateTime startTime;
  final DateTime? endTime;
  final List<TrackingPoint> path;
  final double totalDistance; // in meters

  TripTracking({
    required this.tripId,
    required this.tripName,
    required this.startTime,
    this.endTime,
    required this.path,
    required this.totalDistance,
  });

  bool get isActive => endTime == null;

  Duration get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  String get formattedDuration {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  String get distanceInKm => (totalDistance / 1000).toStringAsFixed(2);
  String get distanceInMeters => totalDistance.toStringAsFixed(0);

  Map<String, dynamic> toJson() {
    return {
      'tripId': tripId,
      'tripName': tripName,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'path': path.map((p) => p.toJson()).toList(),
      'totalDistance': totalDistance,
    };
  }

  factory TripTracking.fromJson(Map<String, dynamic> json) {
    return TripTracking(
      tripId: json['tripId'],
      tripName: json['tripName'],
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      path: (json['path'] as List)
          .map((p) => TrackingPoint.fromJson(p))
          .toList(),
      totalDistance: json['totalDistance'],
    );
  }

  @override
  String toString() {
    return 'TripTracking(tripId: $tripId, distance: ${distanceInKm}km, duration: $formattedDuration, active: $isActive)';
  }
}

class TrackingPoint {
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double? accuracy;

  TrackingPoint({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.accuracy,
  });

  Map<String, dynamic> toJson() {
    return {
      'lat': latitude,
      'lng': longitude,
      'timestamp': timestamp.toIso8601String(),
      'accuracy': accuracy,
    };
  }

  factory TrackingPoint.fromJson(Map<String, dynamic> json) {
    return TrackingPoint(
      latitude: json['lat'],
      longitude: json['lng'],
      timestamp: DateTime.parse(json['timestamp']),
      accuracy: json['accuracy'],
    );
  }

  @override
  String toString() {
    return 'TrackingPoint($latitude, $longitude at $timestamp)';
  }
}
