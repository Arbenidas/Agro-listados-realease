import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:universal_html/html.dart' as html;
import '../models/product.dart';

final Map<UnitType, Map<String, String>> unitMapping = {
  UnitType.quintal: {"id": "0e001ce3", "name": "QUINTAL"},
  UnitType.bandeja: {"id": "b61df036", "name": "BANDEJA"},
  UnitType.jabaJumbo: {"id": "ee464733", "name": "JABA JUMBO"},
  UnitType.saco: {"id": "d3da911d", "name": "SACO"},
  UnitType.bulto: {"id": "176bdd70", "name": "BULTO"},
  UnitType.bolsa: {"id": "42dc4583", "name": "BOLSA"},
  UnitType.fardo: {"id": "cd40923c", "name": "FARDO"},
  UnitType.caja: {"id": "e2266e41", "name": "CAJA"},
  UnitType.unidad: {
    "id": "xxxxxx",
    "name": "UNIDAD",
  },
};

Future<void> shareCsv(List<Product> items, {required String puntoId, required String puntoName}) async {
  final now = DateTime.now().add(const Duration(days: 1));
  final csvFecha = DateFormat('dd/MM/yyyy').format(now);
  final fileDate = DateFormat('dd-MM-yyyy').format(now);

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
  
  // NOTE: You need to define `unitMapping` for the code to work.
  // Example:
  // final Map<UnitType, Map<String, dynamic>> unitMapping = {
  //   UnitType.saco: {"id": "saco_id", "name": "Saco"},
  //   UnitType.caja: {"id": "caja_id", "name": "Caja"},
  // };
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

  final String fileContent = csv.toString();

  if (kIsWeb) {
    // Si la aplicación se ejecuta en la web, descarga el archivo
    final Uint8List data = Uint8List.fromList(fileContent.codeUnits);
    final fileName = 'DESPACHO_${puntoName.replaceAll(' ', '_')}_$fileDate.csv';
    downloadFile(fileName, data);
  } else {
    // Si la aplicación se ejecuta en móvil (iOS, Android, etc.), usa path_provider y share_plus
    final dir = await getTemporaryDirectory();
    final fileName = 'DESPACHO_${puntoName.replaceAll(' ', '_')}_$fileDate.csv';
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(fileContent);

    await Share.shareXFiles([XFile(file.path)], text: 'Archivo CSV exportado');
  }
}
///funcion para poder export el csv desde la web
void downloadFile(String fileName, Uint8List data) {
  final blob = html.Blob([data]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute("download", fileName)
    ..click();
  html.Url.revokeObjectUrl(url);
}
Future<void> sharePdf(List<Product> products, {required String puntoId, required String puntoName}) async {
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
            pw.Table.fromTextArray(
              headers: ['Nombre', 'Cantidad', 'Unidad', 'Precio Unitario', 'Subtotal'],
              data: products.map((p) => [
                p.name,
                p.quantity,
                p.unit.name,
                p.unitPrice.toStringAsFixed(2),
                p.subtotal.toStringAsFixed(2),
              ]).toList(),
            ),
          ],
        );
      },
    ),
  );

  final Uint8List data = await pdf.save();
  final fileName = 'Lista_${puntoName}_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.pdf';

  if (kIsWeb) {
    // Si es web, usa la función de descarga para el navegador
    downloadFile(fileName, data);
  } else {
    // Si es móvil, guarda el archivo temporalmente y usa el diálogo de compartir
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(data);
    await Share.shareXFiles([XFile(file.path)], text: 'Archivo PDF exportado');
  }
}