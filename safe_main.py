import os

filepath = 'lib/main.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Store MaterialApp reference instead of returning it
content = content.replace("    return MaterialApp(", "    Widget materialApp = MaterialApp(")

# 2. Add the custom SnackBarThemeData with floating behavior without margin
t1 = """        // Hacer que los SnackBars (toasts) floten por encima del banner inferior en Web
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
        ),
      ),"""
# Note: Since I reverted `main.dart`, the margin code might still be there, or maybe not. 
# Let's just blindly replace the entire section.
t2 = """        // Iconos más grandes en AppBar
        iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(
            minimumSize: const Size(48, 48),
            iconSize: 26,
          ),
        ),
      ),"""
r2 = """        // Iconos más grandes en AppBar
        iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(
            minimumSize: const Size(48, 48),
            iconSize: 26,
          ),
        ),
        // Hacer que los SnackBars (toasts) floten por encima del banner inferior en Web
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
        ),
      ),"""
content = content.replace(t2, r2)

# 3. Remove the Padding builder from MaterialApp
t3 = """      // --- CAMBIO AQUÍ ---
      // Aislar el anuncio inferior
      builder: (context, child) {
        return Padding(
          padding: EdgeInsets.only(bottom: kIsWeb ? 60.0 : 0.0),
          child: child!,
        );
      },
      // Ya no usamos 'home', usamos 'initialRoute' y 'routes'
      // home: const MyHomePage(title: 'Seleccionar Punto de Venta'),"""
r3 = """      // Ya no usamos 'home', usamos 'initialRoute' y 'routes'
      // home: const MyHomePage(title: 'Seleccionar Punto de Venta'),"""
content = content.replace(t3, r3)

# 4. Add the padding wrapper at the end
t4 = """      navigatorKey: navigatorKey,
    );
  }"""
r4 = """      navigatorKey: navigatorKey,
    );

    if (kIsWeb) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 70.0),
        child: materialApp,
      );
    }
    
    return materialApp;
  }"""
content = content.replace(t4, r4)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)

print("lib/main.dart refactored safely")

EOF
