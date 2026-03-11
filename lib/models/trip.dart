class Trip {
  final String id;
  final String name;
  final double destinationLat;
  final double destinationLng;
  final DateTime createdAt;
  final String? notes;

  Trip({
    required this.id,
    required this.name,
    required this.destinationLat,
    required this.destinationLng,
    required this.createdAt,
    this.notes,
  });

  /// Convert Trip to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'destinationLat': destinationLat,
      'destinationLng': destinationLng,
      'createdAt': createdAt.toIso8601String(),
      'notes': notes,
    };
  }

  /// Create Trip from JSON
  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'],
      name: json['name'],
      destinationLat: json['destinationLat'],
      destinationLng: json['destinationLng'],
      createdAt: DateTime.parse(json['createdAt']),
      notes: json['notes'],
    );
  }

  /// Create a copy of the trip with optional modifications
  Trip copyWith({
    String? id,
    String? name,
    double? destinationLat,
    double? destinationLng,
    DateTime? createdAt,
    String? notes,
  }) {
    return Trip(
      id: id ?? this.id,
      name: name ?? this.name,
      destinationLat: destinationLat ?? this.destinationLat,
      destinationLng: destinationLng ?? this.destinationLng,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
    );
  }

  @override
  String toString() {
    return 'Trip(id: $id, name: $name, destination: ($destinationLat, $destinationLng))';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Trip && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
