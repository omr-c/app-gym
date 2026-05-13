import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Asegúrate de que estas rutas sean correctas según tu estructura de carpetas
import '../socio/socio_registro_screen.dart';
import '../socio/socio_qr_screen.dart';
import '../socio/socio_model.dart'; 
import '../admin/admin_main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // CORRECCIÓN: Configuración de GoogleSignIn con scopes necesarios
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
  );

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  // Tu IP local configurada
  final String ip = "192.168.1.127";
  bool _cargando = false;

  Future<void> _verificarEnSpringBoot(String? email) async {
    if (email == null) return;
    
    // Endpoint actualizado en tu Backend
    final String url = "http://$ip:8080/api/socios/perfil-por-email?email=$email";

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(response.body);
        
        // IMPORTANTE: Asegúrate de que tu clase en socio_model.dart se llame 'Socio'
        // Si se llama 'SocioModel', cambia la siguiente línea a: final socioCargado = SocioModel.fromJson(jsonData);
        final socioCargado = SocioModel.fromJson(jsonData);

        if (mounted) {
          // Limpiamos el rol recibido para evitar errores de espacios o mayúsculas
          String rol = socioCargado.rol.toLowerCase().trim();

          // DEBUG para que veas en la consola qué está llegando realmente
          print("DEBUG: Rol detectado -> '$rol'");

          if (rol == 'admin' || rol == 'recepcion') {
            // SI ES ADMIN -> Va al Dashboard Principal
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const AdminMainScreen()),
              (route) => false,
            );
          } else {
            // SI ES CLIENTE -> Va a su pantalla de QR
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => SocioQrScreen(socio: socioCargado)),
              (route) => false,
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Usuario no encontrado en la base de datos del gimnasio")),
          );
        }
        await _auth.signOut();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error de conexión: $e")),
        );
      }
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Correo o contraseña incorrectos")),
        );
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _loginConGoogle() async {
    setState(() => _cargando = true);
    try {
      // Iniciar flujo de Google Sign-In[cite: 1]
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        setState(() => _cargando = false);
        return;
      }

      // Obtener tokens de autenticación[cite: 1]
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
<<<<<<< Updated upstream
      
      // Crear credencial para Firebase[cite: 1]
      final AuthCredential credencial = GoogleAuthProvider.credential(
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
>>>>>>> Stashed changes
      await _verificarEnSpringBoot(userCredential.user?.email);
      
    } catch (e) {
      debugPrint("Error Google Sign-In: $e");
      _mostrarError("Error al autenticar con Google");
=======
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error al iniciar sesión con Google")),
        );
      }
>>>>>>> Stashed changes
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

              const Icon(Icons.fitness_center, size: 90, color: Colors.orange),
              const SizedBox(height: 10),
              const Text(
                "GYM SYSTEM",
                style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _emailController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Correo Electrónico",
                  labelStyle: TextStyle(color: Colors.grey),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.orange)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.orange, width: 2)),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                obscureText: _oscurecerContrasena,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Contraseña",
                  labelStyle: const TextStyle(color: Colors.grey),
                  enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.orange)),
                  focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.orange, width: 2)),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _oscurecerContrasena ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () => setState(() => _oscurecerContrasena = !_oscurecerContrasena),
                  ),
                ),
              ),
              const SizedBox(height: 50),
              if (_cargando)
                const CircularProgressIndicator(color: Colors.orange)
              else ...[
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _loginConCorreo,
                    child: const Text("INICIAR SESIÓN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white54),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _loginConGoogle,
                  icon: const Icon(Icons.login, color: Colors.white),
                  label: const Text("Continuar con Google", style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const SocioRegistroScreen()));
                  },
                  child: const Text("¿No tienes cuenta? Regístrate aquí", style: TextStyle(color: Colors.orangeAccent)),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}