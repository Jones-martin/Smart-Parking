import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'notification_service.dart';
import 'qr_page.dart';

class BookingPage extends StatefulWidget {
  const BookingPage({super.key});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final slotController = TextEditingController();

  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  int _durationHours = 1;
  bool _isLoading = false;

  // Pricing — ₹50 per hour
  static const double _pricePerHour = 50.0;
  double get _totalCost => _pricePerHour * _durationHours;

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
              primary: Color(0xFFB00000), surface: Color(0xFF2C2C2C)),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
              primary: Color(0xFFB00000), surface: Color(0xFF2C2C2C)),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => selectedTime = picked);
  }

  Future<void> _confirmBooking() async {
    if (nameController.text.isEmpty ||
        emailController.text.isEmpty ||
        phoneController.text.isEmpty ||
        slotController.text.isEmpty ||
        selectedDate == null ||
        selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please fill all fields'),
            backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final walletRef =
          FirebaseFirestore.instance.collection('wallets').doc(uid);
      final walletSnap = await walletRef.get();
      final balance =
          (walletSnap.data()?['balance'] as num?)?.toDouble() ?? 0.0;

      if (balance < _totalCost) {
        // Insufficient balance → fallback to Razorpay
        setState(() => _isLoading = false);
        final useRazorpay = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: const Color(0xFF2C2C2C),
            title: const Text('Insufficient Wallet Balance',
                style: TextStyle(color: Colors.white)),
            content: Text(
              'Wallet: ₹${balance.toStringAsFixed(2)}\nRequired: ₹${_totalCost.toStringAsFixed(2)}\n\nPay via Razorpay instead?',
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel')),
              TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Pay via Razorpay',
                      style: TextStyle(color: Colors.amber))),
            ],
          ),
        );
        if (useRazorpay == true) {
          await launchUrl(Uri.parse('https://rzp.io/rzp/y6U0vahR'),
              mode: LaunchMode.externalApplication);
        }
        return;
      }

      // ── Save booking to Firestore ──────────────────────────────────
      final bookingDateTime = DateTime(
        selectedDate!.year,
        selectedDate!.month,
        selectedDate!.day,
        selectedTime!.hour,
        selectedTime!.minute,
      );

      final bookingRef = FirebaseFirestore.instance
          .collection('bookings')
          .doc(uid)
          .collection('records')
          .doc();

      final batch = FirebaseFirestore.instance.batch();

      // Booking doc
      batch.set(bookingRef, {
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'phone': phoneController.text.trim(),
        'slot': slotController.text.trim().toUpperCase(),
        'bookingDateTime': Timestamp.fromDate(bookingDateTime),
        'durationHours': _durationHours,
        'amount': _totalCost,
        'status': 'confirmed',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Deduct from wallet
      batch.set(
        walletRef,
        {'balance': FieldValue.increment(-_totalCost), 'uid': uid},
        SetOptions(merge: true),
      );

      // Wallet debit transaction
      batch.set(walletRef.collection('transactions').doc(), {
        'amount': _totalCost,
        'type': 'debit',
        'label': 'Parking — Slot ${slotController.text.trim().toUpperCase()}',
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Award loyalty points (10 pts per booking)
      batch.set(
        FirebaseFirestore.instance.collection('users').doc(uid),
        {'loyaltyPoints': FieldValue.increment(10)},
        SetOptions(merge: true),
      );

      // Decrease available slot count
      batch.set(
        FirebaseFirestore.instance.collection('parking_slots').doc('main_lot'),
        {'available': FieldValue.increment(-1)},
        SetOptions(merge: true),
      );

      await batch.commit();

      // ── Notifications ─────────────────────────────────────────────
      await NotificationService.instance.showBookingConfirmation(
          bookingRef.id, slotController.text.trim().toUpperCase());
      await NotificationService.instance
          .scheduleReminder(bookingRef.id,
              slotController.text.trim().toUpperCase(), bookingDateTime);

      if (!mounted) return;

      // ── Navigate to QR page ───────────────────────────────────────
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => QrPage(
            bookingId: bookingRef.id,
            name: nameController.text.trim(),
            slot: slotController.text.trim().toUpperCase(),
            date: DateFormat('EEE, MMM d, yyyy').format(bookingDateTime),
            time: selectedTime!.format(context),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Parking Slot',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFB00000),
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFB00000), Color(0xFF300000)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Cost Banner ──────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.amber.withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Rate: ₹50/hour',
                              style: TextStyle(color: Colors.white70, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text('Total: ₹${_totalCost.toStringAsFixed(0)}',
                              style: const TextStyle(
                                  color: Colors.amber,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20)),
                        ],
                      ),
                      // Duration stepper
                      Row(children: [
                        _stepBtn(Icons.remove, () {
                          if (_durationHours > 1)
                            setState(() => _durationHours--);
                        }),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text('${_durationHours}h',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                        ),
                        _stepBtn(Icons.add, () {
                          if (_durationHours < 24)
                            setState(() => _durationHours++);
                        }),
                      ]),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                _buildTextField(controller: nameController,
                    label: 'Full Name', icon: Icons.person),
                const SizedBox(height: 16),
                _buildTextField(controller: emailController,
                    label: 'Email', icon: Icons.email,
                    keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 16),
                _buildTextField(controller: phoneController,
                    label: 'Phone Number', icon: Icons.phone,
                    keyboardType: TextInputType.phone),
                const SizedBox(height: 16),
                _buildTextField(controller: slotController,
                    label: 'Parking Slot (e.g. A1)', icon: Icons.local_parking),
                const SizedBox(height: 16),
                _buildPickerField(
                  label: selectedDate == null
                      ? 'Select Date'
                      : DateFormat('EEE, MMM d, yyyy').format(selectedDate!),
                  icon: Icons.calendar_today,
                  onTap: _selectDate,
                ),
                const SizedBox(height: 16),
                _buildPickerField(
                  label: selectedTime == null
                      ? 'Select Time'
                      : selectedTime!.format(context),
                  icon: Icons.access_time,
                  onTap: _selectTime,
                ),
                const SizedBox(height: 28),

                // ── Confirm button ────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _confirmBooking,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check_circle_outline),
                    label: Text(
                        _isLoading ? 'Processing...' : 'Confirm & Pay ₹${_totalCost.toStringAsFixed(0)}'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(40)),
                      textStyle: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Center(
                  child: Text(
                    'Payment deducted from your wallet',
                    style: TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stepBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.white70),
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.amber, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      ),
    );
  }

  Widget _buildPickerField(
      {required String label,
      required IconData icon,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2C),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(children: [
          Icon(icon, color: Colors.white70),
          const SizedBox(width: 14),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 15)),
        ]),
      ),
    );
  }
}
