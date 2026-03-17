import 'package:flutter/material.dart';
import '../models/destination.dart';
import '../services/firebase_service.dart';

class DestinationFormScreen extends StatefulWidget {
  final Destination? destination;

  const DestinationFormScreen({super.key, this.destination});

  @override
  State<DestinationFormScreen> createState() => _DestinationFormScreenState();
}

class _DestinationFormScreenState extends State<DestinationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseService _firebaseService = FirebaseService();

  late TextEditingController _nombreController;
  late TextEditingController _descripcionController;
  late TextEditingController _paisController;
  late TextEditingController _ciudadController;
  late TextEditingController _latitudController;
  late TextEditingController _longitudController;

  String _categoriaSeleccionada = 'playa';
  final List<String> _categorias = ['playa', 'montaña', 'ciudad', 'cultural'];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nombreController =
        TextEditingController(text: widget.destination?.nombre ?? '');
    _descripcionController =
        TextEditingController(text: widget.destination?.descripcion ?? '');
    _paisController =
        TextEditingController(text: widget.destination?.pais ?? '');
    _ciudadController =
        TextEditingController(text: widget.destination?.ciudad ?? '');
    _latitudController = TextEditingController(
        text: widget.destination?.latitud.toString() ?? '');
    _longitudController = TextEditingController(
        text: widget.destination?.longitud.toString() ?? '');

    if (widget.destination != null) {
      _categoriaSeleccionada = widget.destination!.categoria;
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _paisController.dispose();
    _ciudadController.dispose();
    _latitudController.dispose();
    _longitudController.dispose();
    super.dispose();
  }

  Future<void> _saveDestination() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final destination = Destination(
      id: widget.destination?.id,
      nombre: _nombreController.text.trim(),
      descripcion: _descripcionController.text.trim(),
      pais: _paisController.text.trim(),
      ciudad: _ciudadController.text.trim(),
      categoria: _categoriaSeleccionada,
      latitud: double.parse(_latitudController.text.trim()),
      longitud: double.parse(_longitudController.text.trim()),
      fechaCreacion: widget.destination?.fechaCreacion ?? DateTime.now(),
    );

    bool success;
    if (widget.destination == null) {
      success = await _firebaseService.createDestination(destination);
    } else {
      success = await _firebaseService.updateDestination(destination);
    }

    setState(() => _isLoading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.destination == null
              ? 'Destino creado exitosamente'
              : 'Destino actualizado exitosamente'),
        ),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al guardar el destino'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.destination != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Destino' : 'Nuevo Destino'),
        backgroundColor: Colors.teal,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nombreController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del destino',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.place),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'El nombre es requerido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descripcionController,
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'La descripción es requerida';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _paisController,
                            decoration: const InputDecoration(
                              labelText: 'País',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.flag),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'El país es requerido';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _ciudadController,
                            decoration: const InputDecoration(
                              labelText: 'Ciudad',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.location_city),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'La ciudad es requerida';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _categoriaSeleccionada,
                      decoration: const InputDecoration(
                        labelText: 'Categoría',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: _categorias.map((categoria) {
                        return DropdownMenuItem(
                          value: categoria,
                          child: Text(categoria.toUpperCase()),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _categoriaSeleccionada = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _latitudController,
                            decoration: const InputDecoration(
                              labelText: 'Latitud',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.my_location),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Requerido';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Número inválido';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _longitudController,
                            decoration: const InputDecoration(
                              labelText: 'Longitud',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.my_location),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Requerido';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Número inválido';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _saveDestination,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        isEditing ? 'ACTUALIZAR DESTINO' : 'CREAR DESTINO',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
