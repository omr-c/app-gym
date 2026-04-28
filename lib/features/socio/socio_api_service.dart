import 'dart:convert';
import 'package:http/http.dart' as http;
import 'socio_model.dart';

class SocioApiService {
  // url de tu backend local. 
  // nota importante: si usas emulador de android usa 10.0.2.2 en lugar de localhost
  static const String baseurl = 'http://192.168.1.68:8080/api/socios';

  // metodo que ejecuta el post para autoregistrar al socio
  Future<Socio?> registrarsocio(Socio socio) async {
    try {
      final url = Uri.parse('$baseurl/registrar');
      
      final response = await http.post(
        url,
        headers: {
          'content-type': 'application/json',
        },
        // convertimos el objeto a json para que spring boot lo entienda
        body: jsonEncode(socio.tojson()),
      );

      // verificamos si la peticion fue un exito (http 200 ok)
      if (response.statusCode == 200) {
        final jsondecodificado = jsonDecode(response.body);
        // retornamos el socio ya con su id y su token qr generados
        return Socio.fromjson(jsondecodificado);
      } else {
        print('error del servidor: codigo ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('error de conexion con el backend: $e');
      return null;
    }
  }
}