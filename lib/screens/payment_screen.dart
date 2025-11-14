import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';
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
  final String _orderId = 'ORDER_${DateTime.now().millisecondsSinceEpoch}';
  String? bookingId;

  @override
  void initState() {
    super.initState();
    _createPendingBooking();
  }

  Future<void> _createPendingBooking() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final now = DateTime.now();
    final endDate = now.add(const Duration(days: 3)); // ví dụ 3 ngày nghỉ

    final doc = await FirebaseFirestore.instance.collection('bookings').add({
      'homestayId': widget.homestay.id,
      'homestayName': widget.homestay.name,
      'totalPrice': widget.totalPrice,
      'orderId': _orderId,
      'paymentMethod': _method,
      'paymentStatus': 'pending',
      'bookingStatus': 'waiting',
      'userId': user.uid,
      'startDate': now,
      'endDate': endDate,
      'meta': widget.bookingMeta ?? {},
      'createdAt': now,
    });

    bookingId = doc.id;
    setState(() {});
  }

  Future<void> _completeCardPayment() async {
    if (bookingId == null) return;
    setState(() => _isPaying = true);
    await Future.delayed(const Duration(seconds: 2));

    FirebaseFirestore.instance.collection('bookings').doc(bookingId).update({
      'paymentStatus': 'paid',
      'paymentMethod': 'card',
      'bookingStatus': 'in_progress',
    });

    setState(() => _isPaying = false);
  }

  Widget _buildMethodTile({
    required String value,
    required Widget leading,
    required String title,
    String? subtitle,
  }) {
    return RadioListTile<String>(
      value: value,
      groupValue: _method,
      onChanged: (v) => setState(() => _method = v!),
      title: Row(
        children: [
          leading,
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              if (subtitle != null)
                Text(subtitle, style: const TextStyle(fontSize: 12)),
            ],
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final homestay = widget.homestay;
    final priceStr = '${widget.totalPrice} đ';
    final qrData =
        'orderId=$_orderId&amount=${widget.totalPrice}&merchant=${homestay.name}';

    return Scaffold(
      appBar: AppBar(title: const Text('Thanh toán (demo)'), backgroundColor: Colors.teal),
      body: bookingId == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('bookings')
                  .doc(bookingId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final data = snapshot.data!.data() as Map<String, dynamic>?;

                final status = data?['paymentStatus'];
                if (status == 'paid') {
                  Future.microtask(() {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Thanh toán thành công!')),
                    );
                    if (Navigator.canPop(context)) Navigator.pop(context);
                  });
                }

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(homestay.name,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text('Tổng tiền: $priceStr', style: const TextStyle(fontSize: 18, color: Colors.teal)),
                      const SizedBox(height: 16),
                      const Text('Chọn phương thức thanh toán:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),

                      _buildMethodTile(
                        value: 'card',
                        leading: const Icon(Icons.credit_card_rounded, size: 34),
                        title: 'Thẻ ngân hàng',
                        subtitle: 'Nhập thông tin thẻ (demo)',
                      ),
                      _buildMethodTile(
                        value: 'momo',
                        leading: Image.asset(
                          'assets/images/momo_logo.png',
                          width: 48, height: 48,
                          errorBuilder: (c,e,s) => const Icon(Icons.wallet, size: 36),
                        ),
                        title: 'Momo',
                        subtitle: 'Quét QR bằng Momo',
                      ),
                      _buildMethodTile(
                        value: 'zalopay',
                        leading: Image.asset(
                          'assets/images/zalopay_logo.png',
                          width: 48, height: 48,
                          errorBuilder: (c,e,s) => const Icon(Icons.qr_code, size: 36),
                        ),
                        title: 'ZaloPay',
                        subtitle: 'Quét QR bằng ZaloPay',
                      ),

                      const SizedBox(height: 18),

                      if (_method == 'momo' || _method == 'zalopay') ...[
                        Center(
                          child: Column(
                            children: [
                              const Text('Quét QR để thanh toán', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(8),
                                color: Colors.white,
                                child: QrImageView(
                                  data: qrData,
                                  version: QrVersions.auto,
                                  size: 220,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text('Order: $_orderId', style: const TextStyle(fontSize: 12)),
                              Text('Số tiền: $priceStr', style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                      ],

                      if (_method == 'card') ...[
                        const Text('Thông tin thẻ (demo):'),
                        const SizedBox(height: 6),
                        TextField(
                          decoration: InputDecoration(
                            labelText: 'Số thẻ',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(child: TextField(decoration: const InputDecoration(labelText: 'MM/YY', border: OutlineInputBorder()))),
                            const SizedBox(width: 8),
                            Expanded(child: TextField(decoration: const InputDecoration(labelText: 'CVV', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
                          ],
                        ),
                      ],

                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isPaying
                              ? null
                              : () {
                                  if (_method == 'card') {
                                    _completeCardPayment();
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Đang chờ xác nhận thanh toán...')),
                                    );
                                  }
                                },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, padding: const EdgeInsets.symmetric(vertical: 14)),
                          child: _isPaying
                              ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                              : Text(_method == 'card' ? 'Thanh toán thẻ (demo)' : 'Tôi đã quét QR'),
                        ),
                      ),

                      const SizedBox(height: 8),
                      Center(
                        child: TextButton(
                          onPressed: () {
                            FirebaseFirestore.instance.collection('bookings').doc(bookingId).update({
                              'paymentStatus': 'paid',
                              'bookingStatus': 'in_progress',
                            });
                          },
                          child: const Text("Xác nhận thanh toán (demo)", style: TextStyle(color: Colors.red)),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
