import 'dart:convert';
import 'package:http/http.dart' as http;

class AirportsApiService {
  Future<List<dynamic>> buscar(String query) async {
    final url = Uri.parse("https://airportsapi.com/api/airports?search=$query");

    final res = await http.get(url);

    if (res.statusCode != 200) return [];

    final data = jsonDecode(res.body);

    if (data == null || data['data'] == null) return [];

    return data['data'];
  }
}
