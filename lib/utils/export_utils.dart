// Archivo: lib/utils/export_utils.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:universal_html/html.dart' as html;
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;
import '../models/product.dart';

final Map<UnitType, Map<String, String>> unitMapping = {
  UnitType.Unidad: {"id": "c8836a89", "name": "Unidad"},
  UnitType.Caja: {"id": "e2266e41", "name": "Caja"},
  UnitType.CajaDoble: {"id": "0549f383", "name": "Caja doble"},
  UnitType.Canasto: {"id": "328e367e", "name": "Canasto"},
  UnitType.Ciento: {"id": "e3680387", "name": "Ciento"},
  UnitType.Docena: {"id": "a7224a1b", "name": "Docena"},
  UnitType.Bolsa: {"id": "42dc4583", "name": "Bolsa"},
  UnitType.BolsaDoble: {"id": "6ec18920", "name": "Bolsa doble"},
  UnitType.Bulto: {"id": "176bdd70", "name": "Bulto"},
  UnitType.Saco: {"id": "d3da911d", "name": "Saco"},
  UnitType.Saco200: {"id": "369b70ea", "name": "Saco 200"},
  UnitType.Saco400: {"id": "d968a514", "name": "Saco 400"},
  UnitType.Fardo: {"id": "cd40923c", "name": "Fardo"},
  UnitType.Jaba: {"id": "c2b21d35", "name": "Jaba"},
  UnitType.JabaJumbo: {"id": "ee464733", "name": "Jaba Jumbo"},
  UnitType.Libra: {"id": "4eee07a0", "name": "Libra"},
  UnitType.Quintal: {"id": "0e001ce3", "name": "1 Quintal"},
  UnitType.MedioQuintal: {"id": "3fb9a892", "name": "1/2 Quintal"},
  UnitType.Manojo: {"id": "efd2c64e", "name": "Manojo"},
  UnitType.Bandeja: {"id": "b61df036", "name": "Bandeja"},
  UnitType.Arroba: {"id": "5b6928cc", "name": "Arroba"},
  UnitType.Marqueta: {"id": "7f9ee2aa", "name": "Marqueta"},
  UnitType.Red: {"id": "1162b08e", "name": "Red"},
  UnitType.BolsaMedia: {"id": "a6a66ed3", "name": "Bolsa media"},
};

// -------------------------------------------------------------
// FUNCIONES DE GENERACIÓN EN SEGUNDO PLANO
// -------------------------------------------------------------
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
    final mapping = unitMapping[p.unit]!;
    final totalProducto = (p.quantity * p.unitPrice).toStringAsFixed(2);
    return [
      "",
      puntoId,
      csvFecha,
      p.id,
      p.name,
      totalProducto,
      p.unitPrice.toStringAsFixed(2),
      p.quantity.toString(),
      mapping["id"],
      mapping["name"],
      "",
      "",
    ];
  }).toList();

  final csv = StringBuffer();
  csv.writeln(headers.join(","));
  for (final row in rows) {
    csv.writeln(row.join(","));
  }

  return Uint8List.fromList(csv.toString().codeUnits);
}

Future<Uint8List> _generatePdfInBackground(Map<String, dynamic> data) async {
  final List<Product> products = data['products'];
  final String puntoName = data['puntoName'];
  final pdf = pw.Document();

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Lista de Productos para $puntoName',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              'Fecha: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 14),
            ),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              headers: [
                'Nombre',
                'Cantidad',
                'Unidad',
                'Precio Unitario',
                'Subtotal'
              ],
              data: products
                  .map((p) => [
                        p.name,
                        p.quantity,
                        p.unit.name,
                        p.unitPrice.toStringAsFixed(2),
                        p.subtotal.toStringAsFixed(2),
                      ])
                  .toList(),
            ),
          ],
        );
      },
    ),
  );
  return await pdf.save();
}

// -------------------------------------------------------------
// FUNCIONES PÚBLICAS PARA COMPARTIR
// -------------------------------------------------------------
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

Future<void> shareBoth(List<Product> products,
    {required String puntoId,
    required String puntoName,
    required BuildContext context}) async {
  await _prepareAndShare(
    context: context,
    products: products,
    puntoId: puntoId,
    puntoName: puntoName,
    exportType: 'both',
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

// -------------------------------------------------------------
// FUNCIÓN CENTRAL PARA PREPARAR Y COMPARTIR
// -------------------------------------------------------------
Future<void> _prepareAndShare({
  required BuildContext context,
  required List<Product> products,
  required String puntoId,
  required String puntoName,
  required String exportType,
}) async {
  _showLoadingDialog(context);
  final now = DateTime.now().add(const Duration(days: 1));
  final fileDate = DateFormat('dd-MM-yyyy').format(now);

  try {
    List<XFile> filesToShare = [];
    String message = 'Aquí están las listas de productos.';
    String title = 'Listas de Productos';

    switch (exportType) {
      case 'csv':
        final csvData = await compute(_generateCsvInBackground, {
          'items': products,
          'puntoId': puntoId,
        });
        final csvFileName =
            'DESPACHO_${puntoName.replaceAll(' ', '_')}_$fileDate.csv';

        if (kIsWeb) {
          filesToShare.add(XFile.fromData(csvData,
              name: csvFileName, mimeType: 'text/csv'));
        } else {
          final tempDir = await getTemporaryDirectory();
          final csvFile = File(p.join(tempDir.path, csvFileName));
          await csvFile.writeAsBytes(csvData);
          filesToShare.add(XFile(csvFile.path, name: csvFileName));
        }
        break;

      case 'pdf':
        final pdfData = await compute(_generatePdfInBackground, {
          'products': products,
          'puntoName': puntoName,
        });
        final pdfFileName = 'Lista_${puntoName}_$fileDate.pdf';

        if (kIsWeb) {
          filesToShare.add(XFile.fromData(pdfData,
              name: pdfFileName, mimeType: 'application/pdf'));
        } else {
          final tempDir = await getTemporaryDirectory();
          final pdfFile = File(p.join(tempDir.path, pdfFileName));
          await pdfFile.writeAsBytes(pdfData);
          filesToShare.add(XFile(pdfFile.path, name: pdfFileName));
        }
        break;

      case 'both':
        final csvData = await compute(_generateCsvInBackground, {
          'items': products,
          'puntoId': puntoId,
        });
        final pdfData = await compute(_generatePdfInBackground, {
          'products': products,
          'puntoName': puntoName,
        });
        final csvFileName =
            'DESPACHO_${puntoName.replaceAll(' ', '_')}_$fileDate.csv';
        final pdfFileName = 'Lista_${puntoName}_$fileDate.pdf';

        if (kIsWeb) {
          filesToShare.add(XFile.fromData(csvData,
              name: csvFileName, mimeType: 'text/csv'));
          filesToShare.add(XFile.fromData(pdfData,
              name: pdfFileName, mimeType: 'application/pdf'));
        } else {
          final tempDir = await getTemporaryDirectory();
          final csvFile = File(p.join(tempDir.path, csvFileName));
          final pdfFile = File(p.join(tempDir.path, pdfFileName));
          await csvFile.writeAsBytes(csvData);
          await pdfFile.writeAsBytes(pdfData);
          filesToShare.add(XFile(csvFile.path, name: csvFileName));
          filesToShare.add(XFile(pdfFile.path, name: pdfFileName));
        }
        break;

      case 'zip':
        final csvData = await compute(_generateCsvInBackground, {
          'items': products,
          'puntoId': puntoId,
        });
        final pdfData = await compute(_generatePdfInBackground, {
          'products': products,
          'puntoName': puntoName,
        });
        final zipFileName =
            'Despacho_${puntoName.replaceAll(' ', '_')}_$fileDate.zip';

        if (kIsWeb) {
          final archive = Archive()
            ..addFile(ArchiveFile('DESPACHO.csv', csvData.length, csvData))
            ..addFile(ArchiveFile('LISTA.pdf', pdfData.length, pdfData));
          final zipData = Uint8List.fromList(ZipEncoder().encode(archive)!);
filesToShare.add(XFile.fromData(
  zipData,
  name: zipFileName,
  mimeType: 'application/zip',
));

          final tempDir = await getTemporaryDirectory();
          final tempFilePath = p.join(tempDir.path, zipFileName);
          final zipEncoder = ZipFileEncoder();
          zipEncoder.create(tempFilePath);
          zipEncoder.addArchiveFile(
              ArchiveFile('DESPACHO.csv', csvData.length, csvData));
          zipEncoder.addArchiveFile(
              ArchiveFile('LISTA.pdf', pdfData.length, pdfData));
          zipEncoder.close();
          filesToShare.add(XFile(tempFilePath, name: zipFileName));
        }
        break;
    }

    if (context.mounted) Navigator.of(context).pop();

    if (kIsWeb) {
      await _shareFilesWeb(
          context: context, files: filesToShare, title: title, message: message);
    } else {
      await Share.shareXFiles(filesToShare,
          subject: title,
          sharePositionOrigin: const Rect.fromLTWH(0, 0, 1, 1));
    }
  } catch (e) {
    if (context.mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al compartir: $e')),
      );
    }
  }
}

Future<void> _shareFilesWeb({
  required BuildContext context,
  required List<XFile> files,
  required String title,
  required String message,
}) async {
  try {
    for (var xfile in files) {
      final bytes = await xfile.readAsBytes();
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", xfile.name ?? "file")
        ..click();
      html.Url.revokeObjectUrl(url);
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Archivos descargados en Web')),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al compartir en Web: $e')),
      );
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
