// Archivo: lib/utils/export_utils.dart
// MEJORADO: PDF vuelve a formato Vertical (Portrait)
// y se reajustan las columnas para que quepa "Observaciones".

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
import 'package:permission_handler/permission_handler.dart';
import '../models/product.dart';
import '../data/units.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

// Importación para el nuevo modelo de lista
import '../models/managed_list.dart';

// --- Funciones de generación en segundo plano ---

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

  final rows = items.map((p) {
    final effectiveUnitPrice = p.unitPrice;
    final mapping = unitMapping[p.unit]!;
    final totalProducto = (p.quantity * effectiveUnitPrice).toStringAsFixed(2);
    return [
      _escapeCsvField(""),
      _escapeCsvField(puntoId),
      _escapeCsvField(csvFecha),
      _escapeCsvField(p.id),
      _escapeCsvField(p.name),
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

// --- FUNCIÓN DE GENERACIÓN DE PDF (ACTUALIZADA) ---

Future<Uint8List> _generateProductListPdf(List<Product> products,
    {String? puntoName}) async {
  final pdf = pw.Document();
  final helvetica = pw.Font.helvetica();
  final helveticaBold = pw.Font.helveticaBold();

  if (products.isEmpty) {
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

  // Cálculos de totales (usados en el footer y al final)
  final totalBultos = products.fold(0.0, (sum, p) => sum + p.quantity);
  final totalPrecio =
      products.fold(0.0, (sum, p) => sum + (p.quantity * p.unitPrice));

  // Formateador de moneda
  final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

  // --- CAMBIO: TABLA DE DATOS (Unidad fusionada con Producto) ---
  final List<List<String>> tableData = products.map((product) {
    final unitName = unitMapping[product.unit]!['name']!;
    // AQUÍ FUSIONAMOS EL NOMBRE Y LA UNIDAD
    final productNameWithUnit = '${product.name} (${unitName})';
    
    return [
      productNameWithUnit, // Columna 0
      product.quantity.toString(), // Columna 1
      // La columna de Unidad se elimina
      currencyFormat.format(product.unitPrice), // Columna 2
      currencyFormat.format(product.subtotal), // Columna 3
      "", // Columna 4: Observaciones
    ];
  }).toList();

  // --- CAMBIO: HEADERS (Unidad eliminada) ---
  final List<String> headers = [
    'Producto (Unidad)', // Título actualizado
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
      // --- Encabezado de Página ---
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
      
      // --- PIE DE PÁGINA (CON RESUMEN PEQUEÑO) ---
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
                // Resumen en cada página
                pw.Text(
                  'Resumen: ${totalBultos.toStringAsFixed(0)} Bultos | ${currencyFormat.format(totalPrecio)}',
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
      
      build: (pw.Context context) {
        return [
          // --- TABLA DE PRODUCTOS REDISEÑADA ---
          pw.Table.fromTextArray(
            headers: headers,
            data: tableData,
            // Estilo de la cabecera
            headerStyle: pw.TextStyle(
              font: helveticaBold,
              fontSize: 9, 
              color: PdfColors.white,
            ),
            headerDecoration: pw.BoxDecoration(
              color: PdfColors.blueGrey800,
            ),
            // Estilo de las celdas
            cellStyle: pw.TextStyle(
              font: helvetica,
              fontSize: 8, 
            ),
            // --- CAMBIO: Anchos de columna reajustados (5 columnas) ---
            columnWidths: {
              0: const pw.FlexColumnWidth(3.5), // Producto (ahora más ancho)
              1: const pw.FlexColumnWidth(0.7), // Cant.
              2: const pw.FlexColumnWidth(1.2), // Precio
              3: const pw.FlexColumnWidth(1.2), // Subtotal
              4: const pw.FlexColumnWidth(2.4), // Observaciones (un poco más ancho)
            },
            // --- CAMBIO: Alineación de celdas (5 columnas) ---
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerRight,
              2: pw.Alignment.centerRight,
              3: pw.Alignment.centerRight,
              4: pw.Alignment.centerLeft, // Observaciones
            },
            rowDecoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
              ),
            ),
          ),
          
          // El "Gran Total" al final del documento ya fue eliminado
          // en el paso anterior.
        ];
      },
    ),
  );
  return pdf.save();
}


// Wrapper para `compute`
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