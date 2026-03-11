import 'package:flutter/material.dart';
import 'location_test_screen.dart';
import 'map_screen.dart';
import 'preferences_screen.dart';
import 'distance_calculator_screen.dart';
import 'trips_screen.dart';
import 'trip_history_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TripMate'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PreferencesScreen()),
              );
            },
            tooltip: 'Preferences',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Trip Planning',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildFeatureCard(
              context,
              'My Trips',
              'Plan trips and track distances',
              Icons.flight_takeoff,
              const TripsScreen(),
            ),
            const SizedBox(height: 16),
            _buildFeatureCard(
              context,
              'Trip History',
              'View completed trip summaries',
              Icons.history,
              const TripHistoryScreen(),
            ),
            const SizedBox(height: 24),
            const Text(
              'Location Features',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildFeatureCard(
              context,
              'Google Maps',
              'View your location on the map',
              Icons.map,
              const MapScreen(),
            ),
            const SizedBox(height: 16),
            _buildFeatureCard(
              context,
              'Distance Calculator',
              'Calculate distances and view history',
              Icons.straighten,
              const DistanceCalculatorScreen(),
            ),
            const SizedBox(height: 16),
            _buildFeatureCard(
              context,
              'Location Test',
              'Test location permissions and tracking',
              Icons.location_searching,
              const LocationTestScreen(),
            ),
            const SizedBox(height: 16),
            _buildFeatureCard(
              context,
              'Preferences',
              'Manage app settings and preferences',
              Icons.settings,
              const PreferencesScreen(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Widget screen,
  ) {
    return Card(
      elevation: 3,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => screen),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(icon, size: 48, color: Colors.blue),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
