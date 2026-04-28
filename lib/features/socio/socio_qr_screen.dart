import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'socio_model.dart';

// pantalla para mostrar la identidad digital (codigo qr) del socio
class SocioQrScreen extends StatelessWidget {
  final Socio socio;

  const SocioQrScreen({super.key, required this.socio});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('tu identidad digital'),
        centerTitle: true,
        // evitamos que el usuario regrese al registro por error
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'hola, ${socio.nombre}',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'este es tu pase de acceso al gimnasio. presentalo en el escaner de recepcion.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 40),
              // generamos el codigo qr visualmente usando el token del backend
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: QrImageView(
                  // si por alguna razon viene nulo, pasamos un string vacio
                  data: socio.qrtoken ?? '',
                  version: QrVersions.auto,
                  size: 250.0,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 40),
              Text(
                'estado actual: ${socio.estado}',
                style: TextStyle(
                  fontSize: 18,
                  // cambiamos el color segun el estado que nos mande spring boot
                  color: socio.estado == 'activo' ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}