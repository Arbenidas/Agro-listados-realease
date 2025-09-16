import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
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

  final dir = await getTemporaryDirectory();
  final fileName = 'DESPACHO_${puntoName.replaceAll(' ', '_')}_$fileDate.csv';
  final file = File('${dir.path}/$fileName');
  await file.writeAsString(csv.toString());

  await Share.shareXFiles([XFile(file.path)], text: 'Archivo CSV exportado');
}

Future<void> sharePdf(List<Product> items, {required String puntoId, required String puntoName}) async {
  final pdf = pw.Document();
  final now = DateTime.now();
  final fecha = DateFormat('dd-MM-yyyy').format(now);
  final total = items.fold(0.0, (sum, p) => sum + p.subtotal);

  pdf.addPage(
    pw.Page(
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              "Listado de productos",
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            pw.Text("Punto: $puntoName"),
            pw.Text("Fecha: $fecha"),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              headers: ["Producto", "Cantidad", "Precio Unidad", "Subtotal"],
              data: items.map((p) {
                return [
                  p.name,
                  p.quantity.toString(),
                  p.unitPrice.toStringAsFixed(2),
                  p.subtotal.toStringAsFixed(2),
                ];
              }).toList(),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              "Total: \$${total.toStringAsFixed(2)}",
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
          ],
        );
      },
    ),
  );

  final dir = await getTemporaryDirectory();
  final fileName = '${puntoName.replaceAll(' ', '_')}_productos.pdf';
  final file = File('${dir.path}/$fileName');
  await file.writeAsBytes(await pdf.save());

  await Share.shareXFiles([XFile(file.path)], text: 'Archivo PDF exportado');
}