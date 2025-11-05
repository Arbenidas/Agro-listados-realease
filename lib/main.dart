// Archivo: lib/main.dart
// MODIFICADO: Añadido botón "Continuar editando" si existe una sesión.
// La app ya NO redirige automáticamente al inicio,
// sino que da la opción de continuar.

import 'package:flutter/material.dart';
import 'package:flutter_listados/data/dispatch_points.dart';
import 'package:flutter_listados/pages/product_management_page.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:universal_html/html.dart' as html;

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _checkVersionAndPromptUpdate();
  runApp(const MyApp());
}

Future<void> _checkVersionAndPromptUpdate() async {
  if (kIsWeb) {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final currentAppVersion = '${packageInfo.version}+${packageInfo.buildNumber}';

    final prefs = await SharedPreferences.getInstance();
    final storedVersion = prefs.getString('app_version');

    debugPrint('Versión actual de la app (pubspec): $currentAppVersion');
    debugPrint('Versión almacenada en el navegador: $storedVersion');

    if (storedVersion != null && storedVersion != currentAppVersion) {
      debugPrint(
          '¡Nueva versión detectada! (Antigua: $storedVersion, Nueva: $currentAppVersion)');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (navigatorKey.currentState != null &&
            navigatorKey.currentState!.context.mounted) {
          showDialog(
            context: navigatorKey.currentState!.context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('¡Actualización Disponible!'),
              content: const Text(
                  'Se ha detectado una nueva versión de la aplicación. Por favor, haz clic en "Recargar" para obtener las últimas mejoras.'),
              actions: [
                TextButton(
                  onPressed: () {
                    debugPrint('Recargando la página...');
                    html.window.location.reload();
                  },
                  child: const Text('Recargar Ahora'),
                ),
              ],
            ),
          );
        } else {
          debugPrint(
              'Advertencia: El contexto del navegador no está disponible para mostrar el diálogo de actualización.');
        }
      });
    }

    await prefs.setString('app_version', currentAppVersion);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Listas de productos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: const MyHomePage(title: 'Seleccionar Punto de Venta'),
      navigatorKey: navigatorKey,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
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
            if (_sessionExists)
              _buildResumeCard(context),

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
                        maxCrossAxisExtent: 300.0,
                        mainAxisSpacing: 12.0,
                        crossAxisSpacing: 12.0,
                        childAspectRatio: 2.5,
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                Icons.edit_note_rounded,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Continuar editando listas',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
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
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor:
                    Theme.of(context).colorScheme.primary.withOpacity(0.1),
                child: Icon(
                  Icons.store_mall_directory_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      puntoName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}