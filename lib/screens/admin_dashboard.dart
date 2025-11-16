import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class AdminDashboardFree extends StatefulWidget {
  const AdminDashboardFree({super.key});

  @override
  State<AdminDashboardFree> createState() => _AdminDashboardFreeState();
}

class _AdminDashboardFreeState extends State<AdminDashboardFree> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  double totalRevenue = 0;
  Map<String, double> revenueByHomestay = {};

  @override
  void initState() {
    super.initState();
    _calculateRevenue();
  }

  // ====== TÍNH DOANH THU ======
  Future<void> _calculateRevenue() async {
    final snapshot = await _db
        .collection('bookings')
        .where('paymentStatus', isEqualTo: 'paid')
        .get();

    double total = 0;
    Map<String, double> byHomestay = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final price = (data['totalPrice'] ?? 0).toDouble();
      final name = data['homestayName'] ?? 'Unknown';

      total += price;
      byHomestay[name] = (byHomestay[name] ?? 0) + price;
    }

    setState(() {
      totalRevenue = total;
      revenueByHomestay = byHomestay;
    });
  }

  // ====== CẬP NHẬT TRẠNG THÁI ======
  Future<void> updateStatus(String id, String status, String name) async {
    await _db.collection('bookings').doc(id).update({
      'status': status,
      'updatedAt': DateTime.now(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Booking $name đã được $status!'),
        backgroundColor: Colors.green,
      ),
    );

    _calculateRevenue();
  }

  // ===== BIỂU ĐỒ DOANH THU ======
  Widget revenueChart() {
    if (revenueByHomestay.isEmpty) {
      return const Center(
        child: Text('Chưa có dữ liệu doanh thu'),
      );
    }

    final barGroups = <BarChartGroupData>[];
    int index = 0;

    revenueByHomestay.forEach((name, revenue) {
      barGroups.add(
        BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(toY: revenue, width: 22, color: Colors.teal)
          ],
        ),
      );
      index++;
    });

    return BarChart(
      BarChartData(
        barGroups: barGroups,
        maxY: revenueByHomestay.values.reduce((a, b) => a > b ? a : b) * 1.2,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i >= 0 && i < revenueByHomestay.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      revenueByHomestay.keys.elementAt(i),
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard Free')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db
            .collection('bookings')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snap.data!.docs;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ====== DOANH THU ======
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tổng doanh thu: ${totalRevenue.toStringAsFixed(0)} VNĐ',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 220,
                        child: Card(
                          elevation: 3,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: revenueChart(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(),

                // ====== DANH SÁCH BOOKING ======
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: data.length,
                  itemBuilder: (context, i) {
                    final b = data[i];
                    final id = b.id;

                    final name = b['homestayName'] ?? 'Unknown';
                    final status = b['status'] ?? 'pending';

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text(name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (b['checkInDate'] != null)
                              Text(
                                  "Check-in: ${dateFormat.format((b['checkInDate'] as Timestamp).toDate())}"),
                            if (b['checkOutDate'] != null)
                              Text(
                                  "Check-out: ${dateFormat.format((b['checkOutDate'] as Timestamp).toDate())}"),
                            Text("Phương thức: ${b['paymentMethod']}"),
                            Text("Tổng: ${b['totalPrice']} VNĐ"),
                            Text("Trạng thái: $status"),
                          ],
                        ),
                        trailing: Column(
                          children: [
                            if (status == 'pending' || status == 'waiting')
                              ElevatedButton(
                                onPressed: () =>
                                    updateStatus(id, 'confirmed', name),
                                child: const Text('Confirm'),
                              ),
                            if (status == 'confirmed')
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red),
                                onPressed: () =>
                                    updateStatus(id, 'checked_out', name),
                                child: const Text('Check-out'),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
