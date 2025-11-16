import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/homestay.dart';
import 'booking_screen.dart';
import 'add_edit_homestay_screen.dart';

class HomestayDetailScreen extends StatelessWidget {
  final Homestay homestay;
  final bool isAdmin;
  const HomestayDetailScreen({super.key, required this.homestay, this.isAdmin = false});

  Future<void> _openMap(String address) async {
    final encodedAddress = Uri.encodeComponent(address);
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$encodedAddress');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw 'Không thể mở bản đồ.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = homestay;

    return Scaffold(
      appBar: AppBar(title: Text(h.name)),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Image.network(h.imageUrl, fit: BoxFit.cover),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    h.location,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () {
                      if (h.address.isNotEmpty) _openMap(h.address);
                    },
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.redAccent, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          h.address.isNotEmpty ? h.address : 'Chưa có địa chỉ',
                          style: const TextStyle(
                            fontSize: 13,
                            decoration: TextDecoration.underline,
                            color: Colors.blueAccent,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(h.description),
                  const SizedBox(height: 12),
                  Text(
                    'Giá: ${h.price} đ/đêm',
                    style: const TextStyle(color: Colors.teal),
                  ),
                  const SizedBox(height: 12),
                  Text('Loại: ${h.kind}'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: h.facilities.map((f) => Chip(label: Text(f))).toList(),
                  ),
                  const SizedBox(height: 20),

                  // 🔘 Nút đặt homestay hoặc chỉnh sửa (tùy theo role)
                  if (!isAdmin)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BookingScreen(homestay: h),
                            ),
                          );
                        },
                        child: const Text('Đặt ngay'),
                      ),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AddOrEditHomestayScreen(homestay: h),
                                ),
                              );
                            },
                            icon: const Icon(Icons.edit),
                            label: const Text('Chỉnh sửa'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Xác nhận xóa'),
                                  content: Text('Bạn có chắc muốn xóa "${h.name}" không?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text('Hủy'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      child: const Text('Xóa'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                try {
                                  await FirebaseFirestore.instance.collection('homestays').doc(h.id).delete();
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Xóa homestay thành công!')),
                                    );
                                    Navigator.pop(context);
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Lỗi khi xóa: $e')),
                                    );
                                  }
                                }
                              }
                            },
                            icon: const Icon(Icons.delete),
                            label: const Text('Xóa'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                          ),
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
