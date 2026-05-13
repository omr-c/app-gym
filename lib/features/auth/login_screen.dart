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
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _cargando = false;
  bool _oscurecerContrasena = true;

  // funcion de emergencia para limpiar la memoria local del celular y evitar sesiones fantasma
  Future<void> _forzarLimpiezaCache() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
    _mostrarMensaje("Caché y memoria local limpiadas con éxito", esError: false);
  }

  // evalua si el usuario ya esta registrado en la base de datos del gimnasio
  Future<void> _verificarEnSpringBoot(String? email, String? nombreDeGoogle) async {
    if (email == null) return;
    
    // IMPORTANTE: Verifica que esta IP siga siendo la de tu computadora
    final String url = "http://192.168.1.68:8080/api/auth/verificar/$email";

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        // el usuario ya existe en la base de datos de spring boot
        final datos = json.decode(response.body);
        datos['email'] = email;
        Socio socioCargado = Socio.fromJson(datos);

        if (socioCargado.rol == 'admin' || socioCargado.rol == 'recepcion') {
          if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ScannerScreen()));
        } else {
          if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => SocioQrScreen(socio: socioCargado)));
        }
      } else if (response.statusCode == 404) {
        // es un usuario nuevo de google, lo mandamos a completar su telefono y perfil
        if (mounted) {
          Navigator.pushReplacement(
            context, 
            MaterialPageRoute(builder: (context) => SocioRegistroScreen(emailGoogle: email, nombreGoogle: nombreDeGoogle))
          );
        }
      } else {
        _mostrarMensaje("Error del servidor: ${response.statusCode}", esError: true);
      }
    } catch (e) {
      // AQUI IMPRIMIMOS EL ERROR REAL PARA SABER QUE ESTA FALLANDO
      debugPrint("❌ ERROR DETALLADO EN LOGIN: $e");
      _mostrarMensaje("Error de conexión con el servidor del gimnasio", esError: true);
    }
  }

  // inicio de sesion rapido con google
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
        accessToken: googleAuth.accessToken, 
        idToken: googleAuth.idToken,
      );
      final UserCredential userCredential = await _auth.signInWithCredential(credencial);
      
      // enviamos el correo y el nombre que google nos dio para autocompletar el perfil
      await _verificarEnSpringBoot(userCredential.user?.email, userCredential.user?.displayName);
    } catch (e) {
      debugPrint("❌ ERROR DE GOOGLE: $e");
      _mostrarMensaje("Error al autenticar con Google", esError: true);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  // inicio de sesion manual tradicional
  Future<void> _loginConCorreo() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) return;
    setState(() => _cargando = true);
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(), 
        password: _passwordController.text.trim(),
      );
      await _verificarEnSpringBoot(userCredential.user?.email, null);
    } on FirebaseAuthException catch (e) {
      debugPrint("❌ ERROR DE FIREBASE: ${e.code}");
      _mostrarMensaje("Tus credenciales son incorrectas", esError: true);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  // envia enlace al correo para recuperar clave olvidada
  Future<void> _recuperarContrasena() async {
    String email = _emailController.text.trim();
    if (email.isEmpty) {
      _mostrarMensaje("Ingresa tu correo en el campo correspondiente", esError: true);
      return;
    }
    try {
      await _auth.sendPasswordResetEmail(email: email);
      _mostrarMensaje("Enlace enviado. Revisa tu bandeja de entrada o spam.");
    } catch (e) {
      _mostrarMensaje("No se pudo enviar el correo de recuperación", esError: true);
    }
  }

  void _mostrarMensaje(String mensaje, {bool esError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje), backgroundColor: esError ? Colors.red : Colors.green));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // boton de limpieza en la esquina para desarrollo o en caso de error
              Align(
                alignment: Alignment.topRight,
                child: IconButton(icon: const Icon(Icons.cleaning_services, color: Colors.grey), onPressed: _forzarLimpiezaCache),
              ),
              const Icon(Icons.fitness_center, size: 80, color: Colors.blueAccent),
              const SizedBox(height: 10),
              const Text("Gimnasio Rats", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),
              TextField(controller: _emailController, decoration: const InputDecoration(labelText: "Correo", border: OutlineInputBorder())),
              const SizedBox(height: 15),
              TextField(
                controller: _passwordController, 
                obscureText: _oscurecerContrasena,
                decoration: InputDecoration(
                  labelText: "Contraseña", border: const OutlineInputBorder(),
                  suffixIcon: IconButton(icon: Icon(_oscurecerContrasena ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => _oscurecerContrasena = !_oscurecerContrasena))
                )
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(onPressed: _recuperarContrasena, child: const Text("¿Olvidaste tu contraseña?"))
              ),
              const SizedBox(height: 25),
              if (_cargando) const CircularProgressIndicator()
              else ...[
                SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _loginConCorreo, child: const Text("Entrar"))),
                const SizedBox(height: 15),
                TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SocioRegistroScreen())),
                  child: const Text("¿Eres nuevo? Regístrate aquí")
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity, height: 50, 
                  child: OutlinedButton.icon(
                    onPressed: _loginConGoogle, 
                    icon: Image.network('https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/120px-Google_%22G%22_logo.svg.png', height: 24),
                    label: const Text("Continuar con Google")
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