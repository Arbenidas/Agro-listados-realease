// lib/widgets/ad_interstitial_dialog.dart
//
// NOTA DE POLÍTICAS (AdSense/AdMob):
// Antes este componente mostraba un anuncio dentro de un diálogo con cuenta
// atrás para "desbloquear" una descarga. Google prohíbe expresamente usar
// anuncios con fines de comportamiento (bloquear/condicionar una acción o
// navegación). Por eso ahora la acción se ejecuta directamente, sin anuncio.
//
// Se conserva la API estática `show(...)` para no tener que modificar las
// llamadas existentes en el resto de la app.
import 'package:flutter/material.dart';

class AdInterstitialDialog {
  /// Ejecuta [onAction] directamente. Los parámetros de título/etiqueta/icono
  /// se mantienen por compatibilidad, pero ya no se muestra ningún anuncio.
  static Future<void> show(
    BuildContext context,
    VoidCallback onAction, {
    String title = 'Tu archivo está listo',
    String actionLabel = 'Descargar ahora',
    IconData actionIcon = Icons.download_rounded,
  }) async {
    onAction();
  }
}
