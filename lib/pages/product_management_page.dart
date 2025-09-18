// Archivo: product_management_page.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_listados/models/lista_productos.dart';
import 'package:flutter_listados/widgets/ProductSearchSheet.dart';
import 'package:universal_html/html.dart' as html;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/product.dart';
import '../utils/export_utils.dart';

class ProductManagementPage extends StatefulWidget {
  final String puntoId;
  final String puntoName;

  const ProductManagementPage({
    super.key,
    required this.puntoId,
    required this.puntoName,
  });

  @override
  State<ProductManagementPage> createState() => _ProductManagementPageState();
}

class _ProductManagementPageState extends State<ProductManagementPage> {
  final List<Product> _products = [];
  bool _hasUnsavedChanges = false;
  late String _storageKey;

  void _onBeforeUnload(html.Event event) {
    if (_hasUnsavedChanges) {
      (event as html.BeforeUnloadEvent).returnValue =
          'Are you sure you want to leave?';
    }
  }

  @override
  void initState() {
    super.initState();
    _storageKey = 'products_list_${widget.puntoId}';
    _loadProducts();
    if (kIsWeb) {
      html.window.addEventListener('beforeunload', _onBeforeUnload);
    }
  }

  @override
  void dispose() {
    if (kIsWeb) {
      html.window.removeEventListener('beforeunload', _onBeforeUnload);
    }
    super.dispose();
  }

  Future<void> _saveProducts() async {
    final prefs = await SharedPreferences.getInstance();
    if (_products.isEmpty) {
      await prefs.remove(_storageKey);
      debugPrint('Lista de productos vacía. Datos borrados del caché.');
    } else {
      final productsJson =
          jsonEncode(_products.map((p) => p.toJson()).toList());
      await prefs.setString(_storageKey, productsJson);
      debugPrint('Lista de productos guardada en la clave: $_storageKey');
    }
  }

  Future<void> _loadProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final savedProducts = prefs.getString(_storageKey);
    debugPrint('Intentando cargar lista de la clave: $_storageKey');
    if (savedProducts != null && savedProducts.isNotEmpty) {
      try {
        final List<dynamic> productsJson = jsonDecode(savedProducts);
        setState(() {
          _products.clear();
          _products.addAll(productsJson
              .map((p) => Product.fromJson(p as Map<String, dynamic>))
              .toList());
        });
        debugPrint('Lista de productos cargada exitosamente.');
      } catch (e) {
        debugPrint('Error al decodificar JSON guardado: $e');
        await prefs.remove(_storageKey);
        debugPrint('Datos de caché corruptos borrados.');
      }
    } else {
      debugPrint('No se encontraron datos guardados en la clave: $_storageKey');
    }
  }

  void _addProduct(Product p) {
    setState(() {
      _products.add(p);
      _hasUnsavedChanges = true;
    });
    _saveProducts();
  }

  void _editProduct(int index, Product p) {
    setState(() {
      _products[index] = p;
      _hasUnsavedChanges = true;
    });
    _saveProducts();
  }

  void _confirmDelete(int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Desea eliminar el producto "${_products[index].name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              _deleteProduct(index);
              Navigator.of(context).pop();
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _deleteProduct(int index) {
    setState(() {
      _products.removeAt(index);
      _hasUnsavedChanges = true;
    });
    _saveProducts();
  }

  void _showAddProductSheet() async {
    final result = await showModalBottomSheet<Product>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ProductSearchSheet(
        productosDisponibles: productosDisponibles, // ✅ Pasa la nueva lista
      ),
    );
    if (result != null) _addProduct(result);
  }


  void _finalizeList() {
    if (_products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No hay productos en la lista")),
      );
      return;
    }

    _hasUnsavedChanges = false;
    _clearSavedProducts();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Exportar lista'),
        content: const Text('Elija el formato de exportación:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              await shareZip(
                _products,
                puntoId: widget.puntoId,
                puntoName: widget.puntoName,
                context: context,
              );
              if (context.mounted) _showCompletionDialog();
            },
            child: const Text('ZIP'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearSavedProducts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    debugPrint('Datos de caché borrados para la clave: $_storageKey');
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Operación completada'),
          content: const Text(
              '¿Deseas permanecer en esta lista o comenzar una nueva?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Seguir editando la lista'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _products.clear();
                });
                _clearSavedProducts();
                Navigator.of(context).pop(); // Cierra el diálogo
                // ✅ Agregamos un segundo pop para regresar a la página anterior
                Navigator.of(context).pop();
              },
              child: const Text('Salir y borrar la lista'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalQuantity =
        _products.fold<int>(0, (sum, product) => sum + product.quantity);
    final totalPrice = _products.fold<double>(
        0.0, (sum, product) => sum + product.subtotal);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.puntoName,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                blurRadius: 2.0,
                color: Colors.black38,
                offset: Offset(1, 1),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _products.isEmpty
                ? const Center(
                    child: Text(
                      'No hay productos agregados.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _products.length,
                    itemBuilder: (context, index) {
                      final p = _products[index];
                      return Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          leading: CircleAvatar(
                            backgroundColor: Colors.deepPurple.shade100,
                            child: Text(p.quantity.toString(),
                                style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold)),
                          ),
                          title: Text(
                            p.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: Text(
                            '${p.unit.name} x \$${p.unitPrice.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          trailing: SizedBox(
                            width: 150,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: Text(
                                    '\$${p.subtotal.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blueAccent),
                                    textAlign: TextAlign.right,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  icon:
                                      const Icon(Icons.edit, color: Colors.green),
                                  onPressed: () async {
                                    final edited =
                                        await showModalBottomSheet<Product>(
                                      context: context,
                                      isScrollControlled: true,
                                      builder: (_) => ProductSearchSheet(
                                        initialProduct: p,
                                        productosDisponibles:
                                            productosDisponibles,
                                      ),
                                    );
                                    if (edited != null) {
                                      _editProduct(index, edited);
                                    }
                                  },
                                  tooltip: 'Editar',
                                ),
                                IconButton(
                                  icon:
                                      const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _confirmDelete(index),
                                  tooltip: 'Eliminar',
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (_products.isNotEmpty)
            Card(
              elevation: 4,
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Bultos:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$totalQuantity',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Precio Total:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '\$${totalPrice.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.grey.shade100,
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: _showAddProductSheet,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      icon: const Icon(Icons.add_circle_outline, size: 28),
                      label: const Text(
                        'Agregar Producto',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: _finalizeList,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      icon: const Icon(Icons.check_circle_outline, size: 28),
                      label: const Text(
                        'Finalizar Lista',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}