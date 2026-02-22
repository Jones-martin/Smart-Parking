import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final _firestore = FirebaseFirestore.instance;
  final _slotsRef = FirebaseFirestore.instance
      .collection('parking_slots')
      .doc('main_lot');

  bool _isAdmin = false;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _checkAdmin();
  }

  Future<void> _checkAdmin() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {setState(() => _checking = false); return;}
    final doc = await _firestore.collection('users').doc(uid).get();
    setState(() {
      _isAdmin = doc.data()?['role'] == 'admin';
      _checking = false;
    });
  }

  Future<void> _updateSlots(int total, int available) async {
    await _slotsRef.set({
      'total': total,
      'available': available,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Slots updated!'), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.redAccent)),
      );
    }
    if (!_isAdmin) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: const Color(0xFFB00000),
          foregroundColor: Colors.white,
          title: const Text('Admin Panel'),
        ),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock, color: Colors.white38, size: 64),
              SizedBox(height: 16),
              Text('Access Denied',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('You need admin privileges.',
                  style: TextStyle(color: Colors.white54)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFFB00000),
        foregroundColor: Colors.white,
        title: const Text('Admin Dashboard',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF3A0000), Colors.black],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Slot Management ──
              const Text('Parking Slot Management',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              StreamBuilder<DocumentSnapshot>(
                stream: _slotsRef.snapshots(),
                builder: (context, snap) {
                  int total = 50;
                  int available = 20;
                  if (snap.hasData && snap.data!.exists) {
                    final d = snap.data!.data() as Map<String, dynamic>;
                    total = (d['total'] as num?)?.toInt() ?? 50;
                    available = (d['available'] as num?)?.toInt() ?? 20;
                  }
                  return _SlotEditor(
                      total: total,
                      available: available,
                      onSave: _updateSlots);
                },
              ),

              const SizedBox(height: 24),

              // ── Stats ──
              const Text('Today\'s Stats',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _TodayStats(firestore: _firestore),

              const SizedBox(height: 24),

              // ── Recent Bookings ──
              const Text('Recent Bookings',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _RecentBookings(firestore: _firestore),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _SlotEditor extends StatefulWidget {
  final int total;
  final int available;
  final Future<void> Function(int, int) onSave;
  const _SlotEditor(
      {required this.total, required this.available, required this.onSave});

  @override
  State<_SlotEditor> createState() => _SlotEditorState();
}

class _SlotEditorState extends State<_SlotEditor> {
  late int _total;
  late int _available;

  @override
  void initState() {
    super.initState();
    _total = widget.total;
    _available = widget.available;
  }

  @override
  Widget build(BuildContext context) {
    final pct = _total > 0 ? _available / _total : 0.0;
    final color = pct > 0.5
        ? Colors.greenAccent
        : pct > 0.2
            ? Colors.amber
            : Colors.redAccent;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFB00000).withOpacity(0.4)),
      ),
      child: Column(children: [
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              LinearProgressIndicator(
                value: pct,
                backgroundColor: Colors.white12,
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 10,
                borderRadius: BorderRadius.circular(5),
              ),
              const SizedBox(height: 8),
              Text('$_available / $_total slots available',
                  style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            ]),
          ),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          _counter('Total', _total,
              onDec: () => setState(() => _total = (_total - 1).clamp(0, 999)),
              onInc: () => setState(() => _total++)),
          const SizedBox(width: 16),
          _counter('Available', _available,
              onDec: () => setState(
                  () => _available = (_available - 1).clamp(0, _total)),
              onInc: () => setState(
                  () => _available = (_available + 1).clamp(0, _total))),
        ]),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => widget.onSave(_total, _available),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
            ),
            child: const Text('Save Changes',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ]),
    );
  }

  Widget _counter(String label, int val,
      {required VoidCallback onDec, required VoidCallback onInc}) {
    return Expanded(
      child: Column(children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          IconButton(
              onPressed: onDec,
              icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent)),
          Text('$val',
              style: const TextStyle(
                  color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          IconButton(
              onPressed: onInc,
              icon: const Icon(Icons.add_circle_outline, color: Colors.greenAccent)),
        ]),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _TodayStats extends StatelessWidget {
  final FirebaseFirestore firestore;
  const _TodayStats({required this.firestore});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);

    return StreamBuilder<AggregateQuerySnapshot>(
      stream: Stream.fromFuture(
        firestore
            .collectionGroup('records')
            .where('bookingDateTime',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
            .count()
            .get(),
      ),
      builder: (context, snap) {
        final count = snap.data?.count ?? 0;
        return Row(children: [
          _statCard('Today\'s\nBookings', '$count', Icons.book_online,
              Colors.blueAccent),
          const SizedBox(width: 12),
          _statCard('Revenue\nEstimate',
              '₹${(count * 50).toStringAsFixed(0)}', Icons.currency_rupee,
              Colors.greenAccent),
        ]);
      },
    );
  }

  Widget _statCard(
      String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 10),
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _RecentBookings extends StatelessWidget {
  final FirebaseFirestore firestore;
  const _RecentBookings({required this.firestore});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore
          .collectionGroup('records')
          .orderBy('bookingDateTime', descending: true)
          .limit(10)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return const Center(
              child: Text('No bookings yet.',
                  style: TextStyle(color: Colors.white38)));
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snap.data!.docs.length,
          itemBuilder: (_, i) {
            final d = snap.data!.docs[i].data() as Map<String, dynamic>;
            final ts = d['bookingDateTime'] as Timestamp?;
            final dateStr = ts != null
                ? DateFormat('MMM d, hh:mm a').format(ts.toDate())
                : '-';
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(children: [
                const Icon(Icons.local_parking,
                    color: Colors.redAccent, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${d['name'] ?? 'N/A'} — Slot ${d['slot'] ?? '-'}',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
                Text(dateStr,
                    style: const TextStyle(color: Colors.white54, fontSize: 11)),
              ]),
            );
          },
        );
      },
    );
  }
}
