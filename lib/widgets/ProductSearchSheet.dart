// lib/widgets/product_search_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter_listados/models/default_units.dart';
import 'package:flutter_listados/models/product.dart';
// ignore: depend_on_referenced_packages

class ProductSearchSheet extends StatefulWidget {
  final Map<String, String> productosDisponibles;
  final Product? initialProduct; // ✅ Ahora es opcional y para edición

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
      _unit = UnitType.Unidad; // Unidad por defecto si no hay producto inicial
      _quantityController.text = '1';
      _unitPriceController.text = '0.00';
      _autocompleteController.text = '';
    }

    _quantityFocusNode.addListener(() {
      if (_quantityFocusNode.hasFocus) {
        // Seleccionar todo el texto al obtener el foco para facilitar la edición
        _quantityController.selection = TextSelection(baseOffset: 0, extentOffset: _quantityController.text.length);
      }
    });

    _unitPriceFocusNode.addListener(() {
      if (_unitPriceFocusNode.hasFocus) {
        _unitPriceController.selection = TextSelection(baseOffset: 0, extentOffset: _unitPriceController.text.length);
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

  void _saveProduct() {
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    final unitPrice = double.tryParse(_unitPriceController.text) ?? 0.0;

    // Validación básica
    if (_name == null || _id == null || quantity <= 0 || unitPrice < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, complete todos los campos correctamente.')),
      );
      return;
    }

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
              Container(
                margin: const EdgeInsets.only(bottom: 16.0),
                height: 5,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              Text(
                widget.initialProduct == null ? 'Agregar Producto' : 'Editar Producto',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 20),
              // El Autocomplete se usa principalmente para seleccionar un producto si es nuevo.
              // Si es un producto existente, solo muestra el nombre.
              if (widget.initialProduct == null)
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
                      _unit = defaultUnits[selection] ?? UnitType.Unidad; // Unidad por defecto
                    });
                  },
                  fieldViewBuilder: (BuildContext context, TextEditingController textEditingController, FocusNode focusNode, VoidCallback onFieldSubmitted) {
                    _autocompleteController.text = textEditingController.text; // Sincroniza el controller del autocomplete
                    return TextFormField(
                      controller: textEditingController,
                      focusNode: focusNode,
                      decoration: const InputDecoration(
                        labelText: 'Buscar y seleccionar producto',
                        hintText: 'Ej. Manzana',
                        suffixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (text) {
                        setState(() {
                          _name = null;
                          _id = null;
                        });
                      },
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_quantityFocusNode),
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
                )
              else
                // Si es un producto existente, solo mostramos el nombre
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    _name!,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              const SizedBox(height: 10),
              DropdownButtonFormField<UnitType>(
                decoration: const InputDecoration(
                  labelText: 'Unidad',
                  border: OutlineInputBorder(),
                ),
                value: _unit,
                items: UnitType.values
                    .map((u) => DropdownMenuItem(value: u, child: Text(u.name)))
                    .toList(),
                onChanged: (u) => setState(() => _unit = u!),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _quantityController,
                focusNode: _quantityFocusNode,
                decoration: const InputDecoration(
                  labelText: 'Cantidad',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_unitPriceFocusNode),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _unitPriceController,
                focusNode: _unitPriceFocusNode,
                decoration: const InputDecoration(
                  labelText: 'Precio unitario',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _saveProduct(), // Guardar al pulsar "Done" en el último campo
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: (_name != null && _id != null)
                        ? _saveProduct
                        : null,
                    child: const Text('Guardar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}