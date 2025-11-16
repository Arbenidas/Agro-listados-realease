// Archivo: lib/utils/export_utils.dart
// MODIFICADO:
// 1. _generateProductListPdf: Separa los productos de CDA.
// 2. Renderiza una tabla normal y luego una tabla gris separada para CDA.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:universal_html/html.dart' as html;
import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import '../models/product.dart';
import '../data/units.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/managed_list.dart';

// --- (Sin cambios en _generateCsvInBackground ni _escapeCsvField) ---
Future<Uint8List> _generateCsvInBackground(Map<String, dynamic> data) async {
  final List<Product> items = data['items'];
  final String puntoId = data['puntoId'];
  final now = DateTime.now().add(const Duration(days: 1));
  final csvFecha = DateFormat('dd/MM/yyyy').format(now);

  final headers = [
    "IdCargado",
    "IdPunto",
    "FechaVenta",
    "IdProducto",
    "Producto",
    "TotalProducto",
    "UnidadesPrecio",
    "Cantidad",
    "IdMedida",
    "UnidadMedida",
    "DatosCargados",
    "UsuarioApp",
  ];

  // --- REQ 1: ESTO YA FUNCIONA ---
  // Como `items` (que es la `ManagedList.products`) ya tiene el ID correcto
  // y el nombre original de CDA, esta función generará el CSV
  // exactamente como lo pediste.
  final rows = items.map((p) {
    final effectiveUnitPrice = p.unitPrice;
    final mapping = unitMapping[p.unit]!;
    final totalProducto = (p.quantity * effectiveUnitPrice).toStringAsFixed(2);
    return [
      _escapeCsvField(""),
      _escapeCsvField(puntoId),
      _escapeCsvField(csvFecha),
      _escapeCsvField(p.id),
      _escapeCsvField(p.name), // <-- Usará el nombre de CDA
      _escapeCsvField(totalProducto),
      _escapeCsvField(effectiveUnitPrice.toStringAsFixed(2)),
      _escapeCsvField(p.quantity.toString()),
      _escapeCsvField(mapping["id"].toString()),
      _escapeCsvField(mapping["name"]!),
      _escapeCsvField(""),
      _escapeCsvField(""),
    ];
  }).toList();

  final csv = StringBuffer();
  csv.writeln(headers.map(_escapeCsvField).join(","));
  for (final row in rows) {
    csv.writeln(row.join(","));
  }

  return Uint8List.fromList(utf8.encode(csv.toString()));
}

String _escapeCsvField(String field) {
  if (field.contains(',') || field.contains('"') || field.contains('\n')) {
    return '"${field.replaceAll('"', '""')}"';
  }
  return field;
}

// ---
// --- ¡¡FUNCIÓN DE GENERACIÓN DE PDF MODIFICADA!! (REQ 2 y 3) ---
// ---
Future<Uint8List> _generateProductListPdf(List<Product> products,
    {String? puntoName}) async {
  final pdf = pw.Document();
  final helvetica = pw.Font.helvetica();
  final helveticaBold = pw.Font.helveticaBold();

  if (products.isEmpty) {
    // ... (sin cambios en el manejo de PDF vacío) ...
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Text(
              'No hay productos para mostrar.',
              style: pw.TextStyle(font: helveticaBold, fontSize: 16),
            ),
          );
        },
      ),
    );
    return pdf.save();
  }

  // --- Cálculos de totales (siguen siendo sobre todos los productos) ---
  final totalBultos = products.fold(0.0, (sum, p) => sum + p.quantity);
  final totalPrecio =
      products.fold(0.0, (sum, p) => sum + (p.quantity * p.unitPrice));
  final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

  // --- CAMBIO: Separar y ordenar listas ---
  final cdaProducts = products
      .where((p) => p.name.toUpperCase().contains("CENTRAL DE ABASTOS"))
      .toList();
  final regularProducts = products
      .where((p) => !p.name.toUpperCase().contains("CENTRAL DE ABASTOS"))
      .toList();

  regularProducts
      .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  cdaProducts
      .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  // --- Generar datos de tabla para productos regulares ---
  final List<List<String>> regularTableData = regularProducts.map((product) {
    final unitName = unitMapping[product.unit]!['name']!;
    final productNameWithUnit = '${product.name} (${unitName})';
    return [
      productNameWithUnit,
      product.quantity.toString(),
      currencyFormat.format(product.unitPrice),
      currencyFormat.format(product.subtotal),
      "", // Observaciones
    ];
  }).toList();

  // --- Generar datos de tabla para productos CDA ---
  final List<List<String>> cdaTableData = cdaProducts.map((product) {
    final unitName = unitMapping[product.unit]!['name']!;
    final productNameWithUnit = '${product.name} (${unitName})';
    return [
      productNameWithUnit,
      product.quantity.toString(),
      currencyFormat.format(product.unitPrice),
      currencyFormat.format(product.subtotal),
      "", // Observaciones
    ];
  }).toList();

  final List<String> headers = [
    'Producto (Unidad)',
    'Cant.',
    'Precio Unit.',
    'Subtotal',
    'Observaciones'
  ];

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4.copyWith(
        marginLeft: 28,
        marginRight: 28,
        marginTop: 48,
        marginBottom: 48,
      ),
      // --- Encabezado de Página (sin cambios) ---
      header: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Reporte de Lista de Productos',
              style: pw.TextStyle(
                  font: helveticaBold,
                  fontSize: 22,
                  color: PdfColors.blueGrey800),
            ),
            if (puntoName != null)
              pw.Text(
                'Punto de Despacho: $puntoName',
                style: pw.TextStyle(font: helvetica, fontSize: 14),
              ),
            pw.Text(
              'Generado: ${DateFormat('dd/MM/yyyy HH:mm a').format(DateTime.now())}',
              style: pw.TextStyle(
                  font: helvetica, fontSize: 10, color: PdfColors.grey600),
            ),
            pw.Divider(thickness: 2, color: PdfColors.blueGrey800),
            pw.SizedBox(height: 10),
          ],
        );
      },
      
      // --- Pie de Página (con resumen total, sin cambios) ---
      footer: (pw.Context context) {
        return pw.Column(
          children: [
            pw.Divider(color: PdfColors.grey400, height: 1, thickness: 0.5),
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Página ${context.pageNumber} / ${context.pagesCount}',
                  style: pw.TextStyle(
                      font: helvetica, fontSize: 8, color: PdfColors.grey600),
                ),
                pw.Text(
                  'Resumen Total: ${totalBultos.toStringAsFixed(0)} Bultos | ${currencyFormat.format(totalPrecio)}',
                  style: pw.TextStyle(
                      font: helveticaBold,
                      fontSize: 8,
                      color: PdfColors.grey800),
                ),
              ],
            ),
          ],
        );
      },
      
      // --- CAMBIO: El build ahora retorna una lista de widgets ---
      build: (pw.Context context) {
        
        final List<pw.Widget> widgets = [];

        // --- 1. Tabla de Productos Regulares ---
        if (regularTableData.isNotEmpty) {
          widgets.add(
            pw.Table.fromTextArray(
              headers: headers,
              data: regularTableData,
              // Estilo de cabecera (Normal)
              headerStyle: pw.TextStyle(
                font: helveticaBold,
                fontSize: 9, 
                color: PdfColors.white,
              ),
              headerDecoration: pw.BoxDecoration(
                color: PdfColors.blueGrey800,
              ),
              // Estilo de celdas (Normal)
              cellStyle: pw.TextStyle(
                font: helvetica,
                fontSize: 8, 
              ),
              columnWidths: {
                0: const pw.FlexColumnWidth(3.5),
                1: const pw.FlexColumnWidth(0.7),
                2: const pw.FlexColumnWidth(1.2),
                3: const pw.FlexColumnWidth(1.2),
                4: const pw.FlexColumnWidth(2.4),
              },
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerRight,
                2: pw.Alignment.centerRight,
                3: pw.Alignment.centerRight,
                4: pw.Alignment.centerLeft,
              },
              rowDecoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                ),
              ),
            ),
          );
        }

        // --- 2. Tabla de Productos CDA (Estilo Gris) ---
        if (cdaTableData.isNotEmpty) {
          // Espaciador y Título
          widgets.add(pw.SizedBox(height: 15));
          widgets.add(
            pw.Header(
              level: 1,
              text: 'Central de Abastos',
              textStyle: pw.TextStyle(
                font: helveticaBold,
                fontSize: 12,
                color: PdfColors.grey700,
              )
            )
          );
          widgets.add(pw.SizedBox(height: 5));

          // Tabla CDA
          widgets.add(
            pw.Table.fromTextArray(
              headers: headers,
              data: cdaTableData,
              // Estilo de cabecera (Gris)
              headerStyle: pw.TextStyle(
                font: helveticaBold,
                fontSize: 9, 
                color: PdfColors.white,
              ),
              headerDecoration: pw.BoxDecoration(
                color: PdfColors.grey600, // <-- GRIS
              ),
              // Estilo de celdas (Gris)
              cellStyle: pw.TextStyle(
                font: helvetica,
                fontSize: 8,
                color: PdfColors.grey800, // <-- GRIS
              ),
              columnWidths: {
                0: const pw.FlexColumnWidth(3.5),
                1: const pw.FlexColumnWidth(0.7),
                2: const pw.FlexColumnWidth(1.2),
                3: const pw.FlexColumnWidth(1.2),
                4: const pw.FlexColumnWidth(2.4),
              },
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerRight,
                2: pw.Alignment.centerRight,
                3: pw.Alignment.centerRight,
                4: pw.Alignment.centerLeft,
              },
              rowDecoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                ),
              ),
            ),
          );
        }
        
        return widgets;
      },
    ),
  );
  return pdf.save();
}


// --- (Sin cambios en el resto del archivo: _pdfGeneratorComputeWrapper, shareAllListsAsZip, etc.) ---
Future<Uint8List> _pdfGeneratorComputeWrapper(Map<String, dynamic> data) async {
  final List<Product> products = data['products'].cast<Product>();
  final String? puntoName = data['puntoName'];
  return await _generateProductListPdf(products, puntoName: puntoName);
}

// --- NUEVA FUNCIÓN DE EXPORTACIÓN ZIP (MÚLTIPLE) ---

Future<void> shareAllListsAsZip(
  List<ManagedList> listas, // <-- Recibe la lista de listas
  BuildContext context,
) async {
  _showLoadingDialog(context);
  final now = DateTime.now();
  final fileDate = DateFormat('dd-MM-yyyy').format(now);

  final archive = Archive();

  // --- LÓGICA DE FILTRADO Y NOMBRADO ---
  final listsToExport = listas.where((l) => l.products.isNotEmpty).toList();
  String zipFileName;

  if (listsToExport.isEmpty) {
    if (context.mounted) Navigator.of(context).pop(); // Cierra loading
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('No hay productos en ninguna lista para exportar.')),
    );
    return;
  } else if (listsToExport.length == 1) {
    // --- Caso 1: Solo una lista con productos ---
    final puntoName =
        listsToExport.first.puntoName.replaceAll(' ', '_').replaceAll(',', '');
    zipFileName = 'Despacho_${puntoName}_$fileDate.zip';
  } else {
    // --- Caso 2: Múltiples listas con productos ---
    // Usamos una abreviatura de las primeras 4 letras de cada punto
    String abrev = listsToExport
        .map((l) {
          String name = l.puntoName.replaceAll(RegExp(r'[\s,.]'), '');
          return name.substring(0, (name.length < 4 ? name.length : 4));
        })
        .join('-');
    zipFileName = 'Despachos_${abrev}_$fileDate.zip';
  }
  // --- FIN DE LÓGICA DE NOMBRADO ---

  try {
    // 1. Recorre CADA lista CON PRODUCTOS para generar sus archivos
    for (final lista in listsToExport) {
      final puntoName = lista.puntoName.replaceAll(' ', '_').replaceAll(',', '');

      // 2. Genera CSV para esta lista
      final csvData = await compute(_generateCsvInBackground, {
        'items': lista.products,
        'puntoId': lista.puntoId,
      });
      final csvFileName = 'DESPACHO_${puntoName}_$fileDate.csv';
      archive.addFile(ArchiveFile(csvFileName, csvData.length, csvData));

      // 3. Genera PDF para esta lista
      final pdfData = await compute(_pdfGeneratorComputeWrapper, {
        'products': lista.products,
        'puntoName': lista.puntoName,
      });
      final pdfFileName = 'Lista_${puntoName}_$fileDate.pdf';
      archive.addFile(ArchiveFile(pdfFileName, pdfData.length, pdfData));
    }

    // 4. Comprime todo en un solo ZIP
    final fileData = Uint8List.fromList(
        ZipEncoder().encode(archive, level: Deflate.DEFAULT_COMPRESSION)!);

    if (context.mounted) Navigator.of(context).pop(); // Cierra loading

    // 5. Usa la lógica de guardado/compartir existente
    if (kIsWeb) {
      final blob = html.Blob([fileData], 'application/zip');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download",
            zipFileName) // <-- Usa el nombre de archivo dinámico
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(
          p.join(tempDir.path, zipFileName)); // <-- Usa el nombre de archivo dinámico
      await tempFile.writeAsBytes(fileData);

      await Share.shareXFiles(
        [XFile(tempFile.path, name: zipFileName)], // <-- Usa el nombre de archivo dinámico
        subject: 'Archivos de Despacho (ZIP)',
        sharePositionOrigin: const Rect.fromLTWH(0, 0, 1, 1),
      );
    }
  } catch (e) {
    debugPrint('Error en shareAllListsAsZip: $e');
    if (context.mounted) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al generar ZIP: $e')),
      );
    }
  }
}

// --- Funciones de exportación y compartición (INDIVIDUALES) ---
// ... (Sin cambios aquí) ...
Future<void> shareCsv(List<Product> items,
    {required String puntoId,
    required String puntoName,
    required BuildContext context}) async {
  await _prepareAndShare(
    context: context,
    products: items,
    puntoId: puntoId,
    puntoName: puntoName,
    exportType: 'csv',
  );
}

Future<void> sharePdf(List<Product> products,
    {required String puntoId,
    required String puntoName,
    required BuildContext context}) async {
  await _prepareAndShare(
    context: context,
    products: products,
    puntoId: puntoId,
    puntoName: puntoName,
    exportType: 'pdf',
  );
}

Future<void> shareZip(List<Product> products,
    {required String puntoId,
    required String puntoName,
    required BuildContext context}) async {
  await _prepareAndShare(
    context: context,
    products: products,
    puntoId: puntoId,
    puntoName: puntoName,
    exportType: 'zip',
  );
}


// --- FUNCIÓN HELPER INTERNA (EXISTENTE) ---
// ... (Sin cambios aquí) ...
Future<void> _prepareAndShare({
  required BuildContext context,
  required List<Product> products,
  required String puntoId,
  required String puntoName,
  required String exportType,
}) async {
  _showLoadingDialog(context);
  final now = DateTime.now();
  final fileDate = DateFormat('dd-MM-yyyy').format(now);
  String title = '';
  Uint8List? fileData;
  String fileName = '';
  String mimeType = '';

  try {
    switch (exportType) {
      case 'csv':
        fileData = await compute(_generateCsvInBackground, {
          'items': products,
          'puntoId': puntoId,
        });
        fileName = 'DESPACHO_${puntoName.replaceAll(' ', '_')}_$fileDate.csv';
        mimeType = 'text/csv';
        title = 'Lista de Productos (CSV)';
        break;

      case 'pdf':
        fileData = await compute(_pdfGeneratorComputeWrapper, {
          'products': products,
          'puntoName': puntoName,
        });
        fileName = 'Lista_${puntoName.replaceAll(' ', '_')}_$fileDate.pdf';
        mimeType = 'application/pdf';
        title = 'Lista de Productos (PDF)';
        break;

      case 'zip':
        final csvData = await compute(_generateCsvInBackground, {
          'items': products,
          'puntoId': puntoId,
        });
        final pdfData = await compute(_pdfGeneratorComputeWrapper, {
          'products': products,
          'puntoName': puntoName,
        });

        final archive = Archive();
        archive.addFile(ArchiveFile(
            'DESPACHO_${puntoName.replaceAll(' ', '_')}_$fileDate.csv',
            csvData.length,
            csvData));
        archive.addFile(ArchiveFile(
            'Lista_${puntoName.replaceAll(' ', '_')}_$fileDate.pdf',
            pdfData.length,
            pdfData));

        fileData = Uint8List.fromList(
            ZipEncoder().encode(archive, level: Deflate.DEFAULT_COMPRESSION)!);
        fileName = 'Despacho_${puntoName.replaceAll(' ', '_')}_$fileDate.zip';
        mimeType = 'application/zip';
        title = 'Archivos de Despacho (ZIP)';
        break;
    }

    if (context.mounted) Navigator.of(context).pop();

    if (fileData != null) {
      if (kIsWeb) {
        final blob = html.Blob([fileData], mimeType);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute("download", fileName)
          ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        final tempDir = await getTemporaryDirectory();
        final tempFile = File(p.join(tempDir.path, fileName));
        await tempFile.writeAsBytes(fileData);
        final filesToShare = [XFile(tempFile.path, name: fileName)];

        bool sharedSuccessfully = false;
        try {
          await Share.shareXFiles(filesToShare,
              subject: title,
              sharePositionOrigin: const Rect.fromLTWH(0, 0, 1, 1));
          sharedSuccessfully = true;
        } catch (e) {
          debugPrint("Error o cancelación al compartir: $e");
        }

        if (context.mounted) {
          if (sharedSuccessfully) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$title compartido exitosamente')),
            );
          } else {
            // ... (tu lógica existente de 'Guardar en dispositivo') ...
          }
        }
      }
    }
  } catch (e) {
    debugPrint('Error general en _prepareAndShare: $e');
    if (context.mounted) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al preparar/compartir archivo: $e')),
      );
    }
  } finally {
    if (context.mounted && Navigator.of(context).canPop()) {
      final currentRoute = ModalRoute.of(context);
      if (currentRoute is PopupRoute &&
          currentRoute.barrierDismissible == false) {
        Navigator.of(context).pop();
      }
    }
  }
}

void _showLoadingDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return const Center(child: CircularProgressIndicator());
    },
  );
}