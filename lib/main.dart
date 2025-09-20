import 'package:agro_listados/models/puntos_despacho.dart';
import 'package:agro_listados/pages/product_management_page.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart'; // ✅ Importado para obtener la versión de la app
import 'package:shared_preferences/shared_preferences.dart'; // ✅ Importado para guardar la versión
import 'package:flutter/foundation.dart'; // ✅ Importado para kIsWeb
import 'package:universal_html/html.dart' as html; // ✅ Importado para recargar en la web

// ✅ Define una GlobalKey para el Navigator, necesaria para mostrar un diálogo
//    antes de que la app se construya completamente o desde una función async.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _checkVersionAndPromptUpdate(); // ✅ Llama a la función de verificación de versión
  runApp(const MyApp());
}

// ✅ Nueva función para verificar la versión y solicitar actualización
Future<void> _checkVersionAndPromptUpdate() async {
  if (kIsWeb) { // ✅ Solo ejecuta esta lógica si estamos en la web
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    // Combina la versión y el número de build
    final currentAppVersion = '${packageInfo.version}+${packageInfo.buildNumber}';

    final prefs = await SharedPreferences.getInstance();
    final storedVersion = prefs.getString('app_version');

    debugPrint('Versión actual de la app (pubspec): $currentAppVersion');
    debugPrint('Versión almacenada en el navegador: $storedVersion');

    if (storedVersion != null && storedVersion != currentAppVersion) {
      debugPrint('¡Nueva versión detectada! (Antigua: $storedVersion, Nueva: $currentAppVersion)');
      // Retrasa la muestra del diálogo para asegurar que el Navigator esté listo
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Asegúrate de que el contexto del Navigator esté disponible
        if (navigatorKey.currentState != null && navigatorKey.currentState!.context.mounted) {
          showDialog(
            context: navigatorKey.currentState!.context, // ✅ Usa la GlobalKey
            barrierDismissible: false, // El usuario debe interactuar con el diálogo
            builder: (context) => AlertDialog(
              title: const Text('¡Actualización Disponible!'),
              content: const Text('Se ha detectado una nueva versión de la aplicación. Por favor, haz clic en "Recargar" para obtener las últimas mejoras.'),
              actions: [
                TextButton(
                  onPressed: () {
                    debugPrint('Recargando la página...');
                    html.window.location.reload(); // ✅ Recarga la página
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

    // Siempre guarda la versión actual para la próxima vez
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
      navigatorKey: navigatorKey, // ✅ Asigna la GlobalKey al MaterialApp
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
  String _appVersion = 'Cargando...'; // ✅ Variable para almacenar la versión

  @override
  void initState() {
    super.initState();
    _filteredPuntos = Map.fromEntries(
      puntos.entries.toList()
        ..sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase())),
    );
    _searchController.addListener(_filterPuntos);
    _loadAppVersion(); // ✅ Carga la versión al inicio
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
      final sortedEntries = puntos.entries.toList()
        ..sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase()));
      _filteredPuntos = Map.fromEntries(
        sortedEntries.where((entry) => entry.key.toLowerCase().contains(query)),
      );
    });
  }

  // ✅ Nueva función para cargar la versión de la aplicación
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
        // ✅ Usar un Column para mostrar el título y la versión
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title),
            Text(
              'Versión: $_appVersion', // ✅ Muestra la versión aquí
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
                            puntoId: entry.value,
                            puntoName: entry.key,
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Icon(
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
          // ✅ Mostrar la versión también en la parte inferior del cuerpo
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