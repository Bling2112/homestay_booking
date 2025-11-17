import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'admin_booking.dart';
import 'admin_homestay_list_screen.dart';
import 'profile_screen.dart';
import 'login_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  double totalRevenue = 0;
  int totalBookings = 0;
  int pendingBookings = 0;
  int confirmedBookings = 0;
  Map<String, double> revenueByHomestay = {};
  Map<String, int> bookingsByStatus = {};

  @override
  void initState() {
    super.initState();
    _calculateStats();
  }

  Future<void> _calculateStats() async {
    final bookingsSnapshot = await _db.collection('bookings').get();
    final homestaysSnapshot = await _db.collection('homestays').get();

    double total = 0;
    int bookings = 0;
    int pending = 0;
    int confirmed = 0;
    Map<String, double> byHomestay = {};
    Map<String, int> byStatus = {};

    for (var doc in bookingsSnapshot.docs) {
      final data = doc.data();
      final price = (data['totalPrice'] ?? 0).toDouble();
      final name = data['homestayName'] ?? 'Unknown';
      final status = data['status'] ?? 'pending';

      if (data['paymentStatus'] == 'paid') {
        total += price;
        byHomestay[name] = (byHomestay[name] ?? 0) + price;
      }

      bookings++;
      byStatus[status] = (byStatus[status] ?? 0) + 1;

      if (status == 'pending') pending++;
      if (status == 'confirmed') confirmed++;
    }

    setState(() {
      totalRevenue = total;
      totalBookings = bookings;
      pendingBookings = pending;
      confirmedBookings = confirmed;
      revenueByHomestay = byHomestay;
      bookingsByStatus = byStatus;
    });
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueChart() {
    if (revenueByHomestay.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bar_chart, size: 48, color: Colors.grey),
              SizedBox(height: 8),
              Text(
                'Chưa có dữ liệu doanh thu',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    final barGroups = <BarChartGroupData>[];
    int index = 0;

    revenueByHomestay.forEach((name, revenue) {
      barGroups.add(
        BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: revenue / 1000, // Convert to thousands
              width: 20,
              color: Colors.teal,
              borderRadius: BorderRadius.circular(4),
            )
          ],
        ),
      );
      index++;
    });

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            '📊 Doanh thu theo Homestay',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.teal,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: BarChart(
              BarChartData(
                barGroups: barGroups,
                maxY: (revenueByHomestay.values.reduce((a, b) => a > b ? a : b) / 1000) * 1.2,
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i >= 0 && i < revenueByHomestay.length) {
                          final name = revenueByHomestay.keys.elementAt(i);
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              name.length > 10 ? '${name.substring(0, 10)}...' : name,
                              style: const TextStyle(fontSize: 10),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}k',
                          style: const TextStyle(fontSize: 12),
                        );
                      },
                    ),
                  ),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(show: true),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          '🏠 Admin Dashboard',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.teal,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'homestay':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminHomestayListScreen()),
                  );
                  break;
                case 'booking':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminBookingManager()),
                  );
                  break;
                case 'profile':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                  break;
                case 'logout':
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Xác nhận đăng xuất'),
                      content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Hủy'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                          ),
                          child: const Text('Đăng xuất'),
                        ),
                      ],
                    ),
                  ).then((shouldLogout) {
                    if (shouldLogout == true) {
                      FirebaseAuth.instance.signOut();
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    }
                  });
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'homestay',
                child: Text('🏠 Quản lý Homestay'),
              ),
              const PopupMenuItem(
                value: 'booking',
                child: Text('📋 Quản lý đơn đặt'),
              ),
              const PopupMenuItem(
                value: 'profile',
                child: Text('👤 Thông tin cá nhân'),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Text('🚪 Đăng xuất'),
              ),
            ],
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: () async {
          await _calculateStats();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.teal, Colors.tealAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chào mừng Admin! 👋',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Quản lý homestay và đơn đặt phòng của bạn',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Stats Grid
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildStatCard(
                    'Tổng doanh thu',
                    '${NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(totalRevenue)}',
                    Icons.attach_money,
                    Colors.green,
                  ),
                  _buildStatCard(
                    'Tổng đơn đặt',
                    totalBookings.toString(),
                    Icons.book_online,
                    Colors.blue,
                  ),
                  _buildStatCard(
                    'Đơn chờ xác nhận',
                    pendingBookings.toString(),
                    Icons.pending,
                    Colors.orange,
                  ),
                  _buildStatCard(
                    'Đơn đã xác nhận',
                    confirmedBookings.toString(),
                    Icons.check_circle,
                    Colors.teal,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Revenue Chart
              _buildRevenueChart(),

              const SizedBox(height: 24),

              // Recent Bookings
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📋 Đơn đặt gần đây',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                    const SizedBox(height: 16),
                    StreamBuilder<QuerySnapshot>(
                      stream: _db
                          .collection('bookings')
                          .orderBy('createdAt', descending: true)
                          .limit(5)
                          .snapshots(),
                      builder: (context, snap) {
                        if (!snap.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final bookings = snap.data!.docs;
                        if (bookings.isEmpty) {
                          return const Center(
                            child: Text(
                              'Chưa có đơn đặt nào',
                              style: TextStyle(color: Colors.grey),
                            ),
                          );
                        }

                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: bookings.length,
                          itemBuilder: (context, i) {
                            final b = bookings[i];
                            final data = b.data() as Map<String, dynamic>;
                            final name = data['homestayName'] ?? 'Unknown';
                            final status = data['status'] ?? 'pending';
                            final userName = data['userName'] ?? 'Khách';
                            final totalPrice = data['totalPrice'] ?? 0;

                            Color statusColor;
                            switch (status) {
                              case 'confirmed':
                                statusColor = Colors.green;
                                break;
                              case 'pending':
                                statusColor = Colors.orange;
                                break;
                              case 'cancelled':
                                statusColor = Colors.red;
                                break;
                              default:
                                statusColor = Colors.grey;
                            }

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '👤 $userName',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '💰 ${NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(totalPrice)}',
                                          style: const TextStyle(
                                            color: Colors.teal,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _getStatusText(status),
                                      style: TextStyle(
                                        color: statusColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminHomestayListScreen()),
          );
        },
        backgroundColor: Colors.teal,
        icon: const Icon(Icons.add),
        label: const Text('Thêm Homestay'),
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Chờ xác nhận';
      case 'confirmed':
        return 'Đã xác nhận';
      case 'cancelled':
        return 'Đã hủy';
      case 'completed':
        return 'Hoàn tất';
      default:
        return status;
    }
  }
}
