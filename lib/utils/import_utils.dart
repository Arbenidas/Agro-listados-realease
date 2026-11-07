// Archivo: lib/utils/import_utils.dart

import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_listados/data/dispatch_points.dart'; 
import 'package:flutter_listados/models/product.dart';
import 'package:flutter_listados/data/products_data.dart';
import 'package:flutter_listados/data/units.dart';
import 'package:flutter_listados/data/product_mapping.dart';

class DistributionPoint {
  final String rawName;
  final String? matchedId;
  final String? matchedName;
  final List<Product> products;

  DistributionPoint({
    required this.rawName,
    this.matchedId,
    this.matchedName,
    required this.products,
  });
}

class ImportUtils {
  
  // --- HELPERS DE NORMALIZACIÓN ---

  static String _normalizeForMatch(String s) {
    return s.toLowerCase()
        .replaceAll(RegExp(r'[áàäâ]'), 'a')
        .replaceAll(RegExp(r'[éèëê]'), 'e')
        .replaceAll(RegExp(r'[íìïî]'), 'i')
        .replaceAll(RegExp(r'[óòöô]'), 'o')
        .replaceAll(RegExp(r'[úùüû]'), 'u')
        .replaceAll('ñ', 'n')
        .replaceAll(RegExp(r'[(),.]'), '') 
        .replaceAll('colonia', 'col')      
        .replaceAll('  ', ' ')             
        .trim();
  }

  static String? _findPuntoId(String excelName) {
    String normalizedExcel = _normalizeForMatch(excelName);
    
    // 1. Búsqueda exacta
    for (var entry in puntosDespacho.entries) {
      if (_normalizeForMatch(entry.key) == normalizedExcel) {
        return entry.value;
      }
    }

    // 2. Búsqueda parcial (contiene)
    for (var entry in puntosDespacho.entries) {
      String normKey = _normalizeForMatch(entry.key);
      if (normalizedExcel.contains(normKey) || normKey.contains(normalizedExcel)) {
        return entry.value;
      }
    }

    return null; 
  }

  // --- HELPER DE PARSEO DE NÚMEROS (CORRECCIÓN DEL ERROR) ---
  
  /// Extrae un double seguro de cualquier tipo de celda (int, double, String, CellValue)
  static double _parseQuantity(dynamic value) {
    if (value == null) return 0.0;
    
    // Caso 1: Primitivos (int, double)
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) return double.tryParse(value) ?? 0.0;

    // Caso 2: Objetos CellValue (Excel 4.0+)
    // Intentamos acceder dinámicamente a .value para soportar IntCellValue, DoubleCellValue, etc.
    try {
      // Usamos dynamic para evitar errores de tipo si la clase no es visible
      dynamic dVal = value;
      // Verificamos si tiene propiedad 'value' (común en wrappers)
      var inner = dVal.value;
      
      if (inner != null) {
        if (inner is int) return inner.toDouble();
        if (inner is double) return inner;
        if (inner is String) return double.tryParse(inner) ?? 0.0;
      }
    } catch (e) {
      // Si falla el acceso dinámico, ignoramos
    }

    // Fallback: Convertir a String y tratar de parsear
    return double.tryParse(value.toString()) ?? 0.0;
  }

  // --- MÉTODOS PÚBLICOS ---

  /// Método 1: Importación MASIVA (Global)
  static Future<List<DistributionPoint>> importDistributionExcel(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        withData: true,
      );

      if (result == null) return [];

      List<int>? bytes;
      if (kIsWeb) {
        bytes = result.files.single.bytes;
      } else {
        final path = result.files.single.path;
        if (path != null) bytes = File(path).readAsBytesSync();
      }

      if (bytes == null) throw Exception("No se pudo leer el archivo.");

      var excel = Excel.decodeBytes(bytes);
      List<DistributionPoint> importedPoints = [];
      
      final table = excel.tables[excel.tables.keys.first];
      if (table == null || table.rows.length < 3) throw Exception("Formato incorrecto.");

      // Fila de encabezados de productos (Fila 3, índice 2)
      final productHeaderRow = table.rows[2]; 

      // Mapa de productos normalizados
      final Map<String, String> normalizedProdMap = {};
      productosDisponibles.forEach((k, v) => normalizedProdMap[_normalizeForMatch(k)] = k);
      productNormalizationMap.forEach((k, v) => normalizedProdMap[_normalizeForMatch(k)] = v);

      // Recorremos las filas de datos (desde Fila 4, índice 3)
      for (int i = 3; i < table.rows.length; i++) {
        final row = table.rows[i];
        if (row.length < 2) continue;

        String puntoRawName = row[1]?.value?.toString().trim() ?? "";
        if (puntoRawName.isEmpty || puntoRawName.toLowerCase() == "total") continue;

        List<Product> pointProducts = [];

        for (int col = 2; col < row.length; col++) {
          if (col >= productHeaderRow.length) break;

          String headerName = productHeaderRow[col]?.value?.toString() ?? "";
          if (headerName.isEmpty) continue;

          // CORRECCIÓN: Usamos el helper robusto para obtener la cantidad
          double quantity = _parseQuantity(row[col]?.value);

          if (quantity > 0) {
            String normHeader = _normalizeForMatch(headerName);
            // Parches manuales
            if (normHeader.contains("arroz precocido")) normHeader = "arroz precocido";
            else if (normHeader == "arroz") normHeader = "arroz blanco"; 
            else if (normHeader.contains("frijol 20")) normHeader = "frijol saco 20lb"; 
            
            String? realName = normalizedProdMap[normHeader];
            
            if (realName == null) {
               realName = normalizedProdMap.keys.firstWhere(
                 (k) => k.contains(normHeader) || normHeader.contains(k), 
                 orElse: () => ""
               );
               if (realName.isNotEmpty) realName = normalizedProdMap[realName];
               else realName = null;
            }

            if (realName != null && productosDisponibles.containsKey(realName)) {
              pointProducts.add(Product(
                id: productosDisponibles[realName]!,
                name: realName,
                quantity: quantity.toInt(),
                unitPrice: 0.0,
                unit: defaultUnits[realName] ?? UnitType.Unidad,
              ));
            }
          }
        }

        if (pointProducts.isNotEmpty) {
          String? foundId = _findPuntoId(puntoRawName);
          
          importedPoints.add(DistributionPoint(
            rawName: puntoRawName,
            matchedId: foundId,
            matchedName: foundId != null ? puntosDespacho.keys.firstWhere((k) => puntosDespacho[k] == foundId) : null,
            products: pointProducts,
          ));
        }
      }

      return importedPoints;
    } catch (e) {
      debugPrint("Error importando Excel: $e");
      return [];
    }
  }

  /// Método 2: Importación INDIVIDUAL (Restaurado)
  static Future<List<Product>> pickAndImportExcel(BuildContext context, {String? filterPuntoName}) async {
    // Reutilizamos la lógica maestra
    List<DistributionPoint> allPoints = await importDistributionExcel(context);
    
    if (filterPuntoName == null) return [];

    String normFilter = _normalizeForMatch(filterPuntoName);

    try {
      final match = allPoints.firstWhere((p) {
          bool matchMapped = p.matchedName != null && _normalizeForMatch(p.matchedName!) == normFilter;
          bool matchRaw = _normalizeForMatch(p.rawName).contains(normFilter) || normFilter.contains(_normalizeForMatch(p.rawName));
          return matchMapped || matchRaw;
      });
      
      return match.products;
    } catch (e) {
      return [];
    }
  }
}