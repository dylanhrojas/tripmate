import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/trip.dart';
import '../models/trip_tracking.dart';
import '../services/storage_service.dart';
import '../services/location_service.dart';
import 'trip_summary_screen.dart';

class TripTrackingScreen extends StatefulWidget {
  final Trip trip;

  const TripTrackingScreen({super.key, required this.trip});

  @override
  State<TripTrackingScreen> createState() => _TripTrackingScreenState();
}

class _TripTrackingScreenState extends State<TripTrackingScreen> {
  final StorageService _storageService = StorageService();
  final LocationService _locationService = LocationService();

  TripTracking? _tracking;
  StreamSubscription<Position>? _positionSubscription;
  bool _isTracking = false;
  Position? _currentPosition;
  Timer? _timer;
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _checkActiveTracking();
  }

  Future<void> _checkActiveTracking() async {
    final activeTracking = await _storageService.getActiveTracking();
    if (activeTracking != null && activeTracking.tripId == widget.trip.id) {
      setState(() {
        _tracking = activeTracking;
        _isTracking = true;
      });
      _startLocationTracking();
      _startTimer();
    }
  }

  Future<void> _startTrip() async {
    final hasPermission = await _locationService.handleLocationPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission required'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final tracking = TripTracking(
        tripId: widget.trip.id,
        tripName: widget.trip.name,
        startTime: DateTime.now(),
        path: [
          TrackingPoint(
            latitude: position.latitude,
            longitude: position.longitude,
            timestamp: DateTime.now(),
            accuracy: position.accuracy,
          ),
        ],
        totalDistance: 0,
      );

      await _storageService.saveActiveTracking(tracking);

      setState(() {
        _tracking = tracking;
        _currentPosition = position;
        _isTracking = true;
        _elapsedSeconds = 0;
      });

      _startLocationTracking();
      _startTimer();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trip started! Tracking your movement...'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting trip: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _startLocationTracking() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    );

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) async {
        if (_tracking == null) return;

        setState(() {
          _currentPosition = position;
        });

        // Add new point to path
        final newPoint = TrackingPoint(
          latitude: position.latitude,
          longitude: position.longitude,
          timestamp: DateTime.now(),
          accuracy: position.accuracy,
        );

        // Calculate distance from last point
        final lastPoint = _tracking!.path.last;
        final distanceFromLast = Geolocator.distanceBetween(
          lastPoint.latitude,
          lastPoint.longitude,
          position.latitude,
          position.longitude,
        );

        // Update tracking
        final updatedPath = List<TrackingPoint>.from(_tracking!.path)
          ..add(newPoint);
        final updatedDistance = _tracking!.totalDistance + distanceFromLast;

        final updatedTracking = TripTracking(
          tripId: _tracking!.tripId,
          tripName: _tracking!.tripName,
          startTime: _tracking!.startTime,
          path: updatedPath,
          totalDistance: updatedDistance,
        );

        setState(() {
          _tracking = updatedTracking;
        });

        // Save to storage
        await _storageService.saveActiveTracking(updatedTracking);
      },
      onError: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tracking error: $error'),
            backgroundColor: Colors.red,
          ),
        );
      },
    );
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isTracking) {
        setState(() {
          _elapsedSeconds++;
        });
      }
    });
  }

  Future<void> _stopTrip() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stop Trip'),
        content: const Text('Are you sure you want to stop tracking this trip?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Stop Trip'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    _positionSubscription?.cancel();
    _timer?.cancel();

    if (_tracking != null) {
      final completedTracking = TripTracking(
        tripId: _tracking!.tripId,
        tripName: _tracking!.tripName,
        startTime: _tracking!.startTime,
        endTime: DateTime.now(),
        path: _tracking!.path,
        totalDistance: _tracking!.totalDistance,
      );

      // Save to history
      await _storageService.saveToTrackingHistory(completedTracking);
      await _storageService.clearActiveTracking();

      setState(() {
        _tracking = completedTracking;
        _isTracking = false;
      });

      if (mounted) {
        // Show summary screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TripSummaryScreen(tracking: completedTracking),
          ),
        );
      }
    }
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.trip.name),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_tracking == null) ...[
              const Icon(Icons.directions_walk, size: 80, color: Colors.blue),
              const SizedBox(height: 16),
              const Text(
                'Ready to Start Trip',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Press "Start Trip" to begin tracking your movement',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _startTrip,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start Trip'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
            ] else ...[
              Card(
                color: _isTracking ? Colors.green.shade50 : Colors.grey.shade100,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isTracking)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          if (_isTracking) const SizedBox(width: 12),
                          Text(
                            _isTracking ? 'TRACKING ACTIVE' : 'TRIP COMPLETED',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _isTracking ? Colors.green.shade900 : Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildStatCard(
                'Duration',
                _formatDuration(_elapsedSeconds),
                Icons.timer,
                Colors.blue,
              ),
              const SizedBox(height: 16),
              _buildStatCard(
                'Distance Walked',
                '${_tracking!.distanceInKm} km',
                Icons.straighten,
                Colors.orange,
              ),
              const SizedBox(height: 16),
              _buildStatCard(
                'Path Points',
                '${_tracking!.path.length} locations',
                Icons.location_on,
                Colors.purple,
              ),
              const SizedBox(height: 16),
              if (_currentPosition != null)
                _buildStatCard(
                  'Current Position',
                  '${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}',
                  Icons.my_location,
                  Colors.green,
                ),
              const Spacer(),
              if (_isTracking)
                ElevatedButton.icon(
                  onPressed: _stopTrip,
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop Trip'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
