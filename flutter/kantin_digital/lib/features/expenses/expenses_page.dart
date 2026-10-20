import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/top_notification.dart';
import '../../shared/auth/auth_session.dart';
import '../../shared/constants/expense_categories.dart';
import '../../shared/constants/user_role.dart';
import '../../shared/models/expense_model.dart';
import '../../shared/models/stock_item_model.dart';
import '../../shared/models/stock_check_model.dart';
import '../cashier/stock_check/stock_service.dart';
import '../cashier/stock_check/widgets/add_stock_item_dialog.dart';
import '../admin/widgets/admin_drawer.dart';
import '../cashier/widgets/cashier_drawer.dart';
import '../manager/widgets/manager_drawer.dart';
import 'expense_service.dart';

/// Halaman Daftar Belanja & Pengeluaran.
///
/// - Kasir / operasional mengisi catatan (`canInput = true`).
/// - Admin/owner & manajer hanya melihat daftar (`canInput = false`).
class ExpensesPage extends StatefulWidget {
  final bool canInput;

  const ExpensesPage({super.key, this.canInput = false});

  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

enum _Period { today, week, month, all }

class _ExpensesPageState extends State<ExpensesPage> {
  final ExpenseService _service = ExpenseService();
  final ScrollController _scrollController = ScrollController();

  _Period _period = _Period.month;
  bool _loading = true;
  ExpenseListResult _result = const ExpenseListResult();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _ymd(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final now = DateTime.now();
      String? start;
      String? end;
      switch (_period) {
        case _Period.today:
          start = _ymd(now);
          end = _ymd(now);
          break;
        case _Period.week:
          start = _ymd(now.subtract(const Duration(days: 6)));
          end = _ymd(now);
          break;
        case _Period.month:
          start = _ymd(DateTime(now.year, now.month, 1));
          end = _ymd(now);
          break;
        case _Period.all:
          break;
      }

      final result = await _service.fetchExpenses(startDate: start, endDate: end);
      if (!mounted) return;
      setState(() {
        _result = result;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      TopNotification.show(
        message: 'Gagal memuat data pengeluaran: $e',
        backgroundColor: AppColors.danger,
        icon: Icons.error_rounded,
      );
    }
  }

  Future<void> _showForm({ExpenseModel? existing}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ExpenseFormSheet(service: _service, existing: existing),
    );
    if (saved == true) _load();
  }

  Future<void> _confirmDelete(ExpenseModel expense) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Pengeluaran?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          'Catatan "${expense.description}" sebesar ${CurrencyFormatter.rupiah(expense.amount)} akan dihapus permanen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await _service.deleteExpense(expense.id);
      if (!mounted) return;
      TopNotification.show(
        message: 'Pengeluaran berhasil dihapus',
        backgroundColor: AppColors.success,
        icon: Icons.check_circle_rounded,
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      TopNotification.show(
        message: 'Gagal menghapus: $e',
        backgroundColor: AppColors.danger,
        icon: Icons.error_rounded,
      );
    }
  }

  Widget _buildDrawer() {
    switch (AuthSession().role) {
      case UserRole.cashier:
      case UserRole.operations:
        return const CashierDrawer();
      case UserRole.manager:
        return const ManagerDrawer();
      default:
        return const AdminDrawer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(
              Icons.menu_rounded,
              color: AppColors.textPrimary,
            ),
            tooltip: 'Menu',
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Daftar Belanja & Pengeluaran',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'Catatan belanja operasional kantin',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Muat ulang',
          ),
        ],
      ),
      drawer: _buildDrawer(),
      floatingActionButton: widget.canInput
          ? FloatingActionButton.extended(
              onPressed: () => _showForm(),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_shopping_cart_rounded),
              label: const Text('Catat Pengeluaran', style: TextStyle(fontWeight: FontWeight.bold)),
            )
          : null,
      body: Column(
        children: [
          _buildSummary(),
          _buildPeriodFilter(),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Pengeluaran',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  CurrencyFormatter.rupiah(_result.totalAmount),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  '${_result.totalTransactions}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Transaksi',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodFilter() {
    const labels = {
      _Period.today: 'Hari Ini',
      _Period.week: '7 Hari',
      _Period.month: 'Bulan Ini',
      _Period.all: 'Semua',
    };

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: labels.entries.map((entry) {
          final selected = _period == entry.key;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(entry.value),
              selected: selected,
              onSelected: (_) {
                if (_period == entry.key) return;
                setState(() => _period = entry.key);
                _load();
              },
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
              selectedColor: AppColors.primary,
              backgroundColor: Colors.white,
              showCheckmark: false,
              side: BorderSide(
                color: selected ? AppColors.primary : const Color(0xFFE2E8F0),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildList() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_result.expenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_rounded, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'Belum ada catatan pengeluaran pada periode ini',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
            ),
            if (widget.canInput) ...[
              const SizedBox(height: 6),
              Text(
                'Tekan tombol "Catat Pengeluaran" untuk menambah',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: _result.expenses.length,
      itemBuilder: (context, index) => _buildCard(_result.expenses[index]),
    );
  }

  Widget _buildCard(ExpenseModel expense) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_categoryIcon(expense.category), color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.description,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        expense.category,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    if (expense.stockItem != null || expense.quantity != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.inventory_2_outlined, size: 11, color: Color(0xFF2563EB)),
                            const SizedBox(width: 4),
                            Text(
                              '${expense.stockItem?.name ?? "Bahan"}${expense.quantity != null ? ": ${expense.quantity!.toStringAsFixed(expense.quantity!.truncateToDouble() == expense.quantity ? 0 : 2)} ${expense.unit ?? expense.stockItem?.unit ?? ''}" : ""}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1D4ED8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Text(
                      _formatDate(expense.expenseDate),
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                if (expense.notes != null && expense.notes!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    expense.notes!,
                    style: const TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                if (expense.userName != null && expense.userName!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.person_outline_rounded, size: 13, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        'Dicatat oleh ${expense.userName}',
                        style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyFormatter.rupiah(expense.amount),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFDC2626),
                ),
              ),
              if (widget.canInput)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, size: 20, color: AppColors.textSecondary),
                  padding: EdgeInsets.zero,
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showForm(existing: expense);
                    } else if (value == 'delete') {
                      _confirmDelete(expense);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_rounded, size: 18, color: AppColors.textSecondary),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.danger),
                          SizedBox(width: 8),
                          Text('Hapus', style: TextStyle(color: AppColors.danger)),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  static const List<String> _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];

  String _formatDate(String raw) {
    final d = DateTime.tryParse(raw);
    if (d == null) return raw;
    return '${d.day} ${_monthNames[d.month - 1]} ${d.year}';
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Bahan Baku':
        return Icons.local_grocery_store_rounded;
      case 'Kemasan & Perlengkapan':
        return Icons.inventory_2_rounded;
      case 'Gas & Listrik':
        return Icons.local_fire_department_rounded;
      case 'Air & Kebersihan':
        return Icons.water_drop_rounded;
      case 'Gaji & Upah':
        return Icons.groups_rounded;
      case 'Sewa Tempat':
        return Icons.storefront_rounded;
      case 'Transportasi':
        return Icons.local_shipping_rounded;
      case 'Peralatan & Perbaikan':
        return Icons.handyman_rounded;
      case 'Promosi & Marketing':
        return Icons.campaign_rounded;
      default:
        return Icons.receipt_long_rounded;
    }
  }
}

/// Form input / edit pengeluaran (dipakai kasir & operasional).
class _ExpenseFormSheet extends StatefulWidget {
  final ExpenseService service;
  final ExpenseModel? existing;

  const _ExpenseFormSheet({required this.service, this.existing});

  @override
  State<_ExpenseFormSheet> createState() => _ExpenseFormSheetState();
}

class _ExpenseFormSheetState extends State<_ExpenseFormSheet> {
  final StockService _stockService = StockService();

  late final TextEditingController _descriptionCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _notesCtrl;
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _unitCtrl;

  String _category = ExpenseCategories.all.first;
  DateTime _date = DateTime.now();
  bool _submitting = false;

  List<StockItemModel> _stockItems = [];
  StockCheckModel? _latestClosing;
  StockItemModel? _selectedStockItem;
  bool _loadingStock = true;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _descriptionCtrl = TextEditingController(text: existing?.description ?? '');
    _amountCtrl = TextEditingController(
      text: existing != null && existing.amount > 0
          ? existing.amount.toStringAsFixed(0)
          : '',
    );
    _notesCtrl = TextEditingController(text: existing?.notes ?? '');
    _qtyCtrl = TextEditingController(
      text: existing?.quantity != null
          ? (existing!.quantity!.truncateToDouble() == existing.quantity
              ? existing.quantity!.toStringAsFixed(0)
              : existing.quantity!.toStringAsFixed(2))
          : '',
    );
    _unitCtrl = TextEditingController(text: existing?.unit ?? '');

    if (existing != null) {
      _category = ExpenseCategories.all.contains(existing.category)
          ? existing.category
          : ExpenseCategories.all.first;
      _date = DateTime.tryParse(existing.expenseDate) ?? DateTime.now();
    }

    _loadStockData();
  }

  @override
  void dispose() {
    _descriptionCtrl.dispose();
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    _qtyCtrl.dispose();
    _unitCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadStockData() async {
    try {
      final items = await _stockService.getStockItems(activeOnly: true);
      final closing = await _stockService.getLatestClosing();
      if (!mounted) return;

      StockItemModel? matched;
      if (widget.existing?.stockItemId != null) {
        matched = items.cast<StockItemModel?>().firstWhere(
          (i) => i?.id == widget.existing!.stockItemId,
          orElse: () => widget.existing!.stockItem,
        );
      } else if (widget.existing != null && widget.existing!.category == 'Bahan Baku') {
        // Coba cari nama yang cocok dari deskripsi
        final descLower = widget.existing!.description.toLowerCase();
        for (final item in items) {
          if (descLower.contains(item.name.toLowerCase())) {
            matched = item;
            break;
          }
        }
      }

      setState(() {
        _stockItems = items;
        _latestClosing = closing;
        _selectedStockItem = matched;
        if (matched != null && _unitCtrl.text.isEmpty) {
          _unitCtrl.text = matched.unit;
        }
        _loadingStock = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingStock = false);
    }
  }

  String _getStockRemainingText(StockItemModel item) {
    if (_latestClosing == null) return 'Belum ada catatan fisik closing';
    final match = _latestClosing!.items.cast<StockCheckItemModel?>().firstWhere(
      (i) => i?.stockItemId == item.id ||
          (i != null && i.itemName.toLowerCase().trim() == item.name.toLowerCase().trim()),
      orElse: () => null,
    );
    if (match == null) {
      return 'Belum tercatat di closing terakhir';
    }
    final whole = match.wholeQuantity.truncateToDouble() == match.wholeQuantity
        ? match.wholeQuantity.toStringAsFixed(0)
        : match.wholeQuantity.toStringAsFixed(2);
    final rem = match.remainderQuantity.truncateToDouble() == match.remainderQuantity
        ? match.remainderQuantity.toStringAsFixed(0)
        : match.remainderQuantity.toStringAsFixed(2);
    return 'Utuh $whole pcs  •  Sisa $rem ${match.unit}';
  }

  void _onStockItemSelected(StockItemModel? item) {
    setState(() {
      _selectedStockItem = item;
      if (item != null) {
        if (_unitCtrl.text.isEmpty || _unitCtrl.text.trim() != item.unit) {
          _unitCtrl.text = item.unit;
        }
        _updateDescriptionFromStock();
      }
    });
  }

  void _updateDescriptionFromStock() {
    if (_selectedStockItem == null) return;
    final qty = _qtyCtrl.text.trim();
    final unit = _unitCtrl.text.trim().isNotEmpty ? _unitCtrl.text.trim() : _selectedStockItem!.unit;
    if (qty.isNotEmpty) {
      _descriptionCtrl.text = 'Beli ${_selectedStockItem!.name} $qty $unit';
    } else {
      _descriptionCtrl.text = 'Beli ${_selectedStockItem!.name}';
    }
  }

  Future<void> _addNewStockItem() async {
    final newItem = await AddStockItemDialog.show(context, service: _stockService);
    if (newItem != null && mounted) {
      setState(() {
        _stockItems.add(newItem);
        _selectedStockItem = newItem;
        _unitCtrl.text = newItem.unit;
        _updateDescriptionFromStock();
      });
      TopNotification.show(
        message: 'Bahan "${newItem.name}" ditambahkan ke master stok!',
        backgroundColor: AppColors.success,
        icon: Icons.check_circle_rounded,
      );
    }
  }

  String _ymd(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    final description = _descriptionCtrl.text.trim();
    final amount = double.tryParse(_amountCtrl.text.trim().replaceAll('.', '').replaceAll(',', '')) ?? 0;
    final qtyVal = double.tryParse(_qtyCtrl.text.trim().replaceAll(',', '.')) ?? 0;

    if (description.isEmpty) {
      TopNotification.show(
        message: 'Keterangan belanja wajib diisi',
        backgroundColor: AppColors.warning,
        icon: Icons.warning_rounded,
      );
      return;
    }
    if (amount <= 0) {
      TopNotification.show(
        message: 'Jumlah pengeluaran harus lebih dari 0',
        backgroundColor: AppColors.warning,
        icon: Icons.warning_rounded,
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final stockItemId = _selectedStockItem?.id;
      final quantity = qtyVal > 0 ? qtyVal : null;
      final unit = _unitCtrl.text.trim().isNotEmpty ? _unitCtrl.text.trim() : _selectedStockItem?.unit;

      if (widget.existing == null) {
        await widget.service.createExpense(
          expenseDate: _ymd(_date),
          category: _category,
          stockItemId: stockItemId,
          quantity: quantity,
          unit: unit,
          description: description,
          amount: amount,
          notes: _notesCtrl.text,
        );
      } else {
        await widget.service.updateExpense(
          widget.existing!.id,
          expenseDate: _ymd(_date),
          category: _category,
          stockItemId: stockItemId,
          quantity: quantity,
          unit: unit,
          description: description,
          amount: amount,
          notes: _notesCtrl.text,
        );
      }

      if (!mounted) return;
      Navigator.pop(context, true);
      TopNotification.show(
        message: widget.existing == null
            ? 'Pengeluaran berhasil dicatat'
            : 'Pengeluaran berhasil diperbarui',
        backgroundColor: AppColors.success,
        icon: Icons.check_circle_rounded,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      TopNotification.show(
        message: 'Gagal menyimpan: $e',
        backgroundColor: AppColors.danger,
        icon: Icons.error_rounded,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final isStockCategory = _category == 'Bahan Baku' || _category == 'Kemasan & Perlengkapan';

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isEdit ? 'Edit Pengeluaran' : 'Catat Pengeluaran Baru',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Tanggal',
                    prefixIcon: const Icon(Icons.calendar_today_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(_ymd(_date)),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: InputDecoration(
                  labelText: 'Kategori',
                  prefixIcon: const Icon(Icons.category_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: ExpenseCategories.all
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _category = value;
                      if (_category != 'Bahan Baku' && _category != 'Kemasan & Perlengkapan') {
                        _selectedStockItem = null;
                      }
                    });
                  }
                },
              ),

              // Bagian Penyesuaian dengan Stok Bahan Baku
              if (isStockCategory) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.inventory_2_rounded, size: 16, color: AppColors.primary),
                              SizedBox(width: 6),
                              Text(
                                'Sesuaikan dengan Stok Bahan',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          TextButton.icon(
                            onPressed: _addNewStockItem,
                            icon: const Icon(Icons.add_circle_outline_rounded, size: 15),
                            label: const Text('+ Bahan Baru', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int?>(
                        initialValue: _selectedStockItem?.id,
                        isExpanded: true,
                        decoration: InputDecoration(
                          hintText: _loadingStock
                              ? 'Memuat daftar bahan...'
                              : 'Pilih bahan dari data stok (opsional)',
                          prefixIcon: const Icon(Icons.inventory_2_outlined),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text(
                              '-- Bukan dari stok (Input manual) --',
                              style: TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                          ),
                          ..._stockItems.map((item) => DropdownMenuItem<int?>(
                                value: item.id,
                                child: Text(
                                  '${item.name} (Satuan: ${item.unit})',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                              )),
                        ],
                        onChanged: (val) {
                          if (val == null) {
                            _onStockItemSelected(null);
                          } else {
                            final found = _stockItems.firstWhere((i) => i.id == val);
                            _onStockItemSelected(found);
                          }
                        },
                      ),

                      // Kartu Informasi Sisa Stok Terakhir
                      if (_selectedStockItem != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFBBF7D0)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.scale_rounded, color: Color(0xFF16A34A), size: 18),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Sisa Stok Fisik Terakhir (Closing):',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF166534),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _getStockRemainingText(_selectedStockItem!),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF15803D),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Form Jumlah Qty Beli & Satuan
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextField(
                                controller: _qtyCtrl,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                onChanged: (_) => _updateDescriptionFromStock(),
                                decoration: InputDecoration(
                                  labelText: 'Jumlah Beli (Qty)',
                                  hintText: 'Misal: 5',
                                  prefixIcon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: _unitCtrl,
                                onChanged: (_) => _updateDescriptionFromStock(),
                                decoration: InputDecoration(
                                  labelText: 'Satuan',
                                  hintText: 'kg, pcs, gram',
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 12),
              TextField(
                controller: _descriptionCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Keterangan Belanja *',
                  hintText: 'Misal: Beli gula pasir 5 kg',
                  prefixIcon: const Icon(Icons.edit_note_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Jumlah (Rp) *',
                  prefixIcon: const Icon(Icons.payments_rounded),
                  prefixText: 'Rp ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notesCtrl,
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Catatan (opsional)',
                  prefixIcon: const Icon(Icons.notes_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submitting ? null : _submit,
                  icon: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(
                    _submitting ? 'Menyimpan...' : (isEdit ? 'Simpan Perubahan' : 'Simpan Pengeluaran'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
