import 'dart:convert';
import 'package:http/http.dart' as http;
import 'socio_model.dart';

class SocioApiService {
  final String baseUrl = "http://192.168.1.68:8080/api/socios";

  // Registro (lo que ya tenías)
  Future<Socio?> registrarsocio(Socio socio) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/registrar"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(socio.toJson()),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return Socio.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // NUEVO: Obtener perfil completo con días restantes[cite: 3]
  Future<Socio?> obtenerPerfil(String qrToken) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/perfil/$qrToken"),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        return Socio.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}