// lib/data/product_mapping.dart
// ACTUALIZADO: Añadidas todas las excepciones de los CSVs
// (LICHA, MARACUYA, PERA, MANDARINA, SANDIA, JICAMA, RABANO, etc.)

const Map<String, String> productNormalizationMap = {
  // --- Mapeos de Central de Abastos (basado en tus CSVs) ---
  "GUISQUIL NACIONAL (CENTRAL DE ABASTOS)": "Guisquil grande",
  "PAPA RUSSET (CENTRAL DE ABASTOS)": "Papa Russet",
  "RABANO (CENTRAL DE ABASTOS)": "Rabano",
  "CEBOLLA BLANCA (CENTRAL DE ABASTOS)": "Cebolla Blanca",
  "PAPAYA (CENTRAL DE ABASTOS)": "Papaya",
  "NARANJA VALENCIA (CENTRAL DE ABASTOS)": "Naranja",
  "YUCA (CENTRAL DE ABASTOS)": "Yuca",
  "HUEVO EXTRA GRANDE (CENTRAL DE ABASTOS)": "Huevos Extra Grandes",
  "LIMON (CENTRAL DE ABASTOS)": "Limon",

  // --- Mapeos de productos con ID 0 o vacío (Casos simples) ---
  
  // Plurales, tildes o variaciones
  "LICHA": "Lichas",
  "MARACUYA": "Maracuyá",
  
  // Nombres directos que fallan por algún motivo
  "RABANO": "Rabano",
  "PERA": "Pera",
  "MANDARINA": "Mandarina",
  "JICAMA": "Jicama",

  // Casos con espacios al final (aunque .trim() debería quitarlos,
  // es más seguro tenerlos aquí)
  "SANDIA": "Sandia",
  "SANDIA ": "Sandia", 

  // Productos con nombres diferentes
  "NARANJA VALENCIA IMPORTADA": "Naranja", // Asignamos la importada a "Naranja"
  
  // --- Añade cualquier otro producto aquí ---
  // "NOMBRE_EN_CSV": "NombreEnProductsData",
};