import 'package:flutter/material.dart';

class DetailOrderPage extends StatelessWidget {
  final bool isTalent;
  final String status; // "progress", "done"

  const DetailOrderPage({
    super.key,
    required this.isTalent,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),

      // ===== APP BAR =====
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: const BackButton(color: Colors.black),
        title: const Text(
          "Detail Order",
          style: TextStyle(color: Colors.black),
        ),
      ),

      // ===== BODY =====
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [

                  // ===== INFO USER =====
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isTalent
                              ? "Informasi Client"
                              : "Informasi Seller",
                          style: _titleStyle(),
                        ),
                        const SizedBox(height: 15),

                        _row("Nama", "Marsya"),
                        _row("Nomor Telepon", "087865776997"),
                        _row("Email", "Marsya@gmail.com"),

                        if (isTalent) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: List.generate(
                              5,
                              (index) => const Icon(
                                Icons.star,
                                color: Colors.black,
                                size: 16,
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 15),

                        ElevatedButton(
                          style: _orangeButton(),
                          onPressed: () {},
                          child: Text(
                            isTalent
                                ? "Hubungi Client"
                                : "Hubungi Seller",
                            style: const TextStyle(color: Colors.white),
                        ),),
                      ],
                    ),
                  ),

                  const SizedBox(height: 15),

                  // ===== DETAIL LAYANAN =====
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Detail Layanan", style: _titleStyle()),
                        const SizedBox(height: 15),

                        _row("Nama", "Desain Logo Minimalis"),
                        _row("Durasi", "7 hari"),
                        _row("Tanggal Order", "12 April 2026"),
                        _row("Deadline", "19 April 2026"),
                        _row("Total Harga", "Rp100.000,00"),
                        _row("Status Pembayaran", "Lunas"),
                        _row("Status Pengerjaan", "Sedang Dikerjakan"),
                      ],
                    ),
                  ),

                  const SizedBox(height: 15),

                  // ===== DESKRIPSI =====
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Deskripsi", style: _titleStyle()),
                        const SizedBox(height: 10),
                        const Text(
                          "Logo minimalis saja dengan dominan warna biru.",
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ===== BOTTOM BUTTON =====
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: _buildBottomButton(),
          ),
        ],
      ),
    );
  }

  // ===== BUTTON DINAMIS =====
  Widget _buildBottomButton() {
    if (isTalent && status == "progress") {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: _blueButton(),
          onPressed: () {},
          child: const Text("Submit Hasil"),
        ),
      );
    }

    if (!isTalent && status == "done") {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              onPressed: () {},
              child: const Text("Ajukan Revisi"),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              style: _blueButton(),
              onPressed: () {},
              child: const Text("Terima Hasil"),
            ),
          ),
        ],
      );
    }

    return const SizedBox();
  }

  // ===== COMPONENT =====

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _row(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  TextStyle _titleStyle() {
    return const TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 14,
    );
  }

  ButtonStyle _orangeButton() {
    return ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFE68C3A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25),
      ),
    );
  }

  ButtonStyle _blueButton() {
    return ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF2C4A6E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25),
      ),
    );
  }
}