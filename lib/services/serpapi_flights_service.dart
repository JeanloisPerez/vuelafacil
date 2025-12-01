import 'dart:convert';
import 'package:http/http.dart' as http;

class SerpApiFlightsService {
  final String apiKey;
  final http.Client _client;

  SerpApiFlightsService({required this.apiKey, http.Client? client})
    : _client = client ?? http.Client();

  String _fixDate(String raw) {
    final date = DateTime.parse(raw);
    return "${date.year.toString().padLeft(4, '0')}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${date.day.toString().padLeft(2, '0')}";
  }

  DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);

  Future<List<Map<String, dynamic>>> searchFlights({
    required String departureId,
    required String arrivalId,
    required String outboundDate,
    String? returnDate,
    String currency = 'USD',
  }) async {
    final today = _normalize(DateTime.now());
    final outbound = _normalize(DateTime.parse(outboundDate));

    if (outbound.isBefore(today)) {
      throw Exception("La fecha de salida no puede ser pasada.");
    }

    if (returnDate != null && returnDate.isNotEmpty) {
      final ret = _normalize(DateTime.parse(returnDate));
      if (ret.isBefore(outbound)) {
        throw Exception("La fecha de regreso debe ser después de la salida.");
      }
    }

    final params = <String, String>{
      'engine': 'google_flights',
      'departure_id': departureId,
      'arrival_id': arrivalId,
      'outbound_date': _fixDate(outboundDate),
      'hl': 'es',
      'currency': currency,
      'api_key': apiKey,
    };

    if (returnDate != null && returnDate.isNotEmpty) {
      params['return_date'] = _fixDate(returnDate);
      params['type'] = '1'; // round trip
    } else {
      params['type'] = '2'; // one way
    }

    final uri = Uri.https('serpapi.com', '/search', params);
    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw Exception(
        'Error ${response.statusCode} al consultar SerpApi: ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    final bestFlights = (data['best_flights'] as List?) ?? [];
    final otherFlights = (data['other_flights'] as List?) ?? [];
    final allOptions = [...bestFlights, ...otherFlights];

    final List<Map<String, dynamic>> mappedFlights = [];
    int idCounter = 1;

    for (final option in allOptions) {
      if (option is! Map<String, dynamic>) continue;

      final segments = (option['flights'] as List?) ?? [];
      if (segments.isEmpty) continue;

      final firstSegment = segments.first as Map<String, dynamic>;
      final lastSegment = segments.last as Map<String, dynamic>;

      final departureAirport =
          (firstSegment['departure_airport'] as Map<String, dynamic>?) ?? {};
      final arrivalAirport =
          (lastSegment['arrival_airport'] as Map<String, dynamic>?) ?? {};

      final layovers = (option['layovers'] as List?) ?? [];

      String? bookingLink;

      if (option['booking_link'] != null) {
        bookingLink = option['booking_link'];
      } else if (option['link'] != null) {
        bookingLink = option['link'];
      } else if (option['deep_link'] != null) {
        bookingLink = option['deep_link'];
      } else if (option['sources'] is List && option['sources'].isNotEmpty) {
        final src = option['sources'][0];
        if (src is Map && src['link'] != null) bookingLink = src['link'];
      } else if (option['providers'] is List &&
          option['providers'].isNotEmpty) {
        final prov = option['providers'][0];
        if (prov is Map && prov['link'] != null) bookingLink = prov['link'];
      } else if (option['itinerary'] is Map) {
        bookingLink = option['itinerary']['link'];
      }

      String? airlineLogo;

      if (firstSegment['airline_logo'] != null) {
        airlineLogo = firstSegment['airline_logo'];
      } else if (option['airline_logo'] != null) {
        airlineLogo = option['airline_logo'];
      } else if (option['sources'] is List && option['sources'].isNotEmpty) {
        final src = option['sources'][0];
        if (src is Map && src['logo'] != null) airlineLogo = src['logo'];
      } else if (option['providers'] is List &&
          option['providers'].isNotEmpty) {
        final prov = option['providers'][0];
        if (prov is Map && prov['logo'] != null) airlineLogo = prov['logo'];
      }

      final int totalDurationMinutes =
          (option['total_duration'] as int?) ??
          (firstSegment['duration'] as int?) ??
          0;

      final hours = totalDurationMinutes ~/ 60;
      final minutes = totalDurationMinutes % 60;
      final duracion = '${hours}h ${minutes}m';

      final price = (option['price'] is num)
          ? (option['price'] as num).toDouble()
          : 0.0;

      final tipo = layovers.isEmpty
          ? 'Directo'
          : (layovers.length == 1 ? '1 escala' : '${layovers.length} escalas');

      final escalaEn = layovers.isNotEmpty
          ? layovers.first['name'] as String?
          : null;

      String formatTime(dynamic raw) {
        final value = raw?.toString();
        if (value == null || value.isEmpty) return '';
        if (value.contains('T')) return value;
        if (value.length >= 16) {
          final date = value.substring(0, 10);
          final time = value.substring(11, 16);
          return '${date}T${time}:00';
        }
        return value;
      }

      final salida = formatTime(departureAirport['time']);
      final llegada = formatTime(arrivalAirport['time']);

      final airline = firstSegment['airline'] ?? 'Desconocida';
      final flightNumber = firstSegment['flight_number'] ?? '';

      mappedFlights.add({
        'id': idCounter++,
        'origen':
            '${departureAirport['name'] ?? ''} (${departureAirport['id'] ?? ''})',
        'destino':
            '${arrivalAirport['name'] ?? ''} (${arrivalAirport['id'] ?? ''})',
        'aerolinea': airline,
        'vuelo': flightNumber,
        'salida': salida,
        'llegada': llegada,
        'duracion': duracion,
        'precio': price,
        'moneda': currency,
        'tipo': tipo,
        'disponibilidad': 8,
        'escala_en': escalaEn,
        'reserva_url': bookingLink,
        'logo': airlineLogo,
      });
    }

    return mappedFlights;
  }

  Future<List<Map<String, dynamic>>> searchAirports(String query) async {
    if (query.trim().isEmpty) return [];

    final uri = Uri.https("serpapi.com", "/search.json", {
      "engine": "google_flights",
      "q": query,
      "type": "2",
      "hl": "en",
      "api_key": apiKey,
    });

    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw Exception(
        "Error buscando aeropuertos: ${response.statusCode} ${response.body}",
      );
    }

    final data = jsonDecode(response.body);

    final List results = data["airport_results"] ?? [];

    return results.map<Map<String, dynamic>>((a) {
      return {
        "name": a["name"] ?? "",
        "country": a["country"] ?? "",
        "city": a["city"] ?? "",
        "code": a["iata_code"] ?? "",
      };
    }).toList();
  }
}
