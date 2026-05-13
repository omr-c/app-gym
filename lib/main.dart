import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'features/auth/login_screen.dart'; 
import 'features/socio/socio_model.dart';
import 'features/socio/socio_qr_screen.dart';
import 'features/admin/admin_main_screen.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const GymApp());
}

class GymApp extends StatelessWidget {
  const GymApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gym Rats App',
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.orange,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final String ip = "192.168.1.127";

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. Cargando estado de Firebase
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        // 2. Si hay un usuario logueado en Firebase
        if (snapshot.hasData && snapshot.data != null) {
          return FutureBuilder<SocioModel?>(
            future: _obtenerPerfil(snapshot.data!.email!),
            builder: (context, socioSnap) {
              if (socioSnap.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  backgroundColor: Colors.black,
                  body: Center(child: CircularProgressIndicator(color: Colors.orange)),
                );
              }

              if (socioSnap.hasData && socioSnap.data != null) {
                final socio = socioSnap.data!;
                // Redirección por ROL
                if (socio.rol == 'admin' || socio.rol == 'recepcion') {
                  return const AdminMainScreen();
                } else {
                  return SocioQrScreen(socio: socio);
                }
              }

              // Si falla al obtener perfil de Java, cerramos sesión
              return const LoginScreen();
            },
          );
        }
        
        // 3. Si no hay sesión, al Login
        return const LoginScreen();
      },
    );
  }

  Future<SocioModel?> _obtenerPerfil(String email) async {
    try {
      final response = await http.get(
        Uri.parse('http://$ip:8080/api/socios/perfil-por-email?email=$email'),
      );

      if (response.statusCode == 200) {
        return SocioModel.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      debugPrint("Error al obtener perfil: $e");
    }
    return null;
  }
}