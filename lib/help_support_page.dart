import 'package:flutter/material.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

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
        title: const Text('Help & support', style: TextStyle(color: Colors.white)),
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
            const Text('FAQs', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: const [
                  ListTile(
                    title: Text('How do I book a slot?', style: TextStyle(color: Colors.white)),
                    subtitle: Text('Open Book > choose slot > pay.', style: TextStyle(color: Colors.white70)),
                  ),
                  ListTile(
                    title: Text('Payment methods', style: TextStyle(color: Colors.white)),
                    subtitle: Text('Razorpay via card/UPI/netbanking.', style: TextStyle(color: Colors.white70)),
                  ),
                  ListTile(
                    title: Text('Contact support', style: TextStyle(color: Colors.white)),
                    subtitle: Text('support@example.com', style: TextStyle(color: Colors.white70)),
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
