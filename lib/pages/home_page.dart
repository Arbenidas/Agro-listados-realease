// lib/pages/home_page.dart
// MODIFICADO: Se añade un 'routeName' estático.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_listados/data/dispatch_points.dart';
import 'package:flutter_listados/pages/product_management_page.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_html/html.dart' as html;

class MyHomePage extends StatefulWidget {
  // --- LÍNEA AÑADIDA ---
  static const String routeName = '/'; // Nombre para la ruta principal
  // --- FIN ---

  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // ... (Todo el resto de tu código en _MyHomePageState no cambia) ...
  // ... (El error que viste en la línea 188 era un síntoma del problema) ...
  // ... (El código de _checkSessionStatus, build, _buildResumeCard, etc., es correcto) ...
  final _searchController = TextEditingController();
  List<MapEntry<String, String>> _allPuntos = [];
  List<MapEntry<String, String>> _displayPuntos = [];
  String _appVersion = 'Cargando...';

  // --- ESTADOS DE SESIÓN ---
  bool _isCheckingSession = true;
  bool _sessionExists = false;

  @override
  void initState() {
    super.initState();

    // 1. Revisa la sesión
    _checkSessionStatus();

    // 2. Prepara los datos de la página
    _allPuntos = puntosDespacho.entries.toList()
      ..sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase()));
    _displayPuntos = List.from(_allPuntos);
    _searchController.addListener(_filterPuntos);
    _loadAppVersion();
  }

  // --- FUNCIÓN MODIFICADA ---
  // Esta función AHORA solo revisa el estado, no navega.
  Future<void> _checkSessionStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final String? existingLists = prefs.getString('managedLists');

    // Comprueba si hay listas guardadas Y si no es una lista vacía "[]"
    final bool sessionFound = (existingLists != null && existingLists.length > 2);

    if (mounted) {
      setState(() {
        _sessionExists = sessionFound;
        _isCheckingSession = false; // Termina la carga
      });
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterPuntos);
    _searchController.dispose();
    super.dispose();
  }

  void _filterPuntos() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _displayPuntos = List.from(_allPuntos);
      } else {
        _displayPuntos = _allPuntos
            .where((entry) => entry.key.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  Future<void> _loadAppVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
    });
  }

  @override
  Widget build(BuildContext c) {
    // --- PANTALLA DE CARGA (Misma lógica de antes) ---
    if (_isCheckingSession) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Buscando sesión...'),
            ],
          ),
        ),
      );
    }

    // --- Pantalla Principal ---
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title),
          ],
        ),
        backgroundColor: Theme.of(c).colorScheme.primary,
        foregroundColor: Theme.of(c).colorScheme.onPrimary,
        actions: kIsWeb ? [_buildInfoMenu(c)] : null,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextFormField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Buscar punto de venta...',
                labelStyle: TextStyle(color: Colors.white70),
                hintText: 'Ej. Santa Ana',
                hintStyle: TextStyle(color: Colors.white70),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                filled: true,
                fillColor: Colors.black.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(
                    color: Theme.of(c).colorScheme.onPrimary,
                  ),
                ),
              ),
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(c).unfocus(),

        // --- CAMBIO: Añadimos un Column ---
        child: Column(
          children: [
            // --- NUEVO WIDGET: BOTÓN DE RESUMIR ---
            if (_sessionExists) _buildResumeCard(context),

            // --- CAMBIO: Envolvemos la cuadrícula en Expanded ---
            Expanded(
              child: CustomScrollView(
                slivers: [
                  // Espaciador
                  // Si NO hay sesión, dejamos un padding superior.
                  // Si HAY sesión, el Card de Resumen ya da el espacio.
                  if (!_sessionExists)
                    const SliverToBoxAdapter(child: SizedBox(height: 16)),

                  // Cuadrícula de Puntos
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 340.0,
                        mainAxisSpacing: 14.0,
                        crossAxisSpacing: 14.0,
                        childAspectRatio: 2.2,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final entry = _displayPuntos[index];
                          return _PuntoCard(
                            puntoName: entry.key,
                            onTap: () {
                              FocusScope.of(context).unfocus();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProductManagementPage(
                                    initialPuntoName: entry.key,
                                  ),
                                ),
                              ).then((_) {
                                // --- IMPORTANTE ---
                                // Cuando volvemos de la página de edición,
                                // volvemos a chequear la sesión.
                                // Si el usuario borró todo, el botón desaparecerá.
                                _checkSessionStatus();
                              });
                            },
                          );
                        },
                        childCount: _displayPuntos.length,
                      ),
                    ),
                  ),

                  // Versión al final
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Versión: $_appVersion',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- MENÚ DE INFORMACIÓN (solo web) ---
  // Enlaza a las páginas de contenido estáticas del sitio.
  Widget _buildInfoMenu(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.info_outline,
          color: Theme.of(context).colorScheme.onPrimary),
      tooltip: 'Información y ayuda',
      onSelected: (page) {
        if (kIsWeb) {
          html.window.open(page, '_self');
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: 'acerca.html',
          child: ListTile(
            leading: Icon(Icons.eco_outlined),
            title: Text('Acerca de'),
          ),
        ),
        PopupMenuItem(
          value: 'guia.html',
          child: ListTile(
            leading: Icon(Icons.menu_book_outlined),
            title: Text('Guía de uso'),
          ),
        ),
        PopupMenuItem(
          value: 'preguntas-frecuentes.html',
          child: ListTile(
            leading: Icon(Icons.help_outline),
            title: Text('Preguntas frecuentes'),
          ),
        ),
        PopupMenuItem(
          value: 'privacidad.html',
          child: ListTile(
            leading: Icon(Icons.privacy_tip_outlined),
            title: Text('Privacidad'),
          ),
        ),
      ],
    );
  }

  // --- NUEVO WIDGET HELPER PARA EL BOTÓN DE RESUMIR ---
  Widget _buildResumeCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      color: Theme.of(context).colorScheme.secondaryContainer,
      elevation: 4,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductManagementPage(
                // Pasamos null para que cargue la sesión guardada
                initialPuntoName: null,
              ),
            ),
          ).then((_) {
            // Actualiza el estado por si el usuario borró la sesión
            _checkSessionStatus();
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Icon(
                Icons.edit_note_rounded,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
                size: 32,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Continuar editando listas',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color:
                            Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 18,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- WIDGET PERSONALIZADO PARA LA TARJETA DEL PUNTO ---
// (Sin cambios)
class _PuntoCard extends StatelessWidget {
  final String puntoName;
  final VoidCallback onTap;

  const _PuntoCard({required this.puntoName, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor:
                    Theme.of(context).colorScheme.primary.withOpacity(0.12),
                child: Icon(
                  Icons.store_mall_directory_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  puntoName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        height: 1.25,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}