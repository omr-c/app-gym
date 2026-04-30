import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../auth/login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // IP corregida sin espacios
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

  Future<void> _logout(BuildContext context) async {
    try {
      // CORRECCIÓN: Usar constructor simple para compatibilidad con versión 6.2.1
      await GoogleSignIn().signOut();
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint("error al salir: $e");
    }
  }

  Future<void> _cargarDatosDashboard() async {
    if (!mounted) return;
    setState(() => cargando = true);

    try {
      final resResumen = await http.get(Uri.parse('http://$ip:8080/api/dashboard/resumen'));
      final resGrafica = await http.get(Uri.parse('http://$ip:8080/api/dashboard/accesos?rango=$rangoSeleccionado'));

      if (resResumen.statusCode == 200 && resGrafica.statusCode == 200) {
        setState(() {
          resumen = json.decode(resResumen.body);
          datosGrafica = json.decode(resGrafica.body);
        });
      }
    } catch (e) {
      debugPrint("error de conexion en dashboard: $e");
    } finally {
      if (mounted) setState(() => cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("estadisticas reales"),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _cargarDatosDashboard),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () => _logout(context),
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _cargarDatosDashboard,
        child: cargando 
          ? const Center(child: CircularProgressIndicator())
          : (resumen == null) // Quitamos la restricción de datosGrafica.isEmpty para que al menos veas los cuadros
              ? ListView(
                  children: const [
                    SizedBox(height: 100),
                    Center(child: Text("no hay datos o hubo un error de conexion")),
                  ],
                )
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("resumen de membresias", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          _buildStatCard("activos", "${resumen?['totalSociosActivos'] ?? 0}", Colors.green, Icons.check_circle),
                          const SizedBox(width: 10),
                          _buildStatCard("deudores", "${resumen?['totalSociosPendientes'] ?? 0}", Colors.orange, Icons.timer),
                        ],
                      ),
                      const SizedBox(height: 25),
                      const Text("ingresos en caja", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          _buildStatCard("hoy", "\$${resumen?['ingresosHoy'] ?? 0}", Colors.blue, Icons.payments),
                          const SizedBox(width: 10),
                          _buildStatCard("semana", "\$${resumen?['ingresosSemana'] ?? 0}", Colors.indigo, Icons.account_balance),
                        ],
                      ),
                      const SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("afluencia", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          DropdownButton<String>(
                            value: rangoSeleccionado,
                            items: const [
                              DropdownMenuItem(value: 'semana', child: Text('esta semana')),
                              DropdownMenuItem(value: 'mes', child: Text('este mes')),
                              DropdownMenuItem(value: 'ano', child: Text('este año')),
                            ],
                            onChanged: (String? nuevoValor) {
                              if (nuevoValor != null) {
                                setState(() => rangoSeleccionado = nuevoValor);
                                _cargarDatosDashboard();
                              }
                            },
                          )
                        ],
                      ),
                      const SizedBox(height: 10),
                      datosGrafica.isEmpty 
                        ? const Center(child: Text("\nTodavía no hay accesos hoy"))
                        : _buildGrafica(),
                      const SizedBox(height: 50),
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
                  width: rangoSeleccionado == 'mes' ? 6 : 18,
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
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  int index = value.toInt();
                  if (index >= 0 && index < datosGrafica.length) {
                    return Text(datosGrafica[index]['fecha'].toString(), style: const TextStyle(fontSize: 9));
                  }
                  return const Text('');
                },
              ),
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
      if ((item['conteoAccesos'] as num).toDouble() > max) max = (item['conteoAccesos'] as num).toDouble();
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