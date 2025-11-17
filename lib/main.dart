import 'package:bookinghomestay/screens/login_screen.dart';
import 'package:bookinghomestay/screens/welcome_screen.dart';
import 'package:bookinghomestay/screens/forgot_password_screen.dart';
import 'package:bookinghomestay/screens/reset_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,    
      title: 'Booking Homestay',
      theme: ThemeData(primarySwatch: Colors.teal),

      // 🟢 Thêm hỗ trợ ngôn ngữ cho DatePicker
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('vi', 'VN'), // Tiếng Việt
        Locale('en', 'US'), // Dự phòng tiếng Anh
      ],

      home: const LoginScreen(),
    );
  }
}
