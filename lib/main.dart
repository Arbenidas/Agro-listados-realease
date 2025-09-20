// Archivo: lib/main.dart
// Corregido: Vuelve a pasar 'puntoName' a ProductManagementPage.

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
      debugPrint('¡Nueva versión detectada! (Antigua: $storedVersion, Nueva: $currentAppVersion)');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (navigatorKey.currentState != null && navigatorKey.currentState!.context.mounted) {
          showDialog(
            context: navigatorKey.currentState!.context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('¡Actualización Disponible!'),
              content: const Text('Se ha detectado una nueva versión de la aplicación. Por favor, haz clic en "Recargar" para obtener las últimas mejoras.'),
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
          debugPrint('Advertencia: El contexto del navegador no está disponible para mostrar el diálogo de actualización.');
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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
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
  Map<String, String> _filteredPuntos = {};
  String _appVersion = 'Cargando...';

  @override
  void initState() {
    super.initState();
    _filteredPuntos = Map.fromEntries(
      puntosDespacho.entries.toList()
        ..sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase())),
    );
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
      final sortedEntries = puntosDespacho.entries.toList()
        ..sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase()));
      _filteredPuntos = Map.fromEntries(
        sortedEntries.where((entry) => entry.key.toLowerCase().contains(query)),
      );
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
            Text(
              'Versión: $_appVersion',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextFormField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Buscar punto de venta',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredPuntos.length,
              itemBuilder: (context, index) {
                final entry = _filteredPuntos.entries.elementAt(index);
                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: InkWell(
                    onTap: () {
                      FocusScope.of(context).unfocus();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductManagementPage(
                            // ✅ Volvemos a pasar solo el nombre del punto
                            initialPuntoName: entry.key,
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: const Icon(
                        Icons.storefront_outlined,
                        color: Colors.deepPurple,
                        size: 32,
                      ),
                      title: Text(
                        entry.key,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0, top: 8.0),
            child: Text(
              'Versión de la aplicación: $_appVersion',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }
}