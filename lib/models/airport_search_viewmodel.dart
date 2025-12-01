import 'package:flutter/foundation.dart';
import '../models/airport_model.dart';
import '../services/airports_api_service.dart';

class AirportSearchViewModel {
  final AirportsApiService service;

  ValueNotifier<List<AirportModel>> resultados = ValueNotifier([]);

  AirportSearchViewModel(this.service);

  Future<void> buscar(String query) async {
    if (query.trim().isEmpty) {
      resultados.value = [];
      return;
    }

    try {
      final items = await service.buscar(query);

      resultados.value = items
          .map((e) => AirportModel.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      resultados.value = [];
    }
  }
}
