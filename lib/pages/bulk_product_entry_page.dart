// Archivo: lib/pages/bulk_product_entry_page.dart
// Modificado: Simplifica la inicialización ya que solo gestiona "currentProducts" (los de Excel).

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_listados/data/products_data.dart' hide defaultUnits;
import 'package:flutter_listados/data/units.dart';
import 'package:flutter_listados/models/product.dart';
import 'package:flutter_listados/utils/pdf_utils.dart';

import '../widgets/product_entry_row.dart';

class BulkProductEntryPage extends StatefulWidget {
  // ✅ Recibe solo la lista de productos que debe gestionar el "modo Excel"
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

    // ✅ Inicializa _tempProductsState solo con los productos que le llegan
    // (que ahora son solo los que pertenecen a la categoría "bulk entry")
    for (var p in widget.currentProducts) {
      // Usamos name+id para una clave única para productos con mismo nombre pero IDs diferentes
      _tempProductsState[p.name + p.id] = p;
    }

    // Luego, itera sobre los productos disponibles por defecto.
    // Si un producto default NO está ya en _tempProductsState, lo añade.
    // Esto asegura que los productos "maestros" siempre estén disponibles para añadir.
    for (var entry in productosDisponibles.entries) {
      final productName = entry.key;
      final productId = entry.value;
      final uniqueKey = productName + productId;

      if (!_tempProductsState.containsKey(uniqueKey)) {
        _tempProductsState[uniqueKey] = Product(
          id: productId,
          name: productName,
          quantity: 0,
          unitPrice: 0.0,
          unit: defaultUnits[productName] ?? UnitType.Unidad,
        );
      }
    }
    
    // Genera _sortedProductNames y FocusNodes de la misma manera que antes
    _sortedProductNames = _tempProductsState.values.map((p) => p.name).toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      
    for (var p in _tempProductsState.values) {
        // Aseguramos que solo se cree un FocusNode por nombre de producto si no existe ya
        if (!_quantityFocusNodes.containsKey(p.name)) {
            _quantityFocusNodes[p.name] = FocusNode();
            _unitPriceFocusNodes[p.name] = FocusNode();
        }
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
    _tempProductsState[updatedProduct.name + updatedProduct.id] = updatedProduct;
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
    _tempProductsState.forEach((key, product) {
      if (product.quantity > 0 && product.unitPrice >= 0) {
        productsToReturn.add(product);
      }
    });
    Navigator.of(context).pop(productsToReturn); // ✅ Devuelve solo los productos de entrada masiva
  }
  
  void _generatePdf() async {
    final List<Product> productsToPrint = [];
    _tempProductsState.forEach((key, product) {
      if (product.quantity > 0 && product.unitPrice >= 0) {
        productsToPrint.add(product);
      }
    });
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
              itemCount: _tempProductsState.length,
              itemBuilder: (context, index) {
                final productEntry = _tempProductsState.entries.elementAt(index); // Acceder por MapEntry
                final product = productEntry.value;
                
                final quantityFN = _quantityFocusNodes[product.name];
                final unitPriceFN = _unitPriceFocusNodes[product.name];

                return ProductEntryRow(
                  key: ValueKey(product.name + product.id),
                  initialProduct: product,
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