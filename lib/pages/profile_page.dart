import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import 'profile_wallet.dart';
import 'profile_portfolio.dart';
import 'edit_profile_page.dart';
import 'onboarding_page.dart';
import 'change_password_page.dart';

class ProfilePage extends StatefulWidget {
  final Function(int)? onNavigate;

  const ProfilePage({super.key, this.onNavigate});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final supabase = Supabase.instance.client;
  int _balance = 0;

  @override
  void initState() {
    super.initState();
    _fetchBalance();
  }

  Future<void> _fetchBalance() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;
      final res = await supabase
          .from('wallets')
          .select('balance')
          .eq('user_id', userId)
          .maybeSingle();
      if (mounted) {
        setState(() {
          _balance = (res?['balance'] as num?)?.toInt() ?? 0;
        });
      }
    } catch (_) {}
  }

  String _formatRupiah(int value) {
    final str = value.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return 'Rp $buffer';
  }

  @override
  Widget build(BuildContext context) {
    final bool isTalent = UserData.role == "talent";

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F9),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280.0,
            pinned: true,
            elevation: 0,
            backgroundColor: const Color(0xFF1A237E),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Profil',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 60),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: UserData.avatarUrl.isNotEmpty
                          ? NetworkImage(UserData.avatarUrl)
                          : null,
                      child: UserData.avatarUrl.isEmpty
                          ? Icon(Icons.person, size: 55, color: Colors.grey[400])
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    UserData.name,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      UserData.role,
                      style: const TextStyle(color: Color(0xFF4CAF50), fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 25),

                // ── Hanya muncul untuk Talent ──────────────────────────────
                if (isTalent) _buildWalletCard(context),
                if (isTalent) const SizedBox(height: 25),

                if (isTalent) _sectionHeader("Pusat Kerja Talent"),
                if (isTalent) _buildMenuCard([
                  _menuItem(context, Icons.work_outline, "Kelola Layanan Saya", isFirst: true),
                  _divider(),
                  _menuItem(context, Icons.image_outlined, "Portofolio Saya"),
                  _divider(),
                  _menuItem(context, Icons.star_outline, "Ulasan Klien", isLast: true),
                ]),

                if (isTalent) const SizedBox(height: 25),
                // ──────────────────────────────────────────────────────────

                _sectionHeader("Pengaturan Akun"),
                _buildMenuCard([
                  _menuItem(context, Icons.person_outline, "Edit Profil", isFirst: true),
                  _divider(),
                  _menuItem(context, Icons.lock_outline, "Ubah Password"),
                  _divider(),
                  _menuItem(context, Icons.notifications_none, "Notifikasi", isLast: true),
                ]),

                const SizedBox(height: 20),

                _buildMenuCard([
                  _menuItem(
                    context,
                    Icons.logout,
                    "Keluar Akun",
                    textColor: Colors.red,
                    iconBgColor: Colors.red.withOpacity(0.1),
                    isFirst: true,
                    isLast: true,
                  ),
                ]),

                const SizedBox(height: 50),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Keluar Akun',
          style: TextStyle(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: const Text(
          'Apakah kamu yakin ingin keluar dari akun ini?',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(ctx),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF1A237E)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Batal',
                style: TextStyle(color: Color(0xFF1A237E), fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                // TODO: await supabase.auth.signOut();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const OnboardingPage()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Keluar',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletCard(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const WalletPage()));
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 25),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Saldo Tersedia", style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 5),
                Text(_formatRupiah(_balance), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
              ],
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const WalletPage()));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Tarik Saldo", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(List<Widget> items) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(children: items),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 30, bottom: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
    );
  }

  Widget _divider() => Divider(
        height: 1,
        thickness: 1,
        color: Colors.grey[100],
        indent: 20,
        endIndent: 20,
      );

  Widget _menuItem(
    BuildContext context,
    IconData icon,
    String title, {
    Color? textColor,
    Color? iconBgColor,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(20) : Radius.zero,
          bottom: isLast ? const Radius.circular(20) : Radius.zero,
        ),
      ),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconBgColor ?? const Color(0xFFE8EAF6),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: textColor ?? const Color(0xFF3F51B5), size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: textColor ?? const Color(0xFF2D3142),
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
      onTap: () {
        if (title == "Dompet & Penarikan") {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const WalletPage()));
        } else if (title == "Portofolio Saya") {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const PortfolioPage()));
        } else if (title == "Kelola Layanan Saya") {
          widget.onNavigate?.call(2);
        } else if (title == "Edit Profil") {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfilePage()));
        } else if (title == "Ubah Password") {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const ChangePasswordPage()));
        } else if (title == "Keluar Akun") {
          _showLogoutDialog(context);
        }
      },
    );
  }
}