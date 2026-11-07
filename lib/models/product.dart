// lib/models/product.dart
// ... (Aquí iría la definición de Product y UnitType)
// ignore_for_file: constant_identifier_names

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
  final bool isCda;

  double get subtotal => quantity * unitPrice;

  bool get isCdaProduct =>
      isCda || name.toUpperCase().contains("CENTRAL DE ABASTOS");

  const Product({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.unit,
    this.isCda = false,
  });

  Product copyWith({
    String? id,
    String? name,
    int? quantity,
    double? unitPrice,
    UnitType? unit,
    bool? isCda,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      unit: unit ?? this.unit,
      isCda: isCda ?? this.isCda,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'unit': unit.index, // Guardar el índice del enum
      'isCda': isCda,
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    final String name = json['name'] as String;
    final bool isCdaFromJson = (json['isCda'] as bool?) ??
        name.toUpperCase().contains("CENTRAL DE ABASTOS");
    return Product(
      id: json['id'] as String,
      name: name,
      quantity: json['quantity'] as int,
      unitPrice: (json['unitPrice'] as num).toDouble(),
      unit: UnitType.values[json['unit'] as int], // Restaurar el enum por índice
      isCda: isCdaFromJson,
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
          unit == other.unit &&
          isCda == other.isCda;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      quantity.hashCode ^
      unitPrice.hashCode ^
      unit.hashCode ^
      isCda.hashCode;
}