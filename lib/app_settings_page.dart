import 'package:flutter/material.dart';

class AppSettingsPage extends StatelessWidget {
  const AppSettingsPage({super.key});

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
        title: const Text('App settings', style: TextStyle(color: Colors.white)),
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
        child: ListView(
          children: [
            SwitchListTile(
              activeThumbColor: Colors.redAccent,
              title: const Text('Enable notifications', style: TextStyle(color: Colors.white)),
              value: true,
              onChanged: (v) {},
            ),
            ListTile(
              leading: const Icon(Icons.language, color: Colors.white70),
              title: const Text('Language', style: TextStyle(color: Colors.white)),
              subtitle: const Text('English', style: TextStyle(color: Colors.white70)),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.white70),
              title: const Text('App version', style: TextStyle(color: Colors.white)),
              subtitle: const Text('1.0.0', style: TextStyle(color: Colors.white70)),
            ),
          ],
        ),
      ),
    );
  }
}
