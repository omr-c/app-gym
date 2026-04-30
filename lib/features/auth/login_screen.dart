import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../socio/socio_registro_screen.dart';
import '../socio/socio_qr_screen.dart';
import '../socio/socio_model.dart';
import '../recepcion/scanner_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _cargando = false;

  Future<void> _verificarEnSpringBoot(String? email) async {
    if (email == null) return;
    // recordatorio: la ip debe ser la de tu maquina local[cite: 16]
    final String url = "http://192.168.1.68:8080/api/auth/verificar/$email";

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final datos = json.decode(response.body);
        Socio socioCargado = Socio.fromJson(datos);

        // CORRECCION: comparacion en minisculas para coincidir con el backend
        if (socioCargado.rol == 'admin' || socioCargado.rol == 'recepcion') {
          debugPrint("rol detectado: ${socioCargado.rol}. redirigiendo a recepcion.");
          if (mounted) {
            Navigator.pushReplacement(
              context, 
              MaterialPageRoute(builder: (context) => const ScannerScreen())
            );
          }
        } else {
          debugPrint("rol detectado: socio. redirigiendo a identidad digital.");
          if (mounted) {
            Navigator.pushReplacement(
              context, 
              MaterialPageRoute(builder: (context) => SocioQrScreen(socio: socioCargado))
            );
          }
        }
      } else if (response.statusCode == 404) {
        if (mounted) {
          Navigator.pushReplacement(
            context, 
            MaterialPageRoute(builder: (context) => SocioRegistroScreen(emailPrellenado: email))
          );
        }
      }
    } catch (e) {
      _mostrarError("error de conexion con el servidor: $e");
    }
  }

  // ... logica de login con google y correo se mantiene igual
  Future<void> _loginConGoogle() async {
    setState(() => _cargando = true);
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => _cargando = false);
        return; 
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credencial = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken, idToken: googleAuth.idToken,
      );
      final UserCredential userCredential = await _auth.signInWithCredential(credencial);
      await _verificarEnSpringBoot(userCredential.user?.email);
    } catch (e) {
      _mostrarError("error al autenticar con google");
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _loginConCorreo() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) return;
    setState(() => _cargando = true);
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(), 
        password: _passwordController.text.trim(),
      );
      await _verificarEnSpringBoot(userCredential.user?.email);
    } catch (e) {
      _mostrarError("correo o contraseña invalidos");
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.red)
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Icon(Icons.fitness_center, size: 80, color: Colors.blueAccent),
              const SizedBox(height: 20),
              const Text("SMART GYM", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),
              TextField(
                controller: _emailController, 
                decoration: const InputDecoration(labelText: "correo", border: OutlineInputBorder())
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _passwordController, 
                decoration: const InputDecoration(labelText: "contraseña", border: OutlineInputBorder()), 
                obscureText: true
              ),
              const SizedBox(height: 25),
              if (_cargando) const CircularProgressIndicator()
              else ...[
                SizedBox(
                  width: double.infinity, 
                  height: 50, 
                  child: ElevatedButton(onPressed: _loginConCorreo, child: const Text("entrar"))
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity, 
                  height: 50, 
                  child: OutlinedButton.icon(
                    onPressed: _loginConGoogle,
                    icon: Image.network('https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/120px-Google_%22G%22_logo.svg.png', height: 24),
                    label: const Text("continuar con google"),
                  )
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}