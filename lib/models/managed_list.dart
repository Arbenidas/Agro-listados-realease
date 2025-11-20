// lib/models/managed_list.dart
import 'package:flutter_listados/models/product.dart';
import 'package:uuid/uuid.dart';

var uuid = Uuid();

class ManagedList {
  final String id;
  String puntoName;
  String puntoId;
  List<Product> products;

  // --- CAMPOS AÑADIDOS PARA LA UI ---
  // Estos son temporales (transient) y no se guardan en JSON.
  // Se usan para que la UI pueda saber el orden.
  @JsonKey(ignore: true)
  List<Product> regularProducts = [];
  @JsonKey(ignore: true)
  List<Product> cdaProducts = [];
  // --- FIN DEL CAMBIO ---

  ManagedList({
    required this.puntoName,
    required this.puntoId,
    List<Product>? products,
    String? id,
  })  : id = id ?? uuid.v4(),
        products = products ?? [];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'puntoName': puntoName,
      'puntoId': puntoId,
      'products': products.map((p) => p.toJson()).toList(),
    };
  }

  factory ManagedList.fromJson(Map<String, dynamic> json) {
    return ManagedList(
      id: json['id'] as String?,
      puntoName: json['puntoName'] as String,
      puntoId: json['puntoId'] as String,
      products: (json['products'] as List<dynamic>)
          .map((pJson) => Product.fromJson(pJson as Map<String, dynamic>))
          .toList(),
    );
  }
}

// --- Simulación de la anotación @JsonKey(ignore: true) ---
// (Si no estás usando un generador de JSON, esto es solo conceptual)
class JsonKey {
  final bool ignore;
  const JsonKey({this.ignore = false});
}