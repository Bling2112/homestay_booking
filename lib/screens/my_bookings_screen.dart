import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/homestay.dart';
import 'homestay_detail_screen.dart';

class BookingWithHomestay {
  final String bookingId;
  final String paymentStatus;
  String bookingStatus;
  final int totalPrice;
  final Homestay homestay;
  final DateTime startDate;
  final DateTime endDate;

  BookingWithHomestay({
    required this.bookingId,
    required this.paymentStatus,
    required this.bookingStatus,
    required this.totalPrice,
    required this.homestay,
    required this.startDate,
    required this.endDate,
  });
}

class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});

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
        final hsDoc = await FirebaseFirestore.instance.collection('homestays').doc(data['homestayId']).get();
        if (hsDoc.exists) {
          final startDate = (data['startDate'] as Timestamp).toDate();
          final endDate = (data['endDate'] as Timestamp).toDate();
          String bookingStatus = data['bookingStatus'] ?? 'waiting';

          // 🔥 Tự động chuyển in_progress → completed
          final now = DateTime.now();
          if (bookingStatus == 'in_progress' && endDate.isBefore(now)) {
            FirebaseFirestore.instance.collection('bookings').doc(doc.id).update({'bookingStatus': 'completed'});
            bookingStatus = 'completed';
          }

          bookings.add(BookingWithHomestay(
            bookingId: doc.id,
            paymentStatus: data['paymentStatus'] ?? 'pending',
            bookingStatus: bookingStatus,
            totalPrice: data['totalPrice'] ?? 0,
            homestay: Homestay.fromFirestore(hsDoc.id, hsDoc.data()!),
            startDate: startDate,
            endDate: endDate,
          ));
        }
      }
      return bookings;
    });
  }

  Color statusColor(String status) {
    switch (status) {
      case 'waiting': return Colors.orange;
      case 'in_progress': return Colors.blue;
      case 'completed': return Colors.green;
      default: return Colors.grey;
    }
  }

  String statusText(String status) {
    switch (status) {
      case 'waiting': return 'Đang đợi xác nhận';
      case 'in_progress': return 'Chưa hoàn thành';
      case 'completed': return 'Hoàn thành';
      default: return 'Không xác định';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Homestay đã đặt'), backgroundColor: Colors.teal),
      body: StreamBuilder<List<BookingWithHomestay>>(
        stream: getUserBookings(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) return Center(child: Text('Lỗi: ${snapshot.error}'));
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
                  leading: Image.network(b.homestay.imageUrl, width: 60, fit: BoxFit.cover),
                  title: Text(b.homestay.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${b.totalPrice} đ/đêm'),
                      Text(statusText(b.bookingStatus),
                          style: TextStyle(
                              color: statusColor(b.bookingStatus),
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => HomestayDetailScreen(homestay: b.homestay)),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
