import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class MyBookingsPage extends StatefulWidget {
  const MyBookingsPage({super.key});

  @override
  State<MyBookingsPage> createState() => _MyBookingsPageState();
}

class _MyBookingsPageState extends State<MyBookingsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final String _uid = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  CollectionReference get _bookingsRef => FirebaseFirestore.instance
      .collection('bookings')
      .doc(_uid)
      .collection('records');

  Stream<QuerySnapshot> _bookingsStream(String status) {
    return _bookingsRef
        .where('status', isEqualTo: status)
        .orderBy('bookingDateTime', descending: true)
        .snapshots();
  }

  Future<void> _cancelBooking(String docId, double amount) async {
    final batch = FirebaseFirestore.instance.batch();

    // Mark booking as cancelled
    batch.update(_bookingsRef.doc(docId), {'status': 'cancelled'});

    // Refund wallet
    final walletRef =
        FirebaseFirestore.instance.collection('wallets').doc(_uid);
    batch.set(walletRef, {'balance': FieldValue.increment(amount), 'uid': _uid},
        SetOptions(merge: true));

    // Refund transaction record
    final txRef = walletRef.collection('transactions').doc();
    batch.set(txRef, {
      'amount': amount,
      'type': 'credit',
      'label': 'Booking Refund',
      'timestamp': FieldValue.serverTimestamp(),
    });

    await batch.commit();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Booking cancelled. ₹${amount.toStringAsFixed(2)} refunded.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFFB00000),
        foregroundColor: Colors.white,
        title: const Text('My Bookings',
            style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amber,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Upcoming'),
            Tab(text: 'Past'),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF3A0000), Colors.black],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            _BookingList(
                stream: _bookingsStream('active'),
                emptyMsg: 'No active bookings',
                showTimer: true,
                onCancel: _cancelBooking),
            _BookingList(
                stream: _bookingsStream('confirmed'),
                emptyMsg: 'No upcoming bookings',
                showCancel: true,
                onCancel: _cancelBooking),
            _BookingList(
                stream: _bookingsStream('completed'),
                emptyMsg: 'No past bookings',
                showRate: true,
                onCancel: _cancelBooking),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF2C2C2C),
        selectedItemColor: Colors.redAccent,
        unselectedItemColor: Colors.white70,
        type: BottomNavigationBarType.fixed,
        currentIndex: 0,
        onTap: (i) {
          if (i == 0) Navigator.pushNamed(context, '/home');
          if (i == 1) Navigator.pushNamed(context, '/map');
          if (i == 2) Navigator.pushNamed(context, '/profile');
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.local_parking), label: 'Book'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Profile'),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _BookingList extends StatelessWidget {
  final Stream<QuerySnapshot> stream;
  final String emptyMsg;
  final bool showTimer;
  final bool showCancel;
  final bool showRate;
  final Future<void> Function(String docId, double amount) onCancel;

  const _BookingList({
    required this.stream,
    required this.emptyMsg,
    this.showTimer = false,
    this.showCancel = false,
    this.showRate = false,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.redAccent));
        }
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.local_parking, color: Colors.white24, size: 64),
                const SizedBox(height: 12),
                Text(emptyMsg,
                    style: const TextStyle(color: Colors.white38, fontSize: 16)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snap.data!.docs.length,
          itemBuilder: (_, i) {
            final doc = snap.data!.docs[i];
            final data = doc.data() as Map<String, dynamic>;
            return _BookingCard(
              docId: doc.id,
              data: data,
              showTimer: showTimer,
              showCancel: showCancel,
              showRate: showRate,
              onCancel: onCancel,
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _BookingCard extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;
  final bool showTimer;
  final bool showCancel;
  final bool showRate;
  final Future<void> Function(String, double) onCancel;

  const _BookingCard({
    required this.docId,
    required this.data,
    required this.showTimer,
    required this.showCancel,
    required this.showRate,
    required this.onCancel,
  });

  @override
  State<_BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends State<_BookingCard> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    if (widget.showTimer) _startTimer();
  }

  void _startTimer() {
    final ts = widget.data['bookingDateTime'] as Timestamp?;
    if (ts == null) return;
    final end = ts.toDate().add(
        Duration(hours: (widget.data['durationHours'] as num? ?? 1).toInt()));
    _tick(end);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick(end));
  }

  void _tick(DateTime end) {
    final rem = end.difference(DateTime.now());
    if (mounted) setState(() => _remaining = rem.isNegative ? Duration.zero : rem);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _fmt(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final slot = widget.data['slot'] as String? ?? 'N/A';
    final name = widget.data['name'] as String? ?? '';
    final ts = widget.data['bookingDateTime'] as Timestamp?;
    final dateStr = ts != null
        ? DateFormat('EEE, MMM d • h:mm a').format(ts.toDate())
        : 'N/A';
    final amount = (widget.data['amount'] as num?)?.toDouble() ?? 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFB00000).withOpacity(0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.local_parking, color: Colors.redAccent, size: 20),
            const SizedBox(width: 8),
            Text('Slot: $slot',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: widget.showTimer
                    ? Colors.green.withOpacity(0.2)
                    : widget.showCancel
                        ? Colors.blue.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                widget.showTimer
                    ? 'Active'
                    : widget.showCancel
                        ? 'Upcoming'
                        : 'Completed',
                style: TextStyle(
                  color: widget.showTimer
                      ? Colors.greenAccent
                      : widget.showCancel
                          ? Colors.lightBlueAccent
                          : Colors.white60,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          Text(name, style: const TextStyle(color: Colors.white70)),
          Text(dateStr, style: const TextStyle(color: Colors.white54, fontSize: 13)),
          Text('₹${amount.toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.w600)),

          // Timer
          if (widget.showTimer && _remaining > Duration.zero) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.timer, color: Colors.greenAccent, size: 18),
                const SizedBox(width: 8),
                Text('Time Remaining: ${_fmt(_remaining)}',
                    style: const TextStyle(
                        color: Colors.greenAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
              ]),
            ),
          ],

          // Cancel button
          if (widget.showCancel) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      backgroundColor: const Color(0xFF2C2C2C),
                      title: const Text('Cancel Booking?',
                          style: TextStyle(color: Colors.white)),
                      content: Text(
                          '₹${amount.toStringAsFixed(2)} will be refunded to your wallet.',
                          style: const TextStyle(color: Colors.white70)),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('No')),
                        TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Yes, Cancel',
                                style: TextStyle(color: Colors.redAccent))),
                      ],
                    ),
                  );
                  if (ok == true) widget.onCancel(widget.docId, amount);
                },
                icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent),
                label: const Text('Cancel Booking',
                    style: TextStyle(color: Colors.redAccent)),
                style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.redAccent)),
              ),
            ),
          ],

          // Rate button
          if (widget.showRate) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/rate',
                      arguments: {
                        'bookingId': widget.docId,
                        'slot': slot,
                      });
                },
                icon: const Icon(Icons.star_outline),
                label: const Text('Rate This Parking'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                ),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}
