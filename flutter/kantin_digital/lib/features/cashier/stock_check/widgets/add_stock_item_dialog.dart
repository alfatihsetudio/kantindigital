import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/top_notification.dart';
import '../../../../shared/models/stock_item_model.dart';
import '../stock_service.dart';

class AddStockItemDialog extends StatefulWidget {
  final StockService service;
  final StockItemModel? itemToEdit;

  const AddStockItemDialog({
    super.key,
    required this.service,
    this.itemToEdit,
  });

  static Future<StockItemModel?> show(
    BuildContext context, {
    required StockService service,
    StockItemModel? itemToEdit,
  }) {
    return showDialog<StockItemModel>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AddStockItemDialog(
        service: service,
        itemToEdit: itemToEdit,
      ),
    );
  }

  @override
  State<AddStockItemDialog> createState() => _AddStockItemDialogState();
}

class _AddStockItemDialogState extends State<AddStockItemDialog> {
  final _nameController = TextEditingController();
  final _unitController = TextEditingController(text: 'gram');
  final _categoryController = TextEditingController(text: 'Bahan Baku');
  bool _saving = false;

  final List<String> _commonUnits = [
    'gram',
    'ml',
    'pcs',
    'kg',
    'botol',
    'pack',
    'cup',
    'porsi',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.itemToEdit != null) {
      _nameController.text = widget.itemToEdit!.name;
      _unitController.text = widget.itemToEdit!.unit;
      _categoryController.text = widget.itemToEdit!.category ?? 'Bahan Baku';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _unitController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    final unit = _unitController.text.trim();
    final category = _categoryController.text.trim();

    if (name.isEmpty) {
      TopNotification.show(
        message: 'Nama item / bahan tidak boleh kosong',
        backgroundColor: AppColors.warning,
        icon: Icons.warning_rounded,
      );
      return;
    }

    if (unit.isEmpty) {
      TopNotification.show(
        message: 'Satuan tidak boleh kosong (contoh: gram, ml, pcs)',
        backgroundColor: AppColors.warning,
        icon: Icons.warning_rounded,
      );
      return;
    }

    setState(() => _saving = true);
    try {
      StockItemModel result;
      if (widget.itemToEdit != null) {
        result = await widget.service.updateStockItem(
          widget.itemToEdit!.id,
          name: name,
          unit: unit,
          category: category,
        );
      } else {
        result = await widget.service.createStockItem(
          name: name,
          unit: unit,
          category: category,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(result);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      TopNotification.show(
        message: 'Gagal menyimpan: $e',
        backgroundColor: AppColors.danger,
        icon: Icons.error_outline_rounded,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.itemToEdit != null;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      actionsPadding: const EdgeInsets.all(20),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.inventory_2_rounded,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEdit ? 'Ubah Item Stok' : 'Tambah Item / Bahan Stok',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Misal: Gula Merah (gram), Susu (ml), Cup (pcs)',
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
      content: SingleChildScrollView(
        child: SizedBox(
          width: 440,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              // Nama item
              TextField(
                controller: _nameController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Nama Item / Bahan *',
                  hintText: 'Contoh: Gula Merah, Susu UHT, Cup 16oz',
                  prefixIcon: const Icon(Icons.label_outline_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
              const SizedBox(height: 16),

              // Satuan
              TextField(
                controller: _unitController,
                decoration: InputDecoration(
                  labelText: 'Satuan Timbangan / Hitung *',
                  hintText: 'gram, ml, pcs, botol',
                  prefixIcon: const Icon(Icons.scale_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
              const SizedBox(height: 8),

              // Quick chip satuan
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: _commonUnits.map((u) {
                  final isSelected = _unitController.text.trim().toLowerCase() == u;
                  return ChoiceChip(
                    label: Text(u),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() {
                        _unitController.text = u;
                      });
                    },
                    selectedColor: AppColors.primaryLight,
                    labelStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : Colors.grey.shade300,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Kategori
              TextField(
                controller: _categoryController,
                decoration: InputDecoration(
                  labelText: 'Kategori (Opsional)',
                  hintText: 'Bahan Baku, Kemasan, Minuman, Topping',
                  prefixIcon: const Icon(Icons.category_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: _saving ? null : _handleSave,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(isEdit ? 'Simpan Perubahan' : 'Tambahkan Item'),
        ),
      ],
    );
  }
}
