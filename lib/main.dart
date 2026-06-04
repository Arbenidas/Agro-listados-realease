// lib/main.dart
// MODIFICADO: Ahora usa rutas nombradas para romper la dependencia circular.

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:universal_html/html.dart' as html;

// Importamos la página de inicio
import 'package:flutter_listados/pages/home_page.dart'; 

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _checkVersionAndPromptUpdate();
  runApp(const MyApp());
}

Future<void> _checkVersionAndPromptUpdate() async {
  // ... (Esta función no cambia) ...
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
    Widget materialApp = MaterialApp(
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
      
      // --- CAMBIO AQUÍ ---
      // Ya no usamos 'home', usamos 'initialRoute' y 'routes'
      // home: const MyHomePage(title: 'Seleccionar Punto de Venta'),
      initialRoute: MyHomePage.routeName, // Ruta inicial
      routes: {
        // Define la ruta principal
        MyHomePage.routeName: (context) =>
            const MyHomePage(title: 'Seleccionar Punto de Venta'),
        // Aquí podrías definir más rutas si las necesitaras
      },
      // --- FIN DEL CAMBIO ---
      
      navigatorKey: navigatorKey,
    );

    if (kIsWeb) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 45.0),
        child: materialApp,
      );
    }
    
    return materialApp;
  }
}