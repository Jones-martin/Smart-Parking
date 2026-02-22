import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Settings extends StatelessWidget {
  const Settings({super.key});

  Future<Map<String, String>> _fetchUserDetails() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {"name": "Guest", "email": ""};

    final email = user.email ?? "";
    final uid = user.uid;

    // Fetch from Firestore
    final doc = await FirebaseFirestore.instance.collection("users").doc(uid).get();

    String displayName = "";
    if (doc.exists && doc.data()!.containsKey("displayName")) {
      displayName = doc["displayName"] ?? "";
    }

    // If Firestore name missing, use email formatted
    if (displayName.trim().isEmpty) {
      displayName = _formatUsernameFromEmail(email);
    }

    return {"name": displayName, "email": email};
  }

  // Convert "ram.kumar123" → "Ram Kumar123"
  static String _formatUsernameFromEmail(String email) {
    if (!email.contains('@')) return email;

    String namePart = email.split('@')[0];
    namePart = namePart.replaceAll('.', ' ').replaceAll('_', ' ');

    List<String> words = namePart.split(' ');
    words = words.map((w) {
      if (w.isEmpty) return "";
      return w[0].toUpperCase() + (w.length > 1 ? w.substring(1) : '');
    }).toList();

    return words.join(' ').trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      // -------------------- BOTTOM NAV --------------------
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF2C2C2C), // Match Home Page color if slightly different, or keep black if preferred. Home uses 0xFF2C2C2C. Settings used Colors.black. I will switch to 0xFF2C2C2C for consistency.
        selectedItemColor: Colors.redAccent,
        unselectedItemColor: Colors.white70,
        type: BottomNavigationBarType.fixed,
        currentIndex: 2, // Profile is now index 2
        onTap: (index) {
          if (index == 0) Navigator.pushNamed(context, '/home');
          if (index == 1) Navigator.pushNamed(context, '/map');
          // index 2 is current page
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.local_parking), label: 'Book'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Profile'),
        ],
      ),

      // -------------------- BODY --------------------
      body: FutureBuilder<Map<String, String>>(
        future: _fetchUserDetails(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }

          final name = snapshot.data!["name"] ?? "";
          final email = snapshot.data!["email"] ?? "";

          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFB00000), Colors.black],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // -------------------- TITLE --------------------
                const Text(
                  "Profile",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 20),

                // -------------------- USER INFO --------------------
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold),
                        ),
                        Text(
                          email,
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),

                    ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Edit Profile feature coming soon!")),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        "Edit Profile",
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),
                const Divider(color: Colors.white24),
                const SizedBox(height: 10),

                // -------------------- MENU ITEMS --------------------

                _menu(context, Icons.account_balance_wallet, "Wallet", "/wallet"),
                _menu(context, Icons.list_alt, "My Bookings", "/my_bookings"),
                _menu(context, Icons.directions_car, "My vehicle", "/my_vehicles"),
                _menu(context, Icons.help_outline, "Help & support", "/help"),
                _menu(context, Icons.lock_outline, "Privacy policy", "/privacy"),
                _menu(context, Icons.admin_panel_settings_outlined, "Admin Panel", "/admin"),
                _menu(context, Icons.settings_outlined, "App settings", "/app_settings"),

                const Spacer(),

                // -------------------- LOGOUT --------------------
                GestureDetector(
                  onTap: () {
                    FirebaseAuth.instance.signOut();
                    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                  },
                  child: Row(
                    children: const [
                      Icon(Icons.logout, color: Colors.redAccent),
                      SizedBox(width: 10),
                      Text(
                        "Logout",
                        style: TextStyle(color: Colors.redAccent, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // -------------------- MENU ITEM WIDGET --------------------
  Widget _menu(BuildContext context, IconData icon, String title, String route) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
