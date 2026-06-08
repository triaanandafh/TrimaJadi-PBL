import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Portfolio {
  final String id;
  final String title;
  final String description;
  final int year;
  final String imageUrl;

  Portfolio({
    required this.id,
    required this.title,
    required this.description,
    required this.year,
    required this.imageUrl,
  });

  factory Portfolio.fromMap(Map<String, dynamic> map) {
    return Portfolio(
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
  late Future<List<Portfolio>> _portfolioFuture;

  @override
  void initState() {
    super.initState();
    _portfolioFuture = fetchPortfolios();
  }

  void _refreshPortfolios() {
    setState(() {
      _portfolioFuture = fetchPortfolios();
    });
  }

  Future<List<Portfolio>> fetchPortfolios() async {
    final userId = supabase.auth.currentUser!.id;
    final data = await supabase
        .from('portfolios')
        .select()
        .eq('talent_id', userId)
        .order('created_at', ascending: false);
    return (data as List)
        .map((item) => Portfolio.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  Future<String?> _uploadImageToSupabase(File imageFile) async {
    try {
      final userId = supabase.auth.currentUser!.id;
      final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = 'portfolios/$fileName';

      await supabase.storage
          .from('portofolio-images')
          .upload(filePath, imageFile);

      final imageUrl = supabase.storage
          .from('portofolio-images')
          .getPublicUrl(filePath);

      return imageUrl;
    } catch (e) {
      return null;
    }
  }

  Future<void> _deletePortfolio(String id) async {
    try {
      await supabase.from('portfolios').delete().eq('id', id);
      _refreshPortfolios();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Portofolio berhasil dihapus")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal menghapus: $e")),
        );
      }
    }
  }

  void _showDeleteDialog(Portfolio portfolio) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Hapus Portofolio?"),
          content: const Text(
              "Apakah kamu yakin ingin menghapus portofolio ini? Data yang dihapus tidak bisa dikembalikan."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deletePortfolio(portfolio.id);
              },
              child: const Text("Hapus", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showAddPortfolioDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final yearController = TextEditingController();

    File? selectedImage;
    String? previewImagePath;
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Tambah Portofolio"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: "Judul Portofolio *",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(
                        labelText: "Deskripsi *",
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: yearController,
                      decoration: const InputDecoration(
                        labelText: "Tahun *",
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () async {
                        final picker = ImagePicker();
                        final XFile? pickedFile = await picker.pickImage(
                          source: ImageSource.gallery,
                          imageQuality: 80,
                        );
                        if (pickedFile != null) {
                          setDialogState(() {
                            selectedImage = File(pickedFile.path);
                            previewImagePath = pickedFile.path;
                          });
                        }
                      },
                      child: Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: previewImagePath != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(previewImagePath!),
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate_outlined,
                                      size: 40, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text("Pilih Gambar dari Galeri",
                                      style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                      ),
                    ),
                    if (previewImagePath != null)
                      TextButton.icon(
                        onPressed: () async {
                          final picker = ImagePicker();
                          final XFile? pickedFile = await picker.pickImage(
                            source: ImageSource.gallery,
                            imageQuality: 80,
                          );
                          if (pickedFile != null) {
                            setDialogState(() {
                              selectedImage = File(pickedFile.path);
                              previewImagePath = pickedFile.path;
                            });
                          }
                        },
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text("Ganti Gambar"),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  child: const Text("Batal"),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (titleController.text.trim().isEmpty ||
                              descController.text.trim().isEmpty ||
                              yearController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      "Judul, deskripsi, dan tahun wajib diisi")),
                            );
                            return;
                          }

                          setDialogState(() => isLoading = true);

                          try {
                            String imageUrl = '';
                            if (selectedImage != null) {
                              final uploadedUrl =
                                  await _uploadImageToSupabase(selectedImage!);
                              imageUrl = uploadedUrl ?? '';
                            }

                            final userId = supabase.auth.currentUser!.id;
                            await supabase.from('portfolios').insert({
                              'talent_id': userId,
                              'title': titleController.text.trim(),
                              'description': descController.text.trim(),
                              'year': int.parse(yearController.text.trim()),
                              'image_url': imageUrl,
                            });

                            if (mounted) {
                              Navigator.pop(context);
                              _refreshPortfolios();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text("Portofolio berhasil ditambahkan!")),
                              );
                            }
                          } catch (e) {
                            setDialogState(() => isLoading = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Gagal menyimpan: $e")),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A237E),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text("Simpan",
                          style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _editPortfolio(Portfolio portfolio) {
    final titleController = TextEditingController(text: portfolio.title);
    final descController = TextEditingController(text: portfolio.description);
    final yearController =
        TextEditingController(text: portfolio.year.toString());

    File? selectedImage;
    String? previewImagePath;
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Edit Portofolio"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: "Judul Portofolio *",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(
                        labelText: "Deskripsi *",
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: yearController,
                      decoration: const InputDecoration(
                        labelText: "Tahun *",
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () async {
                        final picker = ImagePicker();
                        final XFile? pickedFile = await picker.pickImage(
                          source: ImageSource.gallery,
                          imageQuality: 80,
                        );
                        if (pickedFile != null) {
                          setDialogState(() {
                            selectedImage = File(pickedFile.path);
                            previewImagePath = pickedFile.path;
                          });
                        }
                      },
                      child: Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: previewImagePath != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(previewImagePath!),
                                  fit: BoxFit.cover,
                                ),
                              )
                            : portfolio.imageUrl.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      portfolio.imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              const Icon(Icons.broken_image,
                                                  color: Colors.grey),
                                    ),
                                  )
                                : const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_photo_alternate_outlined,
                                          size: 40, color: Colors.grey),
                                      SizedBox(height: 8),
                                      Text("Pilih Gambar dari Galeri",
                                          style:
                                              TextStyle(color: Colors.grey)),
                                    ],
                                  ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        final picker = ImagePicker();
                        final XFile? pickedFile = await picker.pickImage(
                          source: ImageSource.gallery,
                          imageQuality: 80,
                        );
                        if (pickedFile != null) {
                          setDialogState(() {
                            selectedImage = File(pickedFile.path);
                            previewImagePath = pickedFile.path;
                          });
                        }
                      },
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text("Ganti Gambar"),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  child: const Text("Batal"),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (titleController.text.trim().isEmpty ||
                              descController.text.trim().isEmpty ||
                              yearController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      "Judul, deskripsi, dan tahun wajib diisi")),
                            );
                            return;
                          }

                          setDialogState(() => isLoading = true);

                          try {
                            String imageUrl = portfolio.imageUrl;
                            if (selectedImage != null) {
                              final uploadedUrl = await _uploadImageToSupabase(
                                  selectedImage!);
                              imageUrl = uploadedUrl ?? portfolio.imageUrl;
                            }

                            await supabase
                                .from('portfolios')
                                .update({
                                  'title': titleController.text.trim(),
                                  'description': descController.text.trim(),
                                  'year':
                                      int.parse(yearController.text.trim()),
                                  'image_url': imageUrl,
                                })
                                .eq('id', portfolio.id);

                            if (mounted) {
                              Navigator.pop(context);
                              _refreshPortfolios();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text("Portofolio berhasil diupdate!")),
                              );
                            }
                          } catch (e) {
                            setDialogState(() => isLoading = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Gagal mengupdate: $e")),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A237E),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text("Update",
                          style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Portofolio Saya"),
      ),
      body: FutureBuilder<List<Portfolio>>(
        future: _portfolioFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
                child: Text("Terjadi kesalahan: ${snapshot.error}"));
          }

          final portfolios = snapshot.data ?? [];

          if (portfolios.isEmpty) {
            return const Center(
                child: Text("Belum ada portofolio. Klik + untuk menambah."));
          }

          return RefreshIndicator(
            onRefresh: () async => _refreshPortfolios(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: portfolios.length,
              itemBuilder: (context, index) {
                return buildPortfolioCard(portfolios[index]);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddPortfolioDialog,
        backgroundColor: const Color(0xFF1A237E),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget buildPortfolioCard(Portfolio portfolio) {
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
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: portfolio.imageUrl.isNotEmpty
                    ? Image.network(
                        portfolio.imageUrl,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 180,
                          color: Colors.grey[200],
                          child:
                              const Icon(Icons.broken_image, color: Colors.grey),
                        ),
                      )
                    : Container(
                        height: 180,
                        color: Colors.grey[200],
                        child: const Icon(Icons.image_not_supported,
                            color: Colors.grey, size: 40),
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
                    icon: const Icon(Icons.more_vert,
                        color: Colors.white, size: 20),
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editPortfolio(portfolio);
                      } else if (value == 'delete') {
                        _showDeleteDialog(portfolio);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(
                          value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        portfolio.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      portfolio.year.toString(),
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  portfolio.description,
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