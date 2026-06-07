import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// MODEL METODE PENARIKAN
class WithdrawMethodModel {
  final String id;
  final String name;
  final String shortName;
  final Color color;
  final String fieldLabel;
  final String fieldHint;
  final TextInputType keyboardType;
  final List<TextInputFormatter> inputFormatters;

  const WithdrawMethodModel({
    required this.id,
    required this.name,
    required this.shortName,
    required this.color,
    required this.fieldLabel,
    required this.fieldHint,
    required this.keyboardType,
    required this.inputFormatters,
  });
}

final List<WithdrawMethodModel> withdrawMethods = [
  WithdrawMethodModel(
    id: 'bca',
    name: 'Rekening BCA',
    shortName: 'BCA',
    color: const Color(0xFF0070B8),
    fieldLabel: 'Nomor Rekening BCA',
    fieldHint: 'Contoh: 1234567890',
    keyboardType: TextInputType.number,
    inputFormatters: [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(10),
    ],
  ),
  WithdrawMethodModel(
    id: 'mandiri',
    name: 'Rekening Mandiri',
    shortName: 'MDR',
    color: const Color(0xFF003D79),
    fieldLabel: 'Nomor Rekening Mandiri',
    fieldHint: 'Contoh: 1234567890123',
    keyboardType: TextInputType.number,
    inputFormatters: [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(13),
    ],
  ),
  WithdrawMethodModel(
    id: 'gopay',
    name: 'GoPay',
    shortName: 'GPY',
    color: const Color(0xFF00AED6),
    fieldLabel: 'Nomor HP GoPay',
    fieldHint: 'Contoh: 08123456789',
    keyboardType: TextInputType.phone,
    inputFormatters: [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(13),
    ],
  ),
  WithdrawMethodModel(
    id: 'shopeepay',
    name: 'ShopeePay',
    shortName: 'SPY',
    color: const Color(0xFFEE4D2D),
    fieldLabel: 'Nomor HP ShopeePay',
    fieldHint: 'Contoh: 08123456789',
    keyboardType: TextInputType.phone,
    inputFormatters: [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(13),
    ],
  ),
];

// HALAMAN WALLET (dengan tombol Tarik Saldo)
class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  final supabase = Supabase.instance.client;

  bool _isLoading = true;
  int _balance = 0;
  List<Map<String, dynamic>> _transactions = [];

  @override
  void initState() {
    super.initState();
    _fetchWallet();
  }

  Future<void> _fetchWallet() async {
    setState(() => _isLoading = true);
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final walletRes = await supabase
          .from('wallets')
          .select('balance')
          .eq('user_id', userId)
          .maybeSingle();

      final balance = (walletRes?['balance'] as num?)?.toInt() ?? 0;

      final txRes = await supabase
          .from('wallet_transactions')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(30);

      setState(() {
        _balance = balance;
        _transactions = List<Map<String, dynamic>>.from(txRes);
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _processWithdraw({
    required int amount,
    required WithdrawMethodModel method,
    required String accountNumber,
    required String accountName,
  }) async {
    const int withdrawFee = 2500;
    final int totalDeducted = amount + withdrawFee;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User tidak ditemukan');

    if (totalDeducted > _balance) {
      throw Exception(
        'Saldo tidak cukup. Dibutuhkan ${_formatRupiah(totalDeducted)} '
        '(termasuk biaya Rp 2.500), saldo Anda ${_formatRupiah(_balance)}.',
      );
    }

    final newBalance = _balance - totalDeducted;

    await supabase
        .from('wallets')
        .update({'balance': newBalance}).eq('user_id', userId);

    await supabase.from('wallet_transactions').insert({
      'user_id': userId,
      'type': 'debit',
      'amount': amount,
      'platform_fee': withdrawFee,
      'note':
          'Penarikan ke ${method.name} ($accountNumber a.n $accountName)',
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });

    await _fetchWallet();
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

  String _formatDate(String? iso) {
    if (iso == null) return '-';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final mon = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des',
      ];
      return '${dt.day} ${mon[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F2EF),
      appBar: AppBar(
        title: const Text('Dompet Saya',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchWallet),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchWallet,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // ── KARTU SALDO ──
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.all(20),
                      padding: const EdgeInsets.all(25),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1E3A8A).withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Text('Saldo Tersedia',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 14)),
                          const SizedBox(height: 10),
                          Text(
                            _formatRupiah(_balance),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              '90% dari setiap order masuk ke saldo ini',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 11),
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => WithdrawPage(
                                  balance: _balance,
                                  onWithdrawSuccess: ({
                                    required int amount,
                                    required WithdrawMethodModel method,
                                    required String accountNumber,
                                    required String accountName,
                                  }) =>
                                      _processWithdraw(
                                    amount: amount,
                                    method: method,
                                    accountNumber: accountNumber,
                                    accountName: accountName,
                                  ),
                                ),
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE68C3A),
                              minimumSize: const Size(200, 45),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: const Text('Tarik Saldo',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '*Biaya penarikan Rp 2.500 per transaksi',
                            style:
                                TextStyle(color: Colors.white54, fontSize: 10),
                          ),
                        ],
                      ),
                    ),

                    // ── INFO POTONGAN ──
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange[200]!),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline,
                                color: Colors.orange, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Dana ditahan hingga client menerima hasil. '
                                'Platform memotong 10% dari setiap order sebagai biaya layanan.',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.orange[800]),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── RIWAYAT TRANSAKSI ──
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Riwayat Transaksi',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.grey[800]),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    if (_transactions.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            Icon(Icons.receipt_long_outlined,
                                size: 50, color: Colors.grey[300]),
                            const SizedBox(height: 10),
                            Text('Belum ada transaksi',
                                style: TextStyle(color: Colors.grey[400])),
                          ],
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding:
                            const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _transactions.length,
                        itemBuilder: (ctx, i) {
                          final tx = _transactions[i];
                          final type = tx['type']?.toString() ?? 'credit';
                          final isCredit = type == 'credit';
                          final amount =
                              (tx['amount'] as num?)?.toInt() ?? 0;
                          final fee =
                              (tx['platform_fee'] as num?)?.toInt() ?? 0;
                          final note = tx['note']?.toString() ?? '-';
                          final date = _formatDate(
                              tx['created_at']?.toString());

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isCredit
                                        ? Colors.green[50]
                                        : Colors.red[50],
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isCredit
                                        ? Icons.arrow_downward_rounded
                                        : Icons.arrow_upward_rounded,
                                    color: isCredit
                                        ? Colors.green
                                        : Colors.red,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        note,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Text(
                                            date,
                                            style: TextStyle(
                                                color: Colors.grey[500],
                                                fontSize: 11),
                                          ),
                                          if (fee > 0) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.orange[50],
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                'Biaya ${_formatRupiah(fee)}',
                                                style: TextStyle(
                                                    fontSize: 10,
                                                    color:
                                                        Colors.orange[700]),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${isCredit ? '+' : '-'} ${_formatRupiah(amount)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isCredit
                                        ? Colors.green[700]
                                        : Colors.red[700],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }
}

// HALAMAN PILIH METODE PENARIKAN  (Step 1)
class WithdrawPage extends StatelessWidget {
  final int balance;
  final Future<void> Function({
    required int amount,
    required WithdrawMethodModel method,
    required String accountNumber,
    required String accountName,
  }) onWithdrawSuccess;

  const WithdrawPage({
    super.key,
    required this.balance,
    required this.onWithdrawSuccess,
  });

  String _formatRupiah(int v) {
    final str = v.toString();
    final buf = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buf.write('.');
      buf.write(str[i]);
    }
    return 'Rp $buf';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: const BackButton(color: Colors.black),
        title: const Text('Tarik Saldo',
            style: TextStyle(
                color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Kartu Saldo ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E3A8A),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1E3A8A).withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Saldo Tersedia',
                      style:
                          TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 8),
                  Text(
                    _formatRupiah(balance),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 6),
                  const Text('Biaya penarikan: Rp 2.500',
                      style:
                          TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Pilih Tujuan Penarikan',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
            ),
            const SizedBox(height: 12),

            // ── List Metode ──
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: withdrawMethods.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, indent: 16, endIndent: 16),
                itemBuilder: (context, index) {
                  final method = withdrawMethods[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    leading: Container(
                      width: 48,
                      height: 32,
                      decoration: BoxDecoration(
                        color: method.color,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          method.shortName,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12),
                        ),
                      ),
                    ),
                    title: Text(
                      method.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    trailing: const Icon(Icons.chevron_right,
                        color: Colors.grey),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WithdrawDetailPage(
                          balance: balance,
                          method: method,
                          onWithdrawSuccess: onWithdrawSuccess,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// HALAMAN DETAIL PENARIKAN  (Step 2)
class WithdrawDetailPage extends StatefulWidget {
  final int balance;
  final WithdrawMethodModel method;
  final Future<void> Function({
    required int amount,
    required WithdrawMethodModel method,
    required String accountNumber,
    required String accountName,
  }) onWithdrawSuccess;

  const WithdrawDetailPage({
    super.key,
    required this.balance,
    required this.method,
    required this.onWithdrawSuccess,
  });

  @override
  State<WithdrawDetailPage> createState() => _WithdrawDetailPageState();
}

class _WithdrawDetailPageState extends State<WithdrawDetailPage> {
  final _amountCtrl = TextEditingController();
  final _accountCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isSubmitting = false;

  static const int _withdrawFee = 2500;
  static const int _minWithdraw = 50000;

  String _formatRupiah(int v) {
    final str = v.toString();
    final buf = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buf.write('.');
      buf.write(str[i]);
    }
    return 'Rp $buf';
  }

  int get _parsedAmount =>
      int.tryParse(_amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  int get _totalDeducted => _parsedAmount + _withdrawFee;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      await widget.onWithdrawSuccess(
        amount: _parsedAmount,
        method: widget.method,
        accountNumber: _accountCtrl.text.trim(),
        accountName: _nameCtrl.text.trim(),
      );

      if (!mounted) return;

      // ── PERBAIKAN: push biasa ke halaman sukses,
      //    navigasi balik ke WalletPage ditangani di WithdrawSuccessPage ──
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WithdrawSuccessPage(
            amount: _parsedAmount,
            fee: _withdrawFee,
            method: widget.method,
            accountNumber: _accountCtrl.text.trim(),
          ),
        ),
      );
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: const BackButton(color: Colors.black),
        title: Text(
          'Tarik ke ${widget.method.name}',
          style: const TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Badge Metode ──
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: widget.method.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: widget.method.color.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 30,
                      decoration: BoxDecoration(
                        color: widget.method.color,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          widget.method.shortName,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      widget.method.name,
                      style: TextStyle(
                          color: widget.method.color,
                          fontWeight: FontWeight.bold,
                          fontSize: 15),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Form Fields ──
              _buildSectionLabel('Jumlah Penarikan'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => setState(() {}),
                decoration: _inputDecoration(
                  label: 'Jumlah (Rp)',
                  hint: 'Min Rp 50.000',
                  icon: Icons.account_balance_wallet_outlined,
                ),
                validator: (v) {
                  final n = int.tryParse(
                      v?.replaceAll(RegExp(r'[^0-9]'), '') ?? '');
                  if (n == null || n < _minWithdraw) {
                    return 'Minimal penarikan Rp 50.000';
                  }
                  if (n + _withdrawFee > widget.balance) {
                    return 'Saldo tidak cukup (termasuk biaya Rp 2.500)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _buildSectionLabel(widget.method.fieldLabel),
              const SizedBox(height: 8),
              TextFormField(
                controller: _accountCtrl,
                keyboardType: widget.method.keyboardType,
                inputFormatters: widget.method.inputFormatters,
                decoration: _inputDecoration(
                  label: widget.method.fieldLabel,
                  hint: widget.method.fieldHint,
                  icon: Icons.credit_card_outlined,
                ),
                validator: (v) {
                  if (v == null || v.trim().length < 8) {
                    return 'Nomor tidak valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ── Ringkasan ──
              if (_parsedAmount >= _minWithdraw) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    children: [
                      _summaryRow(
                          'Jumlah Ditarik', _formatRupiah(_parsedAmount)),
                      const SizedBox(height: 8),
                      _summaryRow(
                        'Biaya Admin',
                        _formatRupiah(_withdrawFee),
                        valueColor: Colors.red[600],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Divider(height: 1),
                      ),
                      _summaryRow(
                        'Total Dipotong dari Saldo',
                        _formatRupiah(_totalDeducted),
                        isBold: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // ── Tombol Submit ──
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text(
                          'Konfirmasi Penarikan',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15),
                        ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) => Text(
        text,
        style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: Colors.black87),
      );

  Widget _summaryRow(
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
  }) =>
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontWeight:
                    isBold ? FontWeight.bold : FontWeight.normal),
          ),
          Text(
            value,
            style: TextStyle(
                fontSize: 13,
                color: valueColor ??
                    (isBold ? Colors.black87 : Colors.black87),
                fontWeight:
                    isBold ? FontWeight.bold : FontWeight.w500),
          ),
        ],
      );

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFF1E3A8A), width: 1.5),
        ),
        filled: true,
        fillColor: Colors.white,
      );

  @override
  void dispose() {
    _amountCtrl.dispose();
    _accountCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }
}

// HALAMAN SUKSES  (Step 3)
class WithdrawSuccessPage extends StatelessWidget {
  final int amount;
  final int fee;
  final WithdrawMethodModel method;
  final String accountNumber;

  const WithdrawSuccessPage({
    super.key,
    required this.amount,
    required this.fee,
    required this.method,
    required this.accountNumber,
  });

  String _formatRupiah(int v) {
    final str = v.toString();
    final buf = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buf.write('.');
      buf.write(str[i]);
    }
    return 'Rp $buf';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FA),
        elevation: 0,
        automaticallyImplyLeading: false, 
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ── Icon Sukses ──
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline_rounded,
                  color: Colors.green,
                  size: 52,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Penarikan Berhasil!',
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Saldo penarikan kamu sudah terkirim.',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // ── Detail Kartu ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _detailRow('Tujuan', method.name),
                    const Divider(height: 20),
                    _detailRow('Nomor', accountNumber),
                    const Divider(height: 20),
                    _detailRow(
                      'Jumlah Diterima',
                      _formatRupiah(amount),
                      valueColor: Colors.green[700],
                      bold: true,
                    ),
                    const Divider(height: 20),
                    _detailRow(
                      'Biaya Admin',
                      _formatRupiah(fee),
                      valueColor: Colors.red[600],
                    ),
                    const Divider(height: 20),
                    _detailRow(
                      'Total Dipotong',
                      _formatRupiah(amount + fee),
                      bold: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const WalletPage()),
                      (route) => false, // hapus semua route di stack
                    );
                  },
                  child: const Text(
                    'Kembali ke Dompet',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(
    String label,
    String value, {
    Color? valueColor,
    bool bold = false,
  }) =>
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  TextStyle(fontSize: 13, color: Colors.grey[600])),
          Text(
            value,
            style: TextStyle(
                fontSize: 13,
                color: valueColor ?? Colors.black87,
                fontWeight: bold ? FontWeight.bold : FontWeight.w500),
          ),
        ],
      );
}
