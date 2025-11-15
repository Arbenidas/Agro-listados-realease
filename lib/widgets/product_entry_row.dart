// lib/widgets/product_entry_row.dart
// MODIFICADO para manejar estado inválido y corrección

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_listados/models/product.dart';
import 'package:flutter_listados/data/units.dart';

// --- NUEVOS IMPORTS ---
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter_listados/data/products_data.dart'; // Para defaultUnits

class ProductEntryRow extends StatefulWidget {
  final Product initialProduct;
  final int index;
  final Function(Product) onChanged;
  final List<DropdownMenuItem<UnitType>> unitTypeDropdownItems;

  // --- NUEVOS PARÁMETROS ---
  final bool isInvalid;
  final List<MapEntry<String, String>> availableProducts;
  final Function(MapEntry<String, String>) onCorrectProduct;

  const ProductEntryRow({
    required super.key,
    required this.initialProduct,
    required this.index,
    required this.onChanged,
    required this.unitTypeDropdownItems,
    // --- NUEVOS PARÁMETROS REQUERIDOS ---
    required this.isInvalid,
    required this.availableProducts,
    required this.onCorrectProduct,
  });

  @override
  State<ProductEntryRow> createState() => _ProductEntryRowState();
}

class _ProductEntryRowState extends State<ProductEntryRow>
    with AutomaticKeepAliveClientMixin {
  late Product _product;
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  bool _isFocused = false;

  @override
  bool get wantKeepAlive => true; // Mantiene el estado en la lista

  @override
  void initState() {
    super.initState();
    _product = widget.initialProduct;
    if (_product.quantity > 0) {
      _quantityController.text = _product.quantity.toString();
    }
    if (_product.unitPrice > 0) {
      _priceController.text = _product.unitPrice.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _updateProduct() {
     // No actualices si el producto es inválido,
     // ya que no tiene sentido guardar sus cambios
    if(widget.isInvalid) return;

    final int quantity = int.tryParse(_quantityController.text) ?? 0;
    final double price = double.tryParse(_priceController.text) ?? 0.0;
    _product = _product.copyWith(
      quantity: quantity,
      unitPrice: price,
    );
    widget.onChanged(_product);
  }

  void _onUnitChanged(UnitType? newUnit) {
    if (newUnit != null) {
      setState(() {
        _product = _product.copyWith(unit: newUnit);
      });
      _updateProduct();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Necesario para AutomaticKeepAliveClientMixin

    // Color de fondo basado en foco o estado inválido
    Color rowColor = widget.isInvalid
        ? Colors.red.withOpacity(0.15) // Rojo si es inválido
        : (_isFocused
            ? Colors.deepPurple.withOpacity(0.05)
            : (widget.index.isEven
                ? Colors.grey.withOpacity(0.05)
                : Colors.transparent));

    return Container(
      color: rowColor,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: FocusScope(
        onFocusChange: (focus) {
          setState(() {
            _isFocused = focus;
          });
          if (!focus) {
            _updateProduct(); // Guarda al perder foco
          }
        },
        child: Row(
          children: [
            // --- COLUMNA 1: PRODUCTO (CONDICIONAL) ---
            Expanded(
              flex: 4,
              child: widget.isInvalid
                  // --- UI PARA PRODUCTO INVÁLIDO ---
                  ? _buildInvalidProductSelector()
                  // --- UI PARA PRODUCTO VÁLIDO ---
                  : Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4.0, vertical: 12.0),
                      child: Text(
                        _product.name,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
            ),
            // --- COLUMNA 2: CANTIDAD ---
            Expanded(
              flex: 2,
              child: _buildTextField(_quantityController, "Cant."),
            ),
            // --- COLUMNA 3: PRECIO ---
            Expanded(
              flex: 3,
              child: _buildTextField(_priceController, "Precio"),
            ),
            // --- COLUMNA 4: UNIDAD ---
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.only(left: 4.0),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<UnitType>(
                    value: _product.unit,
                    items: widget.unitTypeDropdownItems,
                    onChanged: widget.isInvalid ? null : _onUnitChanged, // Deshabilitado si es inválido
                    isExpanded: true,
                    disabledHint: widget.isInvalid ? Text(_product.unit.name, style: TextStyle(fontSize: 12)) : null,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// --- NUEVO: Widget para el buscador de reemplazo ---
  Widget _buildInvalidProductSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: DropdownSearch<MapEntry<String, String>>(
        items: widget.availableProducts,
        // Cómo mostrar el nombre en la lista
        itemAsString: (entry) => entry.key,
        // Lógica de filtrado
        filterFn: (entry, filter) =>
            entry.key.toLowerCase().contains(filter.toLowerCase()),
        // Configuración del Popup (Modal)
        popupProps: PopupProps.modalBottomSheet(
          showSearchBox: true,
          searchFieldProps: TextFieldProps(
            decoration: InputDecoration(
              labelText: 'Buscar producto de reemplazo',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          modalBottomSheetProps: ModalBottomSheetProps(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
          ),
          title: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              'Producto: "${widget.initialProduct.name}"\nSeleccione un reemplazo válido:',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ),
        ),
        // Decoración del campo principal
        dropdownDecoratorProps: DropDownDecoratorProps(
          baseStyle: TextStyle(
              color: Colors.red.shade900,
              fontWeight: FontWeight.bold,
              fontSize: 13),
          dropdownSearchDecoration: InputDecoration(
            hintText: '¡Producto no válido!',
            hintStyle: TextStyle(color: Colors.red.shade700),
            labelText: 'Corregir Producto',
            labelStyle: TextStyle(color: Colors.red.shade900),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.red.shade700),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.red.shade700, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.red.shade900, width: 2),
            ),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
        ),
        // Callback al seleccionar
        onChanged: (selectedEntry) {
          if (selectedEntry != null) {
            // Llama a la función de la página padre para
            // reemplazar este producto
            widget.onCorrectProduct(selectedEntry);
          }
        },
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.0),
      child: TextFormField(
        controller: controller,
        textAlign: TextAlign.right,
        // Deshabilita los campos si el producto es inválido
        readOnly: widget.isInvalid,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          border: const OutlineInputBorder(),
           // Color de fondo gris si está deshabilitado
          fillColor: widget.isInvalid ? Colors.grey[200] : null,
          filled: widget.isInvalid,
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
        ],
        onChanged: (value) {
          // No es necesario si _updateProduct se llama al desenfocar
        },
      ),
    );
  }
}