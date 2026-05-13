import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'dashboard_screen.dart';
import '../auth/login_screen.dart';
import '../socio/socio_model.dart'; // Importación corregida

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  bool isScanning = true;
  final MobileScannerController controller = MobileScannerController();
  final String ip = "192.168.1.68";
  List<dynamic> historialAccesos = [];

  @override
  void initState() {
    super.initState();
    _cargarHistorial();
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await GoogleSignIn.standard().signOut();
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint("Error al cerrar sesión: $e");
    }
  }

  Future<void> _cargarHistorial() async {
    try {
      final response = await http.get(Uri.parse("http://$ip:8080/api/accesos/recientes"))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        setState(() {
          historialAccesos = jsonDecode(response.body);
        });
      }
    } catch (e) {
      debugPrint("Error al cargar historial: $e");
    }
  }

  // --- FUNCIÓN DE PAGO ---
  Future<void> _ejecutarPago(SocioModel socio) async {
    try {
      final response = await http.post(
        Uri.parse("http://$ip:8080/api/socios/${socio.id}/pagar"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"monto": 250.0}),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        _mostrarSnackBar("✅ Pago exitoso de \$250.00", Colors.green);
        // Actualizamos localmente el estado del socio antes de intentar el registro de entrada
        final socioActivo = SocioModel(
          id: socio.id,
          nombre: socio.nombre,
          telefono: socio.telefono,
          email: socio.email,
          qrToken: socio.qrToken,
          estado: 'activo',
          rol: socio.rol,
          fotoUrl: socio.fotoUrl,
          diasRestantes: 30, // Renovación estándar
        );
        _registrarEntradaManual(socioActivo);
      } else {
        _mostrarSnackBar("❌ Error en el servidor al procesar pago", Colors.red);
      }
    } catch (e) {
      _mostrarSnackBar("❌ Error de red al procesar pago", Colors.red);
    } finally {
      _cargarHistorial(); // Actualiza la lista de abajo
      setState(() => isScanning = true);
    }
  }

  void _mostrarDialogoOpciones(SocioModel socio) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text("SOCIO: ${socio.nombre.toUpperCase()}", 
          style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Estado: ${socio.estado.toUpperCase()}", 
              style: TextStyle(color: socio.estado.toLowerCase() == 'activo' ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text("Seleccione la acción a realizar:", style: TextStyle(color: Colors.white70)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => {Navigator.pop(context), setState(() => isScanning = true)},
            child: const Text("CERRAR", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            onPressed: () {
              Navigator.pop(context);
              _registrarEntradaManual(socio); // Pasamos el objeto socio completo
            },
            child: const Text("REGISTRAR ENTRADA", style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () {
              Navigator.pop(context);
              _ejecutarPago(socio);
            },
            child: const Text("COBRAR MENSUALIDAD", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _mostrarSnackBar(String msj, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msj), backgroundColor: color),
    );
  }

  Future<void> _procesarEscaneo(String qrToken) async {
    try {
      // Obtenemos los datos del socio para mostrarlos en el diálogo
      final response = await http.get(Uri.parse("http://$ip:8080/api/socios/perfil/$qrToken"))
          .timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final socio = SocioModel.fromJson(jsonDecode(response.body));
        _mostrarDialogoOpciones(socio);
      } else {
        _mostrarSnackBar("❌ Código QR no reconocido", Colors.red);
        setState(() => isScanning = true);
      }
    } catch (e) {
      _mostrarSnackBar("❌ Error de red al buscar socio", Colors.red);
      setState(() => isScanning = true);
    }
  }

  Future<void> _registrarEntradaManual(SocioModel socio) async {
    try {
      print('Enviando registro...');
      final response = await http.post(
        // URL actualizada según el nuevo endpoint de accesos
        Uri.parse("http://$ip:8080/api/accesos/registrar/${socio.qrToken}"),
      ).timeout(const Duration(seconds: 5));

      final dynamic data = jsonDecode(response.body);
      // Si data no es un Map o esExitoso es nulo/falso, resultará en false.
      final bool esExitoso = (data is Map && data['esExitoso'] == true);

      if (esExitoso) {
        _mostrarSnackBar("Acceso Autorizado", Colors.green);
      } else {
        _mostrarSnackBar("Acceso Denegado", Colors.red);
      }
    } catch (e) {
      _mostrarSnackBar("❌ Error de red al registrar entrada", Colors.red);
    } finally {
      _cargarHistorial(); // Refrescamos el historial tras el intento de entrada
      setState(() => isScanning = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("RECEPCIÓN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2)),
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.dashboard, color: Colors.orange),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DashboardScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white54),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Área de la Cámara con Overlay
              Expanded(
                flex: 5,
                child: Stack(
                  children: [
                    MobileScanner(
                      controller: controller,
                      onDetect: (capture) {
                        if (isScanning) {
                          final List<Barcode> barcodes = capture.barcodes;
                          if (barcodes.isNotEmpty) {
                            setState(() => isScanning = false);
                            _procesarEscaneo(barcodes.first.rawValue ?? "");
                          }
                        }
                      },
                    ),
                    // Marco de escaneo estético
                    _buildScannerOverlay(),
                  ],
                ),
              ),
              
              // Panel de Historial Moderno
              Expanded(
                flex: 5,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, spreadRadius: 5)
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 25, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("ÚLTIMOS ACCESOS", 
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                            child: const Text("En vivo", style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                          )
                        ],
                      ),
                      const SizedBox(height: 15),
                      Expanded(
                        child: historialAccesos.isEmpty
                          ? const Center(child: Text("Esperando escaneos...", style: TextStyle(color: Colors.white24)))
                          : ListView.builder(
                              padding: const EdgeInsets.only(bottom: 20),
                              itemCount: historialAccesos.length,
                              itemBuilder: (context, index) => _buildAccesoTile(historialAccesos[index]),
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScannerOverlay() {
    return Center(
      child: Container(
        width: 250,
        height: 250,
        decoration: BoxDecoration(
          border: Border.all(color: isScanning ? Colors.orange : Colors.green, width: 2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            // Animación de "escaneo" o simple diseño de esquinas
            Positioned(top: 10, left: 10, child: Container(width: 20, height: 2, color: Colors.orange)),
            Positioned(top: 10, left: 10, child: Container(width: 2, height: 20, color: Colors.orange)),
            // Repetir para otras esquinas si deseas más detalle...
          ],
        ),
      ),
    );
  }

  Widget _buildAccesoTile(dynamic acceso) {
    bool exitoso = acceso['esExitoso'] ?? false;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: exitoso ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
          child: Icon(exitoso ? Icons.check : Icons.close, color: exitoso ? Colors.green : Colors.red, size: 20),
        ),
        title: Text(acceso['nombreSocio'] ?? "Socio", 
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text("${acceso['mensajeSemaforo']}", 
          style: const TextStyle(color: Colors.white54, fontSize: 12)),
        trailing: Text(acceso['horaFormateada'] ?? "", 
          style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
      ),
    );
  }
}