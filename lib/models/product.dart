// lib/models/product.dart
// ... (Aquí iría la definición de Product y UnitType)
enum UnitType {
  Unidad,
  Caja,
  CajaDoble,
  Canasto,
  Ciento,
  Docena,
  Bolsa,
  BolsaDoble,
  Bulto,
  Saco,
  Saco200,
  Saco400,
  Fardo,
  Jaba,
  JabaJumbo,
  Libra,
  Quintal,
  MedioQuintal,
  Manojo,
  Bandeja,
  Arroba,
  Marqueta,
  Red,
  BolsaMedia,
}

class Product {
  final String id;
  final String name;
  final int quantity;
  final double unitPrice;
  final UnitType unit;

  double get subtotal => quantity * unitPrice;

  const Product({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.unit,
  });

  Product copyWith({
    String? id,
    String? name,
    int? quantity,
    double? unitPrice,
    UnitType? unit,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      unit: unit ?? this.unit,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'unit': unit.index, // Guardar el índice del enum
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      quantity: json['quantity'] as int,
      unitPrice: json['unitPrice'] as double,
      unit: UnitType.values[json['unit'] as int], // Restaurar el enum por índice
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Product &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          quantity == other.quantity &&
          unitPrice == other.unitPrice &&
          unit == other.unit;

  @override
  int get hashCode =>
      id.hashCode ^ name.hashCode ^ quantity.hashCode ^ unitPrice.hashCode ^ unit.hashCode;
}