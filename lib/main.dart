import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
// importamos la nueva pantalla de login que crearemos abajo
import 'features/auth/login_screen.dart'; 

void main() async {
  // es obligatorio asegurar que flutter este listo antes de llamar a firebase
  WidgetsFlutterBinding.ensureInitialized();
  
  // inicializamos la conexion con tu proyecto de google
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const GymApp());
}

class GymApp extends StatelessWidget {
  const GymApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'gym system unificado',
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.blue,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
      ),
      // ahora el arranque es nuestra pantalla de login
      home: const LoginScreen(),
    );
  }
}