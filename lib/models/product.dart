enum UnitType { Saco, Caja, Bolsa, Quintal, Unidad, Bulto, Fardo, Bandeja, JabaJumbo, Manojo, Docena, Canasto, Libra, CajaDoble, Ciento, BolsaDoble, Saco200, MedioQuintal, Saco400, Jaba, Arroba, Marqueta, Red, BolsaMedia }

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