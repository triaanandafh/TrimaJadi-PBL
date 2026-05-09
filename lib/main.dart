import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'pages/onboarding_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersiveSticky,
  );

  await Supabase.initialize(
    url: 'https://cbzpffxxllkllgirepcz.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNienBmZnh4bGxrbGxnaXJlcGN6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc1MjE3MTksImV4cCI6MjA5MzA5NzcxOX0.RallJQTtzTENTpJUja2PAN_TW_UbfrULlroFvyxQUw4',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const OnboardingPage(),
    );
  }
}