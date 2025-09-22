// Archivo: lib/pages/bulk_product_entry_page.dart
// OPTIMIZADO para Flutter Web: mejor rendimiento en listas grandes.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_listados/data/products_data.dart' hide defaultUnits;
import 'package:flutter_listados/data/units.dart';
import 'package:flutter_listados/models/product.dart';
import 'package:flutter_listados/utils/pdf_utils.dart';

import '../widgets/product_entry_row.dart';

class BulkProductEntryPage extends StatefulWidget {
  final List<Product> currentProducts;

  const BulkProductEntryPage({
    super.key,
    required this.currentProducts,
  });

  @override
  State<BulkProductEntryPage> createState() => _BulkProductEntryPageState();
}

class _BulkProductEntryPageState extends State<BulkProductEntryPage> {
  final Map<String, Product> _tempProductsState = {};
  late final List<Product> _allProducts;
  final ValueNotifier<List<Product>> _displayProducts = ValueNotifier([]);
  final TextEditingController _searchController = TextEditingController();

  late final List<DropdownMenuItem<UnitType>> _unitTypeDropdownItems;

  @override
  void initState() {
    super.initState();

    // 1. Combina productos existentes + catálogo disponible
    for (var p in widget.currentProducts) {
      _tempProductsState[p.name + p.id] = p;
    }
    for (var entry in productosDisponibles.entries) {
      final uniqueKey = entry.key + entry.value;
      _tempProductsState.putIfAbsent(uniqueKey, () {
        return Product(
          id: entry.value,
          name: entry.key,
          quantity: 0,
          unitPrice: 0.0,
          unit: defaultUnits[entry.key] ?? UnitType.Unidad,
        );
      });
    }

    // 2. Lista única ordenada
    _allProducts = _tempProductsState.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    // 3. Inicializa lista mostrada
    _displayProducts.value = List.of(_allProducts);

    // 4. Dropdown de unidades
    _unitTypeDropdownItems = UnitType.values.map((UnitType unit) {
      final unitName = unitMapping[unit]!['name']!;
      return DropdownMenuItem<UnitType>(
        value: unit,
        child: Text(unitName, style: const TextStyle(fontSize: 12)),
      );
    }).toList();

    // 5. Escucha cambios en el buscador
    _searchController.addListener(_filterProducts);
  }

  void _filterProducts() {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) {
      _displayProducts.value = List.of(_allProducts);
    } else {
      final matches = _allProducts
          .where((p) => p.name.toLowerCase().contains(query))
          .toList();
      final others = _allProducts
          .where((p) => !p.name.toLowerCase().contains(query))
          .toList();
      _displayProducts.value = [...matches, ...others];
    }
  }

  void _onProductRowChanged(Product updatedProduct) {
    _tempProductsState[updatedProduct.name + updatedProduct.id] =
        updatedProduct;
  }

  void _saveBulkEntry() {
    final productsToReturn = _tempProductsState.values.where((p) {
      return p.quantity > 0 || p.unitPrice > 0;
    }).toList();

    Navigator.of(context).pop(productsToReturn);
  }

  void _generatePdf() async {
    final productsToPrint = _tempProductsState.values.where((p) {
      return p.quantity > 0 || p.unitPrice > 0;
    }).toList();

    if (productsToPrint.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Generando PDF... por favor espere')),
      );

      final pdfData = await compute(generateProductListPdf, productsToPrint);

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF generado exitosamente.')),
        );
        // Aquí puedes agregar la opción de compartir/guardar pdfData
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No hay productos con cantidad o precio para exportar.')),
      );
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterProducts);
    _searchController.dispose();
    _displayProducts.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Entrada de Productos (Estilo Excel)'),
        actions: [
        ],
      ),
      body: Column(
        children: [
          // Buscador
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Buscar producto...',
                suffixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          // Encabezado de tabla
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              border: Border(bottom: BorderSide(color: Colors.grey.shade400)),
            ),
            child: Row(
              children: const [
                Expanded(
                  flex: 4,
                  child: Text('Producto',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  flex: 2,
                  child: Text('Cant.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  flex: 3,
                  child: Text('Precio',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  flex: 3,
                  child: Text('Unidad',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          // Lista de productos (reactiva)
          Expanded(
            child: ValueListenableBuilder<List<Product>>(
              valueListenable: _displayProducts,
              builder: (_, products, __) {
                return ListView.builder(
                  cacheExtent: 0.0, // Menos carga en web
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    final uniqueKey = product.name + product.id;

                    return ProductEntryRow(
                      key: ValueKey(uniqueKey),
                      initialProduct: product,
                      index: index,
                      onChanged: _onProductRowChanged,
                      unitTypeDropdownItems: _unitTypeDropdownItems,
                    );
                  },
                );
              },
            ),
          ),
          // Botón de guardar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _saveBulkEntry,
                icon: const Icon(Icons.check),
                label: const Text('Guardar y Añadir a Lista',
                    style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}