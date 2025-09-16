import 'package:flutter/material.dart';
import '../models/product.dart';

// ---------------- ProductSearchSheet ----------------
class ProductSearchSheet extends StatefulWidget {
  final Map<String, String> productosDisponibles;
  final Product? initialProduct;

  const ProductSearchSheet({
    super.key,
    required this.productosDisponibles,
    this.initialProduct,
  });

  @override
  State<ProductSearchSheet> createState() => _ProductSearchSheetState();
}

class _ProductSearchSheetState extends State<ProductSearchSheet> {
  String? _name;
  String? _id;
  late UnitType _unit;
  late int _quantity;
  late double _unitPrice;

  @override
  void initState() {
    super.initState();
    final p = widget.initialProduct;
    _name = p?.name;
    _id = p?.id;
    _unit = p?.unit ?? UnitType.saco;
    _quantity = p?.quantity ?? 1;
    _unitPrice = p?.unitPrice ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Producto'),
                items: widget.productosDisponibles.keys
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                initialValue: _name,
                onChanged: (v) {
                  setState(() {
                    _name = v;
                    _id = widget.productosDisponibles[v!];
                  });
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<UnitType>(
                decoration: const InputDecoration(labelText: 'Unidad'),
                value: _unit,
                items: UnitType.values
                    .map((u) => DropdownMenuItem(value: u, child: Text(u.name)))
                    .toList(),
                onChanged: (u) => setState(() => _unit = u!),
              ),
              const SizedBox(height: 10),
              TextFormField(
                initialValue: _quantity.toString(),
                decoration: const InputDecoration(labelText: 'Cantidad'),
                keyboardType: TextInputType.number,
                onChanged: (v) => _quantity = int.tryParse(v) ?? 1,
              ),
              const SizedBox(height: 10),
              TextFormField(
                initialValue: _unitPrice.toStringAsFixed(2),
                decoration: const InputDecoration(
                  labelText: 'Precio por unidad',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (v) => _unitPrice = double.tryParse(v) ?? 0.0,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: (_name != null && _id != null)
                    ? () {
                        Navigator.pop(
                          context,
                          Product(
                            name: _name!,
                            id: _id!,
                            unit: _unit,
                            quantity: _quantity,
                            unitPrice: _unitPrice,
                          ),
                        );
                      }
                    : null,
                child: const Text('Agregar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
