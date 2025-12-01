// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/custom_navbar.dart';
import '../services/flight_storage.dart';
import '../models/flight_model.dart';
import 'saved_flights_screen.dart';
import '../services/serpapi_flights_service.dart';

class FlightListScreen extends StatefulWidget {
  static const String routeName = "/flights";

  const FlightListScreen({super.key});

  @override
  State<FlightListScreen> createState() => _FlightListScreenState();
}

class _FlightListScreenState extends State<FlightListScreen> {
  int _currentIndex = 0;

  final _api = SerpApiFlightsService(
    apiKey: "887106ec220e4f9430f80e6df70191198c1b5dd65474da6f1c5a0638dba85d8d",
  );

  late String origen;
  late String destino;
  late String origenCodigo;
  late String destinoCodigo;

  late DateTime fechaIda;
  DateTime? fechaVuelta;
  late bool soloIda;

  bool _hasArgs = false;
  bool _initializedArgs = false;

  String _filtroSeleccionado = "precio";

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_initializedArgs) return;
    _initializedArgs = true;

    final routeArgs = ModalRoute.of(context)?.settings.arguments;
    if (routeArgs is Map<String, dynamic>) {
      _hasArgs = true;
      origen = (routeArgs["origen"] ?? '').toString();
      destino = (routeArgs["destino"] ?? '').toString();
      origenCodigo = (routeArgs["origenCodigo"] ?? '').toString();
      destinoCodigo = (routeArgs["destinoCodigo"] ?? '').toString();

      fechaIda = routeArgs["fechaIda"] is DateTime
          ? routeArgs["fechaIda"] as DateTime
          : DateTime.now();
      fechaVuelta = routeArgs["fechaVuelta"] is DateTime
          ? routeArgs["fechaVuelta"] as DateTime
          : null;
      soloIda = routeArgs["soloIda"] == true;
    } else {
      _hasArgs = false;
    }
  }

  String formatDate(DateTime date) {
    return "${date.year.toString().padLeft(4, '0')}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${date.day.toString().padLeft(2, '0')}";
  }

  Future<List<Map<String, dynamic>>> _fetchFlights() async {
    final fechaSalida = formatDate(fechaIda);

    final flights = await _api.searchFlights(
      departureId: origenCodigo,
      arrivalId: destinoCodigo,
      outboundDate: fechaSalida,
      currency: "USD",
    );

    flights.sort((a, b) => a["precio"].compareTo(b["precio"]));

    return flights;
  }

  void _mostrarFiltros() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 260,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Filtrar por:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                title: const Text("Precio (menor a mayor)"),
                leading: Radio(
                  value: "precio",
                  groupValue: _filtroSeleccionado,
                  onChanged: (value) {
                    setState(() => _filtroSeleccionado = "precio");
                    Navigator.pop(context);
                  },
                ),
              ),

              ListTile(
                title: const Text("Duración (más corta primero)"),
                leading: Radio(
                  value: "duracion",
                  groupValue: _filtroSeleccionado,
                  onChanged: (value) {
                    setState(() => _filtroSeleccionado = "duracion");
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Map<String, dynamic>> aplicarFiltro(List<Map<String, dynamic>> flights) {
    List<Map<String, dynamic>> sorted = List.from(flights);

    switch (_filtroSeleccionado) {
      case "precio":
        sorted.sort((a, b) => a["precio"].compareTo(b["precio"]));
        break;
      case "aerolinea":
        sorted.sort(
          (a, b) => (a["aerolinea"] ?? "").compareTo((b["aerolinea"] ?? "")),
        );
        break;
      case "duracion":
        sorted.sort(
          (a, b) =>
              a["duracion"].toString().compareTo(b["duracion"].toString()),
        );
        break;
    }

    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasArgs) {
      // Mostrar pantalla segura indicando que el usuario debe buscar primero
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            "Vuelos Disponibles",
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.search, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  "Primero realiza una búsqueda de vuelos",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((r) => r.isFirst);
                  },
                  child: const Text("Ir al buscador"),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: CustomNavBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            if (index == 1) {
              Navigator.pushNamed(context, SavedFlightsScreen.routeName);
            } else if (index == 0) {
              Navigator.of(context).popUntil((r) => r.isFirst);
            } else if (index == 2) {
              Navigator.of(context).pushReplacementNamed('/profile');
            }
          },
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Vuelos Disponibles",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt, color: Colors.black87),
            onPressed: _mostrarFiltros,
          ),
        ],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchFlights(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final flights = aplicarFiltro(snapshot.data ?? []);

          if (flights.isEmpty) {
            return const Center(child: Text("No se encontraron vuelos."));
          }

          return Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10, left: 15, right: 15),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.local_fire_department,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _filtroSeleccionado == "precio"
                            ? "Filtrado por: Precio (menor a mayor)"
                            : "Filtrado por: $_filtroSeleccionado",
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: flights.length,
                  itemBuilder: (context, index) =>
                      _buildFlightCard(flights[index], index == 0),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: CustomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 1) {
            Navigator.pushNamed(context, SavedFlightsScreen.routeName);
          }
        },
      ),
    );
  }

  Widget _buildFlightCard(dynamic flight, bool esMasBarato) {
    String safeString(dynamic v) => v == null ? '' : v.toString();
    double safePrice(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      margin: const EdgeInsets.only(bottom: 25),
      padding: const EdgeInsets.all(0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // subtle top gradient stripe using base purple to transparent
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: 6,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF5A3FFF).withOpacity(0.95),
                      const Color(0xFF5A3FFF).withOpacity(0.25),
                      Colors.transparent,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: airline + flight code + price badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Logo circle with subtle border and shadow
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12.withOpacity(0.06),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.12),
                          ),
                        ),
                        child: ClipOval(
                          child: flight["logo_url"] != null
                              ? Image.network(
                                  safeString(flight["logo_url"]),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.flight,
                                    color: Color(0xFF5A3FFF),
                                  ),
                                )
                              : const Icon(
                                  Icons.flight,
                                  color: Color(0xFF5A3FFF),
                                ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Airline and flight code
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              safeString(flight["aerolinea"]).isEmpty
                                  ? "—"
                                  : safeString(flight["aerolinea"]),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              safeString(flight["vuelo"]),
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Price box (purple) — prominent
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF5A3FFF), Color(0xFF7C63FF)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF5A3FFF).withOpacity(0.18),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Text(
                          "\$${safePrice(flight["precio"]).toStringAsFixed(2)}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Route and times section
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${safeString(flight["origen"])} → ${safeString(flight["destino"])}",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.schedule,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  // safe substring guard
                                  (safeString(flight["salida"]).length >= 16)
                                      ? "Salida: ${safeString(flight["salida"]).substring(11, 16)}"
                                      : "Salida: ${safeString(flight["salida"])}",
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  "•",
                                  style: TextStyle(color: Colors.grey),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  (safeString(flight["llegada"]).length >= 16)
                                      ? "Llegada: ${safeString(flight["llegada"]).substring(11, 16)}"
                                      : "Llegada: ${safeString(flight["llegada"])}",
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Chips row: duration / tipo / escala
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.airplanemode_active,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              safeString(flight["duracion"]),
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          safeString(flight["tipo"]).isEmpty
                              ? "—"
                              : safeString(flight["tipo"]),
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),

                      if ((flight["escala_en"] ?? "").toString().isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.swap_calls,
                                size: 14,
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                safeString(flight["escala_en"]),
                                style: const TextStyle(color: Colors.orange),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Divider
                  Container(height: 1, color: Colors.grey.withOpacity(0.08)),

                  const SizedBox(height: 12),

                  // Actions row: save + reservar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.bookmark_add,
                              color: Color(0xFF5A3FFF),
                            ),
                            onPressed: () async {
                              final model = FlightModel(
                                id: flight["id"],
                                origen: safeString(flight["origen"]),
                                destino: safeString(flight["destino"]),
                                aerolinea:
                                    safeString(flight["aerolinea"]).isEmpty
                                    ? null
                                    : safeString(flight["aerolinea"]),
                                vuelo: safeString(flight["vuelo"]).isEmpty
                                    ? null
                                    : safeString(flight["vuelo"]),
                                salida: safeString(flight["salida"]),
                                llegada: safeString(flight["llegada"]),
                                duracion: safeString(flight["duracion"]).isEmpty
                                    ? null
                                    : safeString(flight["duracion"]),
                                precio: safePrice(flight["precio"]),
                                moneda: safeString(flight["moneda"]).isEmpty
                                    ? null
                                    : safeString(flight["moneda"]),
                                tipo: safeString(flight["tipo"]).isEmpty
                                    ? null
                                    : safeString(flight["tipo"]),
                                disponibilidad:
                                    safeString(flight["disponibilidad"]).isEmpty
                                    ? null
                                    : safeString(flight["disponibilidad"]),
                                escalaEn:
                                    (flight["escala_en"] ??
                                            flight["escalaEn"]) ==
                                        null
                                    ? null
                                    : safeString(
                                        flight["escala_en"] ??
                                            flight["escalaEn"],
                                      ),
                                bookingUrl:
                                    flight["booking_url"] ??
                                    flight["bookingUrl"],
                                origenCodigo:
                                    flight["origen_codigo"] ??
                                    flight["origenCodigo"],

                                destinoCodigo:
                                    flight["destino_codigo"] ??
                                    flight["destinoCodigo"],
                              );

                              await FlightStorage.saveFlight(model);

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Vuelo guardado correctamente"),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 6),
                          Text(
                            safeString(flight["disponibilidad"]),
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),

                      InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () async {
                          final raw =
                              flight["booking_url"] ?? flight["bookingUrl"];
                          Uri? uri;
                          if (raw == null) {
                            uri = null;
                          } else if (raw is Uri) {
                            uri = raw;
                          } else {
                            final s = raw.toString().trim();
                            uri = Uri.tryParse(s);
                            if (uri == null || !uri.hasScheme) {
                              uri = Uri.tryParse('https://$s');
                            }
                          }

                          if (uri == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Este vuelo no tiene enlace de reserva.",
                                ),
                              ),
                            );
                            return;
                          }

                          if (!await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          )) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("No se pudo abrir el enlace."),
                              ),
                            );
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF5A3FFF),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF5A3FFF,
                                ).withOpacity(0.18),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 10,
                            ),
                            child: Text(
                              "Ir a Reservar",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Más llamativo: badge "Mejor precio" con tilt, gradiente y glow
            if (esMasBarato)
              Positioned(
                left: 12,
                top: -12,
                child: Transform.rotate(
                  angle: -0.08,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFFFA726), Color(0xFFFF7043)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF7043).withOpacity(0.28),
                          blurRadius: 22,
                          spreadRadius: 2,
                          offset: const Offset(0, 10),
                        ),
                        BoxShadow(
                          color: const Color(0xFFFFA726).withOpacity(0.12),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.local_fire_department,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              "🔥 Mejor precio",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              "Oferta destacada",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
