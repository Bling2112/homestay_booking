import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/homestay.dart';
import 'payment_screen.dart';

class BookingScreen extends StatefulWidget {
  final Homestay homestay;
  const BookingScreen({super.key, required this.homestay});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime? _checkInDate;
  DateTime? _checkOutDate;
  int _guestCount = 1;
  String _paymentMethod = 'direct';
  bool _isLoading = false;
  final _noteController = TextEditingController();
  final String _orderId = 'ORDER_${DateTime.now().millisecondsSinceEpoch}';

  /// PICK RANGE NGÀY NHẬN – TRẢ
  Future<void> _pickDateRange() async {
    DateTime now = DateTime.now();
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange: (_checkInDate != null && _checkOutDate != null)
          ? DateTimeRange(start: _checkInDate!, end: _checkOutDate!)
          : DateTimeRange(start: now, end: now.add(const Duration(days: 1))),
      helpText: 'Chọn ngày nhận – trả',
      cancelText: 'Hủy',
      confirmText: 'Xác nhận',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.teal,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _checkInDate = picked.start;
        _checkOutDate = picked.end;
      });
    }
  }

  /// Helper convert Timestamp -> DateTime
  DateTime? _extractDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    return null;
  }

  /// Kiểm tra trùng ngày với cùng homestay
  Future<bool> _isOverlapWithExisting() async {
    if (_checkInDate == null || _checkOutDate == null) return true;

    final bookingRef = FirebaseFirestore.instance.collection('bookings');
    final query = await bookingRef
        .where('status', whereIn: ['waiting', 'confirmed', 'paid'])
        .where('homestayId', isEqualTo: widget.homestay.id)
        .get();

    for (var doc in query.docs) {
      final data = doc.data();
      final existingStart = _extractDate(data['checkInDate']);
      final existingEnd = _extractDate(data['checkOutDate']);
      if (existingStart == null || existingEnd == null) continue;

      final overlap = _checkInDate!.isBefore(existingEnd) &&
          _checkOutDate!.isAfter(existingStart);

      if (overlap) return true; // trùng homestay + ngày
    }

    return false; // không trùng
  }

  /// Xử lý confirm booking
  Future<void> _confirmBooking() async {
    if (_checkInDate == null || _checkOutDate == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Vui lòng chọn ngày.')));
      return;
    }

    setState(() => _isLoading = true);

    final overlap = await _isOverlapWithExisting();
    if (overlap) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Homestay đã được đặt trong thời gian này!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    int nights = _checkOutDate!.difference(_checkInDate!).inDays;
    int totalPrice = nights * widget.homestay.price;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final bookingRef = FirebaseFirestore.instance.collection('bookings');

    if (_paymentMethod == 'online') {
      // Tạo booking pending
      final doc = await bookingRef.add({
        'homestayId': widget.homestay.id,
        'homestayName': widget.homestay.name,
        'checkInDate': _checkInDate,
        'checkOutDate': _checkOutDate,
        'guests': _guestCount,
        'note': _noteController.text,
        'totalPrice': totalPrice,
        'paymentMethod': 'momo', // default QR
        'paymentStatus': 'pending',
        'status': 'waiting',
        'userId': user.uid,
        'orderId': _orderId,
        'createdAt': DateTime.now(),
      });
      final bookingId = doc.id;

      setState(() => _isLoading = false);

      // Chuyển sang PaymentScreen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentScreen(
            homestay: widget.homestay,
            totalPrice: totalPrice,
            bookingMeta: {
              'checkInDate': _checkInDate,
              'checkOutDate': _checkOutDate,
              'guests': _guestCount,
              'note': _noteController.text,
              'bookingId': bookingId,
            },
          ),
        ),
      );
    } else {
      // Thanh toán trực tiếp
      await bookingRef.add({
        'homestayId': widget.homestay.id,
        'homestayName': widget.homestay.name,
        'checkInDate': _checkInDate,
        'checkOutDate': _checkOutDate,
        'guests': _guestCount,
        'note': _noteController.text,
        'totalPrice': totalPrice,
        'paymentMethod': 'cash',
        'paymentStatus': 'pending',
        'status': 'confirmed',
        'userId': user.uid,
        'createdAt': DateTime.now(),
      });

      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đặt homestay thành công! Thanh toán khi đến.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final homestay = widget.homestay;

    return Scaffold(
      appBar: AppBar(title: const Text('Đặt homestay')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(homestay.name,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextButton(
              onPressed: _pickDateRange,
              child: Text(
                (_checkInDate == null || _checkOutDate == null)
                    ? 'Chọn ngày nhận – trả'
                    : '${dateFormat.format(_checkInDate!)} → ${dateFormat.format(_checkOutDate!)}',
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text('Số khách: '),
                IconButton(
                  onPressed: () {
                    if (_guestCount > 1) setState(() => _guestCount--);
                  },
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text('$_guestCount'),
                IconButton(
                  onPressed: () => setState(() => _guestCount++),
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Ghi chú (tùy chọn)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            const Text('Chọn phương thức thanh toán:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            RadioListTile(
              title: const Text('Thanh toán trực tiếp khi đến'),
              value: 'direct',
              groupValue: _paymentMethod,
              onChanged: (value) {
                setState(() => _paymentMethod = value.toString());
              },
            ),
            RadioListTile(
              title: const Text('Thanh toán online'),
              value: 'online',
              groupValue: _paymentMethod,
              onChanged: (value) {
                setState(() => _paymentMethod = value.toString());
              },
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _confirmBooking,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Xác nhận đặt'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
