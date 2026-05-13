import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../socio/socio_model.dart'; // Asegúrate de que esta ruta sea correcta

class DetalleMetricaScreen extends StatefulWidget {
  final String title;
  final String metricType; // 'Socios', 'Activos', 'Vencidos', 'Accesos Hoy'
  final String ip;

  const DetalleMetricaScreen({
    super.key,
    required this.title,
    required this.metricType,
    required this.ip,
  });

  @override
  State<DetalleMetricaScreen> createState() => _DetalleMetricaScreenState();
}

class _DetalleMetricaScreenState extends State<DetalleMetricaScreen> {
  late Future<List<dynamic>> _futureData;

  @override
  void initState() {
    super.initState();
    _futureData = _fetchData();
  }

  Future<List<dynamic>> _fetchData() async {
    String url;
    try {
      switch (widget.metricType) {
        case 'Socios':
          url = 'http://${widget.ip}:8080/api/socios/all';
          break;
        case 'Activos':
          url = 'http://${widget.ip}:8080/api/socios/activos'; // Asumiendo este endpoint
          break;
        case 'Vencidos':
          url = 'http://${widget.ip}:8080/api/socios/vencidos'; // Asumiendo este endpoint
          break;
        case 'Accesos Hoy':
          url = 'http://${widget.ip}:8080/api/accesos/recientes?rango=hoy'; // Reutilizando recientes con filtro
          break;
        default:
          throw Exception('Tipo de métrica no reconocido');
      }

      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error al cargar datos: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint("Error fetching data for ${widget.metricType}: $e");
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _futureData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.orange));
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.white)));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("No hay ${widget.metricType.toLowerCase()} registrados", style: const TextStyle(color: Colors.white)));
          }

          final data = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: data.length,
            itemBuilder: (context, index) {
              // Determinar si es un Socio o un Acceso basado en metricType
              if (widget.metricType == 'Accesos Hoy') {
                // Reutilizar diseño de la lista de accesos recientes de ScannerScreen
                final acceso = data[index];
                bool exitoso = acceso['esExitoso'] ?? false;
                return Card(
                  color: Colors.grey[900],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: Icon(exitoso ? Icons.check_circle : Icons.error,
                        color: exitoso ? Colors.green : Colors.red),
                    title: Text(acceso['nombreSocio'] ?? "Socio Desconocido",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text(acceso['mensajeSemaforo'] ?? "Acceso",
                        style: TextStyle(color: Colors.grey[400])),
                    trailing: Text(acceso['horaFormateada'] ?? "",
                        style: const TextStyle(color: Colors.white70)),
                  ),
                );
              } else {
                // Reutilizar diseño de SociosListScreen
                final socio = SocioModel.fromJson(data[index]); // Convertir map a SocioModel
                Color colorEstado = socio.estado.toLowerCase() == 'activo' ? Colors.green : Colors.red;

                return Card(
                  color: Colors.grey[900],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.orange,
                      backgroundImage: socio.fotoUrl.isNotEmpty ? NetworkImage(socio.fotoUrl) : null,
                      child: socio.fotoUrl.isEmpty
                          ? Text(socio.nombre[0].toUpperCase(), style: const TextStyle(color: Colors.white))
                          : null,
                    ),
                    title: Text(
                      socio.nombre,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "Días restantes: ${socio.diasRestantes}",
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: colorEstado.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: colorEstado),
                      ),
                      child: Text(
                        socio.estado.toUpperCase(),
                        style: TextStyle(color: colorEstado, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                    onTap: () {
                      // Aquí podrías abrir el perfil detallado del socio
                    },
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }
}