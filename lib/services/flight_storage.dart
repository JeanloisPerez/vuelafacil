import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/flight_model.dart';

class FlightStorage {
  static const String key = "saved_flights";

  // Guarda o actualiza si el vuelo ya existe (por id)
  static Future<void> saveFlight(FlightModel flight) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> stored = prefs.getStringList(key) ?? [];

      final List<Map<String, dynamic>> list = stored
          .map((s) {
            try {
              return jsonDecode(s) as Map<String, dynamic>;
            } catch (_) {
              return <String, dynamic>{};
            }
          })
          .where((m) => m.isNotEmpty)
          .toList();

      final id = flight.id;
      final idx = id == null ? -1 : list.indexWhere((m) => m['id'] == id);

      if (idx >= 0) {
        list[idx] = flight.toJson();
      } else {
        list.add(flight.toJson());
      }

      final newStored = list.map((m) => jsonEncode(m)).toList();
      await prefs.setStringList(key, newStored);
    } catch (_) {
      // opcional: log
    }
  }

  static Future<List<FlightModel>> getFlights() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> stored = prefs.getStringList(key) ?? [];
      return stored
          .map((json) {
            try {
              return FlightModel.fromJson(jsonDecode(json));
            } catch (_) {
              return null;
            }
          })
          .whereType<FlightModel>()
          .toList();
    } catch (_) {
      return [];
    }
  }

  // Borra por índice (mantengo para compatibilidad)
  static Future<void> deleteFlight(int index) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> stored = prefs.getStringList(key) ?? [];
      if (index >= 0 && index < stored.length) {
        stored.removeAt(index);
        await prefs.setStringList(key, stored);
      }
    } catch (_) {
      // opcional: log
    }
  }

  // Borra por id (más fiable que índice)
  static Future<void> deleteFlightById(dynamic id) async {
    if (id == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> stored = prefs.getStringList(key) ?? [];
      final List<Map<String, dynamic>> list = stored
          .map((s) {
            try {
              return jsonDecode(s) as Map<String, dynamic>;
            } catch (_) {
              return <String, dynamic>{};
            }
          })
          .where((m) => m.isNotEmpty)
          .toList();
      list.removeWhere((m) => m['id'] == id);
      final newStored = list.map((m) => jsonEncode(m)).toList();
      await prefs.setStringList(key, newStored);
    } catch (_) {
      // opcional: log
    }
  }

  static Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    } catch (_) {}
  }
}
