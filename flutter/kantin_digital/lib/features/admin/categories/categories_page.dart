import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/top_notification.dart';
import '../../../shared/models/category_model.dart';
import '../../admin/widgets/admin_drawer.dart';
import 'categories_controller.dart';

class AdminCategoriesPage extends StatefulWidget {
  const AdminCategoriesPage({super.key});

  @override
  State<AdminCategoriesPage> createState() => _AdminCategoriesPageState();
}

class _AdminCategoriesPageState extends State<AdminCategoriesPage> {
  final AdminCategoriesController _controller = AdminCategoriesController();
  late Future<List<CategoryModel>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _future = _controller.fetchCategories();
    });
  }

  Future<void> _delete(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Kategori?'),
        content: const Text('Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      try {
        await _controller.deleteCategory(id);
        _reload();
        if (!mounted) return;
        TopNotification.show(
          message: 'Kategori berhasil dihapus',
          backgroundColor: AppColors.success,
          icon: Icons.check_circle_rounded,
        );
      } catch (e) {
        if (!mounted) return;
        TopNotification.show(
          message: 'Gagal menghapus: $e',
          backgroundColor: AppColors.danger,
          icon: Icons.error_rounded,
        );
      }
    }
  }

  Future<void> _toggleActive(CategoryModel cat) async {
    try {
      final updated = await _controller.toggleCategory(cat.id);
      _reload();
      if (!mounted) return;
      TopNotification.show(
        message: updated.isActive
            ? '${cat.name} diaktifkan'
            : '${cat.name} dinonaktifkan',
        backgroundColor: updated.isActive ? AppColors.success : Colors.orange,
        icon: updated.isActive ? Icons.check_circle_rounded : Icons.pause_circle_rounded,
      );
    } catch (e) {
      if (!mounted) return;
      TopNotification.show(
        message: 'Gagal mengubah status: $e',
        backgroundColor: AppColors.danger,
        icon: Icons.error_rounded,
      );
    }
  }

  Future<void> _showForm({CategoryModel? category}) async {
    final nameController = TextEditingController(text: category?.name ?? '');
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(category == null ? 'Tambah Kategori' : 'Edit Kategori'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Nama Kategori'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              
              Navigator.pop(context);
              
              try {
                if (category == null) {
                  await _controller.addCategory(name);
                } else {
                  await _controller.editCategory(category.id, name);
                }
                _reload();
                // ignore: use_build_context_synchronously
                TopNotification.show(
                  message: category == null ? 'Kategori berhasil ditambahkan' : 'Kategori berhasil diperbarui',
                  backgroundColor: AppColors.success,
                  icon: Icons.check_circle_rounded,
                );
              } catch (e) {
                 // ignore: use_build_context_synchronously
                TopNotification.show(
                  message: 'Gagal menyimpan: $e',
                  backgroundColor: AppColors.danger,
                  icon: Icons.error_rounded,
                );
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Kelola Kategori'),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      drawer: const AdminDrawer(),
      body: FutureBuilder<List<CategoryModel>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('Belum ada kategori'));
          }

          // Pisahkan aktif dan nonaktif
          final activeItems = items.where((c) => c.isActive).toList();
          final inactiveItems = items.where((c) => !c.isActive).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Aktif
              if (activeItems.isNotEmpty) ...[
                _buildSectionHeader('Aktif', Colors.green, Icons.check_circle),
                const SizedBox(height: 8),
                ...activeItems.map((cat) => _buildCategoryTile(cat)),
              ],
              // Nonaktif
              if (inactiveItems.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildSectionHeader('Tidak Aktif', Colors.orange, Icons.pause_circle),
                const SizedBox(height: 8),
                ...inactiveItems.map((cat) => _buildCategoryTile(cat)),
              ],
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSectionHeader(String label, Color color, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryTile(CategoryModel cat) {
    final isActive = cat.isActive;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? AppColors.border : Colors.orange.shade200,
            width: isActive ? 1 : 1.5,
          ),
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: isActive
                ? AppColors.primary.withValues(alpha: 0.1)
                : Colors.orange.withValues(alpha: 0.1),
            child: Text(
              cat.name[0].toUpperCase(),
              style: TextStyle(
                color: isActive ? AppColors.primary : Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            cat.name,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isActive ? AppColors.textPrimary : Colors.grey,
              decoration: isActive ? null : TextDecoration.none,
            ),
          ),
          subtitle: Text(
            isActive ? 'Tampil di menu pelanggan' : 'Disembunyikan dari pelanggan',
            style: TextStyle(
              fontSize: 11,
              color: isActive ? Colors.green.shade600 : Colors.orange.shade600,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Toggle Switch
              Tooltip(
                message: isActive ? 'Nonaktifkan' : 'Aktifkan',
                child: Switch(
                  value: isActive,
                  activeColor: Colors.green,
                  inactiveThumbColor: Colors.orange,
                  inactiveTrackColor: Colors.orange.withValues(alpha: 0.3),
                  onChanged: (_) => _toggleActive(cat),
                ),
              ),
              // Edit
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                tooltip: 'Edit',
                onPressed: () => _showForm(category: cat),
              ),
              // Delete
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                tooltip: 'Hapus',
                onPressed: () => _delete(cat.id),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
