import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/email_service.dart';

class AdminBookingManager extends StatefulWidget {
  const AdminBookingManager({super.key});

  @override
  State<AdminBookingManager> createState() => _AdminBookingManagerState();
}

class _AdminBookingManagerState extends State<AdminBookingManager> {
  String? selectedHomestay;
  List<String> homestayNames = [];
  Map<String, double> monthlyRevenue = {};
  Map<String, Map<String, double>> homestayRevenueByMonth = {};
  String? selectedMonth;


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
  void initState() {
    super.initState();
    _loadHomestayNames();
    _loadMonthlyRevenue();
    _loadHomestayRevenueByMonth();
  }

  Future<void> _loadHomestayNames() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('homestays').get();
      setState(() {
        homestayNames = snapshot.docs
            .where((doc) {
              if (!doc.exists) return false;
              try {
                final data = doc.data() as Map<String, dynamic>;
                return data.containsKey('name') && data['name'] is String;
              } catch (e) {
                return false;
              }
            })
            .map((doc) {
              try {
                final data = doc.data() as Map<String, dynamic>;
                return data['name'] as String;
              } catch (e) {
                return '';
              }
            })
            .where((name) => name.isNotEmpty)
            .toList();
      });
    } catch (e) {
      print('Error loading homestay names: $e');
      setState(() {
        homestayNames = [];
      });
    }
  }

  Future<void> _loadMonthlyRevenue() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('status', isEqualTo: 'confirmed')
          .get();

      Map<String, double> revenue = {};
      for (var doc in snapshot.docs) {
        if (doc.exists) {
          final data = doc.data();
          if (data.containsKey('createdAt') && data.containsKey('totalPrice')) {
            final createdAt = (data['createdAt'] as Timestamp).toDate();
            final monthKey = DateFormat('yyyy-MM').format(createdAt);
            final price = (data['totalPrice'] as int).toDouble();
            revenue[monthKey] = (revenue[monthKey] ?? 0) + price;
          }
        }
      }

      setState(() {
        monthlyRevenue = revenue;
      });
    } catch (e) {
      print('Error loading monthly revenue: $e');
      setState(() {
        monthlyRevenue = {};
      });
    }
  }

  Future<void> _loadHomestayRevenueByMonth() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('status', isEqualTo: 'confirmed')
          .get();

      Map<String, Map<String, double>> revenue = {};
      for (var doc in snapshot.docs) {
        if (doc.exists) {
          final data = doc.data();
          if (data.containsKey('createdAt') && data.containsKey('totalPrice') && data.containsKey('homestayName')) {
            final createdAt = (data['createdAt'] as Timestamp).toDate();
            final monthKey = DateFormat('yyyy-MM').format(createdAt);
            final homestayName = data['homestayName'] as String;
            final price = (data['totalPrice'] as int).toDouble();

            if (!revenue.containsKey(monthKey)) {
              revenue[monthKey] = {};
            }
            revenue[monthKey]![homestayName] = (revenue[monthKey]![homestayName] ?? 0) + price;
          }
        }
      }

      setState(() {
        homestayRevenueByMonth = revenue;
      });
    } catch (e) {
      print('Error loading homestay revenue by month: $e');
      setState(() {
        homestayRevenueByMonth = {};
      });
    }
  }



  bool _canModifyBooking(DateTime createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt).inDays;
    return difference <= 1;
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Quản lý đặt phòng"),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Đơn đặt phòng'),
              Tab(text: 'Thống kê'),
            ],
          ),
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
                      onPressed: () {
                        // Mark all pending bookings as read (optional)
                        // For now, just navigate or perform action
                      },
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

        body: TabBarView(
          children: [
            // Tab 1: Danh sách booking
            Column(
              children: [
                // Filter dropdown
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: DropdownButtonFormField<String>(
                    value: selectedHomestay,
                    decoration: const InputDecoration(
                      labelText: 'Lọc theo homestay',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Tất cả')),
                      ...homestayNames.map((name) =>
                          DropdownMenuItem(value: name, child: Text(name))),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedHomestay = value;
                      });
                    },
                  ),
                ),

                // Bookings list
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('bookings')
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, snap) {
                      if (!snap.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snap.hasError) {
                        return Center(child: Text('Error loading bookings: ${snap.error}'));
                      }

                      final bookings = snap.data!.docs.where((doc) => doc.exists).where((doc) {
                        if (selectedHomestay == null) return true;
                        try {
                          final data = doc.data() as Map<String, dynamic>;
                          return data['homestayName'] == selectedHomestay;
                        } catch (e) {
                          return false;
                        }
                      }).toList();

                      if (bookings.isEmpty) {
                        return const Center(child: Text("Không có booking nào."));
                      }

                      return ListView.builder(
                        itemCount: bookings.length,
                        itemBuilder: (context, i) {
                          final b = bookings[i];

                          // Skip documents that don't exist
                          if (!b.exists) return const SizedBox.shrink();

                          final dataMap = b.data() as Map<String, dynamic>;
                          final id = b.id;
                          final status = dataMap['status'] ?? 'pending';
                          final userName = dataMap['userName'] ?? 'Khách';
                          final userEmail = dataMap['userEmail'] ?? '';
                          final homestayName = dataMap['homestayName'] ?? '';

                          // Check if required fields exist
                          if (!dataMap.containsKey('checkInDate') ||
                              !dataMap.containsKey('checkOutDate') ||
                              !dataMap.containsKey('createdAt')) {
                            return const SizedBox.shrink();
                          }

                          final checkIn = (dataMap['checkInDate'] as Timestamp).toDate();
                          final checkOut = (dataMap['checkOutDate'] as Timestamp).toDate();
                          final createdAt = (dataMap['createdAt'] as Timestamp).toDate();
                          final canModify = _canModifyBooking(createdAt);

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
                                  Text("👤 Khách: $userName"),
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
                                      if (status == "pending" && canModify)
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

                                      if (status == "pending" && canModify)
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

                                      if (status == "pending" && !canModify)
                                        const Text(
                                          "⏰ Quá hạn 1 ngày, không thể sửa",
                                          style: TextStyle(color: Colors.grey),
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
                ),
              ],
            ),

            // Tab 2: Thống kê doanh thu
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Doanh thu theo tháng',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  if (monthlyRevenue.isEmpty)
                    const Center(child: Text('Chưa có dữ liệu doanh thu'))
                  else
                    SizedBox(
                      height: 300,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: monthlyRevenue.values.reduce((a, b) => a > b ? a : b) * 1.2,
                          barTouchData: BarTouchData(enabled: true),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final months = monthlyRevenue.keys.toList();
                                  if (value.toInt() < months.length) {
                                    return Text(months[value.toInt()].substring(5));
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  return Text('${value.toInt()}k', style: const TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.w500));
                                },
                              ),
                            ),
                            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(show: false),
                          barGroups: monthlyRevenue.entries.map((entry) {
                            final index = monthlyRevenue.keys.toList().indexOf(entry.key);
                            return BarChartGroupData(
                              x: index,
                              barRods: [
                                BarChartRodData(
                                  toY: entry.value / 1000, // Convert to thousands
                                  color: Colors.teal,
                                  width: 20,
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),

                  const SizedBox(height: 20),
                  const Text(
                    'Chi tiết theo tháng:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  ListView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: monthlyRevenue.entries.map((entry) {
                      final month = entry.key;
                      final revenue = entry.value;
                      return ListTile(
                        title: Text('Tháng $month'),
                        trailing: SizedBox(
                          width: 100,
                          child: Text(
                            '${revenue.toStringAsFixed(0)} VND',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.teal,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.right,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),
                  const Text(
                    'Doanh thu theo homestay trong tháng:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  // Month selector
                  DropdownButtonFormField<String>(
                    value: selectedMonth,
                    decoration: const InputDecoration(
                      labelText: 'Chọn tháng',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Tất cả tháng')),
                      ...monthlyRevenue.keys.map((month) =>
                          DropdownMenuItem(value: month, child: Text('Tháng $month'))),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedMonth = value;
                      });
                    },
                  ),

                  const SizedBox(height: 10),

                  if (homestayRevenueByMonth.isEmpty)
                    const Center(child: Text('Chưa có dữ liệu doanh thu theo homestay'))
                  else if (selectedMonth != null && !homestayRevenueByMonth.containsKey(selectedMonth))
                    const Center(child: Text('Không có dữ liệu cho tháng đã chọn'))
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (selectedMonth != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Text(
                              'Tổng doanh thu tháng $selectedMonth: ${monthlyRevenue[selectedMonth]?.toStringAsFixed(0) ?? 0} VND',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal,
                              ),
                            ),
                          ),
                        ListView(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: (selectedMonth == null
                              ? homestayRevenueByMonth.entries
                              : homestayRevenueByMonth.entries.where((entry) => entry.key == selectedMonth)
                          ).map((monthEntry) {
                            final month = monthEntry.key;
                            final homestayRevenues = monthEntry.value;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (selectedMonth == null)
                                  Text(
                                    'Tháng $month',
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                  ),
                                if (selectedMonth == null) const SizedBox(height: 5),
                                ...homestayRevenues.entries.map((homestayEntry) {
                                  final homestayName = homestayEntry.key;
                                  final revenue = homestayEntry.value;
                                  return ListTile(
                                    title: Text(homestayName),
                                    trailing: SizedBox(
                                      width: 100,
                                      child: Text(
                                        '${revenue.toStringAsFixed(0)} VND',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.teal,
                                          fontSize: 14,
                                        ),
                                        textAlign: TextAlign.right,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                const SizedBox(height: 10),
                              ],
                            );
                          }).toList(),
                        ),
                      ],
                    ),

                ],
              ),
            ),
          ],
        ),
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
