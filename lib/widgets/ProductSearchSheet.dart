import 'package:flutter/material.dart';
import '../models/product.dart';

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
  
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _unitPriceController = TextEditingController();
  
  final FocusNode _quantityFocusNode = FocusNode();
  final FocusNode _unitPriceFocusNode = FocusNode();
  
  final TextEditingController _autocompleteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final p = widget.initialProduct;
    if (p != null) {
      _name = p.name;
      _id = p.id;
      _unit = p.unit;
      _quantityController.text = p.quantity.toString();
      _unitPriceController.text = p.unitPrice.toStringAsFixed(2);
      _autocompleteController.text = p.name;
    } else {
      _name = null;
      _id = null;
      _unit = UnitType.Unidad;
      _quantityController.text = '1';
      _unitPriceController.text = '0.00';
      _autocompleteController.text = '';
    }

    _quantityFocusNode.addListener(() {
      if (_quantityFocusNode.hasFocus) {
        _quantityController.clear();
      }
    });

    _unitPriceFocusNode.addListener(() {
      if (_unitPriceFocusNode.hasFocus) {
        _unitPriceController.clear();
      }
    });
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _unitPriceController.dispose();
    _quantityFocusNode.dispose();
    _unitPriceFocusNode.dispose();
    _autocompleteController.dispose();
    super.dispose();
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
              // Barra de arrastre para indicar que el modal puede ser cerrado
              Container(
                margin: const EdgeInsets.only(bottom: 16.0),
                height: 5,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text == '') {
                    return const Iterable<String>.empty();
                  }
                  return widget.productosDisponibles.keys.where((String option) {
                    return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                  });
                },
                onSelected: (String selection) {
                  setState(() {
                    _name = selection;
                    _id = widget.productosDisponibles[selection]!;
                  });
                },
                fieldViewBuilder: (BuildContext context, TextEditingController textEditingController, FocusNode focusNode, VoidCallback onFieldSubmitted) {
                  return TextFormField(
                    controller: textEditingController,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      labelText: 'Buscar y agregar producto',
                      hintText: 'Ej. Manzana',
                      suffixIcon: Icon(Icons.search),
                    ),
                    onChanged: (text) {
                      setState(() {
                        _name = null;
                        _id = null;
                      });
                    },
                  );
                },
                optionsViewBuilder: (BuildContext context, AutocompleteOnSelected<String> onSelected, Iterable<String> options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4.0,
                      child: SizedBox(
                        height: 200.0,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(8.0),
                          itemCount: options.length,
                          itemBuilder: (BuildContext context, int index) {
                            final String option = options.elementAt(index);
                            return GestureDetector(
                              onTap: () {
                                onSelected(option);
                              },
                              child: ListTile(
                                title: Text(option),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<UnitType>(
                decoration: const InputDecoration(labelText: 'Unidad "saco", "bandeja"'),
                initialValue: _unit,
                items: UnitType.values
                    .map((u) => DropdownMenuItem(value: u, child: Text(u.name)))
                    .toList(),
                onChanged: (u) => setState(() => _unit = u!),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _quantityController,
                focusNode: _quantityFocusNode,
                decoration: const InputDecoration(labelText: 'Cantidad'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _unitPriceController,
                focusNode: _unitPriceFocusNode,
                decoration: const InputDecoration(
                  labelText: 'Precio unitario',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: (_name != null && _id != null)
                    ? () {
                        final quantity = int.tryParse(_quantityController.text) ?? 1;
                        final unitPrice = double.tryParse(_unitPriceController.text) ?? 0.0;
                        Navigator.pop(
                          context,
                          Product(
                            name: _name!,
                            id: _id!,
                            unit: _unit,
                            quantity: quantity,
                            unitPrice: unitPrice,
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