import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class TransactionHistoryScreen extends StatelessWidget {
  const TransactionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(title: const Text('Lịch sử giao dịch')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final bookings = snapshot.data!.docs;

          if (bookings.isEmpty) {
            return const Center(child: Text('Không có giao dịch nào.'));
          }

          return ListView.builder(
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final b = bookings[index];
              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  title: Text(
                    b['homestayName'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Check-in: ${dateFormat.format(b['checkInDate'].toDate())}"),
                      Text("Check-out: ${dateFormat.format(b['checkOutDate'].toDate())}"),
                      Text("Phương thức: ${b['paymentMethod']}"),
                      Text("Tổng tiền: ${b['totalPrice']} VNĐ"),
                      Text("Trạng thái: ${b['status']}"),
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
