import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/homestay.dart';
import 'homestay_detail_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class HomestayListScreen extends StatefulWidget {
  const HomestayListScreen({super.key});

  @override
  State<HomestayListScreen> createState() => _HomestayListScreenState();
}

class _HomestayListScreenState extends State<HomestayListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchKeyword = '';
  double _minPrice = 0;
  double _maxPrice = 5000000;
  double _currentMin = 0;
  double _currentMax = 5000000;
  int _minStars = 0;

  Stream<List<Homestay>> getHomestays() {
    return FirebaseFirestore.instance
        .collection('homestays')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Homestay.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  Future<void> _openMap(String address) async {
    final encodedAddress = Uri.encodeComponent(address);
    final url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$encodedAddress');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw 'Không thể mở bản đồ.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Danh sách Homestay')),
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
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

          // 💰 Lọc theo giá
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Giá: ${_currentMin.toInt()}đ'),
                    Text('${_currentMax.toInt()}đ'),
                  ],
                ),
                RangeSlider(
                  min: _minPrice,
                  max: _maxPrice,
                  divisions: 50,
                  labels: RangeLabels(
                    '${_currentMin.toInt()}đ',
                    '${_currentMax.toInt()}đ',
                  ),
                  values: RangeValues(_currentMin, _currentMax),
                  onChanged: (values) {
                    setState(() {
                      _currentMin = values.start;
                      _currentMax = values.end;
                    });
                  },
                  activeColor: Colors.teal,
                ),
              ],
            ),
          ),

          // ⭐ Lọc theo sao
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Row(
              children: [
                const Text('Tối thiểu: ', style: TextStyle(fontSize: 16)),
                for (int i = 1; i <= 5; i++)
                  IconButton(
                    icon: Icon(
                      i <= _minStars ? Icons.star : Icons.star_border,
                      color: Colors.orange,
                    ),
                    onPressed: () {
                      setState(() {
                        _minStars = i == _minStars ? 0 : i;
                      });
                    },
                  ),
              ],
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
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Chưa có homestay nào.'));
                }

                // 🔍 Lọc theo từ khóa, giá và sao
                final filtered = snapshot.data!.where((hs) {
                  final name = hs.name.toLowerCase();
                  final address = hs.address.toLowerCase();
                  final matchesKeyword = name.contains(_searchKeyword) ||
                      address.contains(_searchKeyword);
                  final matchesPrice =
                      hs.price >= _currentMin && hs.price <= _currentMax;
                  final matchesStars = hs.rating >= _minStars;
                  return matchesKeyword && matchesPrice && matchesStars;
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(
                      child: Text('Không tìm thấy homestay nào.'));
                }

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final hs = filtered[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
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
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            InkWell(
                              onTap: () {
                                if (hs.address.isNotEmpty) {
                                  _openMap(hs.address);
                                }
                              },
                              child: Row(
                                children: [
                                  const Icon(Icons.location_on,
                                      color: Colors.redAccent, size: 14),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      hs.address.isNotEmpty
                                          ? hs.address
                                          : 'Chưa có địa chỉ',
                                      style: const TextStyle(
                                          fontSize: 13,
                                          decoration: TextDecoration.underline,
                                          color: Colors.blueAccent),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text('${hs.price} đ/đêm',
                                style:
                                    const TextStyle(color: Color.fromARGB(255, 234, 108, 17))),
                            Row(
                              children: List.generate(
                                hs.rating,
                                (i) => const Icon(Icons.star,
                                    color: Colors.orange, size: 16),
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  HomestayDetailScreen(homestay: hs),
                            ),
                          );
                        },
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
