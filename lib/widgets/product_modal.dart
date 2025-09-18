import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/product.dart';

class ProductModal extends StatefulWidget {
  final Product? initialProduct;
  final void Function(Product) onSave;

  const ProductModal({
    super.key,
    this.initialProduct,
    required this.onSave,
  });

  @override
  State<ProductModal> createState() => _ProductModalState();
}

class _ProductModalState extends State<ProductModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _quantityController;
  UnitType _selectedUnit = UnitType.Unidad;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.initialProduct?.name ?? '');
    _priceController = TextEditingController(
        text: widget.initialProduct?.unitPrice.toString() ?? '');
    _quantityController = TextEditingController(
        text: widget.initialProduct?.quantity.toString() ?? '');
    _selectedUnit = widget.initialProduct?.unit ?? UnitType.Unidad;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final product = Product(
        id: widget.initialProduct?.id ?? const Uuid().v4(),
        name: _nameController.text,
        unitPrice: double.parse(_priceController.text),
        unit: _selectedUnit,
        quantity: int.parse(_quantityController.text),
      );
      widget.onSave(product);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialProduct == null
          ? "Agregar producto"
          : "Editar producto"),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Nombre"),
                validator: (value) =>
                    value == null || value.isEmpty ? "Requerido" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Precio unitario"),
                validator: (value) {
                  if (value == null || value.isEmpty) return "Requerido";
                  if (double.tryParse(value) == null) return "Número inválido";
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Cantidad"),
                validator: (value) {
                  if (value == null || value.isEmpty) return "Requerido";
                  if (int.tryParse(value) == null) return "Número inválido";
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<UnitType>(
                value: _selectedUnit,
                decoration: const InputDecoration(labelText: "Unidad"),
                items: UnitType.values
                    .map(
                      (u) => DropdownMenuItem(
                        value: u,
                        child: Text(u.name),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedUnit = val);
                  }
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Cancelar"),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text("Guardar"),
        ),
      ],
    );
  }
}
