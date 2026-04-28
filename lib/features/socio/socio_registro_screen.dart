import 'package:flutter/material.dart';
import 'socio_model.dart';
import 'socio_api_service.dart';
import 'socio_qr_screen.dart';

// pantalla visual con el formulario de autoregistro para el socio
class SocioRegistroScreen extends StatefulWidget {
  @override
  _SocioRegistroScreenState createState() => _SocioRegistroScreenState();
}

class _SocioRegistroScreenState extends State<SocioRegistroScreen> {
  // llave para validar el estado del formulario
  final _formKey = GlobalKey<FormState>();
  
  // controladores para capturar el texto que escribe el usuario
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  
  // variable para mostrar un indicador de carga mientras el backend responde
  bool _cargando = false;
  
  // instanciamos el servicio que creamos antes
  final SocioApiService _apiService = SocioApiService();

  // funcion que se ejecuta al presionar el boton
  void _registrar() async {
    // validamos que los campos no esten vacios
    if (_formKey.currentState!.validate()) {
      setState(() {
        _cargando = true;
      });

      // armamos el objeto socio con lo que escribio el usuario
      Socio nuevoSocio = Socio(
        nombre: _nombreController.text,
        telefono: _telefonoController.text,
        email: _emailController.text,
      );

      // disparamos la peticion http hacia spring boot
      Socio? socioRegistrado = await _apiService.registrarsocio(nuevoSocio);

      setState(() {
        _cargando = false;
      });

      // evaluamos si el backend nos devolvio el socio ya creado (con su qrtoken)
      if (socioRegistrado != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('registro exitoso. bienvenido ${socioRegistrado.nombre}!')),
        );
        
        // navegamos a la pantalla del qr y reemplazamos la vista actual 
        // para que no pueda regresar al formulario presionando "atras"
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SocioQrScreen(socio: socioRegistrado),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('hubo un error de conexion. intenta de nuevo.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('unete al gimnasio'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'nombre completo',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? 'por favor ingresa tu nombre' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _telefonoController,
                decoration: const InputDecoration(
                  labelText: 'telefono',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) => value!.isEmpty ? 'por favor ingresa tu telefono' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'correo electronico',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) => value!.isEmpty ? 'por favor ingresa un correo' : null,
              ),
              const SizedBox(height: 30),
              // si esta cargando muestra la rueda, si no, muestra el boton
              _cargando
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _registrar,
                        child: const Text('crear identidad digital', style: TextStyle(fontSize: 18)),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}