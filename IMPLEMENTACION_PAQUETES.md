# Implementación de Paquetes en TripMate

Este documento explica cómo se implementaron y utilizaron los paquetes `geolocator` y `flutter_secure_storage` en el proyecto TripMate.

## 📦 Paquetes Utilizados

### 1. Geolocator (v13.0.2)
Paquete para servicios de geolocalización que permite obtener la ubicación del dispositivo y rastrear movimientos.

### 2. Flutter Secure Storage (v9.2.2)
Paquete para almacenamiento seguro y encriptado de datos sensibles en el dispositivo.

---

## 🌍 Geolocator

### Configuración Inicial

**Archivo:** [pubspec.yaml](pubspec.yaml#L39)
```yaml
dependencies:
  geolocator: ^13.0.2
```

**Permisos Android:** [android/app/src/main/AndroidManifest.xml](android/app/src/main/AndroidManifest.xml#L2-L6)
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
```

### Implementación

#### 1. Servicio de Ubicación ([lib/services/location_service.dart](lib/services/location_service.dart))

El servicio `LocationService` encapsula toda la funcionalidad de geolocalización:

**Verificación de Servicios de Ubicación:**
```dart
Future<bool> isLocationServiceEnabled() async {
  return await Geolocator.isLocationServiceEnabled();
}
```
- Verifica si los servicios de ubicación están habilitados en el dispositivo

**Gestión de Permisos:**
```dart
Future<LocationPermission> checkPermission() async {
  return await Geolocator.checkPermission();
}

Future<LocationPermission> requestPermission() async {
  return await Geolocator.requestPermission();
}
```
- Comprueba el estado actual de los permisos
- Solicita permisos al usuario cuando es necesario

**Flujo Completo de Permisos:**
```dart
Future<bool> handleLocationPermission() async {
  // 1. Verificar si los servicios están habilitados
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) return false;

  // 2. Verificar estado del permiso
  LocationPermission permission = await Geolocator.checkPermission();

  // 3. Solicitar permiso si está denegado
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) return false;
  }

  // 4. Manejar permiso denegado permanentemente
  if (permission == LocationPermission.deniedForever) return false;

  return true;
}
```

#### 2. Obtención de Ubicación Actual

**En Map Screen ([lib/screens/map_screen.dart](lib/screens/map_screen.dart#L63-L68)):**
```dart
Position position = await Geolocator.getCurrentPosition(
  locationSettings: const LocationSettings(
    accuracy: LocationAccuracy.high,
  ),
);
```
- Obtiene la posición actual del usuario con alta precisión
- Usado para mostrar la ubicación inicial en el mapa

#### 3. Rastreo de Ubicación en Tiempo Real

**Configuración del Stream ([lib/screens/map_screen.dart](lib/screens/map_screen.dart#L140-L147)):**
```dart
const LocationSettings locationSettings = LocationSettings(
  accuracy: LocationAccuracy.high,
  distanceFilter: 5, // Actualiza cada 5 metros
);

_positionSubscription = Geolocator.getPositionStream(
  locationSettings: locationSettings,
).listen((Position position) {
  // Actualizar UI con nueva posición
  setState(() {
    _currentPosition = position;
  });
});
```
- Usa un stream para recibir actualizaciones continuas de ubicación
- `distanceFilter: 5` solo actualiza cuando el usuario se mueve 5 metros
- Permite seguir el movimiento del usuario en tiempo real

#### 4. Cálculo de Distancias

**En Distance Calculator Screen ([lib/screens/distance_calculator_screen.dart](lib/screens/distance_calculator_screen.dart#L104-L109)):**
```dart
final distance = Geolocator.distanceBetween(
  _currentPosition!.latitude,
  _currentPosition!.longitude,
  destinationLatitude,
  destinationLongitude,
);
```
- Calcula la distancia en metros entre dos coordenadas geográficas
- Usa el método de Haversine para precisión

**En Trip Tracking ([lib/screens/trip_tracking_screen.dart](lib/screens/trip_tracking_screen.dart#L142-L147)):**
```dart
final distanceFromLast = Geolocator.distanceBetween(
  lastPoint.latitude,
  lastPoint.longitude,
  position.latitude,
  position.longitude,
);
```
- Calcula distancia entre puntos consecutivos del recorrido
- Suma las distancias para obtener el total recorrido

### Casos de Uso Implementados

1. **Visualización en Mapa:** Muestra ubicación actual del usuario con marcador
2. **Rastreo de Viajes:** Registra el camino completo del usuario durante un viaje
3. **Cálculo de Distancias:** Calcula distancias entre ubicación actual y destinos
4. **Rastreo Automático:** Actualiza ubicación automáticamente según preferencias

---

## 🔐 Flutter Secure Storage

### Configuración Inicial

**Archivo:** [pubspec.yaml](pubspec.yaml#L45)
```yaml
dependencies:
  flutter_secure_storage: ^9.2.2
```

### Implementación

#### 1. Servicio de Almacenamiento ([lib/services/storage_service.dart](lib/services/storage_service.dart))

**Inicialización:**
```dart
class StorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
}
```

#### 2. Almacenamiento de Ubicaciones

**Guardar Última Ubicación:**
```dart
Future<void> saveLastLocation({
  required double latitude,
  required double longitude,
}) async {
  final timestamp = DateTime.now().toIso8601String();

  await _storage.write(key: _keyLastLat, value: latitude.toString());
  await _storage.write(key: _keyLastLng, value: longitude.toString());
  await _storage.write(key: _keyLastTimestamp, value: timestamp);
}
```

**Recuperar Última Ubicación:**
```dart
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
```

#### 3. Almacenamiento de Preferencias de Usuario

**Guardar Preferencia de Rastreo ([lib/services/storage_service.dart](lib/services/storage_service.dart#L77-L79)):**
```dart
Future<void> setTrackingEnabled(bool enabled) async {
  await _storage.write(key: _keyTrackingEnabled, value: enabled.toString());
}
```

**Leer Preferencia ([lib/services/storage_service.dart](lib/services/storage_service.dart#L82-L88)):**
```dart
Future<bool> getTrackingEnabled() async {
  final value = await _storage.read(key: _keyTrackingEnabled);
  if (value == null) {
    return false; // Valor por defecto
  }
  return value.toLowerCase() == 'true';
}
```

**Uso en Preferences Screen ([lib/screens/preferences_screen.dart](lib/screens/preferences_screen.dart#L22-L28)):**
```dart
Future<void> _loadPreferences() async {
  final trackingEnabled = await _storageService.getTrackingEnabled();
  setState(() {
    _trackingEnabled = trackingEnabled;
    _isLoading = false;
  });
}
```

#### 4. Almacenamiento de Historial de Cálculos

**Guardar Cálculo de Distancia ([lib/services/storage_service.dart](lib/services/storage_service.dart#L93-L104)):**
```dart
Future<void> saveDistanceCalculation(DistanceCalculation calculation) async {
  final history = await getDistanceHistory();
  history.insert(0, calculation); // Agregar al inicio

  // Mantener solo las últimas 50 entradas
  if (history.length > 50) {
    history.removeRange(50, history.length);
  }

  final jsonList = history.map((calc) => calc.toJson()).toList();
  await _storage.write(key: _keyDistanceHistory, value: jsonEncode(jsonList));
}
```
- Convierte objetos complejos a JSON
- Los almacena como strings encriptados
- Mantiene un límite de 50 entradas

**Recuperar Historial:**
```dart
Future<List<DistanceCalculation>> getDistanceHistory() async {
  final value = await _storage.read(key: _keyDistanceHistory);
  if (value == null) return [];

  try {
    final List<dynamic> jsonList = jsonDecode(value);
    return jsonList
        .map((json) => DistanceCalculation.fromJson(json))
        .toList();
  } catch (e) {
    return [];
  }
}
```

#### 5. Almacenamiento de Viajes

**Guardar Viaje ([lib/services/storage_service.dart](lib/services/storage_service.dart#L131-L144)):**
```dart
Future<void> saveTrip(Trip trip) async {
  final trips = await getTrips();

  // Actualizar si existe, agregar si es nuevo
  final index = trips.indexWhere((t) => t.id == trip.id);
  if (index != -1) {
    trips[index] = trip;
  } else {
    trips.add(trip);
  }

  final jsonList = trips.map((t) => t.toJson()).toList();
  await _storage.write(key: _keyTrips, value: jsonEncode(jsonList));
}
```

#### 6. Almacenamiento de Rastreo Activo

**Guardar Rastreo Activo ([lib/services/storage_service.dart](lib/services/storage_service.dart#L188-L191)):**
```dart
Future<void> saveActiveTracking(TripTracking tracking) async {
  final json = tracking.toJson();
  await _storage.write(key: _keyActiveTracking, value: jsonEncode(json));
}
```
- Permite persistir el rastreo en curso
- Si la app se cierra, el rastreo puede continuar al reabrirla

**Recuperar Rastreo Activo ([lib/screens/trip_tracking_screen.dart](lib/screens/trip_tracking_screen.dart#L36-L46)):**
```dart
Future<void> _checkActiveTracking() async {
  final activeTracking = await _storageService.getActiveTracking();
  if (activeTracking != null && activeTracking.tripId == widget.trip.id) {
    setState(() {
      _tracking = activeTracking;
      _isTracking = true;
    });
    _startLocationTracking();
  }
}
```

#### 7. Limpieza de Datos

**Borrar Todo ([lib/services/storage_service.dart](lib/services/storage_service.dart#L70-L72)):**
```dart
Future<void> clearAll() async {
  await _storage.deleteAll();
}
```

**Borrar Entradas Específicas:**
```dart
Future<void> deleteLastLocation() async {
  await _storage.delete(key: _keyLastLat);
  await _storage.delete(key: _keyLastLng);
  await _storage.delete(key: _keyLastTimestamp);
}
```

### Estructura de Keys Utilizadas

```dart
// Ubicaciones
static const String _keyLastLat = 'lastLat';
static const String _keyLastLng = 'lastLng';
static const String _keyLastTimestamp = 'lastTimestamp';

// Preferencias
static const String _keyTrackingEnabled = 'trackingEnabled';

// Historial
static const String _keyDistanceHistory = 'distanceHistory';

// Viajes
static const String _keyTrips = 'trips';
static const String _keyActiveTracking = 'activeTracking';
static const String _keyTrackingHistory = 'trackingHistory';
```

### Ventajas de Seguridad

1. **Encriptación Automática:** Todos los datos se almacenan encriptados
2. **Aislamiento por App:** Los datos solo son accesibles por esta aplicación
3. **Protección en el Keychain/Keystore:**
   - iOS: Usa el Keychain nativo
   - Android: Usa el Android Keystore System

---

## 🔄 Integración entre Ambos Paquetes

### Ejemplo: Guardar Ubicación desde Geolocator

**En Map Screen ([lib/screens/map_screen.dart](lib/screens/map_screen.dart#L182-L224)):**

```dart
Future<void> _saveCurrentLocation() async {
  // 1. Obtener posición con Geolocator
  if (_currentPosition == null) {
    // Error: no hay ubicación
    return;
  }

  try {
    // 2. Guardar con Flutter Secure Storage
    await _storageService.saveLastLocation(
      latitude: _currentPosition!.latitude,
      longitude: _currentPosition!.longitude,
    );

    // 3. Actualizar UI
    setState(() {
      _lastSavedLocation = SavedLocation(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        timestamp: DateTime.now(),
      );
    });
  } catch (e) {
    // Manejar error
  }
}
```

### Ejemplo: Rastreo de Viaje Persistente

**En Trip Tracking Screen ([lib/screens/trip_tracking_screen.dart](lib/screens/trip_tracking_screen.dart#L116-L178)):**

```dart
void _startLocationTracking() {
  // 1. Configurar stream de Geolocator
  _positionSubscription = Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    ),
  ).listen((Position position) async {
    // 2. Calcular distancia con Geolocator
    final distanceFromLast = Geolocator.distanceBetween(
      lastPoint.latitude,
      lastPoint.longitude,
      position.latitude,
      position.longitude,
    );

    // 3. Actualizar tracking
    final updatedTracking = TripTracking(...);

    // 4. Persistir con Flutter Secure Storage
    await _storageService.saveActiveTracking(updatedTracking);
  });
}
```

---

## 📊 Resumen de Funcionalidades

| Funcionalidad | Geolocator | Flutter Secure Storage |
|---------------|------------|------------------------|
| Obtener ubicación actual | ✅ | - |
| Rastreo en tiempo real | ✅ | - |
| Cálculo de distancias | ✅ | - |
| Permisos de ubicación | ✅ | - |
| Guardar ubicaciones | - | ✅ |
| Guardar preferencias | - | ✅ |
| Historial de cálculos | - | ✅ |
| Persistir viajes | - | ✅ |
| Rastreo persistente | - | ✅ |
| Encriptación de datos | - | ✅ |

---

## 🎯 Conclusiones

1. **Geolocator** se utiliza para:
   - Obtener y rastrear la ubicación del usuario
   - Calcular distancias geográficas
   - Gestionar permisos de ubicación

2. **Flutter Secure Storage** se utiliza para:
   - Almacenar de forma segura datos de ubicación
   - Persistir preferencias del usuario
   - Guardar historial de cálculos y viajes
   - Mantener rastreos activos entre sesiones

3. **Integración:** Ambos paquetes trabajan juntos para proporcionar una experiencia completa de rastreo de ubicación con persistencia segura de datos.
