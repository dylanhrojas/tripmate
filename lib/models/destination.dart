import 'package:cloud_firestore/cloud_firestore.dart';

class Destination {
  final String? id;
  final String nombre;
  final String descripcion;
  final String pais;
  final String ciudad;
  final String categoria; // playa, montaña, ciudad, cultural
  final double latitud;
  final double longitud;
  final DateTime fechaCreacion;

  Destination({
    this.id,
    required this.nombre,
    required this.descripcion,
    required this.pais,
    required this.ciudad,
    required this.categoria,
    required this.latitud,
    required this.longitud,
    required this.fechaCreacion,
  });

  // Convertir a Map para guardar en Firestore
  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'descripcion': descripcion,
      'pais': pais,
      'ciudad': ciudad,
      'categoria': categoria,
      'latitud': latitud,
      'longitud': longitud,
      'fechaCreacion': Timestamp.fromDate(fechaCreacion),
    };
  }

  // Crear desde documento de Firestore
  factory Destination.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Destination(
      id: doc.id,
      nombre: data['nombre'] ?? '',
      descripcion: data['descripcion'] ?? '',
      pais: data['pais'] ?? '',
      ciudad: data['ciudad'] ?? '',
      categoria: data['categoria'] ?? '',
      latitud: (data['latitud'] ?? 0.0).toDouble(),
      longitud: (data['longitud'] ?? 0.0).toDouble(),
      fechaCreacion: (data['fechaCreacion'] as Timestamp).toDate(),
    );
  }

  // Copiar con modificaciones
  Destination copyWith({
    String? id,
    String? nombre,
    String? descripcion,
    String? pais,
    String? ciudad,
    String? categoria,
    double? latitud,
    double? longitud,
    DateTime? fechaCreacion,
  }) {
    return Destination(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      pais: pais ?? this.pais,
      ciudad: ciudad ?? this.ciudad,
      categoria: categoria ?? this.categoria,
      latitud: latitud ?? this.latitud,
      longitud: longitud ?? this.longitud,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
    );
  }
}
