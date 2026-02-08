import 'package:flutter/material.dart';

class MyVehiclesPage extends StatelessWidget {
  const MyVehiclesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF300000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF300000),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pushReplacementNamed(context, '/profile'),
        ),
        title: const Text('My vehicle', style: TextStyle(color: Colors.white)),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFF0000), Color(0xFF300000)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Saved Vehicles', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: [
                  Card(
                    color: const Color(0xFF2C2C2C),
                    child: ListTile(
                      leading: const Icon(Icons.directions_car, color: Colors.white),
                      title: const Text('No vehicles added', style: TextStyle(color: Colors.white70)),
                      subtitle: const Text('Tap + to add a vehicle', style: TextStyle(color: Colors.white38)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.add),
                    label: const Text('Add Vehicle'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB00000),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
