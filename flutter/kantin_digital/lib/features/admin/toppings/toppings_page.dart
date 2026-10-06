import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/top_notification.dart';
import '../../../shared/models/category_model.dart';
import '../../../shared/models/topping_model.dart';
import '../menus/menus_service.dart';
import '../../admin/widgets/admin_drawer.dart';
import 'toppings_controller.dart';

class AdminToppingsPage extends StatefulWidget {
  const AdminToppingsPage({super.key});

  @override
  State<AdminToppingsPage> createState() => _AdminToppingsPageState();
}

class _AdminToppingsPageState extends State<AdminToppingsPage> {
  final AdminToppingsController _controller = AdminToppingsController();
  late Future<List<ToppingModel>> _future;
  List<CategoryModel> _categories = const [];
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _future = _controller.fetchToppings();
    });
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await AdminMenusService().getCategories();
      if (!mounted) return;
      setState(() {
        _categories = categories;
        if (_selectedCategoryId != null &&
            !categories.any((category) => category.id == _selectedCategoryId)) {
          _selectedCategoryId = null;
        }
      });
    } catch (e) {
      debugPrint('Error fetching categories: $e');
    }
  }

  Future<void> _delete(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Topping?'),
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
        await _controller.deleteTopping(id);
        _reload();
        if (!mounted) return;
        TopNotification.show(
          message: 'Topping berhasil dihapus',
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

  Future<void> _showForm({ToppingModel? topping}) async {
    final nameCtrl = TextEditingController(text: topping?.name ?? '');
    final priceCtrl = TextEditingController(text: topping?.price.toString() ?? '');

    // Fetch categories so one topping can apply to several menu categories.
    final selectedCategoryIds = <int>{...topping?.categoryIds ?? const []};
    final categoryOptions = <_ToppingCategoryOption>[];
    try {
      final categories = await AdminMenusService().getCategories();
      categoryOptions.addAll(
        categories.map((category) => _ToppingCategoryOption(
              id: category.id,
              name: category.name,
            )),
      );
    } catch (e) {
      debugPrint('Error fetching categories: $e');
    }
    
    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(topping == null ? 'Tambah Topping' : 'Edit Topping'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nama Topping'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceCtrl,
                  decoration: const InputDecoration(labelText: 'Harga Tambahan'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Kategori Menu',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                const SizedBox(height: 4),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Topping ini akan muncul saat menu memakai kategori yang dicentang.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 10),
                if (categoryOptions.isEmpty)
                  const Text('Belum ada kategori menu.')
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categoryOptions.map((category) {
                      final selected = selectedCategoryIds.contains(category.id);
                      return FilterChip(
                        label: Text(category.name),
                        selected: selected,
                        onSelected: (value) {
                          setState(() {
                            if (value) {
                              selectedCategoryIds.add(category.id);
                            } else {
                              selectedCategoryIds.remove(category.id);
                            }
                          });
                        },
                        selectedColor: AppColors.primary.withValues(alpha: 0.12),
                        checkmarkColor: AppColors.primary,
                      );
                    }).toList(),
                  ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Batal')),
              ElevatedButton(
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  final price = int.tryParse(priceCtrl.text) ?? 0;

                  if (name.isEmpty) {
                     TopNotification.show(
                       message: 'Nama tidak boleh kosong',
                       backgroundColor: AppColors.warning,
                       icon: Icons.warning_rounded,
                     );
                     return;
                  }

                  if (selectedCategoryIds.isEmpty) {
                     TopNotification.show(
                       message: 'Pilih minimal satu kategori menu',
                       backgroundColor: AppColors.warning,
                       icon: Icons.warning_rounded,
                     );
                     return;
                  }

                  Navigator.pop(dialogContext);

                  try {
                    if (topping == null) {
                      await _controller.addTopping(
                        name,
                        price,
                        selectedCategoryIds.toList(),
                      );
                    } else {
                      await _controller.editTopping(
                        topping.id,
                        name,
                        price,
                        selectedCategoryIds.toList(),
                      );
                    }
                    _reload();
                    if (!mounted) return;
                    TopNotification.show(
                      message: topping == null ? 'Berhasil ditambah' : 'Berhasil diupdate',
                      backgroundColor: AppColors.success,
                      icon: Icons.check_circle_rounded,
                    );
                  } catch (e) {
                    if (!mounted) return;
                    TopNotification.show(
                      message: 'Error: $e',
                      backgroundColor: AppColors.danger,
                      icon: Icons.error_rounded,
                    );
                  }
                },
                child: const Text('Simpan'),
              ),
            ],
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Kelola Topping'),
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
      body: FutureBuilder<List<ToppingModel>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final allItems = snapshot.data ?? [];
          final items = _selectedCategoryId == null
              ? allItems
              : allItems
                    .where(
                      (item) => item.categoryIds.contains(_selectedCategoryId),
                    )
                    .toList();
          if (items.isEmpty) {
            return Column(
              children: [
                _buildCategoryFilter(),
                const Expanded(
                  child: Center(child: Text('Belum ada topping')),
                ),
              ],
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length + 1,
            separatorBuilder: (_, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildCategoryFilter();
              }

              final item = items[index - 1];
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: const Icon(Icons.layers, color: AppColors.primary),
                  ),
                  title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    item.categoryNames.isEmpty
                        ? CurrencyFormatter.rupiah(item.price)
                        : '${CurrencyFormatter.rupiah(item.price)} • ${item.categoryNames.join(', ')}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showForm(topping: item),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _delete(item.id),
                      ),
                    ],
                  ),
                ),
              );
            },
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

  Widget _buildCategoryFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('Semua'),
              selected: _selectedCategoryId == null,
              onSelected: (_) => setState(() => _selectedCategoryId = null),
              selectedColor: AppColors.primary.withValues(alpha: 0.12),
              checkmarkColor: AppColors.primary,
            ),
          ),
          ..._categories.map(
            (category) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(category.name),
                selected: _selectedCategoryId == category.id,
                onSelected: (_) =>
                    setState(() => _selectedCategoryId = category.id),
                selectedColor: AppColors.primary.withValues(alpha: 0.12),
                checkmarkColor: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToppingCategoryOption {
  final int id;
  final String name;

  const _ToppingCategoryOption({
    required this.id,
    required this.name,
  });
}
