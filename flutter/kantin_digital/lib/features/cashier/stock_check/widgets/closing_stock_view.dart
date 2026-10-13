import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/top_notification.dart';
import '../../../../shared/models/stock_item_model.dart';
import '../../../../shared/models/stock_check_model.dart';
import '../stock_service.dart';
import 'add_stock_item_dialog.dart';
import 'stock_items_management_sheet.dart';

class ClosingStockView extends StatefulWidget {
  final StockService service;
  final VoidCallback onSaved;

  const ClosingStockView({
    super.key,
    required this.service,
    required this.onSaved,
  });

  @override
  State<ClosingStockView> createState() => _ClosingStockViewState();
}

class _ItemInputHolder {
  final StockItemModel item;
  final TextEditingController wholeController;
  final TextEditingController remainderController;
  final TextEditingController notesController;

  _ItemInputHolder({
    required this.item,
    required this.wholeController,
    required this.remainderController,
    required this.notesController,
  });

  void dispose() {
    wholeController.dispose();
    remainderController.dispose();
    notesController.dispose();
  }
}

class _ClosingStockViewState extends State<ClosingStockView> {
  List<_ItemInputHolder> _inputHolders = [];
  final _overallNotesController = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  void dispose() {
    for (final holder in _inputHolders) {
      holder.dispose();
    }
    _overallNotesController.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    setState(() => _loading = true);
    try {
      final items = await widget.service.getStockItems(activeOnly: true);

      // Cek apakah ada data closing terakhir untuk pre-fill template
      final latestClosing = await widget.service.getLatestClosing();
      final latestItemMap = <String, StockCheckItemModel>{};
      if (latestClosing != null) {
        for (final ci in latestClosing.items) {
          latestItemMap[ci.itemName.toLowerCase().trim()] = ci;
        }
      }

      // Dispose holders lama
      for (final holder in _inputHolders) {
        holder.dispose();
      }

      _inputHolders = items.map((item) {
        final existing = latestItemMap[item.name.toLowerCase().trim()];
        // Kita biarkan input bersih atau pre-fill 0 agar kasir menginput stok fisik aktual
        final wholeCtrl = TextEditingController(
          text: existing != null ? existing.wholeQuantity.toStringAsFixed(existing.wholeQuantity.truncateToDouble() == existing.wholeQuantity ? 0 : 2) : '0',
        );
        final remCtrl = TextEditingController(
          text: existing != null ? existing.remainderQuantity.toStringAsFixed(existing.remainderQuantity.truncateToDouble() == existing.remainderQuantity ? 0 : 2) : '0',
        );
        final notesCtrl = TextEditingController();

        return _ItemInputHolder(
          item: item,
          wholeController: wholeCtrl,
          remainderController: remCtrl,
          notesController: notesCtrl,
        );
      }).toList();

      if (mounted) {
        setState(() => _loading = false);
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

  Future<void> _addNewItemQuick() async {
    final newItem = await AddStockItemDialog.show(
      context,
      service: widget.service,
    );
    if (newItem != null) {
      final holder = _ItemInputHolder(
        item: newItem,
        wholeController: TextEditingController(text: '0'),
        remainderController: TextEditingController(text: '0'),
        notesController: TextEditingController(),
      );
      setState(() {
        _inputHolders.add(holder);
      });
      TopNotification.show(
        message: 'Item "${newItem.name}" ditambahkan ke form catatan',
        backgroundColor: AppColors.success,
        icon: Icons.check_circle_rounded,
      );
    }
  }

  Future<void> _submitClosing() async {
    if (_inputHolders.isEmpty) {
      TopNotification.show(
        message: 'Belum ada item bahan untuk dicatat. Tambahkan bahan terlebih dahulu.',
        backgroundColor: AppColors.warning,
        icon: Icons.warning_rounded,
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.lock_clock_rounded, color: AppColors.primary, size: 26),
            SizedBox(width: 10),
            Text('Simpan Tutup Usaha?'),
          ],
        ),
        content: const Text(
          'Pastikan semua hitungan fisik (jumlah utuh & sisa gram/satuan) sudah sesuai dengan stok yang ada di toko.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Periksa Lagi'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, Simpan Catatan'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _saving = true);

    try {
      final itemsPayload = _inputHolders.map((holder) {
        final wholeVal = double.tryParse(holder.wholeController.text.trim()) ?? 0.0;
        final remVal = double.tryParse(holder.remainderController.text.trim()) ?? 0.0;
        return {
          'stock_item_id': holder.item.id,
          'item_name': holder.item.name,
          'unit': holder.item.unit,
          'whole_quantity': wholeVal,
          'remainder_quantity': remVal,
          'notes': holder.notesController.text.trim().isNotEmpty
              ? holder.notesController.text.trim()
              : null,
        };
      }).toList();

      await widget.service.saveStockCheck(
        checkType: 'closing',
        notes: _overallNotesController.text.trim().isNotEmpty
            ? _overallNotesController.text.trim()
            : null,
        items: itemsPayload,
      );

      if (!mounted) return;
      setState(() => _saving = false);

      TopNotification.show(
        message: 'Catatan stok tutup usaha berhasil disimpan!',
        backgroundColor: AppColors.success,
        icon: Icons.check_circle_rounded,
      );

      widget.onSaved();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      TopNotification.show(
        message: 'Gagal menyimpan catatan stok: $e',
        backgroundColor: AppColors.danger,
        icon: Icons.error_outline_rounded,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadItems,
      color: AppColors.primary,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Petunjuk Closing
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF1E3A8A),
                    const Color(0xFF2563EB),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.nightlight_round,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Catatan Stok Tutup Usaha (Closing)',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Timbang dan hitung sisa stok sebelum pulang. Catatan ini akan menjadi dasar pemeriksaan saat buka toko besok.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Header Row & Quick Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Daftar Barang & Bahan (${_inputHolders.length} Item)',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                Row(
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      onPressed: () => StockItemsManagementSheet.show(
                        context,
                        service: widget.service,
                        onUpdated: _loadItems,
                      ),
                      icon: const Icon(Icons.settings_outlined, size: 16),
                      label: const Text('Kelola Master', style: TextStyle(fontSize: 12)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onPressed: _addNewItemQuick,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Tambah Item', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Items List Inputs
            if (_inputHolders.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey),
                    const SizedBox(height: 12),
                    const Text('Belum ada item bahan di toko ini'),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _addNewItemQuick,
                      child: const Text('Tambah Bahan Sekarang'),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _inputHolders.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final holder = _inputHolders[index];
                  final unit = holder.item.unit;

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Item
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.scale_rounded,
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    holder.item.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    'Satuan Pengukuran: $unit',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Form input utuh & sisa
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Input Utuh
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.check_box_outlined, size: 14, color: AppColors.primary),
                                      const SizedBox(width: 4),
                                      const Text(
                                        'Masih Utuh',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  TextField(
                                    controller: holder.wholeController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: InputDecoration(
                                      suffixText: 'kemasan / pcs',
                                      suffixStyle: const TextStyle(fontSize: 11, color: Colors.grey),
                                      hintText: '0',
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey.shade50,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Input Sisa / Gram
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.hourglass_bottom_rounded, size: 14, color: Color(0xFFD97706)),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Sisa / Terbuka ($unit)',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  TextField(
                                    controller: holder.remainderController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: InputDecoration(
                                      suffixText: unit,
                                      suffixStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                                      hintText: '0',
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      filled: true,
                                      fillColor: const Color(0xFFFEF3C7).withValues(alpha: 0.3),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Catatan per item (opsional)
                        TextField(
                          controller: holder.notesController,
                          decoration: InputDecoration(
                            hintText: 'Catatan kondisi item (opsional, misal: sisa 450 gram ditaruh toples)',
                            hintStyle: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade200),
                            ),
                            isDense: true,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

            const SizedBox(height: 16),

            // Catatan Penutupan Keseluruhan
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Catatan Tambahan Penutupan Toko (Opsional)',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _overallNotesController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Misal: Besok pagi gula merah perlu di-restock karena sisa sedikit',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Tombol Simpan Closing
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
                onPressed: _saving ? null : _submitClosing,
                icon: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_rounded),
                label: Text(
                  _saving ? 'Menyimpan Catatan Stok...' : 'Simpan Catatan Stok Tutup Usaha',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
