import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../auth/login_screen.dart';
import '../admin/detalle_metrica_screen.dart'; // NUEVO IMPORT

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final String ip = "192.168.1.127";
  Map<String, dynamic>? resumen;
  List<dynamic> datosGrafica = [];
  bool cargando = true;
  String rangoSeleccionado = 'semana';

  @override
  void initState() {
    super.initState();
    _cargarDatosDashboard();
  }

  Future<void> _cargarDatosDashboard() async {
    if (!mounted) return;
    setState(() => cargando = true);

    try {
      final urlResumen = Uri.parse("http://$ip:8080/api/admin/resumen-dashboard");
      final urlGrafica = Uri.parse("http://$ip:8080/api/admin/estadisticas-accesos?rango=$rangoSeleccionado");

      final respuestas = await Future.wait([
        http.get(urlResumen).timeout(const Duration(seconds: 5)),
        http.get(urlGrafica).timeout(const Duration(seconds: 5)),
      ]);

      if (respuestas[0].statusCode == 200 && respuestas[1].statusCode == 200) {
        setState(() {
          resumen = jsonDecode(respuestas[0].body);
          datosGrafica = jsonDecode(respuestas[1].body);
        });
      }
    } catch (e) {
      print("Error de conexión: $e");
      resumen ??= {"totalSocios": 0, "sociosActivos": 0, "sociosVencidos": 0, "accesosHoy": 0};
    } finally {
      if (mounted) setState(() => cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text("GYM RATS ADMIN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.orange),
            onPressed: _cargarDatosDashboard,
          ),
        ],
      ),
      body: cargando 
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  // Carrusel Horizontal
                  SizedBox(
                    height: 160,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      children: [ // Ahora _buildStatCard es interactivo
                        _buildStatCard("SOCIOS", "${resumen?['totalSocios'] ?? 0}", Colors.blue, Icons.people, 'Socios'),
                        _buildStatCard("ACTIVOS", "${resumen?['sociosActivos'] ?? 0}", Colors.green, Icons.check_circle, 'Activos'),
                        _buildStatCard("VENCIDOS", "${resumen?['sociosVencidos'] ?? 0}", Colors.red, Icons.warning, 'Vencidos'),
                        _buildStatCard("ACCESOS HOY", "${resumen?['accesosHoy'] ?? 0}", Colors.orange, Icons.qr_code_scanner, 'Accesos Hoy'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Gráfica
                  const Text("FLUJO DE ENTRADAS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  Container(
                    height: 250,
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(25)),
                    child: _buildChart(),
                  ),
                  _buildActionItem(Icons.person_add, "Registrar Socio", "Añadir nuevo miembro"),
                ],
              ),
            ),
    );
  }

  Widget _buildChart() {
    if (datosGrafica.isEmpty) {
      return const Center(child: Text("Sin datos registrados", style: TextStyle(color: Colors.white24)));
    }
    return BarChart(
      BarChartData(
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => Colors.blueGrey.withOpacity(0.9),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                'Entradas: ${rod.toY.toInt()}',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              );
            },
          ),
        ),
        alignment: BarChartAlignment.spaceAround,
        maxY: _getMaxY(),
        barGroups: datosGrafica.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: (entry.value['conteoAccesos'] as num).toDouble(),
                color: Colors.orange,
                width: 18,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              )
            ],
          );
        }).toList(),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                int i = value.toInt();
                if (i >= 0 && i < datosGrafica.length) {
                  return SideTitleWidget(
                    meta: meta,
                    space: 10,
                    child: Text(
                      datosGrafica[i]['etiqueta'].toString(), 
                      style: const TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                  );
                }
                return const Text("");
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1.0, // Escala de pasos de 1 en 1
              reservedSize: 30,
              getTitlesWidget: (value, meta) => Text(value.toInt().toString(), 
                style: const TextStyle(color: Colors.grey, fontSize: 10)),
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  double _getMaxY() {
    if (datosGrafica.isEmpty) return 10;
    double max = 0;
    for (var item in datosGrafica) {
      double val = (item['conteoAccesos'] as num).toDouble();
      if (val > max) max = val;
    }
    return max == 0 ? 10 : max + 2;
  }

  // Modificado _buildStatCard para ser interactivo
  Widget _buildStatCard(String label, String value, Color color, IconData icon, String metricType) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetalleMetricaScreen(
              title: label,
              metricType: metricType,
              ip: ip, // Pasamos la IP a la nueva pantalla
            ),
          ),
        );
      },
      child: Container(
        width: 150, margin: const EdgeInsets.only(right: 15), padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(25), border: Border.all(color: color.withOpacity(0.3))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const Spacer(),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem(IconData icon, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(20)),
      child: Row(children: [Icon(icon, color: Colors.orange), const SizedBox(width: 20), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12))])]),
    );
  }
}