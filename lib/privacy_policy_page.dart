import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

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
        title: const Text('Privacy policy', style: TextStyle(color: Colors.white)),
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
        child: const SingleChildScrollView(
          child: Text(
            'Privacy policy placeholder.\n\nThis app collects minimal user information for authentication and booking. Replace this text with your real privacy policy content.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
