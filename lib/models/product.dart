// Archivo: lib/models/product.dart
// Actualizado con el método copyWith

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
  final double unitPrice;
  final UnitType unit;
  final int quantity;

  Product({
    required this.id,
    required this.name,
    required this.unitPrice,
    required this.unit,
    required this.quantity,
  });

  double get subtotal => unitPrice * quantity;

  // ✅ Método copyWith añadido
  Product copyWith({
    String? id,
    String? name,
    double? unitPrice,
    UnitType? unit,
    int? quantity,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      unitPrice: unitPrice ?? this.unitPrice,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
    );
  }

  // Convierte un objeto Product en un Map para serializarlo
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'unitPrice': unitPrice,
      'unit': unit.index, // Guarda el enum como un índice entero
      'quantity': quantity,
    };
  }

  // Crea un objeto Product a partir de un Map (desde un JSON)
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      unitPrice: json['unitPrice'] is int
          ? (json['unitPrice'] as int).toDouble()
          : json['unitPrice'] as double,
      unit: UnitType.values[json['unit'] as int],
      quantity: json['quantity'] is int
          ? (json['quantity'] as int).toInt()
          : json['quantity'] as int,
    );
  }
}