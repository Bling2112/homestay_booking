import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/homestay.dart';
import 'homestay_detail_screen.dart';

class BookingWithHomestay {
  final String bookingId;
  final String paymentStatus;
  String status;
  final int totalPrice;
  final Homestay homestay;
  final DateTime checkIn;
  final DateTime checkOut;

  BookingWithHomestay({
    required this.bookingId,
    required this.paymentStatus,
    required this.status,
    required this.totalPrice,
    required this.homestay,
    required this.checkIn,
    required this.checkOut,
  });
}

class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});

  DateTime? _extractDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    return null;
  }

  Stream<List<BookingWithHomestay>> getUserBookings() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();

    return FirebaseFirestore.instance
        .collection('bookings')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final bookings = <BookingWithHomestay>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();

        final hsDoc = await FirebaseFirestore.instance
            .collection('homestays')
            .doc(data['homestayId'])
            .get();

        if (!hsDoc.exists) continue;

        final checkIn = _extractDate(data['checkInDate']);
        final checkOut = _extractDate(data['checkOutDate']);
        if (checkIn == null || checkOut == null) continue;

        String status = data['status'] ?? 'waiting';

        // 🔥 Auto complete nếu đã checkout
        final now = DateTime.now();
        if (status == 'confirmed' && checkOut.isBefore(now)) {
          FirebaseFirestore.instance.collection('bookings').doc(doc.id).update({
            'status': 'completed',
          });
          status = 'completed';
        }

        bookings.add(
          BookingWithHomestay(
            bookingId: doc.id,
            paymentStatus: data['paymentStatus'] ?? 'pending',
            status: status,
            totalPrice: data['totalPrice'] ?? 0,
            homestay: Homestay.fromFirestore(hsDoc.id, hsDoc.data()!),
            checkIn: checkIn,
            checkOut: checkOut,
          ),
        );
      }

      return bookings;
    });
  }

  Color statusColor(String status) {
    switch (status) {
      case 'waiting':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String statusText(String status) {
    switch (status) {
      case 'waiting':
        return 'Đang đợi xác nhận';
      case 'confirmed':
        return 'Đã xác nhận';
      case 'completed':
        return 'Hoàn thành';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return 'Không xác định';
    }
  }

  Future<void> cancelBooking(String bookingId) async {
    await FirebaseFirestore.instance
        .collection('bookings')
        .doc(bookingId)
        .update({'status': 'cancelled', 'updatedAt': DateTime.now()});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: const Text('Homestay đã đặt'), backgroundColor: Colors.teal),
      body: StreamBuilder<List<BookingWithHomestay>>(
        stream: getUserBookings(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Bạn chưa đặt homestay nào.'));
          }

          final bookings = snapshot.data!;
          return ListView.builder(
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final b = bookings[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: Image.network(
                    b.homestay.imageUrl,
                    width: 60,
                    fit: BoxFit.cover,
                  ),
                  title: Text(b.homestay.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tổng tiền: ${b.totalPrice} đ'),
                      Text(
                        statusText(b.status),
                        style: TextStyle(
                          color: statusColor(b.status),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Từ: ${b.checkIn.day}/${b.checkIn.month}  →  "
                        "Đến: ${b.checkOut.day}/${b.checkOut.month}",
                      ),
                      const SizedBox(height: 4),
                      if (b.status == 'waiting' || b.status == 'confirmed')
                        ElevatedButton(
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Xác nhận hủy booking'),
                                content: const Text(
                                    'Bạn có chắc muốn hủy booking này không?'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Không'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Có'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await cancelBooking(b.bookingId);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red),
                          child: const Text('Hủy booking'),
                        ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HomestayDetailScreen(homestay: b.homestay),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
