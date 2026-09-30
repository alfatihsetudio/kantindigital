import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/top_notification.dart';
import '../../../shared/models/topping_model.dart';
import '../../../shared/models/menu_model.dart';
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

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _future = _controller.fetchToppings();
    });
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
    
    // Fetch menus logic
    List<MenuModel> menus = [];
    try {
      menus = await AdminMenusService().getMenus();
    } catch (e) {
      debugPrint('Error fetching menus: $e');
    }
    
    // Default null for create, but admin needs to pick one
    int? selectedMenuId;
    
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
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: selectedMenuId,
                  decoration: const InputDecoration(labelText: 'Target Menu'),
                  items: menus.map((m) => DropdownMenuItem(
                    value: m.id,
                    child: Text(
                      m.name, 
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  )).toList(),
                  onChanged: (v) => setState(() => selectedMenuId = v),
                  validator: (v) => v == null ? 'Pilih menu' : null,
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

                  if (selectedMenuId == null) {
                     TopNotification.show(
                       message: 'Harap pilih menu target',
                       backgroundColor: AppColors.warning,
                       icon: Icons.warning_rounded,
                     );
                     return;
                  }

                  Navigator.pop(dialogContext);

                  try {
                    if (topping == null) {
                      await _controller.addTopping(name, price, selectedMenuId!);
                    } else {
                      await _controller.editTopping(topping.id, name, price, selectedMenuId!);
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
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('Belum ada topping'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = items[index];
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
                  subtitle: Text(CurrencyFormatter.rupiah(item.price)),
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
}
