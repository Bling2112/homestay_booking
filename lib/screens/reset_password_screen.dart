import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bookinghomestay/screens/login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;

  const ResetPasswordScreen({super.key, required this.email});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  Future<void> _resetPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final code = _codeController.text.trim();
        final newPassword = _passwordController.text.trim();

        // Get reset code from Firestore
        final resetDoc = await FirebaseFirestore.instance
            .collection('password_resets')
            .doc(widget.email)
            .get();

        if (!resetDoc.exists) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mã đặt lại không hợp lệ hoặc đã hết hạn.')),
          );
          return;
        }

        final data = resetDoc.data()!;
        final storedCode = data['resetCode'];
        final timestamp = data['timestamp'] as Timestamp;

        // Check if code is expired (e.g., 1 hour)
        final now = Timestamp.now();
        final difference = now.seconds - timestamp.seconds;
        if (difference > 3600) { // 1 hour in seconds
          await FirebaseFirestore.instance
              .collection('password_resets')
              .doc(widget.email)
              .delete();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mã đặt lại đã hết hạn. Vui lòng yêu cầu mã mới.')),
          );
          return;
        }

        if (code != storedCode) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mã đặt lại không đúng.')),
          );
          return;
        }

        // Since we can't update password without being logged in,
        // we'll show a message to use Firebase's built-in reset link
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng sử dụng liên kết đặt lại mật khẩu được gửi qua email Firebase.'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
        return;



      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.message ?? 'Lỗi không xác định'}')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đặt lại mật khẩu'),
        backgroundColor: Colors.teal,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 159, 236, 224),
              Color.fromARGB(255, 129, 213, 206)
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/logo.png', height: 120),
                const SizedBox(height: 20),
                const Text(
                  "Nhập mã đặt lại",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 30),
                TextFormField(
                  controller: _codeController,
                  decoration: const InputDecoration(
                    labelText: "Mã đặt lại",
                    prefixIcon: Icon(Icons.code),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập mã đặt lại.';
                    }
                    if (value.length != 6) {
                      return 'Mã đặt lại phải có 6 ký tự.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: "Mật khẩu mới",
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
                      return 'Vui lòng nhập mật khẩu mới.';
                    }
                    if (value.length < 6) {
                      return 'Mật khẩu phải có ít nhất 6 ký tự.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: "Xác nhận mật khẩu mới",
                    prefixIcon: const Icon(Icons.lock),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng xác nhận mật khẩu mới.';
                    }
                    if (value != _passwordController.text) {
                      return 'Mật khẩu xác nhận không khớp.';
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
                        onPressed: _resetPassword,
                        child: const Text("Đặt lại mật khẩu"),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
