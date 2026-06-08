import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../widgets/notification_bell.dart'; // ← import widget baru
import '../widgets/rating_widgets.dart';
import 'change_password_page.dart';
import 'edit_profile_page.dart';
import 'notification_page.dart';
import 'onboarding_page.dart';
import 'profile_portfolio.dart';
import 'profile_wallet.dart';
import 'talent_review_page.dart';

class ProfilePage extends StatefulWidget {
  final Function(int)? onNavigate;

  const ProfilePage({super.key, this.onNavigate});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _supabase = Supabase.instance.client;

  int  _balance      = 0;
  bool _isVerified   = false;
  int  _unreadNotif  = 0; // ← jumlah notif belum dibaca

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
    _subscribeNotifCount(); // ← realtime listener
  }

  /// Realtime stream untuk badge angka di menu Notifikasi
  void _subscribeNotifCount() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .listen((data) {
          if (mounted) {
            final unread = data.where((n) => n['is_read'] == false).length;
            setState(() => _unreadNotif = unread);
          }
        });
  }

  Future<void> _fetchProfileData() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final wallet = await _supabase
          .from('wallets')
          .select('balance')
          .eq('user_id', userId)
          .maybeSingle();

      final profile = await _supabase
          .from('users')
          .select('has_verified_badge')
          .eq('id', userId)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _balance    = (wallet?['balance'] as num?)?.toInt() ?? 0;
          _isVerified = profile?['has_verified_badge'] == true;
        });
      }
    } catch (_) {}
  }

  String _formatRupiah(int value) {
    final str    = value.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return 'Rp $buffer';
  }

  @override
  Widget build(BuildContext context) {
    final isTalent = UserData.role == 'talent';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F9),
      body: CustomScrollView(
        slivers: [
          // ── App Bar ───────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 340,
            pinned: false,
            elevation: 0,
            backgroundColor: const Color(0xFF1A237E),
            automaticallyImplyLeading: false,
            toolbarHeight: 70,
            title: const Padding(
              padding: EdgeInsets.only(left: 10),
              child: Text('Profil',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24)),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 25),
                // ── GANTI: pakai NotificationBell widget ──
                child: const NotificationBell(),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 110),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: CircleAvatar(
                      radius: 55,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: UserData.avatarUrl.isNotEmpty
                          ? NetworkImage(UserData.avatarUrl)
                          : null,
                      child: UserData.avatarUrl.isEmpty
                          ? Icon(Icons.person, size: 60, color: Colors.grey[400])
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      UserData.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          UserData.role,
                          style: const TextStyle(
                              color: Color(0xFF4CAF50),
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (isTalent && _isVerified) ...[
                        const SizedBox(width: 8),
                        const VerifiedBadge(),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Body ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 25),

                // Wallet & fitur talent
                if (isTalent) ...[
                  _buildWalletCard(context),
                  const SizedBox(height: 25),
                  _sectionHeader('Pusat Kerja Talent'),
                  _buildMenuCard([
                    _menuItem(context, Icons.work_outline,
                        'Kelola Layanan Saya', isFirst: true),
                    _divider(),
                    _menuItem(
                        context, Icons.image_outlined, 'Portofolio Saya'),
                    _divider(),
                    _menuItem(context, Icons.star_outline, 'Ulasan Klien',
                        isLast: true),
                  ]),
                  const SizedBox(height: 25),
                ],

                _sectionHeader('Pengaturan Akun'),
                _buildMenuCard([
                  _menuItem(context, Icons.person_outline, 'Edit Profil',
                      isFirst: true),
                  _divider(),
                  _menuItem(context, Icons.lock_outline, 'Ubah Password'),
                  _divider(),
                  _menuItem(context, Icons.notifications_none,
                      'Notifikasi', isLast: true, badgeCount: _unreadNotif),
                ]),

                const SizedBox(height: 20),

                _buildMenuCard([
                  _menuItem(
                    context,
                    Icons.logout,
                    'Keluar Akun',
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

  // ── Wallet card ─────────────────────────────────────────────────────
  Widget _buildWalletCard(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const WalletPage())),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 25),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05), blurRadius: 10)
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Saldo Tersedia',
                    style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 5),
                Text(
                  _formatRupiah(_balance),
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A237E)),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const WalletPage())),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFE68C3A),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Tarik Saldo',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Logout dialog ───────────────────────────────────────────────────
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        title: const Text(
          'Keluar Akun',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Apakah kamu yakin ingin keluar dari akun ini?',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF4A5568),
                fontSize: 15,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Kamu perlu login kembali untuk mengakses aplikasi.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF718096),
                fontSize: 13,
                height: 1.3,
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade200, width: 1.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    minimumSize: const Size(double.infinity, 48),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Batal',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await AuthService.logout();
                      UserData.clear();
                      if (context.mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const OnboardingPage()),
                          (_) => false,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF34949),
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text(
                      'Keluar',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────
  Widget _buildMenuCard(List<Widget> items) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 25),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20)),
        child: Column(children: items),
      );

  Widget _sectionHeader(String title) => Padding(
        padding: const EdgeInsets.only(left: 30, bottom: 10),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            title,
            style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
                fontSize: 14),
          ),
        ),
      );

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
    Color?  textColor,
    Color?  iconBgColor,
    bool    isFirst    = false,
    bool    isLast     = false,
    int     badgeCount = 0, // ← badge angka notif belum dibaca
  }) {
    // Trailing: badge merah + chevron jika ada, chevron saja jika tidak
    Widget trailing;
    if (badgeCount > 0) {
      trailing = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              badgeCount > 99 ? '99+' : '$badgeCount',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
        ],
      );
    } else {
      trailing = const Icon(Icons.chevron_right, color: Colors.grey, size: 20);
    }

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top:    isFirst ? const Radius.circular(20) : Radius.zero,
          bottom: isLast  ? const Radius.circular(20) : Radius.zero,
        ),
      ),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconBgColor ?? const Color(0xFFE8EAF6),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon,
            color: textColor ?? const Color(0xFF3F51B5), size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: textColor ?? const Color(0xFF2D3142),
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      trailing: trailing,
      onTap: () {
        switch (title) {
          case 'Kelola Layanan Saya':
            widget.onNavigate?.call(2);
            break;
          case 'Portofolio Saya':
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const PortfolioPage()));
            break;
          case 'Ulasan Klien':
            Navigator.push(context,
                MaterialPageRoute(
                    builder: (_) => const TalentReviewsPage()));
            break;
          case 'Edit Profil':
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const EditProfilePage()));
            break;
          case 'Ubah Password':
            Navigator.push(context,
                MaterialPageRoute(
                    builder: (_) => const ChangePasswordPage()));
            break;
          case 'Notifikasi':
            Navigator.push(context,
                MaterialPageRoute(
                    builder: (_) => const NotificationPage()));
            break;
          case 'Keluar Akun':
            _showLogoutDialog(context);
            break;
        }
      },
    );
  }
}
