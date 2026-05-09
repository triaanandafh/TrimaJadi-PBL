import 'package:flutter/material.dart';

class Project {
  final String title;
  final String description;
  final int year;
  final String imageUrl;

  Project({
    required this.title,
    required this.description,
    required this.year,
    required this.imageUrl,
  });
}

class PortfolioPage extends StatefulWidget {
  const PortfolioPage({super.key});

  @override
  State<PortfolioPage> createState() => _PortfolioPageState();
}

class _PortfolioPageState extends State<PortfolioPage> {
  // data project diletakkan di state agar bisa dimanipulasi
    final List<Project> projects = [
      Project(
        title: "TrimaJadi-PBL",
        description: "Aplikasi manajemen proyek untuk kolaborasi tim mahasiswa.",
        year: 2026,
        imageUrl: "https://images.unsplash.com/photo-1522071820081-009f0129c71c?q=80&w=600&auto=format&fit=crop",
      ),
      Project(
        title: "Queezly",
        description: "Aplikasi quiz interaktif untuk belajar lebih menyenangkan.",
        year: 2026,
        imageUrl: "https://images.unsplash.com/photo-1516321318423-f06f85e504b3?q=80&w=600&auto=format&fit=crop",
      ),
      Project(
        title: "Aplikasi Weather App",
        description: "Aplikasi informasi cuaca secara real-time.",
        year: 2026,
        imageUrl: "https://images.unsplash.com/photo-1516321318423-f06f85e504b3?q=80&w=600&auto=format&fit=crop",
      ),
    ];

    void _deleteProject(int index) {
      setState(() {
        projects.removeAt(index);
      });
    }

    void _showDeleteDialog(int index) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text("Hapus Project?"),
        content: const Text("Apakah kamu yakin ingin menghapus project ini? Data yang dihapus tidak bisa dikembalikan."),
        actions: [
          // Tombol Batal
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          // Tombol Hapus
          TextButton(
            onPressed: () {
              _deleteProject(index); // Jalankan fungsi hapus
              Navigator.pop(context); // Tutup dialog
              
              // Opsional: Tampilkan SnackBar sebagai feedback
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Project berhasil dihapus")),
              );
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.red)),
          ),
        ],
      );
    },
  );
}

    void _editProject(int index) {
      // Logika untuk edit project (bisa buka dialog atau halaman baru)
    }

    void _addProject() {
      // Logika untuk tambah project (bisa buka dialog atau halaman baru)
    }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Portofolio Saya"),
      ),
      body: projects.isEmpty 
        ? const Center(child: Text("Belum ada proyek.")) 
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: projects.length,
            itemBuilder: (context, index) {
              return buildProjectCard(projects[index], index);
            },
          ),
      // PERUBAHAN: Tambahkan Floating Action Button (Tombol +)
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigasi ke halaman form tambah project
          print("Tombol tambah project diklik");
        },
        child: const Icon(Icons.add, color: Colors.white),
        backgroundColor: Color(0xFF1A237E),
      ),
    );
  }

  Widget buildProjectCard(Project project, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children:[
              ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.network(
              project.imageUrl,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 180,
                color: Colors.grey[200],
                child: const Icon(Icons.broken_image, color: Colors.grey),
              ),
            ),
          ),
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white, size: 20),
                onSelected: (value) {
                  if (value == 'edit') {
                    _editProject(index);
                  } else if (value == 'delete') {
                   _showDeleteDialog(index);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text('Edit'),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete'),
                  ),
                ],
              )
            )
          )],
          ),
          // Gambar Project
          
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      project.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      project.year.toString(),
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  project.description,
                  style: const TextStyle(color: Colors.black54),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}