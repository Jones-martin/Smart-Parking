import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';

class AppSettingsPage extends StatelessWidget {
  const AppSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF300000),
      appBar: AppBar(
        backgroundColor: const Color(0xFFB00000),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pushReplacementNamed(context, '/profile'),
        ),
        title: const Text('App Settings',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFB00000), Color(0xFF300000)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Theme Toggle ─────────────────────────────────────────
            _sectionHeader('Appearance'),
            _card(
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: Icon(
                  themeProvider.isDark
                      ? Icons.dark_mode
                      : Icons.light_mode,
                  color: themeProvider.isDark
                      ? Colors.amber
                      : Colors.yellow.shade700,
                ),
                title: Text(
                  themeProvider.isDark ? 'Dark Mode' : 'Light Mode',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w500),
                ),
                subtitle: const Text('Toggle app theme',
                    style: TextStyle(color: Colors.white54, fontSize: 12)),
                activeColor: Colors.amber,
                value: themeProvider.isDark,
                onChanged: (_) => themeProvider.toggle(),
              ),
            ),

            const SizedBox(height: 20),

            // ── Notifications ─────────────────────────────────────────
            _sectionHeader('Notifications'),
            _card(
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary:
                    const Icon(Icons.notifications_active, color: Colors.redAccent),
                title: const Text('Booking Notifications',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w500)),
                subtitle: const Text('Alerts for booking confirmation & reminders',
                    style: TextStyle(color: Colors.white54, fontSize: 12)),
                activeColor: Colors.redAccent,
                value: true,
                onChanged: (v) {},
              ),
            ),

            const SizedBox(height: 20),

            // ── About ──────────────────────────────────────────────────
            _sectionHeader('About'),
            _card(
              child: Column(
                children: [
                  _infoTile(Icons.language, 'Language', 'English'),
                  const Divider(color: Colors.white12),
                  _infoTile(Icons.info_outline, 'App Version', '1.0.0'),
                  const Divider(color: Colors.white12),
                  _infoTile(Icons.code, 'Built with', 'Flutter + Firebase'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title.toUpperCase(),
          style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2)),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: child,
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(width: 14),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
        const Spacer(),
        Text(value, style: const TextStyle(color: Colors.white54, fontSize: 13)),
      ]),
    );
  }
}
