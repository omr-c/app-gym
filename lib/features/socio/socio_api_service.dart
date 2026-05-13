import 'dart:convert';
import 'package:http/http.dart' as http;
import 'socio_model.dart';

class SocioApiService {
  // Asegúrate de que esta IP sea la misma que usas en el Login y Dashboard
  final String baseUrl = "http://192.168.1.127:8080/api/socios";

  // --- EL MÉTODO QUE TE FALTABA ---
  Future<SocioModel> registrarSocio(SocioModel socio) async {
    final url = Uri.parse("$baseUrl/registrar");
    
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(socio.toJson()),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final dynamic jsonData = jsonDecode(response.body);
        return SocioModel.fromJson(jsonData);
      } else {
        // Leemos el error que viene de Spring Boot (ej. "El teléfono ya existe")
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['message'] ?? 'Error al registrar socio en el servidor');
      }
    } catch (e) {
      print("Error en registrarSocio: $e");
      rethrow; // Reenviamos el error para que la pantalla de registro lo atrape
    }
  }

  // Otros métodos que podrías tener...
  Future<List<SocioModel>> getAllSocios() async {
    final response = await http.get(Uri.parse("$baseUrl/all"));
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((dynamic item) => SocioModel.fromJson(item)).toList();
    } else {
      throw Exception("Fallo al cargar socios");
    }
  }
}