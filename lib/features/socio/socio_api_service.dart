import 'dart:convert';
import 'package:http/http.dart' as http;
import 'socio_model.dart';

class SocioApiService {
  // nota: la ruta debe coincidir con el postmapping del backend
  final String baseUrl = "http://192.168.1.127:8080/api/socios/registrar";

  Future<Socio?> registrarsocio(Socio socio) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(socio.toJson()), // enviamos el json con rol y estado
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // el servidor devuelve el socio con su id y qrtoken generados
        return Socio.fromJson(jsonDecode(response.body));
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
}