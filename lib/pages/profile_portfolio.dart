import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Project {
  final String id; // ID unik untuk setiap project (bisa dari Supabase)
  final String title;
  final String description;
  final int year;
  final String imageUrl;

  Project({
    required this.id,
    required this.title,
    required this.description,
    required this.year,
    required this.imageUrl,
  });

  // Fungsi pembantu untuk mengubah data dari Supabase (Map) ke Object Project
  factory Project.fromMap(Map<String, dynamic> map) {
    return Project(
      id: map['id'].toString(),
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      year: map['year'] ?? 0,
      imageUrl: map['image_url'] ?? '',
    );
  }
}

class PortfolioPage extends StatefulWidget {
  const PortfolioPage({super.key});

  @override
  State<PortfolioPage> createState() => _PortfolioPageState();
}

class _PortfolioPageState extends State<PortfolioPage> {
  final supabase = Supabase.instance.client;

  Future<List<Project>> fetchProjects() async {
    final userId = supabase.auth.currentUser!.id; // Mengambil ID Talent yang login

    final data = await supabase
        .from('projects') // Nama tabel di Supabase kamu
        .select()
        .eq('talent_id', userId) // Filter agar hanya muncul portofolio milik user ini
        .order('created_at', ascending: false);
    print("Data projects yang diambil: $data");
    return (data as List).map((item) => Project.fromMap(item as Map<String, dynamic>)).toList();
  }
  // data project diletakkan di state agar bisa dimanipulasi
    // final List<Project> projects = [
    //   Project(
    //     title: "TrimaJadi-PBL",
    //     description: "Aplikasi manajemen proyek untuk kolaborasi tim mahasiswa.",
    //     year: 2026,
    //     imageUrl: "https://images.unsplash.com/photo-1522071820081-009f0129c71c?q=80&w=600&auto=format&fit=crop",
    //   ),
    //   Project(
    //     title: "Queezly",
    //     description: "Aplikasi quiz interaktif untuk belajar lebih menyenangkan.",
    //     year: 2026,
    //     imageUrl: "https://images.unsplash.com/photo-1516321318423-f06f85e504b3?q=80&w=600&auto=format&fit=crop",
    //   ),
    //   Project(
    //     title: "Aplikasi Weather App",
    //     description: "Aplikasi informasi cuaca secara real-time.",
    //     year: 2026,
    //     imageUrl: "https://images.unsplash.com/photo-1516321318423-f06f85e504b3?q=80&w=600&auto=format&fit=crop",
    //   ),
    // ];

    Future<void> _deleteProject(String id) async {
    try {
      await supabase.from('projects').delete().eq('id', id);
      
      // Refresh UI
      setState(() {}); 

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Project berhasil dihapus dari database")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal menghapus: $e")),
      );
    }
  }

    void _showDeleteDialog(Project project) {
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
              _deleteProject(project.id); // Jalankan fungsi hapus
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

    void _editProject(Project project) {
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
      body: FutureBuilder<List<Project>>(
        future: fetchProjects(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Terjadi kesalahan: ${snapshot.error}"));
          }

          final projects = snapshot.data ?? [];

          if (projects.isEmpty) {
            return const Center(child: Text("Belum ada proyek. Klik + untuk menambah."));
          }

          return RefreshIndicator(
            onRefresh: () async => setState(() {}), // Swipe down untuk refresh
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: projects.length,
              itemBuilder: (context, index) {
                return buildProjectCard(projects[index]);
              },
            ),
          );
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

  Widget buildProjectCard(Project project) {
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
                    _editProject(project);
                  } else if (value == 'delete') {
                   _showDeleteDialog(project);
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