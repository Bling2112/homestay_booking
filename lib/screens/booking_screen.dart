import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  final _noteController = TextEditingController();

  /// PICK RANGE NGÀY NHẬN – TRẢ
  Future<void> _pickDateRange() async {
    DateTime now = DateTime.now();

    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange: (_checkInDate != null && _checkOutDate != null)
          ? DateTimeRange(start: _checkInDate!, end: _checkOutDate!)
          : DateTimeRange(
              start: now,
              end: now.add(const Duration(days: 1)),
            ),
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

  /// CONFIRM BOOKING
  Future<void> _confirmBooking() async {
    if (_checkInDate == null || _checkOutDate == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Vui lòng chọn ngày.')));
      return;
    }

    int nights = _checkOutDate!.difference(_checkInDate!).inDays;
    int totalPrice = nights * widget.homestay.price;

    if (_paymentMethod == 'online') {
      // Thanh toán online → chuyển sang PaymentScreen
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
              'note': _noteController.text
            },
          ),
        ),
      );
    } else {
      // Thanh toán trực tiếp → lưu booking vào Firestore
      await FirebaseFirestore.instance.collection('bookings').add({
        'homestayId': widget.homestay.id,
        'homestayName': widget.homestay.name,
        'checkInDate': _checkInDate,
        'checkOutDate': _checkOutDate,
        'guests': _guestCount,
        'note': _noteController.text,
        'totalPrice': totalPrice,
        'paymentMethod': 'direct',
        'status': 'confirmed',
        'createdAt': DateTime.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đặt homestay thành công!')),
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
            Text(
              homestay.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // ------ NÚT CHỌN NGÀY RANGE ------
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

            // ------ SỐ KHÁCH ------
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

            // ------ GHI CHÚ ------
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Ghi chú (tùy chọn)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),

            const SizedBox(height: 20),

            const Text(
              'Chọn phương thức thanh toán:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            // ------ THANH TOÁN TRỰC TIẾP ------
            RadioListTile(
              title: const Text('Thanh toán trực tiếp khi đến'),
              value: 'direct',
              groupValue: _paymentMethod,
              onChanged: (value) {
                setState(() => _paymentMethod = value.toString());
              },
            ),

            // ------ THANH TOÁN ONLINE ------
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
                onPressed: _confirmBooking,
                child: const Text('Xác nhận đặt'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
