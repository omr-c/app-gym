import 'dart:convert';
import 'package:http/http.dart' as http;
import '../socio/socio_model.dart'; // Sube un nivel a features y entra a socio

class AdminService {
  // Tu IP configurada para el acceso local desde el celular
  final String baseUrl = "http://192.168.1.127:8080/api/socios";

  /// Obtiene la lista completa de socios desde el endpoint /all
  Future<List<SocioModel>> getAllSocios() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/all'));

      if (response.statusCode == 200) {
        // Decodifica la respuesta JSON que contiene la lista de socios
        List<dynamic> body = jsonDecode(response.body);
        
        // Mapea cada objeto JSON al modelo Socio
        return body.map((item) => SocioModel.fromJson(item)).toList();
      } else {
        print("Error del servidor: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("Error de conexión en AdminService: $e");
      return [];
    }
  }
}