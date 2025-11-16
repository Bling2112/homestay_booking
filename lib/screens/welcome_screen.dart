import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'homestay_list_screen.dart';
import 'admin_homestay_list_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  String userName = 'Người dùng';
  String userRole = 'user';
  bool _isLoading = true;

  late final AnimationController _controller;
  late final Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _fetchUserData();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _rotationAnimation = Tween<double>(begin: -0.2, end: 0.2)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.repeat(reverse: true);
  }

  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = doc.data();
      setState(() {
        userName = data?['name'] ?? 'Người dùng';
        userRole = data?['role'] ?? 'user';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        userName = 'Người dùng';
        userRole = 'user';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
                      Text(
                        'Xin chào,',
                        style: TextStyle(
                          fontSize: 28,
                          color: Colors.teal[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        userName,
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
  Widget nextScreen;

  switch (userRole.toLowerCase()) {
    case 'admin':
      nextScreen = const AdminHomestayListScreen();
      break;
    case 'user':
    default:
      nextScreen = const HomestayListScreen();
  }

  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (_) => nextScreen),
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
