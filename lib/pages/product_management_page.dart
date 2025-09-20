// Archivo: lib/pages/product_management_page.dart
// Modificado: Se restauran los botones flotantes y se añade espacio para evitar obstrucciones.

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_listados/data/dispatch_points.dart';
import 'package:flutter_listados/data/products_data.dart';
import 'package:flutter_listados/models/product.dart';
import 'package:flutter_listados/utils/export_utils.dart';
import 'package:flutter_listados/widgets/product_modal.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'bulk_product_entry_page.dart';

class ProductManagementPage extends StatefulWidget {
  final String? initialPuntoName;

  const ProductManagementPage({
    super.key,
    this.initialPuntoName,
  });

  @override
  State<ProductManagementPage> createState() => _ProductManagementPageState();
}

class _ProductManagementPageState extends State<ProductManagementPage> {
  List<Product> _manualProducts = [];
  List<Product> _bulkEntryProducts = [];
  String? _selectedPunto;

  @override
  void initState() {
    super.initState();
    if (widget.initialPuntoName != null) {
      _selectedPunto = widget.initialPuntoName;
      _saveSelectedPunto(widget.initialPuntoName);
    } else {
      _loadPuntosDespacho();
    }
    _loadProducts();
  }

  Future<void> _saveSelectedPunto(String? puntoName) async {
    final prefs = await SharedPreferences.getInstance();
    if (puntoName != null) {
      await prefs.setString('selectedPunto', puntoName);
    } else {
      await prefs.remove('selectedPunto');
    }
  }

  Future<void> _loadPuntosDespacho() async {
    final prefs = await SharedPreferences.getInstance();
    final puntoString = prefs.getString('selectedPunto');
    if (puntoString != null) {
      setState(() {
        _selectedPunto = puntoString;
      });
    }
  }

  Future<void> _loadProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final manualProductsJson = prefs.getStringList('manualProducts');
    final bulkEntryProductsJson = prefs.getStringList('bulkEntryProducts');

    setState(() {
      if (manualProductsJson != null) {
        _manualProducts = manualProductsJson
            .map((item) => Product.fromJson(jsonDecode(item)))
            .toList();
      }
      if (bulkEntryProductsJson != null) {
        _bulkEntryProducts = bulkEntryProductsJson
            .map((item) => Product.fromJson(jsonDecode(item)))
            .toList();
      }
    });
  }

  Future<void> _saveProducts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        'manualProducts', _manualProducts.map((item) => jsonEncode(item.toJson())).toList());
    await prefs.setStringList(
        'bulkEntryProducts', _bulkEntryProducts.map((item) => jsonEncode(item.toJson())).toList());
  }

  void _addManualProduct(Product newProduct) {
    setState(() {
      final existingIndex = _manualProducts.indexWhere(
        (p) => p.id == newProduct.id && p.unitPrice == newProduct.unitPrice,
      );

      if (existingIndex != -1) {
        final existingProduct = _manualProducts[existingIndex];
        _manualProducts[existingIndex] = existingProduct.copyWith(
          quantity: existingProduct.quantity + newProduct.quantity,
        );
      } else {
        _manualProducts.add(newProduct);
      }
      _manualProducts.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    });
    _saveProducts();
  }

  void _editProduct(int index, List<Product> productList) async {
    final initialProduct = productList[index];
    final result = await showModalBottomSheet<Product?>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ProductSearchSheet(
        productosDisponibles: productosDisponibles,
        initialProduct: initialProduct,
      ),
    );
    if (result != null) {
      setState(() {
        productList[index] = result;
        productList.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      });
      _saveProducts();
    }
  }

  void _deleteProduct(int index, List<Product> productList, String listName) {
    setState(() {
      productList.removeAt(index);
    });
    _saveProducts();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Producto de $listName eliminado.')),
    );
  }

  void _navigateToBulkEntry() async {
    final updatedBulkProducts = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BulkProductEntryPage(
          currentProducts: _bulkEntryProducts,
        ),
      ),
    );
    if (updatedBulkProducts != null) {
      setState(() {
        _bulkEntryProducts = updatedBulkProducts;
      });
      _saveProducts();
    }
  }

  Future<void> _showExportDialog() async {
    final allProductsForExport = [..._manualProducts, ..._bulkEntryProducts];
    if (allProductsForExport.isEmpty || _selectedPunto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe haber productos en la lista y un punto seleccionado para exportar.'),
        ),
      );
      return;
    }

    allProductsForExport.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    final String puntoId = puntosDespacho[_selectedPunto]!;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Descargar archivo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.archive),
                  label: const Text('Descargar archivo'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    shareZip(allProductsForExport, puntoId: puntoId, puntoName: _selectedPunto!, context: context);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('¿Estás seguro?'),
          content: const Text('Esta acción borrará todas las listas de productos de forma permanente.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Sí, borrar'),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _manualProducts.clear();
                  _bulkEntryProducts.clear();
                });
                _saveProducts();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Todas las listas borradas.')),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final combinedProducts = [..._manualProducts, ..._bulkEntryProducts];
    combinedProducts.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    final totalQuantity = combinedProducts.fold(0.0, (sum, product) => sum + product.quantity);
    final totalPrice = combinedProducts.fold(0.0, (sum, product) => sum + (product.quantity * product.unitPrice));

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedPunto != null ? 'Productos (${_selectedPunto!})' : 'Gestión de Productos'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (String result) {
              if (result == 'export') {
                _showExportDialog();
              } else if (result == 'delete') {
                _showDeleteConfirmationDialog();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.download, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Descargar archivo'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Eliminar lista', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              if (combinedProducts.isNotEmpty)
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Resumen de la lista', style: Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: 8),
                        Text('Cantidad total de productos: ${totalQuantity.toStringAsFixed(2)}'),
                        Text('Costo total de la lista: \$${totalPrice.toStringAsFixed(2)}'),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              if (combinedProducts.isNotEmpty)
                Column(
                  children: combinedProducts.map((product) {
                    final isManual = _manualProducts.contains(product);
                    final cardColor = isManual ? Colors.grey[200] : null;
                    final noteText = isManual ? 'Producto agregado a mano' : null;
                    final productList = isManual ? _manualProducts : _bulkEntryProducts;
                    final listType = isManual ? 'manual' : 'entrada masiva';
                    final index = productList.indexOf(product);

                    return Card(
                      color: cardColor,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        title: Text(product.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Cantidad: ${product.quantity} - Precio: \$${product.unitPrice.toStringAsFixed(2)}'),
                            if (noteText != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  noteText,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _editProduct(index, productList),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteProduct(index, productList, listType),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              if (combinedProducts.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: Text('No hay productos en la lista.', style: TextStyle(color: Colors.grey)),
                  ),
                ),
              // ✅ Se añade un espacio al final de la lista para acomodar los botones flotantes
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
      // ✅ Se restauran los botones flotantes
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'addBulkBtn',
            onPressed: _navigateToBulkEntry,
            label: const Text('Entrada Masiva (Excel)'),
            icon: const Icon(Icons.table_chart),
          ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            heroTag: 'addProductBtn',
            onPressed: () async {
              final result = await showModalBottomSheet<Product?>(
                context: context,
                isScrollControlled: true,
                builder: (_) => ProductSearchSheet(
                  productosDisponibles: productosDisponibles,
                ),
              );
              if (result != null) {
                _addManualProduct(result);
              }
            },
            label: const Text('Añadir Producto Manual'),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}