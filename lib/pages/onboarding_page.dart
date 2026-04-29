import 'package:flutter/material.dart';
import 'package:trimajadi/models/user_model.dart';
import 'package:trimajadi/pages/main_screen.dart';
import 'login_client_page.dart';

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
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 15),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Text(
              "TrimaJadi menghubungkan kamu dengan peluang nyata. "
              "Tawarkan keahlianmu, temukan bantuan yang kamu butuhkan, "
              "dan selesaikan semuanya dengan mudah dan aman.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
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
                UserData.role = "Talent";
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    // builder: (_) => const LoginTalentPage(),
                    builder: (_) => const MainScreen(
                      // Tambahkan callback kosong untuk onTapSearch
                    ),
                  ),
                );
              },
              child: const Text(
                "Mulai sebagai Seller",
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          ),

          const SizedBox(height: 15),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(
                  color: Color(0xFFE67E22),
                ),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              onPressed: () {
                UserData.role = "Client";
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LoginClientPage(),
                  ),
                );
              },
              child: const Text(
                "Mulai sebagai Client",
                style: TextStyle(
                  color: Color(0xFFE67E22),
                ),
              ),
            ),
          ),

          const SizedBox(height: 25),
        ],
      ),
    );
  }
}