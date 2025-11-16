import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/homestay.dart';
import 'add_edit_homestay_screen.dart';
import 'admin_booking.dart';
import 'profile_screen.dart';
import 'login_screen.dart';
import 'homestay_detail_screen.dart';

class AdminHomestayListScreen extends StatefulWidget {
  const AdminHomestayListScreen({super.key});

  @override
  State<AdminHomestayListScreen> createState() => _AdminHomestayListScreenState();
}

class _AdminHomestayListScreenState extends State<AdminHomestayListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchKeyword = '';

  Stream<List<Homestay>> getHomestays() {
    return FirebaseFirestore.instance
        .collection('homestays')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Homestay.fromFirestore(doc.id, doc.data())).toList());
  }

  Future<void> deleteHomestay(String id) async {
    try {
      await FirebaseFirestore.instance.collection('homestays').doc(id).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Xóa homestay thành công!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi xóa: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Homestay'),
        backgroundColor: Colors.teal,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
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
                  FirebaseAuth.instance.signOut();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'booking',
                child: Text('📋 Quản lý đơn'),
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
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Thêm Homestay',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddOrEditHomestayScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 🔍 Thanh tìm kiếm
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm theo tên hoặc địa chỉ...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchKeyword.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchKeyword = '';
                            _searchController.clear();
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchKeyword = value.toLowerCase();
                });
              },
            ),
          ),

          // 📋 Danh sách Homestay
          Expanded(
            child: StreamBuilder<List<Homestay>>(
              stream: getHomestays(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Lỗi: ${snapshot.error}'));
                }
                final data = snapshot.data ?? [];
                if (data.isEmpty) {
                  return const Center(child: Text('Chưa có homestay nào.'));
                }

                // Lọc theo từ khóa
                final filtered = data.where((hs) {
                  final name = hs.name.toLowerCase();
                  final address = hs.address.toLowerCase();
                  return name.contains(_searchKeyword) || address.contains(_searchKeyword);
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('Không tìm thấy homestay nào.'));
                }

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final hs = filtered[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 3,
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            hs.imageUrl,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.image_not_supported, size: 40),
                          ),
                        ),
                        title: Text(
                          hs.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Text(hs.address),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => HomestayDetailScreen(homestay: hs, isAdmin: true),
                            ),
                          );
                        },
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // ✏️ Nút sửa
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blueAccent),
                              tooltip: 'Sửa Homestay',
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AddOrEditHomestayScreen(homestay: hs),
                                  ),
                                );
                              },
                            ),
                            // 🗑️ Nút xóa
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.redAccent),
                              tooltip: 'Xóa Homestay',
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Xác nhận xóa'),
                                    content:
                                        Text('Bạn có chắc muốn xóa "${hs.name}" không?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Hủy'),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.redAccent,
                                        ),
                                        onPressed: () {
                                          Navigator.pop(context);
                                          deleteHomestay(hs.id);
                                        },
                                        child: const Text('Xóa'),
                                      ),
                                    ],
                                  ),
                                );
                              },
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
    );
  }
}
