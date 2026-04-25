import 'package:flutter/material.dart';
import 'package:trimajadi/pages/main_screen.dart';
import '../models/user_model.dart';
import 'homepage_client.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.elliptical(250, 100),
              bottomRight: Radius.elliptical(250, 100),
            ),
            child: Image.asset(
              "assets/images/onboarding.png",
              height: 400,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 30),
          const Text(
            "Mulai dari Skill,\nJadi Penghasilan",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Text(
              "TrimaJadi menghubungkan kamu dengan peluang nyata. Tawarkan keahlianmu, "
              "temukan bantuan yang kamu butuhkan, dan selesaikan semuanya dengan mudah dan aman.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE67E22),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              onPressed: () {
                UserData.name = "User";
                UserData.role = "Talent";

                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => MainScreen()),
                );
              },
              child: const Text("Mulai sebagai Talent"),
            ),
          ),
          const SizedBox(height: 15),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFE67E22)),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              onPressed: () {
                UserData.name = "User";
                UserData.role = "Client";

                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => MainScreen()),
                );
              },
              child: const Text(
                "Mulai sebagai Client",
                style: TextStyle(color: Color(0xFFE67E22)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text("Belum punya akun? Daftar"),
          const SizedBox(height: 25),
        ],
      ),
    );
  }
}