class FlightModel {
  final dynamic id;
  final String origen;
  final String destino;
  final String? origenCodigo;
  final String? destinoCodigo;
  final String? aerolinea;
  final String? vuelo;
  final String salida;
  final String llegada;
  final String? duracion;
  final double precio;
  final String? moneda;
  final String? tipo;
  final String? disponibilidad;
  final String? escalaEn;
  final dynamic bookingUrl;

  FlightModel({
    required this.id,
    required this.origen,
    required this.destino,
    this.origenCodigo,
    this.destinoCodigo,
    this.aerolinea,
    this.vuelo,
    required this.salida,
    required this.llegada,
    this.duracion,
    required this.precio,
    this.moneda,
    this.tipo,
    this.disponibilidad,
    this.escalaEn,
    this.bookingUrl,
  });

  factory FlightModel.fromJson(Map<String, dynamic> json) {
    double _parsePrice(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    String _asString(dynamic v) => v == null ? '' : v.toString();

    return FlightModel(
      id: json['id'],
      origen: _asString(json['origen']),
      destino: _asString(json['destino']),
      origenCodigo: json['origen_codigo'] != null
          ? _asString(json['origen_codigo'])
          : (json['origenCodigo'] != null
                ? _asString(json['origenCodigo'])
                : null),
      destinoCodigo: json['destino_codigo'] != null
          ? _asString(json['destino_codigo'])
          : (json['destinoCodigo'] != null
                ? _asString(json['destinoCodigo'])
                : null),
      aerolinea: json['aerolinea'] != null
          ? _asString(json['aerolinea'])
          : null,
      vuelo: json['vuelo'] != null ? _asString(json['vuelo']) : null,
      salida: _asString(json['salida']),
      llegada: _asString(json['llegada']),
      duracion: json['duracion'] != null ? _asString(json['duracion']) : null,
      precio: _parsePrice(json['precio']),
      moneda: json['moneda'] != null ? _asString(json['moneda']) : null,
      tipo: json['tipo'] != null ? _asString(json['tipo']) : null,
      disponibilidad: json['disponibilidad'] != null
          ? _asString(json['disponibilidad'])
          : null,
      escalaEn: json['escala_en'] != null
          ? _asString(json['escala_en'])
          : (json['escalaEn'] != null ? _asString(json['escalaEn']) : null),
      bookingUrl: json['booking_url'] ?? json['bookingUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'origen': origen,
      'destino': destino,
      'origen_codigo': origenCodigo,
      'destino_codigo': destinoCodigo,
      'aerolinea': aerolinea,
      'vuelo': vuelo,
      'salida': salida,
      'llegada': llegada,
      'duracion': duracion,
      'precio': precio,
      'moneda': moneda,
      'tipo': tipo,
      'disponibilidad': disponibilidad,
      'escala_en': escalaEn,
      'booking_url': bookingUrl is Uri ? bookingUrl.toString() : bookingUrl,
    };
  }
}
