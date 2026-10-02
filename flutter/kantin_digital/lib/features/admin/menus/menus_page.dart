import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/image_upload_helper.dart';
import '../../../core/widgets/top_notification.dart';
import '../../../shared/models/menu_model.dart';
import '../../../shared/models/category_model.dart';
import '../../admin/widgets/admin_drawer.dart';
import 'menus_controller.dart';

class AdminMenusPage extends StatefulWidget {
  const AdminMenusPage({super.key});

  @override
  State<AdminMenusPage> createState() => _AdminMenusPageState();
}

class _AdminMenusPageState extends State<AdminMenusPage> {
  final AdminMenusController _controller = AdminMenusController();
  late Future<List<MenuModel>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _future = _controller.fetchMenus();
    });
  }

  Future<void> _delete(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Menu?'),
        content: const Text('Menu akan dihapus permanen dari sistem.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Batal',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      try {
        await _controller.deleteMenu(id);
        _reload();
        if (!mounted) return;
        TopNotification.show(
          message: 'Menu berhasil dihapus',
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

  Future<void> _showForm({MenuModel? menu}) async {
    final nameCtrl = TextEditingController(text: menu?.name ?? '');
    final priceCtrl = TextEditingController(text: menu?.price.toString() ?? '');
    final descCtrl = TextEditingController(text: menu?.description ?? '');
    CompressedImageFile? selectedImage;
    bool isCompressing = false;
    bool isAvailable = menu?.isAvailable ?? true;

    // We need to fetch categories for the dropdown
    List<CategoryModel> categories = [];
    try {
      categories = await _controller.fetchCategories();
    } catch (e) {
      if (!mounted) return;
      TopNotification.show(
        message: 'Gagal memuat kategori: $e',
        backgroundColor: AppColors.danger,
        icon: Icons.error_rounded,
      );
      return;
    }

    int? selectedCategory;
    if (menu != null && categories.isNotEmpty) {
      try {
        final match = categories.firstWhere((c) => c.name == menu.categoryName);
        selectedCategory = match.id;
      } catch (_) {
        if (categories.isNotEmpty) selectedCategory = categories.first.id;
      }
    } else if (categories.isNotEmpty) {
      selectedCategory = categories.first.id;
    }

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              constraints: const BoxConstraints(maxWidth: 400),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      menu == null ? 'Tambah Menu Baru' : 'Edit Menu',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    Container(
                      height: 150,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: selectedImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: Image.memory(
                                selectedImage!.bytes,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            )
                          : (menu?.imageUrl?.isNotEmpty ?? false)
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: Image.network(
                                menu!.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, st) => const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.broken_image_rounded,
                                        size: 32,
                                        color: AppColors.textMuted,
                                      ),
                                      Text(
                                        'Gambar tidak dapat dimuat',
                                        style: TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          : const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate_rounded,
                                    size: 32,
                                    color: AppColors.textMuted,
                                  ),
                                  Text(
                                    'Preview Gambar',
                                    style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: isCompressing
                          ? null
                          : () async {
                              setState(() => isCompressing = true);
                              try {
                                final image =
                                    await ImageUploadHelper.pickAndCompressImage(
                                      maxDimension: 1200,
                                      quality: 78,
                                    );
                                if (image != null) {
                                  setState(() => selectedImage = image);
                                }
                              } catch (e) {
                                if (!dialogContext.mounted) return;
                                TopNotification.show(
                                  message: 'Gagal memproses gambar: $e',
                                  backgroundColor: AppColors.danger,
                                  icon: Icons.error_rounded,
                                );
                              } finally {
                                if (dialogContext.mounted) {
                                  setState(() => isCompressing = false);
                                }
                              }
                            },
                      icon: isCompressing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.cloud_upload_rounded),
                      label: Text(
                        isCompressing
                            ? 'Memproses gambar...'
                            : selectedImage == null
                            ? 'Unggah Foto Menu'
                            : 'Ganti Foto Menu',
                      ),
                    ),
                    if (selectedImage != null)
                      Text(
                        'Foto dikompres: ${(selectedImage!.bytes.length / 1024).toStringAsFixed(0)} KB',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Nama Menu',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.restaurant_menu),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      // ignore: deprecated_member_use
                      value: selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'Kategori',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.category),
                      ),
                      items: categories.map((c) {
                        return DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name),
                        );
                      }).toList(),
                      onChanged: (val) =>
                          setState(() => selectedCategory = val),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: priceCtrl,
                      decoration: InputDecoration(
                        labelText: 'Harga',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.attach_money),
                        suffixText: 'IDR',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descCtrl,
                      decoration: InputDecoration(
                        labelText: 'Deskripsi (Opsional)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.description),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 24),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        isAvailable ? 'Menu Aktif' : 'Menu Tidak Aktif',
                      ),
                      subtitle: Text(
                        isAvailable
                            ? 'Menu dapat dilihat dan dipesan pelanggan'
                            : 'Menu disembunyikan dari pelanggan',
                      ),
                      value: isAvailable,
                      activeThumbColor: AppColors.primary,
                      onChanged: (value) => setState(() => isAvailable = value),
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: const BorderSide(color: AppColors.border),
                            ),
                            child: const Text(
                              'Batal',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              if (nameCtrl.text.isEmpty ||
                                  priceCtrl.text.isEmpty ||
                                  selectedCategory == null) {
                                TopNotification.show(
                                  message:
                                      'Mohon lengkapi nama, harga, dan kategori',
                                  backgroundColor: AppColors.warning,
                                  icon: Icons.warning_rounded,
                                );
                                return;
                              }

                              final data = {
                                'name': nameCtrl.text.trim(),
                                'price': int.tryParse(priceCtrl.text) ?? 0,
                                'category_id': selectedCategory,
                                'description': descCtrl.text.trim(),
                                'is_available': isAvailable ? 1 : 0,
                              };

                              Navigator.pop(dialogContext);

                              try {
                                if (menu == null) {
                                  await _controller.addMenu(
                                    data,
                                    image: selectedImage,
                                  );
                                } else {
                                  await _controller.editMenu(
                                    menu.id,
                                    data,
                                    image: selectedImage,
                                  );
                                }
                                _reload();
                                if (!mounted) return;
                                // ignore: use_build_context_synchronously
                                TopNotification.show(
                                  message: menu == null
                                      ? 'Menu ditambahkan'
                                      : 'Menu diperbarui',
                                  backgroundColor: AppColors.success,
                                  icon: Icons.check_circle_rounded,
                                );
                              } catch (e) {
                                if (!mounted) return;
                                // ignore: use_build_context_synchronously
                                TopNotification.show(
                                  message: 'Error: $e',
                                  backgroundColor: AppColors.danger,
                                  icon: Icons.error_rounded,
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Simpan'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Kelola Menu'),
        backgroundColor: Colors.transparent,
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
      body: Stack(
        children: [
          // Decoration
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          FutureBuilder<List<MenuModel>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        size: 48,
                        color: AppColors.danger,
                      ),
                      const SizedBox(height: 16),
                      Text('Gagal memuat data: ${snapshot.error}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _reload,
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                );
              }
              final items = snapshot.data ?? [];
              if (items.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.restaurant_menu_rounded,
                        size: 64,
                        color: AppColors.textMuted.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Belum ada menu tersimpan',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final menu = items[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadowLight,
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        onTap: () => _showForm(menu: menu),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              // Image
                              Hero(
                                tag: 'menu_${menu.id}',
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: menu.imageUrl != null && menu.imageUrl!.isNotEmpty
                                        ? Image.network(
                                            menu.imageUrl!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (ctx, err, st) => const Center(
                                              child: Icon(
                                                Icons.fastfood_rounded,
                                                color: AppColors.textMuted,
                                                size: 32,
                                              ),
                                            ),
                                          )
                                        : const Center(
                                            child: Icon(
                                              Icons.fastfood_rounded,
                                              color: AppColors.textMuted,
                                              size: 32,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),

                              // Content
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      menu.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        menu.categoryName,
                                        style: const TextStyle(
                                          color: AppColors.primary,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      CurrencyFormatter.rupiah(menu.price),
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: menu.isAvailable
                                            ? AppColors.success.withValues(
                                                alpha: 0.1,
                                              )
                                            : AppColors.textMuted.withValues(
                                                alpha: 0.12,
                                              ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        menu.isAvailable
                                            ? 'Aktif'
                                            : 'Tidak Aktif',
                                        style: TextStyle(
                                          color: menu.isAvailable
                                              ? AppColors.success
                                              : AppColors.textMuted,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Actions
                              Column(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit_rounded,
                                      color: AppColors.primary,
                                    ),
                                    onPressed: () => _showForm(menu: menu),
                                    tooltip: 'Edit',
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      color: AppColors.danger,
                                    ),
                                    onPressed: () => _delete(menu.id),
                                    tooltip: 'Hapus',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Tambah Menu',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
