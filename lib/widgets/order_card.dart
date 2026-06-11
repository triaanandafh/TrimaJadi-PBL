import 'package:flutter/material.dart';

class OrderCard extends StatelessWidget {
  final String title;
  final String subTitle; // Bisa tanggal atau nama user
  final String status;
  final Color statusColor;
  final String? category;
  final VoidCallback? onTap;

  const OrderCard({
    super.key,
    required this.title,
    required this.subTitle,
    required this.status,
    this.statusColor = Colors.red,
    this.category,
    this.onTap,
  });

  // WIDGET ICON DINAMIS UNTUK LIST AKTIVITAS
  Widget _buildCategoryIcon(String? categoryOrTitle) {
    final cat = (categoryOrTitle ?? '').toLowerCase();
    
    IconData iconData;
    Color iconColor;
    Color bgColor;

    // Pengecekan kata kunci sesuai dengan database-mu
    if (cat.contains('desain') || cat.contains('design') || cat.contains('foto')) {
      iconData = Icons.palette;
      iconColor = Colors.blue;
      bgColor = Colors.blue.shade50;
    } else if (cat.contains('web') || cat.contains('pemrograman') || cat.contains('coding')) {
      iconData = Icons.code;
      iconColor = Colors.orange;
      bgColor = Colors.orange.shade50;
    } else if (cat.contains('edukasi') || cat.contains('tutor') || cat.contains('belajar')) {
      iconData = Icons.school;
      iconColor = Colors.purple;
      bgColor = Colors.purple.shade50;
    } else if (cat.contains('visual') || cat.contains('audio') || cat.contains('video') || cat.contains('voice over')) {
      iconData = Icons.music_note;
      iconColor = Colors.teal;
      bgColor = Colors.teal.shade50;
    } else if (cat.contains('penulisan') || cat.contains('penerjemahan') || cat.contains('translating') || cat.contains('translate')) {
      iconData = Icons.translate;
      iconColor = Colors.green;
      bgColor = Colors.green.shade50;
    } else {
      iconData = Icons.business_center;
      iconColor = Colors.grey;
      bgColor = Colors.grey.shade100;
    }

    // Desain ikon bulat (Circle) khusus untuk list aktivitas
    return Container(
      padding: const EdgeInsets.all(12), 
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle, 
      ),
      child: Icon(iconData, color: iconColor, size: 24),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(15),
          margin: const EdgeInsets.only(bottom: 15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey[100]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 5,
              )
            ],
          ),
          child: Row(
            children: [
              _buildCategoryIcon(category),
              
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      subTitle,
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.circle, size: 8, color: statusColor),
                        const SizedBox(width: 5),
                        Text(
                          status,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
