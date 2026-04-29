import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  bool isScanning = true;
  final MobileScannerController controller = MobileScannerController();
  final String ip = "192.168.1.127";
  List<dynamic> historialAccesos = [];

  @override
  void initState() {
    super.initState();
    _cargarHistorial();
  }

  Future<void> _cargarHistorial() async {
    try {
      final response = await http.get(Uri.parse('http://$ip:8080/api/accesos/recientes'));
      if (response.statusCode == 200) {
        setState(() {
          historialAccesos = json.decode(response.body);
        });
      }
    } catch (e) {
      debugPrint("Error al cargar historial: $e");
    }
  }

  Future<void> validarAcceso(String qrData) async {
    if (!isScanning) return;
    setState(() => isScanning = false);

    try {
      final response = await http.post(
        Uri.parse('http://$ip:8080/api/accesos/escanear/$qrData'),
      ).timeout(const Duration(seconds: 5));

      final Map<String, dynamic> data = json.decode(response.body);
      final String? socioIdReal = data['socioId']?.toString();
      bool esExitoso = data['esExitoso'] ?? false;
      String mensaje = data['mensajeSemaforo'] ?? "ACCESO DENEGADO";

      if (response.statusCode == 200 && esExitoso) {
        _mostrarResultado(mensaje, Colors.green, Icons.check_circle);
      } else {
        _mostrarResultado(
          mensaje, 
          Colors.red, 
          Icons.error,
          mostrarBotonPago: true,
          socioId: socioIdReal ?? qrData
        );
      }
      _cargarHistorial();
    } catch (e) {
      _mostrarResultado("ERROR DE CONEXIÓN", Colors.orange, Icons.wifi_off);
    }
  }

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
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Registrar Pago", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(
              controller: montoController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(labelText: "Monto (\$)", border: OutlineInputBorder(), prefixText: "\$ "),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 55), backgroundColor: Colors.blueAccent),
              onPressed: () {
                if (montoController.text.isNotEmpty) _enviarPago(socioId, montoController.text);
              },
              child: const Text("CONFIRMAR PAGO", style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

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
        _mostrarResultado("PAGO REGISTRADO", Colors.blue, Icons.monetization_on);
        _cargarHistorial();
      } else {
        _mostrarResultado("ERROR AL PROCESAR PAGO", Colors.red, Icons.warning);
      }
    } catch (e) {
      _mostrarResultado("ERROR DE RED", Colors.orange, Icons.wifi_off);
    }
  }

  void _mostrarResultado(String mensaje, Color color, IconData icono, {bool mostrarBotonPago = false, String? socioId}) {
    if (!mounted) return;
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
                onPressed: () { Navigator.pop(context); _mostrarFormularioPago(socioId!); },
                child: const Text("COBRAR MEMBRESÍA"),
              )
            ]
          ],
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.pop(context);
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (mounted) setState(() => isScanning = true);
                });
              },
              child: const Text("CERRAR", style: TextStyle(color: Colors.white)),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Recepción Gym"), centerTitle: true),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: MobileScanner(
              controller: controller,
              onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;
                for (final barcode in barcodes) {
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
                  const Text("Accesos Recientes", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: historialAccesos.length,
                      itemBuilder: (context, index) {
                        final acceso = historialAccesos[index];
                        final bool exito = acceso['esExitoso'] ?? false;
                        
                        // Formateo seguro de fecha
                        String hora = "00:00";
                        try {
                          DateTime dt = DateTime.parse(acceso['fechaHora']);
                          hora = DateFormat('HH:mm').format(dt.toLocal());
                        } catch (e) { hora = "--:--"; }

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: exito ? Colors.green : Colors.red,
                              child: Icon(exito ? Icons.check : Icons.close, color: Colors.white),
                            ),
                            title: Text(acceso['nombreSocio'] ?? "Socio"),
                            subtitle: Text("${acceso['mensajeSemaforo']} • $hora"),
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