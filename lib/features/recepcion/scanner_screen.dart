import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'dashboard_screen.dart';
import '../auth/login_screen.dart';

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

  // funcion para cerrar sesion de forma segura
  Future<void> _logout(BuildContext context) async {
    try {
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

  Future<void> _cargarHistorial() async {
    try {
      final response = await http.get(Uri.parse('http://$ip:8080/api/accesos/recientes'));
      if (response.statusCode == 200) {
        setState(() => historialAccesos = json.decode(response.body));
      }
    } catch (e) {
      debugPrint("error al cargar historial: $e");
    }
  }

  // valida el qr y decide si mostrar exito o el boton de cobro
  Future<void> validarAcceso(String qrData) async {
    if (!isScanning) return;
    setState(() => isScanning = false);

    try {
      final response = await http.post(
        Uri.parse('http://$ip:8080/api/accesos/escanear/$qrData'),
      );

      final Map<String, dynamic> data = json.decode(response.body);
      bool esExitoso = data['esExitoso'] ?? false;
      String mensaje = data['mensajeSemaforo'] ?? "ACCESO DENEGADO";
      // el id del socio es necesario para registrar el pago
      String? socioId = data['socioId']?.toString();

      if (esExitoso) {
        _mostrarResultado(mensaje, Colors.green, Icons.check_circle);
      } else {
        // si no tiene membresia, permitimos cobrar desde aqui
        _mostrarResultado(
          mensaje, 
          Colors.red, 
          Icons.error, 
          mostrarBotonPago: true, 
          socioId: socioId ?? qrData
        );
      }
      _cargarHistorial();
    } catch (e) {
      _mostrarResultado("ERROR DE CONEXION", Colors.orange, Icons.wifi_off);
    }
  }

  // abre un formulario para ingresar el dinero recibido[cite: 6]
  void _mostrarFormularioPago(String socioId) {
    final TextEditingController montoController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom, 
          left: 20, right: 20, top: 20
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("registrar pago", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(
              controller: montoController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "monto (\$)", 
                border: OutlineInputBorder(), 
                prefixText: "\$ "
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 55), 
                backgroundColor: Colors.blueAccent
              ),
              onPressed: () {
                if (montoController.text.isNotEmpty) {
                  _enviarPago(socioId, montoController.text);
                }
              },
              child: const Text("confirmar pago", style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // envia el pago al backend para activar al socio
  Future<void> _enviarPago(String socioId, String monto) async {
    Navigator.pop(context);
    try {
      final response = await http.post(
        Uri.parse('http://$ip:8080/api/membresias/pagar'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "socioId": socioId,
          "monto": double.parse(monto),
          "metodoPago": "EFECTIVO",
          "duracionDias": 30
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _mostrarResultado("pago registrado", Colors.blue, Icons.monetization_on);
        _cargarHistorial();
      } else {
        _mostrarResultado("error al procesar pago", Colors.red, Icons.warning);
      }
    } catch (e) {
      _mostrarResultado("error de red", Colors.orange, Icons.wifi_off);
    }
  }

  void _mostrarResultado(String mensaje, Color color, IconData icono, {bool mostrarBotonPago = false, String? socioId}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 80, color: Colors.white),
            const SizedBox(height: 20),
            Text(mensaje, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            if (mostrarBotonPago) ...[
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _mostrarFormularioPago(socioId!);
                },
                child: const Text("cobrar membresia"),
              )
            ]
          ],
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() => isScanning = true);
              },
              child: const Text("cerrar", style: TextStyle(color: Colors.white)),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("recepcion gym"),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.logout, color: Colors.redAccent),
          onPressed: () => _logout(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DashboardScreen())),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: MobileScanner(
              controller: controller,
              onDetect: (capture) {
                for (final barcode in capture.barcodes) {
                  if (isScanning && barcode.rawValue != null) validarAcceso(barcode.rawValue!);
                }
              },
            ),
          ),
          Expanded(
            flex: 6,
            child: Container(
              padding: const EdgeInsets.all(15),
              color: Colors.grey[100],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("accesos recientes", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: historialAccesos.length,
                      itemBuilder: (context, index) {
                        final acceso = historialAccesos[index];
                        return Card(
                          child: ListTile(
                            leading: Icon(
                              acceso['esExitoso'] == true ? Icons.check_circle : Icons.error, 
                              color: acceso['esExitoso'] == true ? Colors.green : Colors.red
                            ),
                            title: Text(acceso['nombreSocio'] ?? "socio"),
                            subtitle: Text("${acceso['mensajeSemaforo']}"),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}