import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carousel_slider/carousel_slider.dart';
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
            // Image carousel
            if (h.imageUrls.isNotEmpty)
              CarouselSlider(
                options: CarouselOptions(
                  height: 250,
                  autoPlay: true,
                  enlargeCenterPage: true,
                  aspectRatio: 16 / 9,
                  autoPlayInterval: const Duration(seconds: 3),
                ),
                items: h.imageUrls.map((url) {
                  return Builder(
                    builder: (BuildContext context) {
                      return Container(
                        width: MediaQuery.of(context).size.width,
                        margin: const EdgeInsets.symmetric(horizontal: 5.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: NetworkImage(url),
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
              )
            else
              Image.network(h.imageUrl, fit: BoxFit.cover, height: 250),

            // Reviews section
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('homestays')
                  .doc(h.id)
                  .collection('reviews')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Chưa có đánh giá nào.',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  );
                }

                final reviews = snapshot.data!.docs;
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Đánh giá từ khách hàng',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...reviews.map((review) {
                        final data = review.data() as Map<String, dynamic>;
                        final rating = data['rating'] ?? 0;
                        final comment = data['comment'] ?? '';
                        final userName = data['userName'] ?? 'Khách';
                        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.person, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      userName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Spacer(),
                                    Row(
                                      children: List.generate(5, (index) {
                                        return Icon(
                                          index < rating ? Icons.star : Icons.star_border,
                                          color: Colors.orange,
                                          size: 16,
                                        );
                                      }),
                                    ),
                                  ],
                                ),
                                if (createdAt != null)
                                  Text(
                                    '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                if (comment.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(comment),
                                ],
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
            ),

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
                  Text('Sức chứa tối đa: ${h.maxGuests} khách'),
                  const SizedBox(height: 12),
                  Text('Phụ thu khách thêm: ${h.extraGuestFee} đ/khách/đêm'),
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
