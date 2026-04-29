import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

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

  @override
  void initState() {
    super.initState();
    _cargarDatosDashboard();
  }

  // FUNCIÓN PRINCIPAL QUE TRAE LOS DATOS
  Future<void> _cargarDatosDashboard() async {
    try {
      final resResumen = await http.get(Uri.parse('http://$ip:8080/api/dashboard/resumen'));
      final resGrafica = await http.get(Uri.parse('http://$ip:8080/api/dashboard/accesos-semanales'));

      if (resResumen.statusCode == 200 && resGrafica.statusCode == 200) {
        setState(() {
          resumen = json.decode(resResumen.body);
          datosGrafica = json.decode(resGrafica.body);
          cargando = false;
        });
      }
    } catch (e) {
      debugPrint("Error Dashboard: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Estadísticas Reales"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarDatosDashboard, // Botón manual de refresco
          )
        ],
      ),
      // EL REFRESH INDICATOR PERMITE DESLIZAR HACIA ABAJO
      body: RefreshIndicator(
        onRefresh: _cargarDatosDashboard,
        child: cargando 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(), // Obliga a que siempre se pueda deslizar
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Resumen de Membresías", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      _buildStatCard("Activos", "${resumen?['totalSociosActivos']}", Colors.green, Icons.check_circle),
                      const SizedBox(width: 10),
                      _buildStatCard("Deudores", "${resumen?['totalSociosPendientes']}", Colors.orange, Icons.timer),
                    ],
                  ),
                  const SizedBox(height: 25),
                  const Text("Ingresos en Caja", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      _buildStatCard("Hoy", "\$${resumen?['ingresosHoy']}", Colors.blue, Icons.payments),
                      const SizedBox(width: 10),
                      _buildStatCard("Semana", "\$${resumen?['ingresosSemana']}", Colors.indigo, Icons.account_balance),
                    ],
                  ),
                  const SizedBox(height: 30),
                  const Text("Afluencia de la Semana", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  _buildGrafica(),
                  const SizedBox(height: 50), // Espacio extra al final
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildGrafica() {
    return Container(
      height: 280,
      padding: const EdgeInsets.only(top: 20, right: 10),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: _getMaxY(),
          barGroups: datosGrafica.asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: (entry.value['conteoAccesos'] as num).toDouble(),
                  color: Colors.blueAccent,
                  width: 18,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                )
              ],
            );
          }).toList(),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (val, meta) => Text(val.toInt().toString(), style: const TextStyle(fontSize: 10))
              ),
              axisNameWidget: const Text("Personas"),
              axisNameSize: 15,
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  int index = value.toInt();
                  if (index >= 0 && index < datosGrafica.length) {
                    DateTime dt = DateTime.parse(datosGrafica[index]['fecha']);
                    return Text("${dt.day}/${dt.month}", style: const TextStyle(fontSize: 9));
                  }
                  return const Text('');
                },
              ),
              axisNameWidget: const Text("Fechas"),
              axisNameSize: 25,
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  double _getMaxY() {
    if (datosGrafica.isEmpty) return 10;
    double max = 0;
    for (var item in datosGrafica) {
      if (item['conteoAccesos'] > max) max = (item['conteoAccesos'] as num).toDouble();
    }
    return max + 2;
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}