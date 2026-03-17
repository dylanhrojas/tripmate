import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/destination.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'destinations';

  // Obtener todos los destinos
  Stream<List<Destination>> getDestinations() {
    return _firestore
        .collection(_collection)
        .orderBy('fechaCreacion', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Destination.fromFirestore(doc))
            .toList());
  }

  // Obtener un destino por ID
  Future<Destination?> getDestinationById(String id) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection(_collection).doc(id).get();
      if (doc.exists) {
        return Destination.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error obteniendo destino: $e');
      return null;
    }
  }

  // Crear nuevo destino
  Future<bool> createDestination(Destination destination) async {
    try {
      await _firestore.collection(_collection).add(destination.toMap());
      return true;
    } catch (e) {
      print('Error creando destino: $e');
      return false;
    }
  }

  // Actualizar destino existente
  Future<bool> updateDestination(Destination destination) async {
    try {
      if (destination.id == null) return false;
      await _firestore
          .collection(_collection)
          .doc(destination.id)
          .update(destination.toMap());
      return true;
    } catch (e) {
      print('Error actualizando destino: $e');
      return false;
    }
  }

  // Eliminar destino
  Future<bool> deleteDestination(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
      return true;
    } catch (e) {
      print('Error eliminando destino: $e');
      return false;
    }
  }

  // Buscar destinos por categoría
  Stream<List<Destination>> getDestinationsByCategory(String categoria) {
    return _firestore
        .collection(_collection)
        .where('categoria', isEqualTo: categoria)
        .orderBy('fechaCreacion', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Destination.fromFirestore(doc))
            .toList());
  }
}
