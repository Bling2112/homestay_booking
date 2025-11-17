import 'package:bookinghomestay/screens/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'homestay_list_screen.dart';
import 'register_screen.dart';
import 'welcome_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>(); // <-- Thêm GlobalKey cho Form
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginWithEmail() async {
    // 1. Kiểm tra Validation trước khi gọi API
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const WelcomeScreen()),
          );
        }
      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Đăng nhập lỗi: ${e.message ?? 'Lỗi không xác định'}')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  // Cần bổ sung _isLoading cho Google và Facebook tương tự _loginWithEmail
  Future<void> _loginWithGoogle() async {
    setState(() => _isLoading = true); // <-- Bổ sung loading
    try {
      final googleUser = await GoogleSignIn().signIn();
      // ... (Phần logic còn lại)
    } catch (e) {
      // ... (Xử lý lỗi)
    } finally {
      setState(() => _isLoading = false); // <-- Bổ sung tắt loading
    }
  }

  Future<void> _loginWithFacebook() async {
    setState(() => _isLoading = true); // <-- Bổ sung loading
    try {
      // ... (Phần logic còn lại)
    } catch (e) {
      // ... (Xử lý lỗi)
    } finally {
      setState(() => _isLoading = false); // <-- Bổ sung tắt loading
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập email trước.')),
      );
      return;
    }

    try {
      await _auth.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email đặt lại mật khẩu đã được gửi. Vui lòng kiểm tra hộp thư.'),
          backgroundColor: Colors.green,
        ),
      );
    } on FirebaseAuthException catch (e) {
      String message = 'Lỗi không xác định';
      if (e.code == 'user-not-found') {
        message = 'Email không tồn tại trong hệ thống.';
      } else if (e.code == 'invalid-email') {
        message = 'Email không hợp lệ.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $message')),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 159, 236, 224),
              Color.fromARGB(255, 129, 213, 206)
            ], // xanh ngọc nhẹ
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form( // <-- Bọc các TextField trong Widget Form
            key: _formKey, // <-- Gán GlobalKey
          child: Column(
            children: [
              const SizedBox(height: 60),
              Image.asset('assets/images/logo.png', height: 120),
              const SizedBox(height: 20),
              const Text(
                "Đăng nhập",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: "Email",
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập Email.';
                    }
                    if (!value.contains('@')) {
                      return 'Email không hợp lệ.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              const SizedBox(height: 16),
              TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: "Mật khẩu",
                    prefixIcon: const Icon(Icons.lock),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập Mật khẩu.';
                    }
                    if (value.length < 6) {
                      return 'Mật khẩu phải có ít nhất 6 ký tự.';
                    }
                    return null;
                  },
                ),
              const SizedBox(height: 24),
              _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            minimumSize: const Size(double.infinity, 48)),
                        onPressed: _loginWithEmail,
                        child: const Text("Đăng nhập"),
                      ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                ),
                child: const Text(
                  "Quên mật khẩu?",
                  style: TextStyle(color: Colors.teal),
                ),
              ),
              const SizedBox(height: 16),
              const SizedBox(height: 16), TextButton( onPressed: () => Navigator.push( context, MaterialPageRoute(builder: (_) => const RegisterScreen()), ),child: const Text("Chưa có tài khoản? Đăng ký"), ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Image.asset('assets/images/google.png', height: 40),
                    onPressed: _loginWithGoogle,
                  ),
                  const SizedBox(width: 20),
                  IconButton(
                    icon: Image.asset('assets/images/facebook.png', height: 40),
                    onPressed: _loginWithFacebook,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}
