import 'package:flutter/material.dart';
import 'package:flutter_listados/pages/product_management_page.dart';

void main() {
  runApp(const MyApp());
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

  final Map<String, String> puntos = {
    "AH - Ahuachapán, Ahuachapán Centro": "Punto042",
    "AH - Atiquizaya, Atiquizaya": "Punto031",
    "AH - San Francisco Menéndez, Col La Palma": "Punto001",
    "SA - Chalchuapa, Cancha de futbol Reparto Guadalupano": "Punto005",
    "Congo": "Punto049",
    "SA - Metapán, Mercado Ex Rastro": "Punto004",
    "SA - Santa Ana, Colonia El Palmar": "Punto002",
    "SA - Santa Ana, Skate Park Colonia El Ivu": "Punto003",
    "SO - Armenia, Parque de Armenia": "Punto006",
    "SO - Izalco, Parque Ecológico de Izalco": "Punto007",
    "SO - Juayua, Juayua": "Punto032",
    "SO - Sonsonate, Plaza Gastronomica El Angel": "Punto041",
    "CH - Chalatenango, Parqueo Municipal Barrio El Chile": "Punto047",
    "CH - Nueva Concepción, Predio en oficinas de CENTA Nueva Concepción": "Punto009",
    "LL - Ciudad Arce, Zona Verde Santa Rosa Las Lomas": "Punto011",
    "LL - Colón, Distrito 2 Nuevo Lourdes": "Punto048",
    "LL - Puerto de La Libertad, Parqueo Anexo Alcaldía Municipal": "Punto037",
    "LL - Quezaltepeque, Parque Norberto Moran": "Punto013",
    "LL - San Juan Opico, Terminal de Autobuses": "Punto012",
    "LL - Santa Tecla, Parque Daniel Hernandez": "Punto014",
    "LL - Santa Tecla, Santa Tecla 2": "Punto060",
    "LL - Zaragoza, Plaza Las Banderas": "Punto050",
    "SS - Aguilares, Parque Central Aguilares": "Punto043",
    "SS - Ayutuxtepeque, Plaza Municipal de Ayutuxtepeque": "Punto035",
    "SS - Ciudad Delgado, Plaza Monseñor Romero": "Punto016",
    "SS - Ilopango, Ticsa": "Punto017",
    "SS - Mejicanos, Mercado Zacamil": "Punto015",
    "SS - San Marcos, Paque Joya Esperanza  Y Paz": "Punto021",
    "SS - San Martin, San Martín": "Punto018",
    "SS - Santo Tomas, Santo Tomas": "Punto033",
    "SS - Soyapango, Redondel de Unicentro": "Punto019",
    "CU - Cojutepeque, Parque Las Alamedas": "Punto023",
    "CU - Suchitoto, Frente a Gasolinera Valle del Señor": "Punto044",
    "LP - Olocuilta, Parque Ecológico": "Punto045",
    "CA - Ilobasco, Parque Central Ilobasco": "Punto038",
    "CA - Sensuntepeque, Abajo de Gobernación": "Punto022",
    "SV - Apastepeque, Frente a Galeria Apacinte": "Punto052",
    "SV - San Vicente, Esquina Cancha Tacon": "Punto025",
    "US - Berlín, Ex Rastro Municipal": "Punto058",
    "US - El Triunfo, Estadio Municipal": "Punto054",
    "US - Jiquilisco, Zona Verde Frente a Penal": "Punto030",
    "US - Santiago de María, Santiago de María": "Punto034",
    "US - Usulután, Mercado Municipal No 5": "Punto040",
    "SM - Chinameca, Parque Central de Chinameca": "Punto028",
    "SM - Ciudad Barrios, Tiangue Municipal": "Punto053",
    "SM - El Tránsito, El Tránsito": "Punto061",
    "SM - San Miguel, Centro de Gobierno Municipal San Miguel": "Punto029",
    "SM - San Miguel, Estadio Barraza": "Punto057",
    "MO - Corinto, Barrio Las Delicias": "Punto055",
    "MO - Jocoro, Colonia Nueva Jocoro": "Punto056",
    "MO - Meanguera, Col. La Planta": "Punto027",
    "MO - San Francisco Gotera, Campo de la Feria": "Punto046",
    "LU - Anamorós, Zona Verde Municipal": "Punto059",
    "LU - La Unión, Sector El Amate": "Punto026",
    "LU - Santa Rosa de Lima, Terminal de Buses Santa Rosa de Lima": "Punto039",
    "SO - Acajutla, Frente a Parque Botanico": "Punto008",
    "CH - El Paraíso, Cancha Techada de Parque Municipal El Paraiso": "Punto010",
    "CU - San Rafael Cedros, Frente a la Alcaldía de San Rafael Cedros": "Punto051",
    "LP - Zacatecoluca, Plaza Civica": "Punto024",
    "APOPA":"Punto020"
  };

  @override
  void initState() {
    super.initState();
    _filteredPuntos = Map.fromEntries(
      puntos.entries.toList()
        ..sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase())),
    );
    _searchController.addListener(_filterPuntos);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
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
                          fontSize: 18, // Aumenta el tamaño de la fuente
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}