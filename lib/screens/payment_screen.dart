import 'package:bookinghomestay/models/email_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import '../models/homestay.dart';

class PaymentScreen extends StatefulWidget {
  final Homestay homestay;
  final int totalPrice;
  final Map<String, dynamic>? bookingMeta;

  const PaymentScreen({
    super.key,
    required this.homestay,
    required this.totalPrice,
    this.bookingMeta,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isPaying = false;
  String _method = 'momo';
  String? _bookingId;
  bool _showQR = false;
  final String _orderId = 'ORDER_${DateTime.now().millisecondsSinceEpoch}';

  DateTime? _extractDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    return null;
  }

  String _formatDate(DateTime date) => DateFormat('dd/MM/yyyy').format(date);

  Future<bool> _isOverlapWithExisting(DateTime checkIn, DateTime checkOut) async {
    final bookingRef = FirebaseFirestore.instance.collection('bookings');
    final query = await bookingRef
        .where('status', whereIn: ['confirmed', 'paid'])
        .where('homestayId', isEqualTo: widget.homestay.id)
        .get();

    for (var doc in query.docs) {
      final data = doc.data();
      final start = _extractDate(data['checkInDate']);
      final end = _extractDate(data['checkOutDate']);
      if (start == null || end == null) continue;
      if (checkIn.isBefore(end) && checkOut.isAfter(start)) return true;
    }
    return false;
  }

  Future<bool> _createBooking() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final checkIn = _extractDate(widget.bookingMeta?['checkInDate']);
    final checkOut = _extractDate(widget.bookingMeta?['checkOutDate']);
    if (checkIn == null || checkOut == null) return false;

    // Kiểm tra trùng
    if (await _isOverlapWithExisting(checkIn, checkOut)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Homestay đã được đặt trong thời gian này!")),
      );
      return false;
    }

    // Fetch user name from Firestore
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final String userName = userDoc.data()?['name'] ?? user.displayName ?? 'Khách';

    final doc = await FirebaseFirestore.instance.collection('bookings').add({
      'homestayId': widget.homestay.id,
      'homestayName': widget.homestay.name,
      'checkInDate': checkIn,
      'checkOutDate': checkOut,
      'guests': widget.bookingMeta?['guests'],
      'note': widget.bookingMeta?['note'],
      'totalPrice': widget.totalPrice,
      'paymentMethod': _method,
      'paymentStatus': 'pending',
      'status': 'waiting',
      'userId': user.uid,
      'userEmail': user.email ?? '',
      'userName': userName,
      'orderId': _orderId,
      'createdAt': DateTime.now(),
    });

    _bookingId = doc.id;
    return true;
  }

  Future<void> _sendEmail() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      bool result = await EmailService.sendEmail(
        toEmail: user.email ?? '',
        name: user.displayName ?? 'Khách hàng',
        homestay: widget.homestay.name,
        status: 'Đặt thành công',
        checkIn: _formatDate(_extractDate(widget.bookingMeta?['checkInDate'])!),
        checkOut: _formatDate(_extractDate(widget.bookingMeta?['checkOutDate'])!),
      );
      print('Email sent: $result');
    } catch (e) {
      print('Error sending email: $e');
    }
  }

  Future<void> _rateHomestay() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final checkOut = _extractDate(widget.bookingMeta?['checkOutDate']);
    if (checkOut == null || checkOut.isAfter(DateTime.now())) return; // Chỉ cho phép đánh giá sau khi checkout

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        int selectedRating = 0;
        final commentController = TextEditingController();
        return AlertDialog(
          title: const Text('Đánh giá homestay'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Bạn đã trải nghiệm homestay này. Hãy đánh giá:'),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < selectedRating ? Icons.star : Icons.star_border,
                          color: Colors.orange,
                          size: 32,
                        ),
                        onPressed: () {
                          setState(() {
                            selectedRating = index + 1;
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: commentController,
                    decoration: const InputDecoration(
                      labelText: 'Nhận xét (tùy chọn)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Bỏ qua'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, {
                'rating': selectedRating,
                'comment': commentController.text.trim(),
              }),
              child: const Text('Gửi đánh giá'),
            ),
          ],
        );
      },
    );

    if (result != null && result['rating'] > 0) {
      final rating = result['rating'] as int;
      final comment = result['comment'] as String;

      // Lưu review vào subcollection
      await FirebaseFirestore.instance
          .collection('homestays')
          .doc(widget.homestay.id)
          .collection('reviews')
          .add({
            'userId': user.uid,
            'userName': user.displayName ?? 'Khách',
            'rating': rating,
            'comment': comment,
            'createdAt': DateTime.now(),
          });

      // Tính lại rating trung bình
      final reviewsSnapshot = await FirebaseFirestore.instance
          .collection('homestays')
          .doc(widget.homestay.id)
          .collection('reviews')
          .get();

      double totalRating = 0;
      for (var doc in reviewsSnapshot.docs) {
        totalRating += (doc.data()['rating'] as int).toDouble();
      }
      final averageRating = reviewsSnapshot.docs.isNotEmpty
          ? (totalRating / reviewsSnapshot.docs.length).round()
          : 0;

      // Cập nhật rating trong homestay
      await FirebaseFirestore.instance
          .collection('homestays')
          .doc(widget.homestay.id)
          .update({'rating': averageRating});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cảm ơn bạn đã đánh giá $rating sao!')),
      );
    }
  }

  Future<void> _autoCompletePayment() async {
    if (_bookingId == null) return;

    // Mô phỏng quét QR sau 5 giây
    await Future.delayed(const Duration(seconds: 5));

    await FirebaseFirestore.instance.collection('bookings').doc(_bookingId).update({
      'paymentStatus': 'paid',
      'status': 'confirmed',
    });

    await _sendEmail();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Thanh toán thành công! Email đã gửi.')),
    );

    Navigator.pop(context);
  }

  void _startPaymentFlow() async {
    setState(() => _isPaying = true);

    bool success = await _createBooking();
    if (!success) {
      setState(() => _isPaying = false);
      return;
    }

    if (_method == 'momo' || _method == 'zalopay') {
      setState(() => _showQR = true);
      _autoCompletePayment();
      return;
    }

    // Thanh toán khi đến
    await _sendEmail();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đặt thành công! Email đã gửi.')),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final homestay = widget.homestay;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Thanh toán"),
        backgroundColor: Colors.teal,
      ),
      body: _showQR
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _method == 'momo'
                        ? "Quét Momo để thanh toán"
                        : "Quét ZaloPay để thanh toán",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  QrImageView(
                    data: "PAYMENT|$_method|$_orderId|${widget.totalPrice}",
                    size: 220,
                  ),
                  const SizedBox(height: 20),
                  const Text("Hệ thống sẽ tự xác nhận sau 5 giây...",
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(homestay.name,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text('Tổng tiền: ${widget.totalPrice} đ',
                      style: const TextStyle(fontSize: 18, color: Colors.teal)),
                  const SizedBox(height: 16),
                  const Text('Chọn phương thức thanh toán:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  RadioListTile(
                    value: 'momo',
                    groupValue: _method,
                    onChanged: (v) => setState(() => _method = v!),
                    title: const Text("Momo QR (demo)"),
                  ),
                  RadioListTile(
                    value: 'zalopay',
                    groupValue: _method,
                    onChanged: (v) => setState(() => _method = v!),
                    title: const Text("ZaloPay QR (demo)"),
                  ),
                  RadioListTile(
                    value: 'cash',
                    groupValue: _method,
                    onChanged: (v) => setState(() => _method = v!),
                    title: const Text("Thanh toán khi đến"),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isPaying ? null : _startPaymentFlow,
                      child: _isPaying
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(_method == 'cash'
                              ? 'Đặt & thanh toán khi đến'
                              : 'Thanh toán'),
                    ),
                  )
                ],
              ),
            ),
    );
  }
}
