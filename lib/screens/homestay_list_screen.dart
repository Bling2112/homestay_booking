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
import 'admin_homestay_list_screen.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'favorites_screen.dart';

class HomestayListScreen extends StatefulWidget {
  const HomestayListScreen({super.key});

  @override
  State<HomestayListScreen> createState() => _HomestayListScreenState();
}

class _HomestayListScreenState extends State<HomestayListScreen> {
  int _currentIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchKeyword = '';
  String _selectedLocation = 'Tất cả';
  String _selectedSort = 'popular';
  double _priceRange = 2000000;
  int _selectedRating = 0;
  int _currentCarouselIndex = 0;

  String _userRole = 'user';
  String _userName = 'Người dùng';
  String _userId = '';
  int _notificationCount = 0;
  bool _notificationsRead = false;
  Set<String> _favoriteIds = {};

  // Danh sách địa điểm và categories
  final List<String> _locations = [
    'Tất cả',
    'Đà Lạt',
    'Hà Nội',
    'Đà Nẵng',
    'Phú Quốc',
    'Sapa',
    'Nha Trang',
  ];
  final List<Map<String, dynamic>> _categories = [
    {
      'icon': Icons.house,
      'label': 'Tất cả',
      'type': 'all',
      'color': Colors.blue,
    },
    {
      'icon': Icons.nature,
      'label': 'View đẹp',
      'type': 'scenic',
      'color': Colors.green,
    },
    {
      'icon': Icons.spa,
      'label': 'Sang trọng',
      'type': 'luxury',
      'color': Colors.purple,
    },
    {
      'icon': Icons.family_restroom,
      'label': 'Gia đình',
      'type': 'family',
      'color': Colors.orange,
    },
    {
      'icon': Icons.people,
      'label': 'Nhóm bạn',
      'type': 'group',
      'color': Colors.red,
    },
    {
      'icon': Icons.beach_access,
      'label': 'Biển',
      'type': 'beach',
      'color': Colors.teal,
    },
    {
      'icon': Icons.landscape,
      'label': 'Núi rừng',
      'type': 'mountain',
      'color': Colors.brown,
    },
    {
      'icon': Icons.location_city,
      'label': 'Thành phố',
      'type': 'city',
      'color': Colors.blueGrey,
    },
  ];
  String _selectedCategory = 'all';

  // Promotion banners
  final List<Map<String, dynamic>> _promotions = [
    {
      'image':
          'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800',
      'title': 'Ưu đãi đặc biệt',
      'subtitle': 'Giảm đến 30% cho đặt phòng tuần này',
    },
    {
      'image':
          'https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?w=800',
      'title': 'Homestay mới',
      'subtitle': 'Khám phá những địa điểm mới nhất',
    },
    {
      'image':
          'https://images.unsplash.com/photo-1510798831971-661eb04b3739?w=800',
      'title': 'Mùa hè rực rỡ',
      'subtitle': 'Trải nghiệm tuyệt vời cùng gia đình',
    },
  ];

  // Quick actions
  final List<Map<String, dynamic>> _quickActions = [
    {'icon': Icons.calendar_today, 'label': 'Đặt nhanh', 'color': Colors.blue},
    {'icon': Icons.local_offer, 'label': 'Khuyến mãi', 'color': Colors.red},
    {'icon': Icons.favorite, 'label': 'Yêu thích', 'color': Colors.pink},
    {'icon': Icons.history, 'label': 'Lịch sử', 'color': Colors.green},
  ];

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      setState(() {
        _userRole = doc.data()?['role']?.toString().toLowerCase() ?? 'user';
        _userName = doc.data()?['name'] ?? 'Người dùng';
        _userId = user.uid;
      });
      _loadNotificationCount();
      _loadFavoriteIds();
    }
  }

  Future<void> _loadNotificationCount() async {
    if (_userRole == 'admin') {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('bookings')
              .where('status', whereIn: ['pending', 'waiting'])
              .get();
      setState(() {
        _notificationCount = snapshot.docs.length;
      });
    } else {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('bookings')
              .where('userId', isEqualTo: _userId)
              .where('status', whereIn: ['confirmed', 'waiting'])
              .get();
      setState(() {
        _notificationCount = snapshot.docs.length;
      });
    }
  }

  Future<void> _loadFavoriteIds() async {
    if (_userId.isNotEmpty) {
      final snapshot = await FirebaseFirestore.instance
          .collection('favorites')
          .where('userId', isEqualTo: _userId)
          .get();
      setState(() {
        _favoriteIds = snapshot.docs.map((doc) => doc['homestayId'] as String).toSet();
      });
    }
  }

  Future<void> _toggleFavorite(String homestayId) async {
    if (_userId.isEmpty) return;

    final isFavorited = _favoriteIds.contains(homestayId);
    final favoritesRef = FirebaseFirestore.instance.collection('favorites');

    if (isFavorited) {
      // Remove from favorites
      final snapshot = await favoritesRef
          .where('userId', isEqualTo: _userId)
          .where('homestayId', isEqualTo: homestayId)
          .get();
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
      setState(() {
        _favoriteIds.remove(homestayId);
      });
    } else {
      // Add to favorites
      await favoritesRef.add({
        'userId': _userId,
        'homestayId': homestayId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      setState(() {
        _favoriteIds.add(homestayId);
      });
    }
  }

  // ========== CÁC TÍNH NĂNG MỚI ==========

  // 1. Promotion Carousel
  Widget _buildPromotionCarousel() {
    return Column(
      children: [
        CarouselSlider(
          options: CarouselOptions(
            height: 160,
            autoPlay: true,
            enlargeCenterPage: true,
            aspectRatio: 16 / 9,
            autoPlayInterval: const Duration(seconds: 5),
            onPageChanged: (index, reason) {
              setState(() {
                _currentCarouselIndex = index;
              });
            },
          ),
          items:
              _promotions.map((promo) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    image: DecorationImage(
                      image: NetworkImage(promo['image']),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          promo['title'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          promo['subtitle'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children:
              _promotions.asMap().entries.map((entry) {
                return Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        _currentCarouselIndex == entry.key
                            ? Colors.teal
                            : Colors.grey.withOpacity(0.4),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  // 2. Quick Actions Grid
  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Thao tác nhanh',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _quickActions.length,
              itemBuilder: (context, index) {
                final action = _quickActions[index];
                return GestureDetector(
                  onTap: () => _handleQuickAction(action['label']),
                  child: Container(
                    width: 80,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: action['color'].withOpacity(0.1),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: action['color'].withOpacity(0.3),
                            ),
                          ),
                          child: Icon(
                            action['icon'],
                            color: action['color'],
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          action['label'],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 3. Enhanced Categories với animation
  Widget _buildCategories() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Khám phá theo loại',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
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
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? category['color'] : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                      border:
                          isSelected
                              ? null
                              : Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          category['icon'] as IconData,
                          color: isSelected ? Colors.white : category['color'],
                          size: 24,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          category['label'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                isSelected ? Colors.white : category['color'],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 4. Enhanced Search Bar với suggestions
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.teal,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: '🔍 Tìm kiếm homestay, địa điểm...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                      suffixIcon: Icon(Icons.mic, color: Colors.teal),
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
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.filter_list_alt,
                    color: Colors.teal,
                    size: 28,
                  ),
                  onPressed: () => _showEnhancedFilterBottomSheet(context),
                ),
              ),
            ],
          ),
          // Search suggestions
          if (_searchKeyword.isEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 30,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildSearchSuggestion('Đà Lạt view núi'),
                  _buildSearchSuggestion('Homestay gia đình'),
                  _buildSearchSuggestion('Biển Phú Quốc'),
                  _buildSearchSuggestion('View thành phố'),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchSuggestion(String text) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, color: Colors.teal),
      ),
    );
  }

  // 5. Enhanced Filter Bottom Sheet
  void _showEnhancedFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setModalState) {
              return Container(
                height: MediaQuery.of(context).size.height * 0.9,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(25),
                    topRight: Radius.circular(25),
                  ),
                ),
                child: Column(
                  children: [
                    // Header
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
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '🎛️ Bộ lọc nâng cao',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Tìm homestay hoàn hảo cho bạn',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.teal,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.teal,
                              size: 28,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          // Location
                          _buildEnhancedFilterSection(
                            '📍 Thành phố',
                            Icons.location_on,
                            DropdownButton<String>(
                              value: _selectedLocation,
                              isExpanded: true,
                              items:
                                  _locations.map((location) {
                                    return DropdownMenuItem(
                                      value: location,
                                      child: Text(location),
                                    );
                                  }).toList(),
                              onChanged: (value) {
                                setModalState(() {
                                  _selectedLocation = value!;
                                });
                              },
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Price Range với visual
                          _buildEnhancedFilterSection(
                            '💰 Khoảng giá',
                            Icons.attach_money,
                            Column(
                              children: [
                                Slider(
                                  value: _priceRange,
                                  min: 100000,
                                  max: 5000000,
                                  divisions: 49,
                                  onChanged: (value) {
                                    setModalState(() {
                                      _priceRange = value;
                                    });
                                  },
                                  activeColor: Colors.teal,
                                  inactiveColor: Colors.teal[100],
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildPriceChip('100K', 100000),
                                    _buildPriceChip('500K', 500000),
                                    _buildPriceChip('1Tr', 1000000),
                                    _buildPriceChip('2Tr', 2000000),
                                    _buildPriceChip('5Tr', 5000000),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Rating với stars
                          _buildEnhancedFilterSection(
                            '⭐ Đánh giá tối thiểu',
                            Icons.star,
                            Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: List.generate(5, (index) {
                                    return GestureDetector(
                                      onTap: () {
                                        setModalState(() {
                                          _selectedRating = index + 1;
                                        });
                                      },
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color:
                                              _selectedRating >= index + 1
                                                  ? Colors.amber
                                                  : Colors.grey[200],
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.star,
                                          color:
                                              _selectedRating >= index + 1
                                                  ? Colors.white
                                                  : Colors.grey,
                                          size: 24,
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _selectedRating == 0
                                      ? 'Tất cả đánh giá'
                                      : '${_selectedRating}+ sao',
                                  style: TextStyle(
                                    color: Colors.teal,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Sorting
                          _buildEnhancedFilterSection(
                            '🔀 Sắp xếp',
                            Icons.sort,
                            DropdownButton<String>(
                              value: _selectedSort,
                              isExpanded: true,
                              items: const [
                                DropdownMenuItem(
                                  value: 'popular',
                                  child: Text('🔥 Phổ biến nhất'),
                                ),
                                DropdownMenuItem(
                                  value: 'rating',
                                  child: Text('⭐ Đánh giá cao nhất'),
                                ),
                                DropdownMenuItem(
                                  value: 'price_low',
                                  child: Text('💰 Giá thấp → cao'),
                                ),
                                DropdownMenuItem(
                                  value: 'price_high',
                                  child: Text('💎 Giá cao → thấp'),
                                ),
                              ],
                              onChanged: (value) {
                                setModalState(() {
                                  _selectedSort = value!;
                                });
                              },
                            ),
                          ),

                          const SizedBox(height: 30),

                          // Action Buttons
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.refresh),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 15,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    side: const BorderSide(color: Colors.teal),
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
                                  label: const Text(
                                    'Đặt lại',
                                    style: TextStyle(color: Colors.teal),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.check),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.teal,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 15,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.pop(context);
                                    setState(() {});
                                  },
                                  label: const Text(
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
              );
            },
          ),
    );
  }

  Widget _buildEnhancedFilterSection(
    String title,
    IconData icon,
    Widget content,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.teal, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Colors.teal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        content,
      ],
    );
  }

  Widget _buildPriceChip(String label, double price) {
    final isSelected = _priceRange >= price;
    return GestureDetector(
      onTap: () {
        setState(() {
          _priceRange = price;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.teal : Colors.grey[100],
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? Colors.teal : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.teal,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // 6. Enhanced Homestay Card với more features
  Widget _buildEnhancedHomestayCard(Homestay homestay, BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
            // Image với overlay
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  child: Image.network(
                    homestay.imageUrl,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (context, error, stackTrace) => Container(
                          height: 200,
                          color: Colors.grey[200],
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.home_work,
                                size: 50,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Không thể tải ảnh',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                  ),
                ),

                // Gradient overlay
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),

                // Top badges
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: Row(
                    children: [
                      // Rating badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 14,
                            ),
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

                      const Spacer(),

                      // Favorite button
                      GestureDetector(
                        onTap: () => _toggleFavorite(homestay.id),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            _favoriteIds.contains(homestay.id)
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: Colors.red,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom info overlay
                Positioned(
                  bottom: 12,
                  left: 12,
                  right: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        homestay.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              homestay.address,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Thông tin chi tiết
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Facilities chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (homestay.facilities.length > 3)
                        ...homestay.facilities
                            .take(3)
                            .map(
                              (facility) => Chip(
                                label: Text(facility),
                                backgroundColor: Colors.teal[50],
                                labelStyle: const TextStyle(fontSize: 10),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                            )
                            .toList()
                      else
                        ...homestay.facilities
                            .map(
                              (facility) => Chip(
                                label: Text(facility),
                                backgroundColor: Colors.teal[50],
                                labelStyle: const TextStyle(fontSize: 10),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                            )
                            .toList(),

                      if (homestay.facilities.length > 3)
                        Chip(
                          label: Text('+${homestay.facilities.length - 3}'),
                          backgroundColor: Colors.grey[200],
                          labelStyle: const TextStyle(fontSize: 10),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Price và action
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${homestay.price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal,
                            ),
                          ),
                          const Text(
                            '/đêm',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),

                      ElevatedButton.icon(
                        icon: const Icon(Icons.roofing, size: 16),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) =>
                                      HomestayDetailScreen(homestay: homestay),
                            ),
                          );
                        },
                        label: const Text(
                          'Đặt ngay',
                          style: TextStyle(fontWeight: FontWeight.bold),
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

  // ========== CÁC PHƯƠNG THỨC HIỆN CÓ (giữ nguyên) ==========

  void _handleQuickAction(String label) {
    switch (label) {
      case 'Đặt nhanh':
        _showQuickBookingModal();
        break;
      case 'Khuyến mãi':
        _showPromotionsModal();
        break;
      case 'Yêu thích':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FavoritesScreen()),
        );
        break;
      case 'Lịch sử':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MyBookingsScreen()),
        );
        break;
    }
  }

  void _showQuickBookingModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        child: Column(
          children: [
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
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '⚡ Đặt phòng nhanh',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Chọn homestay và đặt ngay',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.teal,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.teal,
                      size: 28,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
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

                  final homestays = snapshot.data ?? [];
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: homestays.length,
                    itemBuilder: (context, index) {
                      final homestay = homestays[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              homestay.imageUrl,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    width: 60,
                                    height: 60,
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.home_work),
                                  ),
                            ),
                          ),
                          title: Text(homestay.name),
                          subtitle: Text(
                            '${homestay.price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ/đêm',
                          ),
                          trailing: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => HomestayDetailScreen(homestay: homestay),
                                ),
                              );
                            },
                            child: const Text('Đặt ngay'),
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
      ),
    );
  }

  void _showPromotionsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(25),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🎉 Khuyến mãi',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Ưu đãi đặc biệt đang chờ bạn',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.red,
                      size: 28,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.local_offer, color: Colors.red),
                      title: const Text('Giảm 30% cho đặt phòng tuần này'),
                      subtitle: const Text('Áp dụng cho tất cả homestay'),
                      trailing: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text('Sử dụng'),
                      ),
                    ),
                  ),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.card_giftcard, color: Colors.orange),
                      title: const Text('Miễn phí đêm đầu tiên'),
                      subtitle: const Text('Cho đặt phòng từ 3 đêm trở lên'),
                      trailing: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                        ),
                        child: const Text('Sử dụng'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Stream<List<Homestay>> getHomestays() {
    return FirebaseFirestore.instance
        .collection('homestays')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => Homestay.fromFirestore(doc.id, doc.data()))
                  .toList(),
        );
  }

  List<Homestay> _filterAndSortHomestays(List<Homestay> homestays) {
    var filtered =
        homestays.where((hs) {
          final matchesSearch =
              hs.name.toLowerCase().contains(_searchKeyword) ||
              hs.address.toLowerCase().contains(_searchKeyword) ||
              hs.description.toLowerCase().contains(_searchKeyword);

          final matchesLocation =
              _selectedLocation == 'Tất cả' ||
              hs.address.contains(_selectedLocation);

          final matchesPrice = hs.price <= _priceRange;
          final matchesRating = hs.rating >= _selectedRating;

          return matchesSearch &&
              matchesLocation &&
              matchesPrice &&
              matchesRating;
        }).toList();

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
        break;
    }

    return filtered;
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
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'Xin chào, $_userName!',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: Colors.teal,
        elevation: 0,
        actions: [
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
                      MaterialPageRoute(
                        builder: (_) => const AdminBookingManager(),
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MyBookingsScreen(),
                      ),
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
                      _notificationCount > 9
                          ? '9+'
                          : _notificationCount.toString(),
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

      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
          await _fetchUserData();
        },
        child: ListView(
          children: [
            // Promotion Carousel
            _buildPromotionCarousel(),

            // Search Bar
            _buildSearchBar(),

            // Quick Actions
            _buildQuickActions(),

            // Categories
            _buildCategories(),

            // Homestay List
            StreamBuilder<List<Homestay>>(
              stream: getHomestays(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: CircularProgressIndicator(color: Colors.teal),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(40),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 60,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Lỗi: ${snapshot.error}',
                            style: const TextStyle(color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => setState(() {}),
                            child: const Text('Thử lại'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final data = snapshot.data ?? [];
                final filteredHomestays = _filterAndSortHomestays(data);

                if (filteredHomestays.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(40),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.search_off,
                            size: 60,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Không tìm thấy homestay phù hợp',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _searchKeyword.isNotEmpty
                                ? 'Từ khóa: "$_searchKeyword"'
                                : 'Hãy thử điều chỉnh bộ lọc',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed:
                                () => _showEnhancedFilterBottomSheet(context),
                            child: const Text('Mở bộ lọc'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  children: [
                    // Results header
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${filteredHomestays.length} homestay được tìm thấy',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.tune, color: Colors.teal),
                            onPressed:
                                () => _showEnhancedFilterBottomSheet(context),
                          ),
                        ],
                      ),
                    ),

                    // Homestay list
                    ...filteredHomestays
                        .map(
                          (homestay) =>
                              _buildEnhancedHomestayCard(homestay, context),
                        )
                        .toList(),
                  ],
                );
              },
            ),
          ],
        ),
      ),

      // Bottom Navigation Bar (giữ nguyên)
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });

          switch (index) {
            case 0:
              break;
            case 1:
              if (_userRole == 'admin') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminBookingManager(),
                  ),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyBookingsScreen()),
                );
              }
              Future.delayed(const Duration(milliseconds: 100), () {
                if (mounted) {
                  setState(() {
                    _currentIndex = 0;
                  });
                }
              });
              break;
            case 2:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
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

      // Floating Action Button for quick booking
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showEnhancedFilterBottomSheet(context);
        },
        backgroundColor: Colors.teal,
        child: const Icon(Icons.search, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
