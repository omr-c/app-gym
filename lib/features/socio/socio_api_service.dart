import 'dart:convert';
import 'package:http/http.dart' as http;
import 'socio_model.dart';

class SocioApiService {
  final String baseUrl = "http://192.168.1.68:8080/api/socios";

  // Metodo para solicitar codigo otp
  Future<int> enviarCodigo(String email, String telefono) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/solicitar-codigo?email=$email&telefono=$telefono"),
      );
      return response.statusCode; 
    } catch (e) { 
      return 500; 
    }
  }

  // Valida el codigo otp en el servidor
  Future<bool> validarCodigo(String email, String codigo) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/validar-codigo?email=$email&codigo=$codigo"),
      );
      return response.body == 'true';
    } catch (e) { 
      return false; 
    }
  }

  // Registra un nuevo socio en la base de datos
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

  // Obtiene los datos actualizados del perfil mediante el qrToken
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

  // Manda la nueva url de la foto o el nuevo nombre al backend de java
  Future<bool> actualizarPerfil(String id, String nombre, String? fotoUrl) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/actualizar/$id"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "nombre": nombre,
          "fotoUrl": fotoUrl,
        }),
      );
      return response.statusCode == 200;
    } catch (e) { 
      return false; 
    }
  }
}