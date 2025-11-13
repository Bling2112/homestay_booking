import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'homestay_list_screen.dart';
import 'dart:math';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  String? userName;
  bool _isLoading = true;

  late final AnimationController _controller;
  late final Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _fetchUserData();

    // Khởi tạo animation lắc tay
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _rotationAnimation = Tween<double>(begin: -0.2, end: 0.2)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.repeat(reverse: true); // lặp vô hạn
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      setState(() {
        userName = (doc.exists && doc['name'] != null) ? doc['name'] : 'Người dùng';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        userName = 'Người dùng';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE0F7FA),
      body: SafeArea(
        child: Center(
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.teal)
              : SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 🖐️ Ảnh vẫy tay với animation
                      SizedBox(
                        width: 150,
                        height: 150,
                        child: AnimatedBuilder(
                          animation: _rotationAnimation,
                          builder: (context, child) {
                            return Transform.rotate(
                              angle: _rotationAnimation.value,
                              child: child,
                            );
                          },
                          child: Image.asset('assets/images/waving.png'),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 👋 Chào mừng
                      Text('Xin chào,',
                        style: TextStyle(
                          fontSize: 28,
                          color: Colors.teal[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        userName ?? 'Người dùng',
                        style: TextStyle(
                          fontSize: 30,
                          color: Colors.teal[900],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 50),

                      ElevatedButton.icon(
                        icon: const Icon(Icons.arrow_forward_ios,
                            color: Colors.white),
                        label: const Text(
                          "Tiếp tục",
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const HomestayListScreen()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 40, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}