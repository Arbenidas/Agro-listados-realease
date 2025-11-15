// lib/data/product_mapping.dart
// ACTUALIZADO: Añadidas todas las excepciones de los CSVs

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

  // --- Mapeos de productos con ID 0 o vacío (LICHA, PERA, etc.) ---
  
  "LICHA": "Lichas", // El CSV dice Licha, la BD dice Lichas
  "MARACUYA": "Maracuyá", // El CSV no tiene tilde
  "PERA": "Pera",
  "MANDARINA": "Mandarina",
  "SANDIA": "Sandia", // El CSV a veces tiene "SANDIA " (con espacio)
  "SANDIA ": "Sandia", // ..así que añadimos ambas por seguridad.
  "JICAMA": "Jicama",
  "RABANO": "Rabano",
  "NARANJA VALENCIA IMPORTADA": "Naranja", // Asignamos la importada a "Naranja"

  // --- Añade cualquier otro producto aquí ---
  // "NOMBRE_EN_CSV": "NombreEnProductsData",
};