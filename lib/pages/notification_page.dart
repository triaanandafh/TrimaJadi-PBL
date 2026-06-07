import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';
import 'detail_order_page.dart';
import 'chat_page.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final _supabase = Supabase.instance.client;
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
    _subscribeRealtime();
  }

  // ── Fetch dari Supabase ──────────────────────────────────────
  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final data = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      setState(() {
        _notifications =
            (data as List).map((e) => NotificationModel.fromJson(e)).toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat notifikasi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Realtime listener ────────────────────────────────────────
  void _subscribeRealtime() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .listen((data) {
          if (mounted) {
            setState(() {
              _notifications =
                  data.map((e) => NotificationModel.fromJson(e)).toList();
            });
          }
        });
  }

  // ── Tandai sudah dibaca ──────────────────────────────────────
  Future<void> _markAsRead(String id) async {
    await _supabase
        .from('notifications')
        .update({'is_read': true}).eq('id', id);

    setState(() {
      final idx = _notifications.indexWhere((n) => n.id == id);
      if (idx != -1) {
        final n = _notifications[idx];
        _notifications[idx] = NotificationModel(
          id: n.id,
          title: n.title,
          subtitle: n.subtitle,
          type: n.type,
          isRead: true,
          createdAt: n.createdAt,
          referenceId: n.referenceId,
        );
      }
    });
  }

  // ── Mark all as read ─────────────────────────────────────────
  Future<void> _markAllAsRead() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    await _supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', userId)
        .eq('is_read', false);

    setState(() {
      _notifications = _notifications
          .map((n) => NotificationModel(
                id: n.id,
                title: n.title,
                subtitle: n.subtitle,
                type: n.type,
                isRead: true,
                createdAt: n.createdAt,
                referenceId: n.referenceId,
              ))
          .toList();
    });
  }

  // ── Tap notifikasi → navigate ────────────────────────────────
  Future<void> _onTapNotif(NotificationModel notif) async {
    // Tandai sudah dibaca dulu
    if (!notif.isRead) await _markAsRead(notif.id);

    if (!mounted) return;

    switch (notif.type) {
      case 'order':
      case 'completed':
      case 'review':
        if (notif.referenceId != null) {
          // Fetch dulu apakah user ini talent atau client di order tersebut
          final userId = _supabase.auth.currentUser?.id;
          final orderData = await _supabase
              .from('orders')
              .select('talent_id, work_status')
              .eq('id', notif.referenceId!)
              .maybeSingle();

          if (!mounted) return;

          if (orderData != null) {
            final isTalent = orderData['talent_id'] == userId;
            final status = orderData['work_status'] ?? 'pending';

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DetailOrderPage(
                  orderId: notif.referenceId!,
                  isTalent: isTalent,
                  status: status,
                ),
              ),
            );
          } else {
            _showSnackBar('Order tidak ditemukan');
          }
        }
        break;

      case 'chat':
        if (notif.referenceId != null) {
          // Fetch nama chat partner dari order
          final userId = _supabase.auth.currentUser?.id;
          final orderData = await _supabase
              .from('orders')
              .select('talent_id, client_id, service_name')
              .eq('id', notif.referenceId!)
              .maybeSingle();

          if (!mounted) return;

          if (orderData != null) {
            // Kalau user adalah talent, chat partner adalah client dan sebaliknya
            final isTalent = orderData['talent_id'] == userId;
            final partnerId =
                isTalent ? orderData['client_id'] : orderData['talent_id'];

            // Fetch nama partner dari profiles/users
            final partnerData = await _supabase
                .from('profiles')  // sesuaikan nama tabel profil kamu
                .select('name, full_name')
                .eq('id', partnerId)
                .maybeSingle();

            if (!mounted) return;

            final partnerName = partnerData?['name'] ??
                partnerData?['full_name'] ??
                orderData['service_name'] ??
                'Chat';

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatPage(name: partnerName, receiverId: partnerData?['id']?.toString() ?? ''),
              ),
            );
          } else {
            _showSnackBar('Chat tidak ditemukan');
          }
        }
        break;

      default:
        // Type tidak dikenal, tidak navigate
        break;
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  // ── Helpers icon & warna ─────────────────────────────────────
  IconData _iconFromType(String type) {
    switch (type) {
      case 'order':
        return Icons.shopping_bag_rounded;
      case 'chat':
        return Icons.chat_bubble_rounded;
      case 'completed':
        return Icons.check_circle_rounded;
      case 'review':
        return Icons.star_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _colorFromType(String type) {
    switch (type) {
      case 'order':
        return Colors.orange;
      case 'chat':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'review':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  // ── Grouping berdasarkan tanggal ─────────────────────────────
  String _dateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final notifDate = DateTime(date.year, date.month, date.day);

    if (notifDate == today) return 'Hari ini';
    if (notifDate == yesterday) return 'Kemarin';
    return '${date.day}/${date.month}/${date.year}';
  }

  List<Widget> _buildGroupedList() {
    final Map<String, List<NotificationModel>> grouped = {};

    for (final notif in _notifications) {
      final label = _dateLabel(notif.createdAt.toLocal());
      grouped.putIfAbsent(label, () => []).add(notif);
    }

    final widgets = <Widget>[];
    grouped.forEach((label, items) {
      widgets.add(_buildDateLabel(label));
      for (final item in items) {
        widgets.add(_buildNotifItem(item));
      }
      widgets.add(const SizedBox(height: 20));
    });

    return widgets;
  }

  // ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Row(
          children: [
            const Text(
              'Notifikasi',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                'Tandai semua',
                style: TextStyle(fontSize: 12),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _fetchNotifications,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: _buildGroupedList(),
                  ),
                ),
    );
  }

  // ── Widget: empty state ──────────────────────────────────────
  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined,
              size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Belum ada notifikasi',
            style: TextStyle(color: Colors.grey[500], fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Notifikasi order dan pesan akan muncul di sini',
            style: TextStyle(color: Colors.grey[400], fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Widget: date label ───────────────────────────────────────
  Widget _buildDateLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  // ── Widget: notif item ───────────────────────────────────────
  Widget _buildNotifItem(NotificationModel notif) {
    final icon = _iconFromType(notif.type);
    final color = _colorFromType(notif.type);
    final local = notif.createdAt.toLocal();
    final timeStr =
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';

    // Label tujuan navigasi
    String? navLabel;
    if (notif.referenceId != null) {
      switch (notif.type) {
        case 'order':
        case 'completed':
        case 'review':
          navLabel = 'Lihat Order';
          break;
        case 'chat':
          navLabel = 'Buka Chat';
          break;
      }
    }

    return GestureDetector(
      onTap: () => _onTapNotif(notif),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: notif.isRead ? Colors.grey[50] : Colors.blue[50],
          borderRadius: BorderRadius.circular(12),
          border: notif.isRead
              ? null
              : Border.all(color: Colors.blue.withOpacity(0.2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          notif.title,
                          style: TextStyle(
                            fontWeight: notif.isRead
                                ? FontWeight.w500
                                : FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Dot merah kalau belum dibaca
                      if (!notif.isRead)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notif.subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Label navigasi
                      if (navLabel != null)
                        Row(
                          children: [
                            Icon(Icons.arrow_forward_ios,
                                size: 10, color: color),
                            const SizedBox(width: 4),
                            Text(
                              navLabel,
                              style: TextStyle(
                                fontSize: 11,
                                color: color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      // Waktu
                      Text(
                        timeStr,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
