import 'package:flutter/material.dart';
import 'package:flutter_listados/widgets/ProductSearchSheet.dart';
import 'package:universal_html/html.dart' as html;
import '../models/product.dart';
import '../utils/export_utils.dart';

class ProductManagementPage extends StatefulWidget {
  final String puntoId;
  final String puntoName;

  const ProductManagementPage({
    super.key,
    required this.puntoId,
    required this.puntoName,
  });

  @override
  State<ProductManagementPage> createState() => _ProductManagementPageState();
}

class _ProductManagementPageState extends State<ProductManagementPage> {
  final List<Product> _products = [];
  bool _hasUnsavedChanges = false;

  final Map<String, String> productosDisponibles = {
    "APIO": "Producto002",
    "AJO": "fcd4b7e5",
    "AYOTE": "Producto043",
    "BROCOLI SENCILLO": "b5d35820",
    "BERENJENA": "Producto048",
    "CEBOLLA BLANCA": "Producto007",
    "CEBOLLA MORADA": "Producto008",
    "COLIFLOR": "Producto010",
    "CHILE VERDE": "Producto009",
    "EJOTES": "Producto011",
    "ELOTE DULCE": "d78f21fb",
    "GUISQUIL CHAPIN": "Producto014",
    "GUISQUIL INDIO PRIMERA": "Producto014",
    "CHILE JALAPEÑO": "Producto009",
    "Lechuga Grande": "f0c77c84",
    "Lechuga Mediana": "Producto016",
    "Limon": "Producto023",
    "Papa Bellina": "Producto024",
    "Pepino": "Producto027",
    "Platano Grande": "Producto030",
    "PIPIAN DE PRIMERA": "cd11d087",
    "PIPIAN DE SEGUNDA": "2084fae4",
    "REMOLACHA": "Producto032",
    "REPOLLO": "Producto032",
    "TOMATE GRUESO": "Producto063",
    "TOMATE MEDIANO": "Producto037",
    "ZANAHORIA grande sin tallo": "Producto039",
    "ZUCCHINI": "Producto039",
    "YUCA": "Producto042",
    "BANANO": "Producto004",
    "Lichas": "Producto015",
    "JAMAICA": "Producto054",
    "MANZANA GALA": "d2713057",
    "MANZANA VERDE": "Producto052",
    "NARANJA": "Producto023",
    "PAPA GRANDE": "Producto024",
    "PIÑA": "Producto028",
    "RABANO": "Producto034",
    "AGUACATE INDIO": "Producto051",
    "AGUACATE MEXICANO": "f13b82b3",
    "Alberja China": "537578f8",
    "Arandanos": "c2b30bd0",
    "Berro": "c4c0211a",
    "Camote": "cbe51401",
    "Chipilin": "Producto060",
    "Chocolate": "3fb96c12",
    "Cilantro": "Producto050",
    "Coco": "8667aa66",
    "Elote": "56a2d47e",
    "FRESA": "Producto057",
    "Fruta en bandeja": "7970698f",
    "Gelatinitas": "f3a99898",
    "Gomitas": "cd62f26e",
    "Granadilla": "d17dab29",
    "Guineo de seda": "a4f268b8",
    "Kiwi": "817a1bd5",
    "Mamey": "918fff43",
    "Mandarina clementina": "edfac207",
    "Mandarina": "091de4f8",
    "Manzana mixta": "9f0f1ee9",
    "Manzana golden": "1840ece4",
    "Melón": "Producto055",
    "Melocotón": "Producto022",
    "Mora (fruta)": "Producto059",
    "Mora monte": "f9d9dcc2",
    "Nance": "6dd71ced",
    "Tamarindo": "Producto045",
    "Platano mediano": "Producto031",
    "Manzana Roja": "Producto021",
    "Maracuya": "567bd74d",
    "Brócoli doble": "b5d35820",
    "Brócoli pequeño": "ef79a203",
    "Anona": "77f72adb",
    "Encurtido o curtido": "d30a38ff",
    "Ciruela": "0a166eef",
    "Dulce de panela": "26b4e0b6",
    "Espinaca": "e6b567a6",
    "Güisquil perulero": "c36ab341",
    "Hierva buena": "Producto061",
    "Huevo grande": "16f5d47d",
    "Huevo mediano": "490ee12d",
    "Huevos Extra Grandes": "3a1034ad",
    "Huevos pequeños": "9e3deb6a",
    "Jícama": "6e8b0360",
    "Jocote": "be9be332",
    "Jocote acido": "81c58d58",
    "Jocote de azucaron": "defa9469",
    "Lechuga escarola": "aef77fa0",
    "Loroco": "Producto019",
    "Manzana Pink Lady": "138a0457",
    "Marshmellow": "c2466763",
    "Olor": "e1e2e86d",
    "Papa mexicana": "52a1a57d",
    "Papa pequeña en red": "6d793ec7",
    "Papa Russet": "9dbe65fe",
    "Papa soloma": "20348300",
    "Papaya": "Producto026",
    "Pera": "a66f6a3a",
    "Perejil": "5a43d485",
    "Repollo morado": "5f03bb17",
    "Sandía": "c9b1dcba",
    "Mix de monte": "05aa25a1",
    "Tomate de tercera": "7367ffb8",
    "Uva Morada": "Producto044",
    "Uva negra": "0f8714a2",
    "Uva roja": "1924cd5a",
    "Uva Verde": "e481f318",
    "Zanahoria pequeña sin tallo": "Producto040",
  };

  void _onBeforeUnload(html.Event event) {
  if (_hasUnsavedChanges) {
    // Cast the event to the correct type to access returnValue.
    (event as html.BeforeUnloadEvent).returnValue = 'Are you sure you want to leave?';
  }
}

  @override
  void initState() {
    super.initState();
    // Add the listener for web platforms
    html.window.addEventListener('beforeunload', _onBeforeUnload);
  }

  @override
  void dispose() {
    // Remove the listener to prevent memory leaks
    html.window.removeEventListener('beforeunload', _onBeforeUnload);
    super.dispose();
  }

  void _addProduct(Product p) {
    setState(() {
      _products.add(p);
      _hasUnsavedChanges = true; // Set to true when a change is made
    });
  }

  void _editProduct(int index, Product p) {
    setState(() {
      _products[index] = p;
      _hasUnsavedChanges = true; // Set to true when a change is made
    });
  }

  void _confirmDelete(int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Desea eliminar el producto "${_products[index].name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              _deleteProduct(index);
              Navigator.of(context).pop();
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _deleteProduct(int index) {
    setState(() {
      _products.removeAt(index);
      _hasUnsavedChanges = true; // Set to true when a change is made
    });
  }

  void _showAddProductSheet() async {
    final result = await showModalBottomSheet<Product>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ProductSearchSheet(
        productosDisponibles: productosDisponibles,
      ),
    );
    if (result != null) _addProduct(result);
  }

  void _finalizeList() {
    if (_products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No hay productos en la lista")),
      );
      return;
    }

    // Set _hasUnsavedChanges to false since the list is being finalized
    setState(() {
      _hasUnsavedChanges = false;
    });

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Exportar lista'),
        content: const Text('Elija el formato de exportación:'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              shareCsv(_products,
                  puntoId: widget.puntoId,
                  puntoName: widget.puntoName,
                  context: context);
            },
            child: const Text('CSV'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              sharePdf(_products,
                  puntoId: widget.puntoId,
                  puntoName: widget.puntoName,
                  context: context);
            },
            child: const Text('PDF'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Note: WillPopScope is not needed for the web version's main functionality.
    // The html.window listener handles the browser's "beforeunload" event.
    return Scaffold(
      appBar: AppBar(title: Text(widget.puntoName)),
      body: Column(
        children: [
          Expanded(
            child: _products.isEmpty
                ? const Center(
                    child: Text(
                      'No hay productos agregados.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _products.length,
                    itemBuilder: (context, index) {
                      final p = _products[index];
                      return Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          leading: CircleAvatar(
                            backgroundColor: Colors.deepPurple.shade100,
                            child: Text(p.quantity.toString(),
                                style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold)),
                          ),
                          title: Text(
                            p.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: Text(
                            '${p.unit.name} x \$${p.unitPrice.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          trailing: SizedBox(
                            width: 150,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: Text(
                                    '\$${p.subtotal.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blueAccent),
                                    textAlign: TextAlign.right,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.green),
                                  onPressed: () async {
                                    final edited =
                                        await showModalBottomSheet<Product>(
                                      context: context,
                                      isScrollControlled: true,
                                      builder: (_) => ProductSearchSheet(
                                        initialProduct: p,
                                        productosDisponibles:
                                            productosDisponibles,
                                      ),
                                    );
                                    if (edited != null) _editProduct(index, edited);
                                  },
                                  tooltip: 'Editar',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _confirmDelete(index),
                                  tooltip: 'Eliminar',
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.grey.shade100,
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar Producto'),
                    onPressed: _showAddProductSheet,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text('Finalizar Lista'),
                    onPressed: _finalizeList,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}