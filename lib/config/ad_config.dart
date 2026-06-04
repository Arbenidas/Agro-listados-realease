// lib/config/ad_config.dart
// Reemplaza los valores con los IDs reales de tu cuenta de Google AdSense.
// Publisher ID: lo encuentras en AdSense > Cuenta > Información de la cuenta
// Slot ID: lo encuentras al crear una unidad de anuncio en AdSense > Anuncios

class AdConfig {
  // Tu Publisher ID de AdSense (formato: ca-pub-XXXXXXXXXXXXXXXX)
  static const String publisherId = 'ca-pub-7702396954288314';

  // Slot para el diálogo que aparece antes de descargar
  // Tamaño recomendado: Rectángulo mediano (300x250)
  static const String interstitialSlot = '4531784987';

  // Slot para el banner fijo en la parte inferior de la página
  // Tamaño recomendado: Banner adaptable horizontal
  static const String bottomBannerSlot = '4531784987';

  // Segundos de espera antes de habilitar el botón de descarga
  static const int downloadCountdownSeconds = 5;
}
