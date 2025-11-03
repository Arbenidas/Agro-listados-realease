import 'package:flutter_listados/models/product.dart';
import 'package:uuid/uuid.dart'; // Necesitarás agregar `uuid` a tu pubspec.yaml si aún no lo has hecho

class ManagedList {
  final String id; // ID único para cada lista
  final String puntoName;
  final String puntoId;
  List<Product> products;

  ManagedList({
    required this.puntoName,
    required this.puntoId,
    List<Product>? products,
  }) : this.id = Uuid().v4(), // Genera un ID único
       this.products = products ?? [];

  // Métodos para persistencia (Paso 4)
  Map<String, dynamic> toJson() => {
        'id': id,
        'puntoName': puntoName,
        'puntoId': puntoId,
        'products': products.map((p) => p.toJson()).toList(),
      };

  factory ManagedList.fromJson(Map<String, dynamic> json) {
    return ManagedList(
      puntoName: json['puntoName'],
      puntoId: json['puntoId'],
      products: (json['products'] as List)
          .map((p) => Product.fromJson(p))
          .toList(),
    );
  }
}