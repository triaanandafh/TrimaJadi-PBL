import 'package:flutter/material.dart';

class WalletPage extends StatelessWidget {
  const WalletPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dompet Saya", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: Column(
        children: [
          // Total Saldo Card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: const Color(0xFF1A237E),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Column(
              children: [
                const Text("Total Saldo", style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 10),
                const Text("Rp 750.000", 
                    style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => _showWithdrawDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    minimumSize: const Size(200, 45),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Tarik Saldo Sekarang", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 10),
                const Text("*Biaya penarikan Rp 2.500 per transaksi", 
                    style: TextStyle(color: Colors.white54, fontSize: 10)),
              ],
            ),
          ),

          // Riwayat Transaksi Section
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 25, vertical: 10),
            child: Align(alignment: Alignment.centerLeft, child: Text("Riwayat Transaksi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
          ),
          
          Expanded(
            child: ListView.builder(
              itemCount: 5,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: index % 2 == 0 ? Colors.green[50] : Colors.red[50],
                    child: Icon(index % 2 == 0 ? Icons.arrow_downward : Icons.arrow_upward, 
                                color: index % 2 == 0 ? Colors.green : Colors.red, size: 18),
                  ),
                  title: Text(index % 2 == 0 ? "Pendapatan Jasa" : "Penarikan Saldo"),
                  subtitle: Text("12 Mei 2026"),
                  trailing: Text(index % 2 == 0 ? "+ Rp 150.000" : "- Rp 200.000", 
                                 style: TextStyle(fontWeight: FontWeight.bold, color: index % 2 == 0 ? Colors.green : Colors.red)),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  void _showWithdrawDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Konfirmasi Penarikan", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            const TextField(decoration: InputDecoration(labelText: "Jumlah Penarikan", hintText: "Min Rp 50.000")),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: const Color(0xFF1A237E)),
              onPressed: () {}, 
              child: const Text("Konfirmasi", style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }
}