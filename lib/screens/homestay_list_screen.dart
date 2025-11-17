import 'package:bookinghomestay/screens/admin_booking.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/homestay.dart';
import 'homestay_detail_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'my_bookings_screen.dart';
import 'admin_homestay_list_screen.dart'; // Thêm import này

class HomestayListScreen extends StatefulWidget {
  const HomestayListScreen({super.key});

  @override
  State<HomestayListScreen> createState() => _HomestayListScreenState();
}

class _HomestayListScreenState extends State<HomestayListScreen> {
  int _currentIndex = 0; // Thêm bottom navigation
  final TextEditingController _searchController = TextEditingController();
  String _searchKeyword = '';
  String _selectedLocation = 'Tất cả';
  String _selectedSort = 'popular';
  double _priceRange = 2000000; // Giá mặc định 2 triệu
  int _selectedRating = 0;

  String _userRole = 'user';
  String _userName = 'Người dùng';
  String _userId = '';
  int _notificationCount = 0;
  bool _notificationsRead = false;

  // Danh sách địa điểm và categories
  final List<String> _locations = ['Tất cả', 'Đà Lạt', 'Hà Nội', 'Đà Nẵng', 'Phú Quốc', 'Sapa', 'Nha Trang'];
  final List<Map<String, dynamic>> _categories = [
    {'icon': Icons.house, 'label': 'Tất cả', 'type': 'all'},
    {'icon': Icons.nature, 'label': 'View đẹp', 'type': 'scenic'},
    {'icon': Icons.spa, 'label': 'Sang trọng', 'type': 'luxury'},
    {'icon': Icons.family_restroom, 'label': 'Gia đình', 'type': 'family'},
    {'icon': Icons.people, 'label': 'Nhóm bạn', 'type': 'group'},
  ];
  String _selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      setState(() {
        _userRole = doc.data()?['role']?.toString().toLowerCase() ?? 'user';
        _userName = doc.data()?['name'] ?? 'Người dùng';
        _userId = user.uid;
      });
      _loadNotificationCount();
    }
  }

  Future<void> _loadNotificationCount() async {
    if (_userRole == 'admin') {
      final snapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('status', whereIn: ['pending', 'waiting'])
          .get();
      setState(() {
        _notificationCount = snapshot.docs.length;
      });
    } else {
      final snapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: _userId)
          .where('status', whereIn: ['confirmed', 'waiting'])
          .get();
      setState(() {
        _notificationCount = snapshot.docs.length;
      });
    }
  }

  Stream<List<Homestay>> getHomestays() {
    return FirebaseFirestore.instance
        .collection('homestays')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Homestay.fromFirestore(doc.id, doc.data())).toList());
  }

  List<Homestay> _filterAndSortHomestays(List<Homestay> homestays) {
    // Lọc theo từ khóa và điều kiện
    var filtered = homestays.where((hs) {
      final matchesSearch = _searchKeyword.isEmpty ||
          hs.name.toLowerCase().contains(_searchKeyword) ||
          hs.address.toLowerCase().contains(_searchKeyword) ||
          hs.description.toLowerCase().contains(_searchKeyword) ||
          hs.location.toLowerCase().contains(_searchKeyword) ||
          hs.facilities.any((facility) => facility.toLowerCase().contains(_searchKeyword));

      final matchesLocation = _selectedLocation == 'Tất cả' ||
          hs.address.contains(_selectedLocation) ||
          hs.location.contains(_selectedLocation);

      final matchesPrice = hs.price <= _priceRange;
      final matchesRating = hs.rating >= _selectedRating;

      final matchesCategory = _selectedCategory == 'all' ||
          (_selectedCategory == 'scenic' && (hs.description.contains('view') || hs.description.contains('cảnh'))) ||
          (_selectedCategory == 'luxury' && (hs.kind.contains('sang trọng') || hs.price > 1000000)) ||
          (_selectedCategory == 'family' && (hs.kind.contains('gia đình') || hs.maxGuests >= 4)) ||
          (_selectedCategory == 'group' && hs.maxGuests >= 6);

      return matchesSearch && matchesLocation && matchesPrice && matchesRating && matchesCategory;
    }).toList();

    // Sắp xếp
    switch (_selectedSort) {
      case 'price_low':
        filtered.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_high':
        filtered.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'rating':
        filtered.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'popular':
      default:
        // Giữ nguyên thứ tự (popular có thể dựa trên số lượt booking sau này)
        break;
    }

    return filtered;
  }

  // Hàm mở bộ lọc
  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        child: Column(
          children: [
            // Header của bottom sheet
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.teal[50],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(25),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '🔍 Bộ lọc nâng cao',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.teal),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Lọc theo địa điểm
                  _buildFilterSection(
                    '📍 Thành phố',
                    DropdownButton<String>(
                      value: _selectedLocation,
                      isExpanded: true,
                      items: _locations.map((location) {
                        return DropdownMenuItem(
                          value: location,
                          child: Text(location),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedLocation = value!;
                        });
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Lọc theo khoảng giá
                  _buildFilterSection(
                    '💰 Khoảng giá (tối đa: ${_priceRange.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ)',
                    Column(
                      children: [
                        Slider(
                          value: _priceRange,
                          min: 100000,
                          max: 5000000,
                          divisions: 49,
                          onChanged: (value) {
                            setState(() {
                              _priceRange = value;
                            });
                          },
                          activeColor: Colors.teal,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('100.000đ', style: TextStyle(color: Colors.grey[600])),
                            Text('5.000.000đ', style: TextStyle(color: Colors.grey[600])),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Lọc theo số sao
                  _buildFilterSection(
                    '⭐ Đánh giá tối thiểu',
                    Row(
                      children: List.generate(5, (index) {
                        return Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedRating = index + 1;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _selectedRating >= index + 1 
                                    ? Colors.amber 
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.star,
                                    color: _selectedRating >= index + 1 
                                        ? Colors.white 
                                        : Colors.grey,
                                    size: 20,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${index + 1}+',
                                    style: TextStyle(
                                      color: _selectedRating >= index + 1 
                                          ? Colors.white 
                                          : Colors.grey,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Sắp xếp
                  _buildFilterSection(
                    '🔀 Sắp xếp theo',
                    DropdownButton<String>(
                      value: _selectedSort,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 'popular', child: Text('Phổ biến nhất')),
                        DropdownMenuItem(value: 'rating', child: Text('Đánh giá cao nhất')),
                        DropdownMenuItem(value: 'price_low', child: Text('Giá thấp → cao')),
                        DropdownMenuItem(value: 'price_high', child: Text('Giá cao → thấp')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedSort = value!;
                        });
                      },
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Nút áp dụng và đặt lại
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              _selectedLocation = 'Tất cả';
                              _priceRange = 2000000;
                              _selectedRating = 0;
                              _selectedSort = 'popular';
                            });
                            Navigator.pop(context);
                          },
                          child: const Text(
                            'Đặt lại',
                            style: TextStyle(color: Colors.teal),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            setState(() {});
                          },
                          child: const Text(
                            'Áp dụng',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
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

  Widget _buildFilterSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Colors.teal,
          ),
        ),
        const SizedBox(height: 8),
        content,
      ],
    );
  }

  Widget _buildHomestayCard(Homestay homestay, BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => HomestayDetailScreen(homestay: homestay),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hình ảnh homestay
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: Image.network(
                    homestay.imageUrl,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 180,
                      color: Colors.grey[200],
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.home_work, size: 50, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('Không thể tải ảnh', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Badge đánh giá
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${homestay.rating}.0',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Thông tin homestay
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          homestay.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${homestay.price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          homestay.address,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    homestay.description.length > 100
                        ? '${homestay.description.substring(0, 100)}...'
                        : homestay.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.people, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            'Tối đa ${homestay.maxGuests} khách',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => HomestayDetailScreen(homestay: homestay),
                            ),
                          );
                        },
                        child: const Text(
                          'Đặt ngay',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🏡 HomestayFinder',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Xin chào, $_userName!',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.teal,
        elevation: 0,
        actions: [
          // Notification icon với badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {
                  setState(() {
                    _notificationsRead = true;
                  });
                  if (_userRole == 'admin') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AdminBookingManager()),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MyBookingsScreen()),
                    );
                  }
                },
              ),
              if (_notificationCount > 0 && !_notificationsRead)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      _notificationCount > 9 ? '9+' : _notificationCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.teal,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: '🔍 Tìm kiếm homestay...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchKeyword = value.toLowerCase();
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.filter_list_alt, color: Colors.teal),
                    onPressed: () => _showFilterBottomSheet(context),
                    tooltip: 'Bộ lọc',
                  ),
                ),
              ],
            ),
          ),

          // Categories Horizontal List
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category['type'];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = category['type'] as String;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.teal : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: isSelected ? null : Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          category['icon'] as IconData,
                          color: isSelected ? Colors.white : Colors.teal,
                          size: 20,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          category['label'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected ? Colors.white : Colors.teal,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Danh sách homestay
          Expanded(
            child: StreamBuilder<List<Homestay>>(
              stream: getHomestays(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.teal),
                  );
                }
                
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 60, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          'Lỗi: ${snapshot.error}',
                          style: const TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }
                
                final data = snapshot.data ?? [];
                final filteredHomestays = _filterAndSortHomestays(data);
                
                if (filteredHomestays.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off, size: 60, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text(
                          'Không tìm thấy homestay phù hợp',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchKeyword.isNotEmpty ? 'Từ khóa: "$_searchKeyword"' : 'Hãy thử điều chỉnh bộ lọc',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() {});
                  },
                  child: ListView.builder(
                    itemCount: filteredHomestays.length,
                    itemBuilder: (context, index) {
                      return _buildHomestayCard(filteredHomestays[index], context);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          
          // Xử lý navigation
          switch (index) {
            case 0: // Trang chủ - Đã ở trang chủ
              break;
            case 1: // Quản lý/Đơn đặt
              if (_userRole == 'admin') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminBookingManager()),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyBookingsScreen()),
                );
              }
              // Reset về tab 0 sau khi chuyển trang
              Future.delayed(const Duration(milliseconds: 100), () {
                if (mounted) {
                  setState(() {
                    _currentIndex = 0;
                  });
                }
              });
              break;
            case 2: // Profile
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
              // Reset về tab 0 sau khi chuyển trang
              Future.delayed(const Duration(milliseconds: 100), () {
                if (mounted) {
                  setState(() {
                    _currentIndex = 0;
                  });
                }
              });
              break;
          }
        },
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.bookmark_border),
                if (_notificationCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 14,
                        minHeight: 14,
                      ),
                    ),
                  ),
              ],
            ),
            label: _userRole == 'admin' ? 'Quản lý' : 'Đơn của tôi',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Cá nhân',
          ),
        ],
      ),
    );
  }
}