import 'package:flutter/material.dart';

import 'features/recepcion/scanner_screen.dart';
import 'features/recepcion/dashboard_screen.dart';

void main() {
  runApp(const GymApp());
}

class GymApp extends StatelessWidget {
  const GymApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gym System - Alexis',
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.blue,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
      ),
      home: const MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  // Índice para saber qué pestaña está seleccionada
  int _selectedIndex = 0;

  // Lista de las pantallas principales del proyecto
  final List<Widget> _screens = [
    const ScannerScreen(),    // Posición 0: Tu módulo de Recepción
    const DashboardScreen(),  // Posición 1: Tu nuevo módulo de Gráficas
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // El body cambia automáticamente según el índice seleccionado
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      
      // La barra de navegación inferior (BottomNavigationBar)
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner_rounded),
            label: 'Recepción',
            tooltip: 'Escanear Socios',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insights_rounded),
            label: 'Dashboard',
            tooltip: 'Estadísticas Reales',
          ),
        ],
      ),
    );
  }
}