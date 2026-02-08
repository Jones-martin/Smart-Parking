import 'package:flutter/material.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

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
        title: const Text('Terms and conditions', style: TextStyle(color: Colors.white)),
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
            'Terms and conditions placeholder.\n\nReplace with your app terms. Users must agree to these before booking.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
