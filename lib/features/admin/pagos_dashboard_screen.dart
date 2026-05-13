import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui';

class PagosDashboardScreen extends StatefulWidget {
  const PagosDashboardScreen({super.key});

  @override
  State<PagosDashboardScreen> createState() => _PagosDashboardScreenState();
}

class _PagosDashboardScreenState extends State<PagosDashboardScreen> {
  final String ip = "192.168.1.127";
  String filtroSeleccionado = 'Mes';
  double metaMensual = 20000.0;
  double recaudadoActualmente = 0.0;
  List<dynamic> cobrosRecientes = [];
  List<dynamic> historialMensual = [];
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDatosPagos();
  }

  Future<void> _cargarDatosPagos() async {
    setState(() => cargando = true);
    try {
      // Llamamos a los endpoints de finanzas (asegúrate de tenerlos en tu Backend)
      final String rango = filtroSeleccionado.toLowerCase();
      
      final resResumen = await http.get(Uri.parse('http://$ip:8080/api/pagos/resumen?rango=$rango'));
      // Ahora pasamos el rango también a los cobros recientes para filtrar la lista según el botón
      final resRecientes = await http.get(Uri.parse('http://$ip:8080/api/pagos/recientes?rango=$rango'));
      final resHistorial = await http.get(Uri.parse('http://$ip:8080/api/pagos/historial-mensual'));

      if (resResumen.statusCode == 200 && resRecientes.statusCode == 200) {
        final dataResumen = json.decode(resResumen.body);
        setState(() {
          recaudadoActualmente = (dataResumen['totalRecaudado'] as num).toDouble();
          metaMensual = (dataResumen['metaMensual'] as num).toDouble();
          cobrosRecientes = json.decode(resRecientes.body);
          if (resHistorial.statusCode == 200) historialMensual = json.decode(resHistorial.body);
        });
      }
    } catch (e) {
      debugPrint("Error cargando pagos: $e");
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
        title: const Text("FINANZAS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.orange),
            onPressed: _cargarDatosPagos,
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _cargarDatosPagos,
        color: Colors.orange,
        child: cargando 
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. TARJETA PRINCIPAL CON GRADIENTE (DINÁMICA)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.orange, Color(0xFF8B0000)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Balance ${filtroSeleccionado}", style: const TextStyle(color: Colors.white70, fontSize: 16)),
                        const SizedBox(height: 10),
                        Text("\$${recaudadoActualmente.toStringAsFixed(2)}", 
                          style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 20),
                        const Text("Ingresos del periodo seleccionado", style: TextStyle(color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // 2. FILTROS RÁPIDOS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: ['Hoy', 'Semana', 'Mes'].map((filtro) {
                      bool esSeleccionado = filtroSeleccionado == filtro;
                      return GestureDetector(
                        onTap: () {
                          setState(() => filtroSeleccionado = filtro);
                          _cargarDatosPagos(); // Recargar al cambiar filtro
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: esSeleccionado ? Colors.orange : Colors.grey[900],
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(filtro, style: TextStyle(color: esSeleccionado ? Colors.black : Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 40),

                  // 3. GRÁFICO CIRCULAR (DATOS REALES)
                  const Text("PROGRESO DE META", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  _buildGlassCard(
                    child: Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: PieChart(
                            PieChartData(
                              sectionsSpace: 5,
                              centerSpaceRadius: 40,
                              sections: [
                                PieChartSectionData(
                                  color: Colors.orange,
                                  value: recaudadoActualmente,
                                  title: '',
                                  radius: 25,
                                ),
                                PieChartSectionData(
                                  color: Colors.grey[800],
                                  value: (metaMensual - recaudadoActualmente) > 0 ? metaMensual - recaudadoActualmente : 0,
                                  title: '',
                                  radius: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLegendItem(Colors.orange, "Recaudado"),
                              const SizedBox(height: 10),
                              _buildLegendItem(Colors.grey[800]!, "Restante"),
                              const SizedBox(height: 15),
                              Text("Meta: \$${metaMensual.toInt()}", style: const TextStyle(color: Colors.white54, fontSize: 12)),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // 4. HISTORIAL MENSUAL (TIPO CALENDARIO / LISTA HORIZONTAL)
                  const Text("HISTORIAL POR MES", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  SizedBox(
                    height: 110,
                    child: historialMensual.isEmpty
                      ? const Center(child: Text("Sin historial registrado", style: TextStyle(color: Colors.grey, fontSize: 12)))
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: historialMensual.length,
                          itemBuilder: (context, index) {
                            final item = historialMensual[index];
                            return _buildMonthCard(
                              item['mes'] ?? "Mes", 
                              "\$${item['total'] ?? '0'}",
                              item['anio'] ?? ""
                            );
                          },
                        ),
                  ),

                  const SizedBox(height: 40),

                  // 4. LISTA DE ACTIVIDAD (DATOS DEL BACKEND)
                  Text("COBROS: ${filtroSeleccionado.toUpperCase()}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  cobrosRecientes.isEmpty 
                    ? const Center(child: Text("No hay cobros registrados", style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: cobrosRecientes.length,
                        itemBuilder: (context, index) {
                          final pago = cobrosRecientes[index];
                          return _buildCobroTile(pago);
                        },
                      ),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildMonthCard(String mes, String total, dynamic anio) {
    return Container(
      width: 130,
      margin: const EdgeInsets.only(right: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05), // Efecto Glassmorfismo
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(mes.toUpperCase(), style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text(total, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          Text(anio.toString(), style: const TextStyle(color: Colors.white54, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(color: Colors.white, fontSize: 14)),
      ],
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildCobroTile(dynamic pago) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.payments, color: Colors.green),
        ),
        title: Text(
          pago['nombreSocio'] ?? "Socio",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          pago['fechaFormateada'] ?? "Pago de Mensualidad", 
          style: const TextStyle(color: Colors.grey, fontSize: 12)
        ),
        trailing: Text(
          "+\$${pago['monto']}", 
          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }
}