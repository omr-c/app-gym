import 'package:flutter/material.dart';
// importamos la pantalla de registro que acabas de crear
import 'features/socio/socio_registro_screen.dart';

void main() {
  runApp(const MyApp());
}

// clase principal que arranca la aplicacion del gimnasio
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'smart gym manager',
      // quitamos la etiqueta roja de debug de la esquina
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // definimos un color base para la app
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // configuramos tu pantalla de registro como la vista inicial
      home: SocioRegistroScreen(),
    );
  }
}