import 'package:flutter/material.dart';
import '../models/destination.dart';
import '../services/firebase_service.dart';
import 'destination_form_screen.dart';

class DestinationsAdminScreen extends StatefulWidget {
  const DestinationsAdminScreen({super.key});

  @override
  State<DestinationsAdminScreen> createState() =>
      _DestinationsAdminScreenState();
}

class _DestinationsAdminScreenState extends State<DestinationsAdminScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  // Iconos para categorías
  IconData _getCategoryIcon(String categoria) {
    switch (categoria.toLowerCase()) {
      case 'playa':
        return Icons.beach_access;
      case 'montaña':
        return Icons.landscape;
      case 'ciudad':
        return Icons.location_city;
      case 'cultural':
        return Icons.museum;
      default:
        return Icons.place;
    }
  }

  // Colores para categorías
  Color _getCategoryColor(String categoria) {
    switch (categoria.toLowerCase()) {
      case 'playa':
        return Colors.blue;
      case 'montaña':
        return Colors.green;
      case 'ciudad':
        return Colors.orange;
      case 'cultural':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  void _confirmDelete(BuildContext context, Destination destination) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar destino'),
        content: Text('¿Seguro que deseas eliminar "${destination.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              bool success =
                  await _firebaseService.deleteDestination(destination.id!);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Destino eliminado')),
                );
              }
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administrar Destinos'),
        backgroundColor: Colors.teal,
      ),
      body: StreamBuilder<List<Destination>>(
        stream: _firebaseService.getDestinations(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final destinations = snapshot.data ?? [];

          if (destinations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.explore_off, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No hay destinos registrados',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Presiona + para agregar uno',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: destinations.length,
            itemBuilder: (context, index) {
              final destination = destinations[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getCategoryColor(destination.categoria),
                    child: Icon(
                      _getCategoryIcon(destination.categoria),
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    destination.nombre,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        '${destination.ciudad}, ${destination.pais}',
                        style: const TextStyle(fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        destination.categoria.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          color: _getCategoryColor(destination.categoria),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DestinationFormScreen(
                                destination: destination,
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDelete(context, destination),
                      ),
                    ],
                  ),
                  onTap: () {
                    // Mostrar detalles
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(destination.nombre),
                        content: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                destination.descripcion,
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 16),
                              _buildDetailRow('País', destination.pais),
                              _buildDetailRow('Ciudad', destination.ciudad),
                              _buildDetailRow(
                                  'Categoría', destination.categoria),
                              _buildDetailRow('Latitud',
                                  destination.latitud.toStringAsFixed(4)),
                              _buildDetailRow('Longitud',
                                  destination.longitud.toStringAsFixed(4)),
                            ],
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cerrar'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const DestinationFormScreen(),
            ),
          );
        },
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
