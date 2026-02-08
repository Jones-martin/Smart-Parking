import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);

    switch (index) {
      case 1:
        Navigator.pushNamed(context, '/booking');
        break;
      case 2:
        Navigator.pushNamed(context, '/profile');
        break;
    }
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> _getUserDoc() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No user logged in');
    return FirebaseFirestore.instance.collection('users').doc(user.uid).get();
  }

  String _formatUsername(String email) {
    if (!email.contains('@')) return _capitalize(email);
    String name = email.split('@')[0].replaceAll('.', ' ').replaceAll('_', ' ');
    return name.split(' ').map(_capitalize).join(' ');
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    // Make status bar icons light and status bar transparent
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ));

    // include the status bar inset + appbar height so content starts below the AppBar
    final topInset = MediaQuery.of(context).padding.top;
    const double toolbarHeight = kToolbarHeight; // default AppBar height (56)
    final double topPadding = topInset + toolbarHeight + 8.0; // +8 for breathing room

    return Scaffold(
      extendBodyBehindAppBar: true, // allow gradient behind status bar
      backgroundColor: Colors.transparent,

      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: toolbarHeight,
        title: const Text(
          'Smart Parking',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () {},
          ),
        ],
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),

      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFB00000), // top red
              Color(0xFF7A0000), // mid
              Colors.black,      // bottom
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),

        // <-- IMPORTANT: use topPadding that includes status bar + AppBar height
        padding: EdgeInsets.fromLTRB(20, topPadding, 20, 20),

        child: SafeArea(
          top: false, // we've already accounted for top area above
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top section: name and edit button
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                        future: _getUserDoc(),
                        builder: (context, snapshot) {
                          String display = 'Customer';
                          String email = '';
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text("Welcome Back 👋",
                                    style: TextStyle(color: Colors.white70, fontSize: 16)),
                                SizedBox(height: 6),
                                Text("Loading...",
                                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                              ],
                            );
                          }
                          final user = FirebaseAuth.instance.currentUser;
                          email = (snapshot.hasData && snapshot.data!.exists)
                              ? (snapshot.data!.data()?['email'] as String? ?? user?.email ?? '')
                              : (user?.email ?? '');
                          display = _formatUsername(email);
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Welcome Back 👋",
                                  style: TextStyle(color: Colors.white70, fontSize: 16)),
                              const SizedBox(height: 6),
                              Text(display,
                                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(email, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                            ],
                          );
                        },
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, '/profile'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      child: const Text("Edit Profile"),
                    ),
                  ],
                ),

                const SizedBox(height: 18),
                const Divider(color: Colors.white24),
                const SizedBox(height: 18),
                const Text("Find your", style: TextStyle(color: Colors.white70, fontSize: 18)),
                const Text("Parking Space", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 18),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2C2C),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: const TextField(
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search space...',
                      hintStyle: TextStyle(color: Colors.white54),
                      border: InputBorder.none,
                      icon: Icon(Icons.search, color: Colors.white70),
                    ),
                  ),
                ),
                const SizedBox(height: 26),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: const [
                    VehicleButton(icon: Icons.directions_car, label: 'Car'),
                    VehicleButton(icon: Icons.two_wheeler, label: 'Bike'),
                    VehicleButton(icon: Icons.directions_bus, label: 'Van'),
                  ],
                ),
                const SizedBox(height: 36),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text("Nearby parking spots will appear here.", style: TextStyle(color: Colors.white70)),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF2C2C2C),
        selectedItemColor: Colors.redAccent,
        unselectedItemColor: Colors.white70,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.local_parking), label: 'Book'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Profile'),
        ],
      ),
    );
  }
}

class VehicleButton extends StatelessWidget {
  final IconData icon;
  final String label;
  const VehicleButton({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: const Color(0xFF2C2C2C),
          radius: 30,
          child: Icon(icon, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white)),
      ],
    );
  }
}
