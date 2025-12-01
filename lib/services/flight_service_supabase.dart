import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/flight_model.dart';

class FlightServiceSupabase {
  final supabase = Supabase.instance.client;

  Future<void> saveFlight(FlightModel flight) async {
    await supabase.from('flights').insert(flight.toJson());
  }

  Future<List<FlightModel>> getFlights() async {
    final response = await supabase.from('flights').select();

    return response
        // .map((map) => FlightModel.fromMap(map))
        .toList()
        .cast<FlightModel>();
  }

  Future<void> deleteFlight(String id) async {
    await supabase.from('flights').delete().eq('id', id);
  }
}
