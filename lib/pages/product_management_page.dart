// Archivo: lib/pages/product_management_page.dart
// MODIFICADO:
// 1. _importCsvAndAddProducts: Mantiene el nombre original de CDA pero asigna el ID correcto.
// 2. _buildProductListUI: Separa los productos de CDA, los pone al final y los muestra con opacidad.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_listados/data/dispatch_points.dart';
import 'package:flutter_listados/data/product_icons.dart';
import 'package:flutter_listados/data/products_data.dart';
import 'package:flutter_listados/data/units.dart';
import 'package:flutter_listados/models/managed_list.dart';
import 'package:flutter_listados/models/product.dart';
import 'package:flutter_listados/utils/export_utils.dart';
import 'package:flutter_listados/widgets/product_modal.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_listados/data/product_mapping.dart';

import 'bulk_product_entry_page.dart';

class ProductManagementPage extends StatefulWidget {
  // ... (código sin cambios) ...
  final String? initialPuntoName;

  const ProductManagementPage({
    super.key,
    this.initialPuntoName,
  });

  @override
  State<ProductManagementPage> createState() => _ProductManagementPageState();
}

class _ProductManagementPageState extends State<ProductManagementPage>
    with TickerProviderStateMixin {
  final List<ManagedList> _listas = [];
  late TabController _tabController;

  late final Map<String, UnitType> _inverseUnitMap;
  bool _isLoading = true;

  // --- Mapas pre-calculados para búsqueda rápida ---
  late final Map<String, String> _normalizedMasterProductMap; // Mapa de productos limpios
  late final Map<String, String> _normalizedMapping; // Mapa de "CENTRAL DE ABASTOS"

  @override
  void initState() {
    super.initState();
    _initializeInverseUnitMap();
    _initializeNormalizationMaps();
    _loadAllLists(initialPuntoName: widget.initialPuntoName);
  }

  // --- Nueva función para normalizar texto (ignora tildes, mayúsculas) ---
  String _normalizeString(String s) {
    return s
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ñ', 'n');
  }

  // --- Pre-calcula los mapas para una búsqueda más rápida ---
  void _initializeNormalizationMaps() {
    _normalizedMasterProductMap = {};
    for (final cleanName in productosDisponibles.keys) {
      _normalizedMasterProductMap[_normalizeString(cleanName)] = cleanName;
    }
    _normalizedMapping = {};
    for (final entry in productNormalizationMap.entries) {
      _normalizedMapping[_normalizeString(entry.key)] = entry.value;
    }
  }

  // --- LÓGICA DE CARGA Y GUARDADO ---
  // ... (Sin cambios en _loadAllLists, _saveProducts, _initializeInverseUnitMap, _getUnitTypeFromString) ...
  Future<void> _loadAllLists({String? initialPuntoName}) async {
    final prefs = await SharedPreferences.getInstance();
    final listasJson = prefs.getString('managedLists');
    int lastActiveIndex = prefs.getInt('lastActiveListIndex') ?? 0;
    int targetTabIndex = lastActiveIndex;

    if (listasJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(listasJson);
        _listas.addAll(decoded.map((json) => ManagedList.fromJson(json)));
      } catch (e) {
        debugPrint("Error al decodificar listas guardadas: $e");
      }
    }

    if (_listas.isEmpty) {
      _listas.add(ManagedList(puntoName: "Nueva Lista", puntoId: ""));
      lastActiveIndex = 0;
      targetTabIndex = 0;
    }

    if (lastActiveIndex >= _listas.length) {
      lastActiveIndex = 0;
      targetTabIndex = 0;
    }

    if (initialPuntoName != null) {
      final existingIndex =
          _listas.indexWhere((lista) => lista.puntoName == initialPuntoName);

      if (existingIndex != -1) {
        targetTabIndex = existingIndex;
      } else {
        final puntoId = puntosDespacho[initialPuntoName];
        if (puntoId != null) {
          final newList =
              ManagedList(puntoName: initialPuntoName, puntoId: puntoId);
          setState(() {
            _listas[lastActiveIndex] = newList;
          });
          targetTabIndex = lastActiveIndex;
          await _saveProducts();
        }
      }
    }

    _tabController = TabController(
      length: _listas.length,
      vsync: this,
      initialIndex: targetTabIndex,
    );

    _tabController.addListener(() async {
      if (!_tabController.indexIsChanging) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('lastActiveListIndex', _tabController.index);
        setState(() {});
      }
    });

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonList =
        jsonEncode(_listas.map((lista) => lista.toJson()).toList());
    await prefs.setString('managedLists', jsonList);
  }

  void _initializeInverseUnitMap() {
    _inverseUnitMap = {};
    unitMapping.forEach((key, value) {
      _inverseUnitMap[value['name']!.toLowerCase()] = key;
    });
  }

  UnitType _getUnitTypeFromString(String unitName) {
    final cleanedName = unitName.trim().toLowerCase();
    return _inverseUnitMap[cleanedName] ?? UnitType.Unidad;
  }

  // --- LÓGICA DE GESTIÓN DE LISTAS (PESTAÑAS) ---
  // ... (Sin cambios aquí: _promptAddNewList, _addNewList, _confirmRemoveList, _promptDuplicateList) ...
  void _promptAddNewList() {
    String? selectedPunto;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Añadir Nueva Lista'),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          content: DropdownSearch<String>(
            popupProps: PopupProps.menu(
              showSearchBox: true,
              searchFieldProps: TextFieldProps(
                decoration: InputDecoration(
                  labelText: "Buscar punto de venta",
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              constraints: BoxConstraints(maxHeight: 500),
            ),
            items: puntosDespacho.keys.toList()
              ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase())),
            dropdownDecoratorProps: DropDownDecoratorProps(
              dropdownSearchDecoration: InputDecoration(
                labelText: "Punto de Venta",
                hintText: "Selecciona un punto",
              ),
            ),
            onChanged: (String? newValue) {
              selectedPunto = newValue;
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Añadir'),
              onPressed: () {
                if (selectedPunto != null) {
                  _addNewList(selectedPunto!);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _addNewList(String puntoName, {bool duplicateFromCurrent = false}) async {
    final puntoId = puntosDespacho[puntoName];
    if (puntoId == null) return;

    List<Product> productsToCopy = [];

    if (duplicateFromCurrent && _listas.isNotEmpty) {
      final currentList = _listas[_tabController.index];
      productsToCopy =
          currentList.products.map((p) => Product.fromJson(p.toJson())).toList();
    }

    setState(() {
      final newList = ManagedList(
        puntoName: puntoName,
        puntoId: puntoId,
        products: productsToCopy,
      );
      _listas.add(newList);

      _tabController = TabController(
        length: _listas.length,
        vsync: this,
        initialIndex: _listas.length - 1,
      );
      _tabController.addListener(() async {
        if (!_tabController.indexIsChanging) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('lastActiveListIndex', _tabController.index);
          setState(() {});
        }
      });
    });
    await _saveProducts();
  }

  void _confirmRemoveList(ManagedList lista) {
    if (_listas.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No puedes eliminar la última lista.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('¿Eliminar lista "${lista.puntoName}"?'),
          content: Text('Esta acción es permanente.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Eliminar'),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _listas.remove(lista);
                  _tabController = TabController(
                    length: _listas.length,
                    vsync: this,
                    initialIndex: 0,
                  );
                  _tabController.addListener(() async {
                    if (!_tabController.indexIsChanging) {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setInt('lastActiveListIndex', _tabController.index);
                      setState(() {});
                    }
                  });
                });
                _saveProducts();
              },
            ),
          ],
        );
      },
    );
  }

  void _promptDuplicateList() {
    if (_listas.isEmpty) return;
    final currentPuntoName = _listas[_tabController.index].puntoName;
    String? selectedPunto;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Duplicar "${currentPuntoName}" en:'),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          content: DropdownSearch<String>(
            popupProps: PopupProps.menu(
              showSearchBox: true,
              searchFieldProps: TextFieldProps(
                decoration: InputDecoration(
                  labelText: "Buscar punto de venta",
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              constraints: BoxConstraints(maxHeight: 500),
            ),
            items: puntosDespacho.keys.toList()
              ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase())),
            dropdownDecoratorProps: DropDownDecoratorProps(
              dropdownSearchDecoration: InputDecoration(
                labelText: "Punto de Venta",
                hintText: "Selecciona un punto",
              ),
            ),
            onChanged: (String? newValue) {
              selectedPunto = newValue;
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Duplicar'),
              onPressed: () {
                if (selectedPunto != null) {
                  _addNewList(selectedPunto!, duplicateFromCurrent: true);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  // --- LÓGICA DE GESTIÓN DE PRODUCTOS ---

  void _addManualProduct(Product newProduct, ManagedList lista) {
    setState(() {
      final existingIndex = lista.products.indexWhere(
        (p) => p.id == newProduct.id && p.unitPrice == newProduct.unitPrice,
      );

      if (existingIndex != -1) {
        final existingProduct = lista.products[existingIndex];
        lista.products[existingIndex] = existingProduct.copyWith(
          quantity: existingProduct.quantity + newProduct.quantity,
        );
      } else {
        lista.products.add(newProduct);
      }
      // El ordenamiento ahora se hace en _buildProductListUI
    });
    _saveProducts();
  }


  // ---
  // --- ¡¡FUNCIÓN MODIFICADA!! ---
  // ---
  Future<void> _importCsvAndAddProducts(ManagedList lista) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null && result.files.single.bytes != null) {
        String fileContent;
        Uint8List bytes;

        if (kIsWeb) {
          bytes = result.files.single.bytes!;
        } else {
          String filePath = result.files.single.path!;
          File file = File(filePath);
          bytes = await file.readAsBytes();
        }

        try {
          fileContent = utf8.decode(bytes);
        } catch (e) {
          debugPrint('Error de decodificación UTF-8, intentando Latin-1: $e');
          try {
            fileContent = latin1.decode(bytes);
          } catch (e2) {
            debugPrint('Error de decodificación Latin-1: $e2');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text(
                        'Error: No se pudo leer el archivo. Intenta con UTF-8 o Latin-1.')),
              );
            }
            return;
          }
        }

        final lines = fileContent.split('\n').skip(1);
        final List<Product> importedProducts = [];

        for (var line in lines) {
          if (line.trim().isEmpty) continue;
          final fields = line.split(',');
          if (fields.length >= 10) {
            try {
              // --- INICIO DE LA LÓGICA DE NORMALIZACIÓN (REQ 1) ---
              
              String idProducto = fields[3].trim();
              String nombre = fields[4].trim(); // <-- Nombre original
              if (nombre.toUpperCase() == "PAQUETE DE BOLSA") {
                continue; // Salta esta línea y sigue con la próxima
              }
              final double quantityAsDouble =
                  double.tryParse(fields[7].trim()) ?? 0.0;
              final double unitPrice =
                  double.tryParse(fields[6].trim()) ?? 0.0;
              final String unitName = fields[9].trim();
              UnitType unit = _getUnitTypeFromString(unitName);

              if (idProducto.isEmpty || idProducto == "0") {
                String normalizedCsvName = _normalizeString(nombre);
                String? cleanName; // El nombre de products_data.dart
                
                cleanName = _normalizedMasterProductMap[normalizedCsvName];
                
                if (cleanName == null) {
                  cleanName = _normalizedMapping[normalizedCsvName];
                }

                if (cleanName != null &&
                    productosDisponibles.containsKey(cleanName)) {
                  
                  // --- ESTA ES LA CLAVE ---
                  idProducto = productosDisponibles[cleanName]!; // ID Correcto
                  unit = defaultUnits[cleanName] ?? unit; // Unidad Correcta
                  // `nombre` se queda con el valor original del CSV
                  // (ej. "GUISQUIL NACIONAL (CENTRAL DE ABASTOS)")
                
                } else {
                  if (idProducto.isEmpty) idProducto = "0";
                }
              }
              // --- FIN DE LA LÓGICA DE NORMALIZACIÓN ---

              final product = Product(
                id: idProducto, // ID Corregido
                name: nombre, // Nombre Original
                quantity: quantityAsDouble.toInt(),
                unitPrice: unitPrice,
                unit: unit,
              );
              importedProducts.add(product);

            } catch (e) {
              debugPrint("Error al procesar línea CSV: $line. Error: $e");
            }
          } else {
            debugPrint("Línea CSV con formato incorrecto: $line");
          }
        }

        setState(() {
          for (var newProduct in importedProducts) {
             _addManualProduct(newProduct, lista);
          }
        });
        _saveProducts();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Se importaron y procesaron ${importedProducts.length} productos a "${lista.puntoName}".')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al importar archivo: $e')),
        );
      }
    }
  }

  void _editProduct(int index, ManagedList lista, bool isCdaProduct) async {
    // --- CAMBIO: Necesitamos el índice original ---
    // En lugar de `index`, buscamos el producto en la lista principal
    final originalIndex = lista.products
        .indexWhere((p) => p == (isCdaProduct ? lista.cdaProducts[index] : lista.regularProducts[index]));

    if (originalIndex == -1) return; // No se encontró (no debería pasar)
    
    final initialProduct = lista.products[originalIndex];
    // ... el resto de la función _editProduct no cambia
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
        lista.products[originalIndex] = result;
      });
      _saveProducts();
    }
  }

  void _deleteProduct(ManagedList lista, Product productToDelete) {
    // Guardamos el producto por si quiere deshacer
    final deletedProduct = productToDelete;
    // Buscamos el índice original para poder re-insertarlo
    final originalIndex = lista.products.indexOf(deletedProduct);

    setState(() {
      lista.products.remove(deletedProduct);
    });
    _saveProducts();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Producto "${deletedProduct.name}" eliminado.'),
        action: SnackBarAction(
          label: 'DESHACER',
          onPressed: () {
            setState(() {
              // Re-inserta en la posición original si es posible
              if (originalIndex != -1 && originalIndex < lista.products.length) {
                lista.products.insert(originalIndex, deletedProduct);
              } else {
                lista.products.add(deletedProduct); // Fallback
              }
            });
            _saveProducts();
          },
        ),
      ),
    );
  }


  void _navigateToBulkEntry(ManagedList lista) async {
    final updatedBulkProducts = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BulkProductEntryPage(
          currentProducts:
              lista.products.map((p) => Product.fromJson(p.toJson())).toList(),
        ),
      ),
    );
    if (updatedBulkProducts != null) {
      setState(() {
        lista.products = updatedBulkProducts;
      });
      _saveProducts();
    }
  }

  // --- LÓGICA DE EXPORTACIÓN Y BORRADO ---
  // ... (Sin cambios aquí: _showExportDialog, ... _deleteAllAndExit) ...
  Future<void> _showExportDialog() async {
    if (_listas.every((lista) => lista.products.isEmpty)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Todas las listas están vacías. No hay nada que exportar.'),
          ),
        );
      }
      return;
    }
    await shareAllListsAsZip(_listas, context);
  }

  void _showClearProductsConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('¿Limpiar Productos?'),
          content: const Text(
              'Esta acción borrará todos los productos de TODAS las listas, pero conservará las pestañas.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.orange),
              child: const Text('Sí, limpiar'),
              onPressed: () {
                Navigator.of(context).pop();
                _clearAllProducts();
              },
            ),
          ],
        );
      },
    );
  }

  void _clearAllProducts() {
    setState(() {
      for (var lista in _listas) {
        lista.products.clear();
      }
    });
    _saveProducts();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Se limpiaron los productos de todas las listas.')),
    );
  }

  void _showDeleteAllAndExitConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('¿Eliminar Todo y Salir?'),
          content: const Text(
              'Esta acción borrará TODAS las listas y productos guardados.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Sí, eliminar y salir'),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteAllAndExit();
              },
            ),
          ],
        );
      },
    );
  }

  void _deleteAllAndExit() async {
    setState(() {
      _listas.clear();
      _isLoading = true; // Prevenir builds
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('managedLists');
    await prefs.remove('lastActiveListIndex');

    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/',
        (Route<dynamic> route) => false,
      );
    }
  }


  // --- BUILD METHOD ---
  @override
  Widget build(BuildContext context) {
    // ... (Sin cambios en el `build` principal, AppBar, TabBar, FABs) ...
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Cargando listas...'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final Color primaryColor = Theme.of(context).colorScheme.primary;
    final Color onPrimaryColor = Theme.of(context).colorScheme.onPrimary;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: onPrimaryColor,
        title: Text(
          _listas.isNotEmpty && _listas.length > _tabController.index
              ? _listas[_tabController.index].puntoName
              : 'Gestión de Listas',
          style: TextStyle(fontWeight: FontWeight.bold, color: onPrimaryColor),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add_box_outlined, color: onPrimaryColor),
            tooltip: 'Añadir nueva lista',
            onPressed: _promptAddNewList,
          ),
          IconButton(
            icon: Icon(Icons.copy, color: onPrimaryColor),
            tooltip: 'Duplicar lista actual',
            onPressed: _promptDuplicateList,
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: onPrimaryColor),
            onSelected: (String result) {
              if (_listas.isEmpty && result != 'delete_all') return;

              ManagedList? currentList;
              if (_listas.isNotEmpty) {
                currentList = _listas[_tabController.index];
              }

              if (result == 'import' && currentList != null) {
                _importCsvAndAddProducts(currentList);
                // --- NUEVO: Opción para exportar solo CSV ---
              } else if (result == 'export_csv' && currentList != null) {
                // Llamamos a la función shareCsv que ya tienes en export_utils.dart
                shareCsv(
                  currentList.products,
                  puntoId: currentList.puntoId,
                  puntoName: currentList.puntoName,
                  context: context,
                );
              // -------------------------------------------
              } else if (result == 'export_all') {
                _showExportDialog();
              } else if (result == 'clear_products') {
                _showClearProductsConfirmationDialog();
              } else if (result == 'delete_all') {
                _showDeleteAllAndExitConfirmationDialog();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'import',
                child: Row(
                  children: [
                    Icon(Icons.upload_file, color: Colors.green),
                    SizedBox(width: 10),
                    Text('Importar CSV (a esta lista)'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'export_csv',
                child: Row(
                  children: [
                    Icon(Icons.table_view_outlined, color: Colors.teal),
                    SizedBox(width: 10),
                    Text('Descargar SOLO CSV (Actual)'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'export_all',
                child: Row(
                  children: [
                    Icon(Icons.archive_outlined, color: Colors.blue),
                    SizedBox(width: 10),
                    Text('Exportar todo (ZIP)'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'clear_products',
                child: Row(
                  children: [
                    Icon(Icons.cleaning_services_outlined,
                        color: Colors.orange),
                    SizedBox(width: 10),
                    Text('Limpiar productos de listas'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'delete_all',
                child: Row(
                  children: [
                    Icon(Icons.delete_forever_outlined, color: Colors.red),
                    SizedBox(width: 10),
                    Text('Eliminar todo y salir'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: onPrimaryColor,
          unselectedLabelColor: onPrimaryColor.withOpacity(0.7),
          indicatorColor: Theme.of(context).colorScheme.secondary,
          indicatorWeight: 4.0,
          tabs: _listas.map((lista) {
            return Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(lista.puntoName,
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(width: 8),
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _confirmRemoveList(lista),
                    child: Icon(Icons.close, size: 16),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _listas.map((lista) {
          return _buildProductListUI(lista);
        }).toList(),
      ),
      floatingActionButton: _listas.isNotEmpty
          ? Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Botón secundario (Excel) - pequeño
                FloatingActionButton(
                  heroTag: 'addBulkBtn',
                  onPressed: () {
                    if (_listas.isNotEmpty) {
                      _navigateToBulkEntry(_listas[_tabController.index]);
                    }
                  },
                  tooltip: 'Entrada Masiva (Excel)',
                  mini: true,
                  child: const Icon(Icons.table_chart_outlined),
                ),
                const SizedBox(height: 12),
                // Botón primario (Añadir Manual) - extendido
                FloatingActionButton.extended(
                  heroTag: 'addProductBtn',
                  onPressed: () async {
                    if (_listas.isEmpty) return;
                    final result = await showModalBottomSheet<Product?>(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => ProductSearchSheet(
                        productosDisponibles: productosDisponibles,
                      ),
                    );
                    if (result != null) {
                      _addManualProduct(result, _listas[_tabController.index]);
                    }
                  },
                  label: const Text('Añadir Producto'),
                  icon: const Icon(Icons.add),
                ),
              ],
            )
          : null,
    );
  }

  // ---
  // --- ¡¡WIDGET HELPER MODIFICADO!! (REQ 2 y 3) ---
  // ---
  Widget _buildProductListUI(ManagedList lista) {
    final products = lista.products;

    // --- CAMBIO: Separar listas ---
    final cdaProducts = products
        .where((p) => p.name.toUpperCase().contains("CENTRAL DE ABASTOS"))
        .toList();
    final regularProducts = products
        .where((p) => !p.name.toUpperCase().contains("CENTRAL DE ABASTOS"))
        .toList();

    // --- CAMBIO: Ordenar listas por separado ---
    regularProducts
        .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    cdaProducts
        .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    
    // Guardar las listas ordenadas en el objeto `ManagedList`
    // para que `_editProduct` y `_deleteProduct` puedan encontrar el índice correcto.
    lista.regularProducts = regularProducts;
    lista.cdaProducts = cdaProducts;

    final totalQuantity =
        products.fold<double>(0.0, (sum, product) => sum + product.quantity);
    final totalPrecio = products.fold<double>(
        0.0, (sum, product) => sum + (product.quantity * product.unitPrice));

    // --- Estado Vacío ---
    if (products.isEmpty) {
      // ... (sin cambios) ...
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox_outlined, size: 100, color: Colors.grey[300]),
              const SizedBox(height: 24),
              Text(
                'Lista Vacía',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Añade productos usando el botón "+" o importa un archivo CSV desde el menú.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[500],
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // --- Lista con Productos ---
    return ListView(
      key: ValueKey(lista.id),
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 100), // Padding para FABs
      children: [
        // --- Tarjeta de Resumen (sin cambios) ---
        Card(
          elevation: 4,
          color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Resumen: ${lista.puntoName}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSummaryInfo(
                      context,
                      'Bultos Totales',
                      totalQuantity.toStringAsFixed(0),
                      Icons.calculate_outlined,
                    ),
                    _buildSummaryInfo(
                      context,
                      'Costo Total',
                      NumberFormat.currency(symbol: '\$')
                          .format(totalPrecio),
                      Icons.monetization_on_outlined,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // --- CAMBIO: Lista de Productos (Parte 1: Regulares) ---
        ...regularProducts.map((product) {
          final index = regularProducts.indexOf(product);
          return Dismissible(
            key: ValueKey(
                product.id + product.name + product.quantity.toString()),
            direction: DismissDirection.endToStart,
            onDismissed: (direction) {
              _deleteProduct(lista, product);
            },
            background: Container(
              color: Colors.red[700],
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.centerRight,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Eliminar',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  SizedBox(width: 8),
                  Icon(Icons.delete_sweep_outlined, color: Colors.white),
                ],
              ),
            ),
            child: Card( // --- Sin opacidad ---
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    getEmojiForProduct(product.name),
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                title: Text(product.name,
                    style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  '${product.quantity} ${unitMapping[product.unit]!['name'] ?? 'Unidad'} x \$${product.unitPrice.toStringAsFixed(2)}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      NumberFormat.currency(symbol: '\$')
                          .format(product.subtotal),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 15,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                      onPressed: () => _editProduct(index, lista, false), // false = no es CDA
                      tooltip: 'Editar producto',
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),

        // --- CAMBIO: Título y Lista de Productos (Parte 2: CDA) ---
        if (cdaProducts.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 24, left: 16, right: 16, bottom: 8),
            child: Text(
              "Central de Abastos",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ),
          
        ...cdaProducts.map((product) {
          final index = cdaProducts.indexOf(product);
          return Dismissible(
            key: ValueKey(
                product.id + product.name + product.quantity.toString()),
            direction: DismissDirection.endToStart,
            onDismissed: (direction) {
              _deleteProduct(lista, product);
            },
            background: Container(
              color: Colors.red[700],
              // ... (fondo igual al anterior) ...
            ),
            child: Opacity( // --- Con opacidad (más gris) ---
              opacity: 0.75, 
              child: Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                // color: Colors.grey[50], // Alternativa a la opacidad
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.grey[200], // Avatar gris
                    child: Text(
                      getEmojiForProduct(product.name),
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  title: Text(product.name,
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    '${product.quantity} ${unitMapping[product.unit]!['name'] ?? 'Unidad'} x \$${product.unitPrice.toStringAsFixed(2)}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        NumberFormat.currency(symbol: '\$')
                            .format(product.subtotal),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700], // Total gris
                          fontSize: 15,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.edit_outlined, color: Colors.grey[600]), // Icono gris
                        onPressed: () => _editProduct(index, lista, true), // true = es CDA
                        tooltip: 'Editar producto',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  // Helper para la tarjeta de resumen
  // ... (Sin cambios aquí) ...
  Widget _buildSummaryInfo(
      BuildContext context, String title, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }
}

// --- CAMBIO: Añadir estas dos listas al modelo ManagedList ---
// (Esto es necesario para que _editProduct y _deleteProduct funcionen
// después de ordenar las listas por separado)
extension ListSeparation on ManagedList {
  static final Map<String, List<Product>> _regularProductsCache = {};
  static final Map<String, List<Product>> _cdaProductsCache = {};

  List<Product> get regularProducts => _regularProductsCache[id] ?? [];
  set regularProducts(List<Product> value) => _regularProductsCache[id] = value;

  List<Product> get cdaProducts => _cdaProductsCache[id] ?? [];
  set cdaProducts(List<Product> value) => _cdaProductsCache[id] = value;
}