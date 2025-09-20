// Archivo: lib/pages/bulk_product_entry_page.dart
// Actualizado para generar el PDF en segundo plano y prevenir el congelamiento.


import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_listados/data/lista_productos.dart';
import 'package:flutter_listados/models/default_units.dart';
import 'package:flutter_listados/models/product.dart';
import 'package:flutter_listados/utils/generador_pdf.dart';

import '../widgets/product_entry_row.dart';

// ✅ Tarea pesada para crear el PDF, ejecutada en segundo plano
Future<void> _generatePdfInBackground(List<Product> productsToPrint) async {
  await generateProductListPdf(productsToPrint, openFile: true);
}

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
  List<String> _sortedProductNames = [];
  late final List<DropdownMenuItem<UnitType>> _unitTypeDropdownItems;
  final Map<String, FocusNode> _quantityFocusNodes = {};
  final Map<String, FocusNode> _unitPriceFocusNodes = {};
  
  @override
  void initState() {
    super.initState();
    if (widget.currentProducts.isEmpty) {
        for (var entry in productosDisponibles.entries) {
          final productName = entry.key;
          _tempProductsState[productName] = Product(
            id: entry.value,
            name: productName,
            quantity: 0,
            unitPrice: 0.0,
            unit: defaultUnits[productName] ?? UnitType.Unidad,
          );
        }
    } else {
        for (var p in widget.currentProducts) {
          _tempProductsState[p.name] = p;
        }
        for (var entry in productosDisponibles.entries) {
          final productName = entry.key;
          if (!_tempProductsState.containsKey(productName)) {
             _tempProductsState[productName] = Product(
              id: entry.value,
              name: productName,
              quantity: 0,
              unitPrice: 0.0,
              unit: defaultUnits[productName] ?? UnitType.Unidad,
            );
          }
        }
    }

    _sortedProductNames = _tempProductsState.keys.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      
    for (var productName in _sortedProductNames) {
      _quantityFocusNodes[productName] = FocusNode();
      _unitPriceFocusNodes[productName] = FocusNode();
    }

    _unitTypeDropdownItems = UnitType.values.map((UnitType unit) {
      return DropdownMenuItem<UnitType>(
        value: unit,
        child: Text(unit.name, style: const TextStyle(fontSize: 12)),
      );
    }).toList();
  }

  @override
  void dispose() {
    _quantityFocusNodes.forEach((key, node) => node.dispose());
    _unitPriceFocusNodes.forEach((key, node) => node.dispose());
    super.dispose();
  }

  void _onProductRowChanged(Product updatedProduct) {
    _tempProductsState[updatedProduct.name] = updatedProduct;
  }
  
  void _focusNextProductQuantity(String currentProductName) {
    final int currentIndex = _sortedProductNames.indexOf(currentProductName);
    if (currentIndex + 1 < _sortedProductNames.length) {
      final nextProductName = _sortedProductNames[currentIndex + 1];
      FocusScope.of(context).requestFocus(_quantityFocusNodes[nextProductName]);
    } else {
      FocusScope.of(context).unfocus();
    }
  }

  void _saveBulkEntry() {
    List<Product> productsToReturn = [];
    _tempProductsState.forEach((productName, product) {
      if (product.quantity > 0 && product.unitPrice >= 0) {
        productsToReturn.add(product);
      }
    });
    Navigator.of(context).pop(productsToReturn);
  }
  
  void _generatePdf() async {
    final List<Product> productsToPrint = [];
    _tempProductsState.forEach((productName, product) {
      if (product.quantity > 0 && product.unitPrice >= 0) {
        productsToPrint.add(product);
      }
    });
    if (productsToPrint.isNotEmpty) {
      // ✅ Mostrar un indicador de carga antes de la operación
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Generando PDF... por favor espere')),
      );
      // ✅ Usamos compute() para que la generación no congele la UI
      await compute(_generatePdfInBackground, productsToPrint);
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF generado exitosamente.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay productos con cantidad o precio para exportar.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Entrada de Productos (Estilo Excel)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _generatePdf,
            tooltip: 'Generar PDF',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              border: Border(bottom: BorderSide(color: Colors.grey.shade400)),
            ),
            child: Row(
              children: const [
                Expanded(flex: 4, child: Text('Producto', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('Cant.', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 3, child: Text('Precio', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 3, child: Text('Unidad', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              cacheExtent: 1000.0,
              itemCount: _sortedProductNames.length,
              itemBuilder: (context, index) {
                final productName = _sortedProductNames[index];
                
                final quantityFN = _quantityFocusNodes[productName];
                final unitPriceFN = _unitPriceFocusNodes[productName];

                return ProductEntryRow(
                  key: ValueKey(productName),
                  initialProduct: _tempProductsState[productName]!,
                  index: index,
                  onChanged: _onProductRowChanged,
                  unitTypeDropdownItems: _unitTypeDropdownItems,
                  quantityFocusNode: quantityFN,
                  unitPriceFocusNode: unitPriceFN,
                  onFocusMoveToNextProduct: _focusNextProductQuantity,
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _saveBulkEntry,
                icon: const Icon(Icons.check),
                label: const Text('Guardar y Añadir a Lista', style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}