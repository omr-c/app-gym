import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'socio_model.dart';
import 'socio_api_service.dart';
import 'socio_qr_screen.dart';

class SocioRegistroScreen extends StatefulWidget {
  final String? emailPrellenado;
  const SocioRegistroScreen({super.key, this.emailPrellenado});

  @override
  _SocioRegistroScreenState createState() => _SocioRegistroScreenState();
}

class _SocioRegistroScreenState extends State<SocioRegistroScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmarController = TextEditingController();

  bool _cargando = false;
  bool _oscurecerContrasena = true;
  bool _oscurecerConfirmar = true;
  
  final SocioApiService _apiService = SocioApiService();

  @override
  void initState() {
    super.initState();
    if (widget.emailPrellenado != null) {
      _emailController.text = widget.emailPrellenado!;
    }
  }

  void _registrar() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_passwordController.text != _confirmarController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Las contraseñas no coinciden')),
      );
      return;
    }

    setState(() => _cargando = true);

    User? user;
    try {
      // 1. Registro en Firebase
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      user = userCredential.user;

      if (user != null) {
        // 2. Preparar datos para Spring Boot
        SocioModel nuevoSocio = SocioModel(
          nombre: _nombreController.text.trim(),
          telefono: _telefonoController.text.trim(),
          email: _emailController.text.trim(),
          estado: 'pendiente', // Por defecto inicia pendiente de pago
          rol: 'socio',
        );

        // 3. Registro en Backend Java
        final resultado = await _apiService.registrarSocio(nuevoSocio);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('¡Registro exitoso! Pasa a recepción para activar tu cuenta.')),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => SocioQrScreen(socio: resultado)),
          );
        }
      }
    } catch (e) {
      print("ERROR DETECTADO: $e");
      // Si el usuario se creó en Firebase pero falló en Java, lo borramos para no dejar basura
      if (user != null) {
        await user.delete();
      }
      
      if (mounted) {
        String mensajeError = e.toString().contains('already-in-use') 
          ? 'Este correo ya está registrado.' 
          : 'Error en el servidor. Intenta de nuevo.';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mensajeError)),
        );

        // 2. intentar registrar en spring boot (aqui se valida el telefono)
        Socio? socioRegistrado = await _apiService.registrarsocio(nuevoSocio);
        
        if (socioRegistrado == null) {
          // si el api devuelve null, probablemente el telefono o email ya existen
          if (mounted) setState(() => _cargando = false);
          _mostrarMensaje('El teléfono o correo ya están registrados en el gimnasio');
          return;
        }

        // 3. si el backend acepto al socio, creamos la cuenta en firebase auth
        if (widget.emailPrellenado == null) {
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );
        }

        if (mounted) {
          setState(() => _cargando = false);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => SocioQrScreen(socio: socioRegistrado))
          );
        }
      } on FirebaseAuthException catch (e) {
        if (mounted) setState(() => _cargando = false);
        _mostrarMensaje(e.code == 'email-already-in-use' 
            ? 'Este correo ya esta registrado' 
            : 'Error en la cuenta: ${e.message}');
      } catch (e) {
        if (mounted) setState(() => _cargando = false);
        _mostrarMensaje('Error inesperado durante el registro');
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Registro de Socio', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Icon(Icons.person_add_alt_1, size: 80, color: Colors.orange),
              const SizedBox(height: 20),
              _buildTextField(_nombreController, 'Nombre Completo', Icons.person),
              const SizedBox(height: 15),
              _buildTextField(_telefonoController, 'Teléfono', Icons.phone, keyboardType: TextInputType.phone),
              const SizedBox(height: 15),
              _buildTextField(_emailController, 'Correo Electrónico', Icons.email, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 15),
              _buildPasswordField(_passwordController, 'Contraseña', _oscurecerContrasena, () {
                setState(() => _oscurecerContrasena = !_oscurecerContrasena);
              }),
              const SizedBox(height: 15),
              _buildPasswordField(_confirmarController, 'Confirmar Contraseña', _oscurecerConfirmar, () {
                setState(() => _oscurecerConfirmar = !_oscurecerConfirmar);
              }),
              const SizedBox(height: 30),
              if (_cargando) 
                const CircularProgressIndicator(color: Colors.orange)
              else 
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                    ),
                    onPressed: _registrar,
                    child: const Text('CREAR CUENTA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: Colors.orange),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.grey)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.orange)),
      ),
      validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
    );
  }

  Widget _buildPasswordField(TextEditingController controller, String label, bool obscure, VoidCallback toggle) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: const Icon(Icons.lock, color: Colors.orange),
        suffixIcon: IconButton(icon: Icon(obscure ? Icons.visibility : Icons.visibility_off, color: Colors.grey), onPressed: toggle),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.grey)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.orange)),
      ),
      validator: (value) => value!.length < 6 ? 'Mínimo 6 caracteres' : null,
    );
  }
}