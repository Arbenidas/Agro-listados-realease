// lib/widgets/ad_interstitial_dialog.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../config/ad_config.dart';

// Importaciones solo para web
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;
// ignore: avoid_web_libraries_in_flutter
import 'package:universal_html/html.dart' as html;

class AdInterstitialDialog extends StatefulWidget {
  final VoidCallback onDownload;
  final String title;
  final String actionLabel;
  final IconData actionIcon;

  const AdInterstitialDialog({
    super.key,
    required this.onDownload,
    this.title = 'Tu archivo está listo',
    this.actionLabel = 'Descargar ahora',
    this.actionIcon = Icons.download_rounded,
  });

  // Registrado una sola vez para todo el ciclo de vida de la app
  static bool _viewRegistered = false;
  static const String _viewType = 'adsense-interstitial-ad';

  static void _ensureViewRegistered() {
    if (_viewRegistered || !kIsWeb) return;
    _viewRegistered = true;
    try {
      // ignore: undefined_prefixed_name
      ui_web.platformViewRegistry.registerViewFactory(_viewType, (int id) {
        final container = html.DivElement()
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.display = 'flex'
          ..style.alignItems = 'center'
          ..style.justifyContent = 'center'
          ..style.backgroundColor = '#f5f5f5';

        final ins = html.Element.tag('ins')
          ..className = 'adsbygoogle'
          ..style.display = 'block'
          ..style.width = '100%'
          ..style.height = '100%'
          ..setAttribute('data-ad-client', AdConfig.publisherId)
          ..setAttribute('data-ad-slot', AdConfig.interstitialSlot)
          ..setAttribute('data-ad-format', 'auto')
          ..setAttribute('data-full-width-responsive', 'true');

        container.append(ins);

        // Lanza el anuncio después de que el elemento esté en el DOM
        Future.delayed(const Duration(milliseconds: 300), () {
          html.window.dispatchEvent(html.CustomEvent('pushAdsbyGoogle'));
        });

        return container;
      });
    } catch (_) {
      // Ya registrado, ignorar
    }
  }

  /// Muestra el diálogo y ejecuta [onAction] cuando el usuario confirma.
  static Future<void> show(
    BuildContext context,
    VoidCallback onAction, {
    String title = 'Tu archivo está listo',
    String actionLabel = 'Descargar ahora',
    IconData actionIcon = Icons.download_rounded,
  }) {
    _ensureViewRegistered();
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AdInterstitialDialog(
        onDownload: onAction,
        title: title,
        actionLabel: actionLabel,
        actionIcon: actionIcon,
      ),
    );
  }

  @override
  State<AdInterstitialDialog> createState() => _AdInterstitialDialogState();
}

class _AdInterstitialDialogState extends State<AdInterstitialDialog> {
  late int _secondsLeft;
  Timer? _timer;
  bool _canDownload = false;

  @override
  void initState() {
    super.initState();
    _secondsLeft = AdConfig.downloadCountdownSeconds;
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _secondsLeft--;
        if (_secondsLeft <= 0) {
          _canDownload = true;
          t.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      title: Row(
        children: [
          Icon(widget.actionIcon,
              color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(widget.title)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildAdArea(),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _canDownload
                ? Row(
                    key: const ValueKey('ready'),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle,
                          color: Colors.green[700], size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'Listo para descargar',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                : Text(
                    key: const ValueKey('waiting'),
                    'La descarga estará lista en $_secondsLeft segundo${_secondsLeft == 1 ? '' : 's'}...',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                    textAlign: TextAlign.center,
                  ),
          ),
          const SizedBox(height: 8),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _canDownload
              ? () {
                  Navigator.of(context).pop();
                  widget.onDownload();
                }
              : null,
          icon: Icon(widget.actionIcon, size: 18),
          label: Text(
            _canDownload
                ? widget.actionLabel
                : 'Espera... ($_secondsLeft)',
          ),
        ),
      ],
    );
  }

  Widget _buildAdArea() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.hardEdge,
      child: kIsWeb &&
              AdConfig.publisherId != 'ca-pub-XXXXXXXXXXXXXXXX'
          ? const HtmlElementView(
              viewType: AdInterstitialDialog._viewType,
            )
          : _buildPlaceholder(),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.campaign_outlined, size: 36, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text(
            'Publicidad',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 13,
            ),
          ),
          Text(
            '(Configura tu ID de AdSense en\nlib/config/ad_config.dart)',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
