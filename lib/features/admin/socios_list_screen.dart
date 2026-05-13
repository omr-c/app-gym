import 'package:flutter/material.dart';
import 'admin_service.dart'; // Importa el servicio que creamos
import '../socio/socio_model.dart'; // Sube un nivel y entra a socio

class SociosListScreen extends StatefulWidget {
  const SociosListScreen({super.key});

  @override
  State<SociosListScreen> createState() => _SociosListScreenState();
}

class _SociosListScreenState extends State<SociosListScreen> {
  final AdminService _adminService = AdminService();
  late Future<List<SocioModel>> _futureSocios;

  @override
  void initState() {
    super.initState();
    // Llamamos al backend al iniciar la pantalla
    _futureSocios = _adminService.getAllSocios();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Lista de Socios", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.orange),
            onPressed: () {
              setState(() {
                _futureSocios = _adminService.getAllSocios();
              });
            },
          )
        ],
      ),
      body: FutureBuilder<List<SocioModel>>(
        future: _futureSocios,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.orange));
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.white)));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No hay socios registrados", style: TextStyle(color: Colors.white)));
          }

          final socios = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: socios.length,
            itemBuilder: (context, index) {
              final socio = socios[index];
              
              // Lógica de colores según el estado que viene del Back
              Color colorEstado = socio.estado.toLowerCase() == 'activo' ? Colors.green : Colors.red;

              return Card(
                color: Colors.grey[900],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.orange,
                    backgroundImage: socio.fotoUrl.isNotEmpty ? NetworkImage(socio.fotoUrl) : null,
                    child: socio.fotoUrl.isEmpty 
                        ? Text(socio.nombre[0].toUpperCase(), style: const TextStyle(color: Colors.white)) 
                        : null,
                  ),
                  title: Text(
                    socio.nombre,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "Días restantes: ${socio.diasRestantes}",
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: colorEstado.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: colorEstado),
                    ),
                    child: Text(
                      socio.estado.toUpperCase(),
                      style: TextStyle(color: colorEstado, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  onTap: () {
                    // Aquí podrías abrir el perfil detallado del socio
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}