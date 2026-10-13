import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/top_notification.dart';
import '../../../../shared/models/stock_item_model.dart';
import '../stock_service.dart';
import 'add_stock_item_dialog.dart';

class StockItemsManagementSheet extends StatefulWidget {
  final StockService service;
  final VoidCallback? onUpdated;

  const StockItemsManagementSheet({
    super.key,
    required this.service,
    this.onUpdated,
  });

  static Future<void> show(
    BuildContext context, {
    required StockService service,
    VoidCallback? onUpdated,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StockItemsManagementSheet(
        service: service,
        onUpdated: onUpdated,
      ),
    );
  }

  @override
  State<StockItemsManagementSheet> createState() =>
      _StockItemsManagementSheetState();
}

class _StockItemsManagementSheetState extends State<StockItemsManagementSheet> {
  List<StockItemModel> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() => _loading = true);
    try {
      final data = await widget.service.getStockItems(activeOnly: false);
      if (mounted) {
        setState(() {
          _items = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        TopNotification.show(
          message: 'Gagal memuat item stok: $e',
          backgroundColor: AppColors.danger,
          icon: Icons.error_outline_rounded,
        );
      }
    }
  }

  Future<void> _addItem() async {
    final newItem = await AddStockItemDialog.show(
      context,
      service: widget.service,
    );
    if (newItem != null) {
      _loadItems();
      widget.onUpdated?.call();
      TopNotification.show(
        message: 'Item "${newItem.name}" berhasil ditambahkan',
        backgroundColor: AppColors.success,
        icon: Icons.check_circle_rounded,
      );
    }
  }

  Future<void> _editItem(StockItemModel item) async {
    final updated = await AddStockItemDialog.show(
      context,
      service: widget.service,
      itemToEdit: item,
    );
    if (updated != null) {
      _loadItems();
      widget.onUpdated?.call();
      TopNotification.show(
        message: 'Item "${updated.name}" berhasil diperbarui',
        backgroundColor: AppColors.success,
        icon: Icons.check_circle_rounded,
      );
    }
  }

  Future<void> _deleteItem(StockItemModel item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Item Stok?'),
        content: Text(
          'Apakah Anda yakin ingin menghapus item "${item.name}" dari daftar stok toko?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await widget.service.deleteStockItem(item.id);
        _loadItems();
        widget.onUpdated?.call();
        TopNotification.show(
          message: 'Item "${item.name}" berhasil dihapus',
          backgroundColor: AppColors.success,
          icon: Icons.check_circle_rounded,
        );
      } catch (e) {
        TopNotification.show(
          message: 'Gagal menghapus item: $e',
          backgroundColor: AppColors.danger,
          icon: Icons.error_outline_rounded,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Drag Handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              // Sheet Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.settings_suggest_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Kelola Master Bahan & Stok',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Daftar bahan yang wajib diperiksa saat buka & tutup toko',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _addItem,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text(
                        'Tambah',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Item List
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      )
                    : _items.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.inventory_2_outlined,
                                  size: 64,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Belum ada item bahan yang didaftarkan',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton.icon(
                                  onPressed: _addItem,
                                  icon: const Icon(Icons.add),
                                  label: const Text('Tambah Item Baru'),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            controller: scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: _items.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final item = _items[index];
                              return Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          Icons.scale_rounded,
                                          color: AppColors.primary,
                                          size: 22,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 15,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  border: Border.all(
                                                    color: Colors.grey.shade300,
                                                  ),
                                                ),
                                                child: Text(
                                                  'Satuan: ${item.unit}',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color:
                                                        AppColors.textSecondary,
                                                  ),
                                                ),
                                              ),
                                              if (item.category != null &&
                                                  item.category!.isNotEmpty) ...[
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: AppColors
                                                        .primaryLight
                                                        .withValues(alpha: 0.4),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      6,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    item.category!,
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: AppColors.primary,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit_outlined,
                                        size: 20,
                                        color: AppColors.textSecondary,
                                      ),
                                      onPressed: () => _editItem(item),
                                      tooltip: 'Ubah Item',
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        size: 20,
                                        color: AppColors.danger,
                                      ),
                                      onPressed: () => _deleteItem(item),
                                      tooltip: 'Hapus Item',
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }
}
