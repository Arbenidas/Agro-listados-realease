// lib/pages/bulk_product_entry_page.dart
// OPTIMIZADO con lógica de validación y corrección.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_listados/data/products_data.dart';
import 'package:flutter_listados/data/units.dart';
import 'package:flutter_listados/models/product.dart';
import 'package:flutter_listados/utils/pdf_utils.dart';

// --- NUEVOS IMPORTS ---
import 'package:flutter_listados/data/product_mapping.dart';
import '../widgets/product_entry_row.dart';
import '../widgets/ad_interstitial_dialog.dart';
// Asegúrate de tener dropdown_search en tu pubspec.yaml
// (ya lo tenías)

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

  // --- NUEVO: Set para rastrear productos inválidos ---
  final Set<String> _invalidProductKeys = {};

  // --- NUEVO: Lista de productos disponibles para el DropdownSearch ---
  late final List<MapEntry<String, String>> _availableProductEntries;

  @override
  void initState() {
    super.initState();

    // 1. Pre-procesa y normaliza los productos entrantes
    _processAndNormalizeProducts();

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

    // 5. Prepara la lista para DropdownSearch
    _availableProductEntries = productosDisponibles.entries.toList()
      ..sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase()));

    // 6. Escucha cambios en el buscador
    _searchController.addListener(_filterProducts);
  }

  /// --- NUEVO: Lógica de normalización y validación ---
  void _processAndNormalizeProducts() {
    // Procesa productos existentes (ej. de un CSV)
    for (var p in widget.currentProducts) {
      Product productToProcess = p;
      bool isInvalid = false;
      String originalKey = p.name + p.id;

      // 1. Verifica si el producto necesita normalización (Id 0 o vacío)
      if (p.id == "0" || p.id.isEmpty) {
        String? cleanNameKey = productNormalizationMap[p.name.trim().toUpperCase()];

        // 2. Intenta mapeo automático
        if (cleanNameKey != null &&
            productosDisponibles.containsKey(cleanNameKey)) {
          // ¡Éxito! Producto normalizado automáticamente
          productToProcess = p.copyWith(
            id: productosDisponibles[cleanNameKey],
            name: cleanNameKey,
            unit: defaultUnits[cleanNameKey] ?? p.unit, // Actualiza unidad
          );
        } else {
          // 3. Falla el mapeo automático, marcar como inválido
          isInvalid = true;
        }
      }

      final uniqueKey =
          productToProcess.name + productToProcess.id;

      if (isInvalid) {
        // Si es inválido, usamos la clave original (con Id 0) para rastrearlo
        _invalidProductKeys.add(originalKey);
        _tempProductsState[originalKey] = productToProcess;
      } else {
         // Si es válido o se corrigió, lo agregamos/actualizamos
        _tempProductsState[uniqueKey] = productToProcess;
      }
    }

    // Agrega el resto del catálogo (productos que no estaban en la lista)
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

  /// --- NUEVO: Callback para cuando un producto es corregido manualmente ---
  void _onProductCorrected(
      Product oldProduct, MapEntry<String, String> newProductEntry) {
    final oldKey = oldProduct.name + oldProduct.id;

    // Crea el nuevo producto "corregido"
    final correctedProduct = Product(
      id: newProductEntry.value, // ID corregido
      name: newProductEntry.key, // Nombre corregido
      quantity: oldProduct.quantity, // Mantiene cantidad
      unitPrice: oldProduct.unitPrice, // Mantiene precio
      unit: defaultUnits[newProductEntry.key] ?? UnitType.Unidad, // Unidad por defecto
    );

    final newKey = correctedProduct.name + correctedProduct.id;

    setState(() {
      // 1. Actualiza el estado temporal
      _tempProductsState.remove(oldKey);
      _tempProductsState[newKey] = correctedProduct;

      // 2. Quita la marca de inválido
      _invalidProductKeys.remove(oldKey);

      // 3. Actualiza la lista de productos (para UI y búsqueda)
      _allProducts.removeWhere((p) => (p.name + p.id) == oldKey);
      _allProducts.add(correctedProduct);
      _allProducts
        .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      // 4. Refresca la lista visible
      _filterProducts();
    });
  }

  /// --- MODIFICADO: Bloquea el guardado si hay inválidos ---
  void _saveBulkEntry() {
    FocusScope.of(context).unfocus();
    // 1. Revisa si AÚN quedan inválidos
    // Es posible que el usuario no haya corregido todos.
    bool hasInvalidProducts = false;
    for (String key in _tempProductsState.keys) {
      if (_invalidProductKeys.contains(key)) {
        hasInvalidProducts = true;
        break;
      }
    }

    if (hasInvalidProducts) {
      // 2. Si hay, muestra error y no guardes
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Error de Validación'),
          content: const Text(
              'Aún existen productos marcados en rojo. Por favor, corrija todos los productos no válidos (seleccionando un reemplazo) antes de guardar.'),
          actions: [
            TextButton(
              child: const Text('Entendido'),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      );
      return; // Detiene el guardado
    }

    // 3. Si todo está bien, filtra los que no tienen cantidad NI precio
    final productsToReturn = _tempProductsState.values.where((p) {
      // Asegurarnos de no incluir productos inválidos (doble chequeo)
      if (_invalidProductKeys.contains(p.name + p.id)) {
        return false;
      }
      // Filtro principal: solo devuelve los que tienen datos
      return p.quantity > 0 || p.unitPrice > 0;
    }).toList();


    // 4. Procede a guardar
    Navigator.of(context).pop(productsToReturn);
  }

  void _generatePdf() async {
    // ... (Tu código existente para PDF)
    // Recomendación: Aplicar la misma validación de _saveBulkEntry
    // para no imprimir PDFs con productos inválidos.
    final productsToPrint = _tempProductsState.values.where((p) {
      return (p.quantity > 0 || p.unitPrice > 0) &&
          !_invalidProductKeys.contains(p.name + p.id);
    }).toList();

    if (productsToPrint.isNotEmpty) {
      // Usa el diálogo de anuncio antes de generar el PDF
      AdInterstitialDialog.show(context, () async {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Generando PDF... por favor espere')),
        );

        await compute(generateProductListPdf, productsToPrint);

        if (context.mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PDF generado exitosamente.')),
          );
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'No hay productos válidos con cantidad o precio para exportar.')),
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
          // Tu acción de PDF, si la tenías
          IconButton(
            icon: Icon(Icons.picture_as_pdf),
            onPressed: _generatePdf,
            tooltip: 'Generar PDF (Solo válidos)',
          )
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

                    // --- MODIFICADO: Pasa los nuevos parámetros ---
                    return ProductEntryRow(
                      key: ValueKey(uniqueKey), // Clave única
                      initialProduct: product,
                      index: index,
                      onChanged: _onProductRowChanged,
                      unitTypeDropdownItems: _unitTypeDropdownItems,
                      // --- NUEVOS PARÁMETROS ---
                      isInvalid: _invalidProductKeys.contains(uniqueKey),
                      availableProducts: _availableProductEntries,
                      onCorrectProduct: (newProductEntry) {
                        _onProductCorrected(product, newProductEntry);
                      },
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