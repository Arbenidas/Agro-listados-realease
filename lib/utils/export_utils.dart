// Archivo: lib/utils/export_utils.dart
// CORREGIDO para problemas de descompresión ZIP

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// ✅ Importación de archive simplificada y directa para las clases necesarias
import 'package:archive/archive.dart';
import 'package:flutter_listados/models/units.dart';
import 'package:flutter_listados/utils/generador_pdf.dart'; 
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io' show File, Directory;
import 'dart:html' as html;
import '../models/product.dart';


// Tarea pesada para crear los bytes del ZIP, ejecutada en segundo plano
Future<Uint8List> _createZipFileBytes(Map<String, dynamic> data) async {
  final List<Product> products = data['products'];
  final String puntoName = data['puntoName'];
  final String puntoId = data['puntoId'];
  
  // Creamos un objeto Archive para construir el ZIP en memoria
  final archive = Archive();

  // --- 1. Generar el PDF en memoria y añadirlo al archivo ---
  final pdfBytes = await generateProductListPdf(products, openFile: false);
  final pdfFileName = 'lista_productos_$puntoName.pdf';
  // ✅ Usar ArchiveFile.noCompress si no queremos compresión para el PDF (a veces ayuda a evitar corrupción)
  // O solo ArchiveFile si queremos compresión por defecto
  archive.addFile(ArchiveFile(pdfFileName, pdfBytes.length, pdfBytes));


  // --- 2. Crear el contenido JSON y añadirlo al archivo ---
  final List<Map<String, dynamic>> productsJson = products.map((p) => {
    'id': p.id,
    'name': p.name,
    'quantity': p.quantity,
    'unit': unitMapping[p.unit]?['name'] ?? p.unit.name,
    'unitPrice': p.unitPrice,
    'subtotal': p.subtotal,
  }).toList();
  final jsonString = jsonEncode(productsJson);
  final jsonFileName = 'lista_productos_$puntoName.json';
  archive.addFile(ArchiveFile(jsonFileName, jsonString.length, Uint8List.fromList(utf8.encode(jsonString))));


  // --- 3. Crear el contenido TXT y añadirlo al archivo ---
  final StringBuffer txtContent = StringBuffer();
  txtContent.writeln('Lista de Productos para: $puntoName (ID: $puntoId)');
  txtContent.writeln('Fecha de exportación: ${DateTime.now().toIso8601String().split('T')[0]}');
  txtContent.writeln('--------------------------------------------------');
  double totalGeneral = 0.0;
  for (var p in products) {
    txtContent.writeln('${p.name} - ${p.quantity} ${unitMapping[p.unit]?['name'] ?? p.unit.name} x \$${p.unitPrice.toStringAsFixed(2)} = \$${p.subtotal.toStringAsFixed(2)}');
    totalGeneral += p.subtotal;
  }
  txtContent.writeln('--------------------------------------------------');
  txtContent.writeln('TOTAL GENERAL: \$${totalGeneral.toStringAsFixed(2)}');
  final txtFileName = 'lista_productos_$puntoName.txt';
  archive.addFile(ArchiveFile(txtFileName, txtContent.length, Uint8List.fromList(utf8.encode(txtContent.toString()))));


  // Codificar el objeto Archive a bytes ZIP
  final zipEncoder = ZipEncoder();
  // El nivel de compresión por defecto de ZipEncoder es Deflate.DEFAULT_COMPRESSION (6),
  // que suele ser el más compatible.
  // Si BEST_COMPRESSION (9) sigue dando problemas, podríamos probar con DEFAULT o NO_COMPRESSION.
  final zipBytesList = zipEncoder.encode(archive, level: Deflate.DEFAULT_COMPRESSION); // ✅ Cambiado a DEFAULT_COMPRESSION

  if (zipBytesList == null) {
    throw Exception('Failed to encode zip archive.');
  }

  return Uint8List.fromList(zipBytesList);
}

Future<void> shareZip(
  List<Product> products, {
  required String puntoId,
  required String puntoName,
  required BuildContext context,
}) async {
  if (products.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("No hay productos para exportar.")),
    );
    return;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Preparando archivo ZIP...')),
  );

  try {
    // Usamos compute() para crear los bytes del ZIP en un hilo de segundo plano
    final zipBytes = await compute(_createZipFileBytes, {
      'products': products,
      'puntoId': puntoId,
      'puntoName': puntoName,
    });

    if (context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      if (kIsWeb) {
        // Lógica específica para la web: descarga el ZIP
        final blob = html.Blob([zipBytes], 'application/zip');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute("download", "lista_productos_$puntoName.zip")
          ..click();
        html.Url.revokeObjectUrl(url);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Archivo ZIP descargado exitosamente.')),
        );
      } else {
        // Lógica para móvil/escritorio: guardar en archivo temporal y compartir
        final tempDir = await getTemporaryDirectory();
        final zipFilePath = '${tempDir.path}/lista_productos_$puntoName.zip';
        final file = File(zipFilePath);
        await file.writeAsBytes(zipBytes); // Escribimos los bytes al archivo temporal

        await Share.shareXFiles([XFile(zipFilePath)], text: 'Lista de productos para $puntoName');
      }
    }
  } catch (e) {
    debugPrint('Error al procesar el archivo ZIP: $e');
    if (context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al procesar el archivo.')),
      );
    }
  }
}