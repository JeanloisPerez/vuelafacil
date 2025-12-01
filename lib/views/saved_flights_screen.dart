import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/flight_storage.dart';
import '../services/serpapi_flights_service.dart';
import '../models/flight_model.dart';
import '../widgets/custom_navbar.dart';

class SavedFlightsScreen extends StatefulWidget {
  static const String routeName = '/savedFlights';
  const SavedFlightsScreen({super.key});

  @override
  State<SavedFlightsScreen> createState() => _SavedFlightsScreenState();
}

class _SavedFlightsScreenState extends State<SavedFlightsScreen> {
  final _api = SerpApiFlightsService(
    apiKey: "887106ec220e4f9430f80e6df70191198c1b5dd65474da6f1c5a0638dba85d8d",
  );

  List<FlightModel> savedFlights = [];
  List<FlightModel> currentFlights = [];
  final GlobalKey<AnimatedListState> _listKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    savedFlights = await FlightStorage.getFlights();
    setState(() {});
  }

  Future<void> _deleteAt(int index) async {
    await FlightStorage.deleteFlight(index);
    await loadData();
  }

  bool isFlightAvailable(FlightModel f) {
    return currentFlights.any((apiFlight) => apiFlight.id == f.id);
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return "${dt.day.toString().padLeft(2, '0')}/"
          "${dt.month.toString().padLeft(2, '0')}/"
          "${dt.year}";
    } catch (_) {
      return iso.split('T').first;
    }
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return "${dt.hour.toString().padLeft(2, '0')}:"
          "${dt.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      final parts = iso.split('T');
      return parts.length > 1 ? parts[1].substring(0, 5) : iso;
    }
  }

  Widget _priceBadge(double price, String? moneda) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5A3FFF), Color(0xFF7C63FF)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5A3FFF).withOpacity(0.14),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Text(
        "${price.toStringAsFixed(2)} ${moneda ?? 'USD'}",
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Normaliza bookingUrl (String or Uri) a Uri? seguro para launchUrl
  Uri? _bookingUri(dynamic raw) {
    if (raw == null) return null;
    if (raw is Uri) return raw;
    if (raw is String) {
      final s = raw.trim();
      if (s.isEmpty) return null;
      Uri? uri = Uri.tryParse(s);
      if (uri != null && uri.hasScheme) return uri;
      // si falta scheme, intentar con https
      uri = Uri.tryParse('https://$s');
      if (uri != null && uri.hasScheme) return uri;
    }
    return null;
  }

  // helper: extrae el texto dentro de los paréntesis, o devuelve el original si no hay
  String _extractParentheses(String s) {
    final match = RegExp(r'\(([^)]+)\)').firstMatch(s);
    return match != null ? match.group(1)! : s;
  }

  Future<void> _checkAvailability(FlightModel f, int index) async {
    // loader modal
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // obtener fecha en yyyy-MM-dd (si aplica)
      String outboundDate;
      try {
        final dt = DateTime.parse(f.salida);
        outboundDate =
            "${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
      } catch (_) {
        outboundDate = f.salida.split('T').first;
      }

      final departureId = (f.origenCodigo != null && f.origenCodigo!.isNotEmpty)
          ? f.origenCodigo!
          : _extractParentheses(f.origen);
      final arrivalId = (f.destinoCodigo != null && f.destinoCodigo!.isNotEmpty)
          ? f.destinoCodigo!
          : _extractParentheses(f.destino);

      final flights = await _api.searchFlights(
        departureId: departureId,
        arrivalId: arrivalId,
        outboundDate: outboundDate,
        currency: "USD",
      );

      Navigator.of(context).pop(); // cerrar loader

      final idStr = f.id?.toString();
      final found = flights.any(
        (item) =>
            item != null &&
            item["id"] != null &&
            item["id"].toString() == idStr,
      );

      if (found) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Vuelo disponible")));
      } else {
        final remove = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Vuelo no disponible"),
            content: const Text(
              "El vuelo ya no aparece en los resultados. ¿Deseas eliminarlo de guardados?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text("Cancelar"),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text(
                  "Eliminar",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        );

        if (remove == true) {
          await _deleteAt(index);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Vuelo eliminado de guardados")),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Conservado en guardados")),
          );
        }
      }
    } catch (e) {
      Navigator.of(context).pop(); // cerrar loader si hay error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error comprobando disponibilidad: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = savedFlights.length;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mis Vuelos Guardados"),
        backgroundColor: const Color(0xFF5A3FFF),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(74),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
            decoration: const BoxDecoration(
              color: Color(0xFF5A3FFF),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.bookmark, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Guardados para más tarde",
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "$total vuelo${total == 1 ? '' : 's'} guardado${total == 1 ? '' : 's'}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: loadData,
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  tooltip: "Refrescar lista",
                ),
              ],
            ),
          ),
        ),
      ),
      backgroundColor: const Color(0xFFF5F5F7),
      bottomNavigationBar: CustomNavBar(
        currentIndex: 1,
        onTap: (int i) {
          if (i == 1) return; // ya estamos aquí
          if (i == 0) {
            // Volver a la pantalla raíz (home)
            Navigator.of(context).pushReplacementNamed('/home');
            return;
          }
          if (i == 2) {
            Navigator.of(context).pushReplacementNamed('/profile');
            return;
          }
        },
      ),
      body: savedFlights.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.bookmark_border, size: 56, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    "No tienes vuelos guardados",
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
              itemCount: savedFlights.length,
              itemBuilder: (context, index) {
                final f = savedFlights[index];
                final available = isFlightAvailable(f);

                final fecha = _formatDate(f.salida);
                final salidaHora = _formatTime(f.salida);
                final llegadaHora = _formatTime(f.llegada);

                return GestureDetector(
                  onTap: () {
                    // expandir/mostrar más detalle: por ahora abrir diálogo con info
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => Padding(
                        padding: MediaQuery.of(context).viewInsets,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      "${f.origen} → ${f.destino}",
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  _priceBadge(f.precio, f.moneda),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                "${_formatDate(f.salida)} • $salidaHora → $llegadaHora",
                                style: const TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(height: 12),
                              Text("Aerolínea: ${f.aerolinea ?? '—'}"),
                              const SizedBox(height: 6),
                              Text("Vuelo: ${f.vuelo ?? '—'}"),
                              const SizedBox(height: 6),
                              Text("Duración: ${f.duracion ?? '—'}"),
                              const SizedBox(height: 6),
                              Text("Tipo: ${f.tipo ?? '—'}"),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF5A3FFF),
                                    ),
                                    onPressed: () async {
                                      Navigator.pop(context);
                                      final uri = _bookingUri(f.bookingUrl);
                                      if (uri == null) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              "No hay enlace de reserva",
                                            ),
                                          ),
                                        );
                                        return;
                                      }
                                      if (!await launchUrl(
                                        uri,
                                        mode: LaunchMode.externalApplication,
                                      )) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              "No se pudo abrir el enlace",
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                    icon: const Icon(Icons.open_in_new),
                                    label: const Text("Abrir reserva"),
                                  ),
                                  const SizedBox(width: 10),
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _checkAvailability(f, index);
                                    },
                                    icon: const Icon(
                                      Icons.sync,
                                      color: Colors.orange,
                                    ),
                                    label: const Text("Comprobar"),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12.withOpacity(0.06),
                            blurRadius: 12,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Accent stripe
                          Container(
                            width: 8,
                            height: 150,
                            decoration: BoxDecoration(
                              color: const Color(0xFF5A3FFF),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(14),
                                bottomLeft: Radius.circular(14),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Top row: airline + price badge
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.grey.withOpacity(0.06),
                                        ),
                                        child: const Icon(
                                          Icons.flight_takeoff,
                                          color: Color(0xFF5A3FFF),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              f.aerolinea ?? '—',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              f.vuelo ?? "",
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            available
                                                ? "En oferta"
                                                : "Guardado",
                                            style: TextStyle(
                                              color: available
                                                  ? const Color(0xFF2ECC71)
                                                  : Colors.grey,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            "${f.precio.toStringAsFixed(2)} ${f.moneda ?? 'USD'}",
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    "${f.origen} → ${f.destino}",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.calendar_today,
                                        size: 14,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        fecha,
                                        style: const TextStyle(
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Icon(
                                        Icons.schedule,
                                        size: 14,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        "$salidaHora → $llegadaHora",
                                        style: const TextStyle(
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  // Chips row
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 6,
                                    children: [
                                      _infoChip(
                                        icon: Icons.airplanemode_active,
                                        label: f.duracion ?? "—",
                                      ),
                                      _infoChip(
                                        icon: Icons.info_outline,
                                        label: f.tipo ?? "—",
                                      ),
                                      if ((f.escalaEn ?? "").isNotEmpty)
                                        _infoChip(
                                          icon: Icons.swap_calls,
                                          label: f.escalaEn ?? "",
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  // Actions
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          TextButton.icon(
                                            onPressed: () async {
                                              final uri = _bookingUri(
                                                f.bookingUrl,
                                              );
                                              if (uri == null) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      "No hay enlace de reserva disponible",
                                                    ),
                                                  ),
                                                );
                                                return;
                                              }
                                              if (!await launchUrl(
                                                uri,
                                                mode: LaunchMode
                                                    .externalApplication,
                                              )) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      "No se pudo abrir el enlace",
                                                    ),
                                                  ),
                                                );
                                              }
                                            },
                                            icon: const Icon(
                                              Icons.open_in_new,
                                              color: Color(0xFF5A3FFF),
                                            ),
                                            label: const Text("Abrir reserva"),
                                          ),
                                          const SizedBox(width: 6),
                                          TextButton.icon(
                                            onPressed: () =>
                                                _checkAvailability(f, index),
                                            icon: const Icon(
                                              Icons.sync,
                                              color: Colors.orange,
                                            ),
                                            label: const Text("Comprobar"),
                                          ),
                                        ],
                                      ),
                                      IconButton(
                                        tooltip: "Eliminar",
                                        onPressed: () => _deleteAt(index),
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.redAccent,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _infoChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
