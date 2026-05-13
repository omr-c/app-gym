import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../recepcion/dashboard_screen.dart';
import '../recepcion/scanner_screen.dart';
import 'socios_list_screen.dart';
import 'pagos_dashboard_screen.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _selectedIndex = 0;

  // Lista de páginas vinculadas a la navegación
  final List<Widget> _pages = [
    const DashboardScreen(),     // Índice 0: Inicio
    const SociosListScreen(),    // Índice 1: Socios
    const ScannerScreen(),       // Índice 2: Escáner (Botón Central)
    const PagosDashboardScreen(), // Índice 3: Pagos
    const Center(child: Text("Ajustes", style: TextStyle(color: Colors.white))), // Índice 4
  ];

  void _onItemTapped(int index) {
    HapticFeedback.mediumImpact(); // Vibración al tocar
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.black,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home_filled, "Inicio", 0),
              _buildNavItem(Icons.people_alt_outlined, "Socios", 1),
              const SizedBox(width: 40), // Espacio para el FloatingActionButton
              _buildNavItem(Icons.monetization_on_outlined, "Pagos", 3),
              _buildNavItem(Icons.settings_outlined, "Ajustes", 4),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        shape: const CircleBorder(),
        onPressed: () => _onItemTapped(2), // Llama al escáner
        child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 30),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isSelected ? Colors.orange : Colors.white, size: 26),
          Text(label, style: TextStyle(color: isSelected ? Colors.orange : Colors.white, fontSize: 10)),
        ],
      ),
    );
  }
}