enum UnitType { saco, caja, bolsa, quintal, unidad, bulto, fardo, bandeja, jabaJumbo }

class Product {
  final String name;
  final UnitType unit;
  final int quantity;
  final double unitPrice;
  final String id;

  Product({
    required this.name,
    required this.unit,
    required this.quantity,
    required this.unitPrice,
    required this.id,
  });

  double get subtotal => quantity * unitPrice;
}