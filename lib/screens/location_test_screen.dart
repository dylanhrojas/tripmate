import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';

class LocationTestScreen extends StatefulWidget {
  const LocationTestScreen({super.key});

  @override
  State<LocationTestScreen> createState() => _LocationTestScreenState();
}

class _LocationTestScreenState extends State<LocationTestScreen> {
  final LocationService _locationService = LocationService();
  Position? _currentPosition;
  String _statusMessage = '';
  bool _isLoading = false;
  bool _isTracking = false;
  StreamSubscription<Position>? _positionStreamSubscription;
  int _updateCount = 0;

  Future<void> _getCurrentPosition() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Checking permissions...';
    });

    try {
      // Handle location permission
      bool hasPermission = await _locationService.handleLocationPermission();

      if (!hasPermission) {
        final status = await _locationService.getPermissionStatus();
        setState(() {
          _statusMessage = status.message;
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _statusMessage = 'Getting current position...';
      });

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      setState(() {
        _currentPosition = position;
        _statusMessage = 'Position retrieved successfully';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _startTracking() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Checking permissions...';
    });

    try {
      // Handle location permission
      bool hasPermission = await _locationService.handleLocationPermission();

      if (!hasPermission) {
        final status = await _locationService.getPermissionStatus();
        setState(() {
          _statusMessage = status.message;
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _statusMessage = 'Starting location tracking...';
        _isTracking = true;
        _updateCount = 0;
        _isLoading = false;
      });

      // Start position stream
      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // Update every 5 meters
      );

      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (Position position) {
          setState(() {
            _currentPosition = position;
            _updateCount++;
            _statusMessage = 'Tracking active - Update #$_updateCount';
          });
        },
        onError: (error) {
          setState(() {
            _statusMessage = 'Tracking error: ${error.toString()}';
            _isTracking = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: ${e.toString()}';
        _isLoading = false;
        _isTracking = false;
      });
    }
  }

  void _stopTracking() {
    _positionStreamSubscription?.cancel();
    setState(() {
      _isTracking = false;
      _statusMessage = 'Tracking stopped';
    });
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Test'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _isLoading || _isTracking ? null : _getCurrentPosition,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Get Current Position'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _isLoading || _isTracking ? null : _startTracking,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Start Continuous Tracking'),
            ),
            const SizedBox(height: 12),
            if (_isTracking)
              ElevatedButton(
                onPressed: _stopTracking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Stop Tracking'),
              ),
            const SizedBox(height: 20),
            if (_statusMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isTracking ? Colors.green.shade50 : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isTracking ? Colors.green : Colors.blue,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    if (_isTracking)
                      const Padding(
                        padding: EdgeInsets.only(right: 12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    Expanded(
                      child: Text(
                        _statusMessage,
                        style: TextStyle(
                          color: _isTracking ? Colors.green.shade900 : Colors.blue.shade900,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            if (_currentPosition != null) ...[
              const Text(
                'Current Position:',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildInfoCard(
                'Latitude',
                _currentPosition!.latitude.toStringAsFixed(6),
                Icons.my_location,
              ),
              const SizedBox(height: 12),
              _buildInfoCard(
                'Longitude',
                _currentPosition!.longitude.toStringAsFixed(6),
                Icons.location_on,
              ),
              const SizedBox(height: 12),
              _buildInfoCard(
                'Accuracy',
                '${_currentPosition!.accuracy.toStringAsFixed(2)} meters',
                Icons.gps_fixed,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: Colors.blue, size: 32),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
