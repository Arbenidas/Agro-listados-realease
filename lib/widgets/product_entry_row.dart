// Archivo: lib/widgets/product_entry_row.dart
// NUEVO WIDGET

import 'package:flutter/material.dart';
import 'package:flutter_listados/models/product.dart';

typedef ProductChangedCallback = void Function(Product updatedProduct);

class ProductEntryRow extends StatefulWidget {
  final Product initialProduct;
  final int index;
  final ProductChangedCallback onChanged;
  final List<DropdownMenuItem<UnitType>> unitTypeDropdownItems;
  final FocusNode? quantityFocusNode;
  final FocusNode? unitPriceFocusNode;
  final Function(String currentProductName)? onFocusMoveToNextProduct;

  const ProductEntryRow({
    super.key,
    required this.initialProduct,
    required this.index,
    required this.onChanged,
    required this.unitTypeDropdownItems,
    this.quantityFocusNode,
    this.unitPriceFocusNode,
    this.onFocusMoveToNextProduct,
  });

  @override
  _ProductEntryRowState createState() => _ProductEntryRowState();
}

class _ProductEntryRowState extends State<ProductEntryRow> with AutomaticKeepAliveClientMixin {
  late Product _currentProduct;

  @override
  void initState() {
    super.initState();
    _currentProduct = widget.initialProduct;
  }

  @override
  void didUpdateWidget(covariant ProductEntryRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialProduct != oldWidget.initialProduct) {
      _currentProduct = widget.initialProduct;
    }
  }

  @override
  bool get wantKeepAlive => true;

  void _onFieldSubmitted(String currentField) {
    if (currentField == 'quantity') {
      if (widget.unitPriceFocusNode != null) {
        FocusScope.of(context).requestFocus(widget.unitPriceFocusNode);
      }
    } else if (currentField == 'unitPrice') {
      if (widget.onFocusMoveToNextProduct != null) {
        widget.onFocusMoveToNextProduct!(widget.initialProduct.name);
      } else {
        FocusScope.of(context).unfocus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final TextInputAction quantityInputAction = widget.unitPriceFocusNode != null ? TextInputAction.next : TextInputAction.done;
    final TextInputAction unitPriceInputAction = widget.onFocusMoveToNextProduct != null ? TextInputAction.next : TextInputAction.done;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
        color: widget.index.isEven ? Colors.white : Colors.grey[50],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                _currentProduct.name,
                style: const TextStyle(fontSize: 15),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 40,
              child: TextFormField(
                key: ValueKey('${_currentProduct.id}_quantity'),
                initialValue: _currentProduct.quantity == 0 ? '' : _currentProduct.quantity.toString(),
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                focusNode: widget.quantityFocusNode,
                textInputAction: quantityInputAction,
                onFieldSubmitted: (_) => _onFieldSubmitted('quantity'),
                onChanged: (value) {
                  final newQuantity = int.tryParse(value) ?? 0;
                  if (newQuantity != _currentProduct.quantity) {
                    setState(() {
                      _currentProduct = _currentProduct.copyWith(quantity: newQuantity);
                      widget.onChanged(_currentProduct);
                    });
                  }
                },
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: SizedBox(
              height: 40,
              child: TextFormField(
                key: ValueKey('${_currentProduct.id}_price'),
                initialValue: _currentProduct.unitPrice == 0.0 ? '' : _currentProduct.unitPrice.toStringAsFixed(2),
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                focusNode: widget.unitPriceFocusNode,
                textInputAction: unitPriceInputAction,
                onFieldSubmitted: (_) => _onFieldSubmitted('unitPrice'),
                onChanged: (value) {
                  final newPrice = double.tryParse(value) ?? 0.0;
                  if (newPrice != _currentProduct.unitPrice) {
                    setState(() {
                      _currentProduct = _currentProduct.copyWith(unitPrice: newPrice);
                      widget.onChanged(_currentProduct);
                    });
                  }
                },
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: SizedBox(
              height: 40,
              child: DropdownButtonFormField<UnitType>(
                key: ValueKey('${_currentProduct.id}_unit'),
                isDense: true,
                value: _currentProduct.unit,
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 8),
                  border: OutlineInputBorder(),
                ),
                items: widget.unitTypeDropdownItems,
                menuMaxHeight: MediaQuery.of(context).size.height * 0.4,
                onChanged: (UnitType? newValue) {
                  if (newValue != null && newValue != _currentProduct.unit) {
                    setState(() {
                      _currentProduct = _currentProduct.copyWith(unit: newValue);
                      widget.onChanged(_currentProduct);
                    });
                    FocusScope.of(context).unfocus();
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}