// Archivo: lib/main.dart
// RE DISEÑO UI: Convertida la lista en una cuadrícula (Grid) visual.
// OPTIMIZADO:
// 1. La lista de puntos se ordena 1 SOLA VEZ en initState para mejorar el rendimiento del filtro.
// 2. Añadido GestureDetector para ocultar el teclado en móviles y corregir el overflow.

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
  
  // --- OPTIMIZACIÓN DE RENDIMIENTO ---
  // Lista 1: Contiene TODOS los puntos, ordenados 1 sola vez.
  List<MapEntry<String, String>> _allPuntos = [];
  // Lista 2: Contiene los puntos a MOSTRAR (filtrados).
  List<MapEntry<String, String>> _displayPuntos = [];
  // --- FIN DE OPTIMIZACIÓN ---

  String _appVersion = 'Cargando...';

  @override
  void initState() {
    super.initState();
    
    // --- OPTIMIZACIÓN DE RENDIMIENTO ---
    // Ordenamos la lista 1 sola vez al inicio.
    _allPuntos = puntosDespacho.entries.toList()
      ..sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase()));
    // Al inicio, la lista a mostrar es igual a la lista completa.
    _displayPuntos = List.from(_allPuntos);
    // --- FIN DE OPTIMIZACIÓN ---
    
    _searchController.addListener(_filterPuntos);
    _loadAppVersion();
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
      // --- OPTIMIZACIÓN DE RENDIMIENTO ---
      // El filtro ahora es mucho más rápido.
      if (query.isEmpty) {
        // Si no hay búsqueda, muestra todos los puntos (ya ordenados).
        _displayPuntos = List.from(_allPuntos);
      } else {
        // Si hay búsqueda, filtra la lista ya ordenada.
        // No necesita volver a ordenar (sort).
        _displayPuntos = _allPuntos
            .where((entry) => entry.key.toLowerCase().contains(query))
            .toList();
      }
      // --- FIN DE OPTIMIZACIÓN ---
    });
  }

  Future<void> _loadAppVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
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
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
      // --- CORRECCIÓN DE OVERFLOW (MÓVIL) ---
      // Envolvemos el body en un GestureDetector para ocultar el teclado
      // al tocar fuera del campo de búsqueda.
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: CustomScrollView(
          slivers: [
            // Espaciador
            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Cuadrícula de Puntos
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 300.0, // Ancho máximo de cada tarjeta
                  mainAxisSpacing: 12.0,
                  crossAxisSpacing: 12.0,
                  childAspectRatio: 2.5, // Más anchas que altas
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    // Usamos la lista _displayPuntos (optimizada)
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
                        );
                      },
                    );
                  },
                  childCount: _displayPuntos.length, // Usamos la lista optimizada
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
      // --- FIN DE CORRECCIÓN DE OVERFLOW ---
    );
  }
}

// --- WIDGET PERSONALIZADO PARA LA TARJETA DEL PUNTO ---

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
              // Icono
              CircleAvatar(
                backgroundColor:
                    Theme.of(context).colorScheme.primary.withOpacity(0.1),
                child: Icon(
                  Icons.store_mall_directory_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              // Texto
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
              // Icono de flecha
              Icon(Icons.arrow_forward_ios,
                  size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}