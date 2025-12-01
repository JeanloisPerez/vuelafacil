import 'package:flutter/material.dart';
import 'FlightListScreen.dart';
import 'saved_flights_screen.dart';
import 'profile_screen.dart';
import '../services/serpapi_flights_service.dart';
import '../widgets/custom_navbar.dart';
import '../models/airport_search_viewmodel.dart';
import '../models/airport_model.dart';
import '../services/airports_api_service.dart';

class HomeScreen extends StatefulWidget {
  static const String routeName = '/home';

  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 0;

  String origen = "Seleccionar";
  String destino = "Seleccionar";

  String? origenCodigo;
  String? destinoCodigo;

  bool soloIda = true;

  DateTime fechaIda = DateTime.now();
  DateTime? fechaVuelta;

  int pasajeros = 1;

  // Mapeo CIUDAD → CÓDIGO IATA
  final Map<String, String> ciudadesConCodigo = {
    "Orlando": "MCO",
    "Santo Domingo": "SDQ",
    "New York": "JFK",
    "Madrid": "MAD",
    "Bogotá": "BOG",
    "Buenos Aires": "EZE",
    "London": "LHR",
    "Roma": "FCO",
    "Tokio": "NRT",
  };

  List<String> get ciudades => ciudadesConCodigo.keys.toList();

  Future<void> _seleccionarFechaIda() async {
    DateTime hoy = DateTime.now();
    DateTime fechaMinima = DateTime(hoy.year, hoy.month, hoy.day);

    DateTime? nuevaFecha = await showDatePicker(
      context: context,
      initialDate: fechaIda.isBefore(fechaMinima) ? fechaMinima : fechaIda,
      firstDate: fechaMinima,
      lastDate: DateTime(2030),
    );

    if (nuevaFecha != null) {
      setState(() => fechaIda = nuevaFecha);

      if (!soloIda &&
          fechaVuelta != null &&
          fechaVuelta!.isBefore(nuevaFecha)) {
        fechaVuelta = null;
      }
    }
  }

  Future<void> _seleccionarFechaVuelta() async {
    if (soloIda) return;

    DateTime fechaMinima = fechaIda;

    DateTime? nuevaFecha = await showDatePicker(
      context: context,
      initialDate: fechaVuelta ?? fechaMinima.add(const Duration(days: 1)),
      firstDate: fechaMinima,
      lastDate: DateTime(2030),
    );

    if (nuevaFecha != null) {
      setState(() => fechaVuelta = nuevaFecha);
    }
  }

  void _seleccionarPasajeros() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Selecciona pasajeros",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: pasajeros > 1
                            ? () {
                                setSheetState(() => pasajeros--);
                                setState(() {});
                              }
                            : null,
                        icon: const Icon(Icons.remove_circle),
                      ),
                      Text(
                        "$pasajeros",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setSheetState(() => pasajeros++);
                          setState(() {});
                        },
                        icon: const Icon(Icons.add_circle),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _buscarAeropuerto(bool esOrigen) {
    final viewModel = AirportSearchViewModel(AirportsApiService());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final TextEditingController controller = TextEditingController();

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: "Buscar aeropuerto o ciudad",
                  prefixIcon: Icon(Icons.flight),
                  border: OutlineInputBorder(),
                ),
                onChanged: (text) {
                  viewModel.buscar(text);
                },
              ),

              const SizedBox(height: 10),

              SizedBox(
                height: 300,
                child: ValueListenableBuilder<List<AirportModel>>(
                  valueListenable: viewModel.resultados,
                  builder: (context, lista, _) {
                    if (lista.isEmpty) {
                      return const Center(
                        child: Text(
                          "Escribe para buscar aeropuertos...",
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: lista.length,
                      itemBuilder: (_, i) {
                        final a = lista[i];

                        return ListTile(
                          title: Text("${a.city} (${a.code})"),
                          subtitle: Text("${a.name} - ${a.country}"),
                          onTap: () {
                            setState(() {
                              if (esOrigen) {
                                origen = a.city;
                                origenCodigo = a.code;
                              } else {
                                destino = a.city;
                                destinoCodigo = a.code;
                              }
                            });
                            Navigator.pop(context);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _seleccionarPais(bool esOrigen) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          child: ListView(
            children: ciudades
                .map(
                  (ciudad) => ListTile(
                    title: Text(ciudad),
                    trailing: Text(
                      ciudadesConCodigo[ciudad]!,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        if (esOrigen) {
                          origen = ciudad;
                          origenCodigo = ciudadesConCodigo[ciudad];
                        } else {
                          destino = ciudad;
                          destinoCodigo = ciudadesConCodigo[ciudad];
                        }
                      });
                      Navigator.pop(context);
                    },
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }

  String formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),

      bottomNavigationBar: CustomNavBar(
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() => currentIndex = index);

          if (index == 1) {
            Navigator.pushNamed(context, SavedFlightsScreen.routeName);
          } else if (index == 2) {
            Navigator.pushNamed(context, ProfileScreen.routeName);
          }
        },
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: SizedBox(
                  height: 250,
                  width: double.infinity,
                  child: Image.asset(
                    "lib/core/assets/plane.png",
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ORIGEN / DESTINO
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () => _seleccionarPais(true),
                      child: Row(
                        children: [
                          const Icon(Icons.flight_takeoff, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  origen,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (origenCodigo != null)
                                  Text(
                                    origenCodigo!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const Icon(Icons.expand_more),
                        ],
                      ),
                    ),

                    const Divider(height: 18),

                    GestureDetector(
                      onTap: () => _seleccionarPais(false),
                      child: Row(
                        children: [
                          const Icon(Icons.flight_land, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  destino,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (destinoCodigo != null)
                                  Text(
                                    destinoCodigo!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const Icon(Icons.expand_more),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // FECHAS
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                soloIda = true;
                                fechaVuelta = null;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: soloIda
                                    ? const Color(0xFF5A3FFF)
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  'Solo Ida',
                                  style: TextStyle(
                                    color: soloIda
                                        ? Colors.white
                                        : Colors.grey[700],
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                soloIda = false;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: !soloIda
                                    ? const Color(0xFF5A3FFF)
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  'Ida y Vuelta',
                                  style: TextStyle(
                                    color: !soloIda
                                        ? Colors.white
                                        : Colors.grey[700],
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: _seleccionarFechaIda,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Ida",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  formatDate(fechaIda),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        if (!soloIda) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: _seleccionarFechaVuelta,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Vuelta",
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    fechaVuelta == null
                                        ? "Seleccionar"
                                        : formatDate(fechaVuelta!),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // PASAJEROS
              GestureDetector(
                onTap: _seleccionarPasajeros,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.people_alt, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "$pasajeros pasajero(s)",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Icon(Icons.expand_more),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // BOTÓN FINAL
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5A3FFF),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    if (!soloIda && fechaVuelta == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Debes seleccionar fecha de regreso."),
                        ),
                      );
                      return;
                    }

                    if (origenCodigo == null || destinoCodigo == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Debes seleccionar origen y destino."),
                        ),
                      );
                      return;
                    }

                    Navigator.pushNamed(
                      context,
                      FlightListScreen.routeName,
                      arguments: {
                        'origen': origen,
                        'destino': destino,
                        'origenCodigo': origenCodigo,
                        'destinoCodigo': destinoCodigo,
                        'fechaIda': fechaIda,
                        'fechaVuelta': fechaVuelta,
                        'soloIda': soloIda,
                        'pasajeros': pasajeros,
                      },
                    );
                  },
                  child: const Text(
                    "Buscar vuelos",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
