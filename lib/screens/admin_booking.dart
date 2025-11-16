import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/email_service.dart';

class AdminBookingManager extends StatelessWidget {
  const AdminBookingManager({super.key});

  String translateStatus(String status) {
    switch (status) {
      case 'pending': return 'Chờ xác nhận';
      case 'waiting': return 'Đang chờ thanh toán';
      case 'confirmed': return 'Đã xác nhận';
      case 'paid': return 'Đã thanh toán';
      case 'cancelled': return 'Đã hủy';
      case 'completed': return 'Hoàn tất';
      case 'rejected': return 'Từ chối';
      default: return status;
    }
  }

  Color statusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'waiting': return Colors.amber;
      case 'confirmed': return Colors.green;
      case 'paid': return Colors.teal;
      case 'cancelled': return Colors.red;
      case 'completed': return Colors.blueGrey;
      case 'rejected': return Colors.grey;
      default: return Colors.black;
    }
  }

  Future<void> updateStatus(
    String id,
    String status,
    String userEmail,
    String userName,
    String homestayName,
    DateTime checkIn,
    DateTime checkOut,
  ) async {
    await FirebaseFirestore.instance.collection('bookings').doc(id).update({
      'status': status,
      'updatedAt': DateTime.now(),
    });

    await EmailService.sendEmail(
      toEmail: userEmail,
      name: userName,
      homestay: homestayName,
      status: translateStatus(status),
      checkIn: DateFormat('dd/MM/yyyy').format(checkIn),
      checkOut: DateFormat('dd/MM/yyyy').format(checkOut),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text("Quản lý đặt phòng"),
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('bookings')
                .where('status', isEqualTo: 'pending')
                .snapshots(),
            builder: (context, snap) {
              int count = snap.hasData ? snap.data!.docs.length : 0;

              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications),
                    onPressed: () {},
                  ),
                  if (count > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          count.toString(),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12),
                        ),
                      ),
                    )
                ],
              );
            },
          ),
        ],
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .orderBy('createdAt', descending: true)
            .snapshots(),

        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final bookings = snap.data!.docs;
          if (bookings.isEmpty) {
            return const Center(child: Text("Không có booking nào."));
          }

          return ListView.builder(
            itemCount: bookings.length,
            itemBuilder: (context, i) {
              final b = bookings[i];

              // 🔥 LẤY MAP AN TOÀN
              final dataMap = b.data() as Map<String, dynamic>;

              final id = b.id;
              final status = dataMap['status'] ?? 'pending';

              final userName = dataMap['userName'] ?? 'Khách';
              final userEmail = dataMap['userEmail'] ?? '';

              final homestayName = dataMap['homestayName'] ?? '';

              final checkIn = (dataMap['checkInDate'] as Timestamp).toDate();
              final checkOut = (dataMap['checkOutDate'] as Timestamp).toDate();

              return Card(
                margin: const EdgeInsets.all(10),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        homestayName,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),

                      const SizedBox(height: 6),
                      Text("👤 Người đặt: $userName"),
                      Text("📧 Email: $userEmail"),

                      const SizedBox(height: 6),
                      Text("📅 Check-in: ${dateFormat.format(checkIn)}"),
                      Text("📅 Check-out: ${dateFormat.format(checkOut)}"),

                      const SizedBox(height: 6),
                      Text("👥 Khách: ${dataMap['guests'] ?? 0}"),
                      Text("💵 Tổng tiền: ${dataMap['totalPrice'] ?? 0}"),
                      Text("💳 Thanh toán: ${dataMap['paymentMethod'] ?? ''}"),

                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text(
                            "🟢 Trạng thái: ",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            translateStatus(status),
                            style: TextStyle(
                              color: statusColor(status),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      Row(
                        children: [
                          if (status == "pending")
                            ElevatedButton(
                              onPressed: () => updateStatus(
                                id,
                                'confirmed',
                                userEmail,
                                userName,
                                homestayName,
                                checkIn,
                                checkOut,
                              ),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green),
                              child: const Text("Xác nhận"),
                            ),

                          const SizedBox(width: 10),

                          if (status == "pending")
                            ElevatedButton(
                              onPressed: () => updateStatus(
                                id,
                                'cancelled',
                                userEmail,
                                userName,
                                homestayName,
                                checkIn,
                                checkOut,
                              ),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red),
                              child: const Text("Hủy"),
                            ),

                          if (status == "confirmed")
                            ElevatedButton(
                              onPressed: () => updateStatus(
                                id,
                                'completed',
                                userEmail,
                                userName,
                                homestayName,
                                checkIn,
                                checkOut,
                              ),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueGrey),
                              child: const Text("Khách đã trả phòng"),
                            ),
                        ],
                      ),
                    ],
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


/// =======================================================================
/// ⭐ HÀM TẠO BOOKING — KHÔNG THAY ĐỔI, CHỈ ĐẢM BẢO HOẠT ĐỘNG CHUẨN ⭐
/// =======================================================================

Future<void> createBooking({
  required String homestayId,
  required String homestayName,
  required DateTime checkInDate,
  required DateTime checkOutDate,
  required int guests,
  required int totalPrice,
  required String paymentMethod,
}) async {

  final user = FirebaseAuth.instance.currentUser;
  if (user == null) throw Exception("User not logged in");

  final userDoc = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .get();

  final String userName = userDoc.data()?['name'] ?? '';
  final String userEmail = userDoc.data()?['email'] ?? user.email ?? '';

  final orderId = "ORDER_${DateTime.now().millisecondsSinceEpoch}";

  await FirebaseFirestore.instance.collection('bookings').add({
    'orderId': orderId,
    'userId': user.uid,
    'userEmail': userEmail,
    'userName': userName,
    'homestayId': homestayId,
    'homestayName': homestayName,
    'checkInDate': checkInDate,
    'checkOutDate': checkOutDate,
    'guests': guests,
    'totalPrice': totalPrice,
    'paymentMethod': paymentMethod,
    'paymentStatus': 'paid',
    'status': 'confirmed',
    'note': '',
    'createdAt': DateTime.now(),
  });
}
