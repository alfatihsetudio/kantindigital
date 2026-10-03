import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/top_notification.dart';
import '../../../shared/models/menu_model.dart';
import '../../../shared/models/table_model.dart';
import '../../../shared/models/topping_model.dart';
import '../../../shared/providers/tenant_provider.dart';
import 'manual_order_service.dart';
import 'widgets/item_customization_sheet.dart';

/// Manual Order Page for Cashier
/// Allows cashier to create orders directly without QR scan
class ManualOrderPage extends StatefulWidget {
  const ManualOrderPage({super.key});

  @override
  State<ManualOrderPage> createState() => _ManualOrderPageState();
}

class _ManualOrderPageState extends State<ManualOrderPage> {
  final ManualOrderService _service = ManualOrderService();
  
  List<MenuModel> _menus = [];
  List<TableModel> _tables = [];
  bool _loading = true;
  bool _submitting = false;
  
  // Cart items: List of complex items instead of Map
  final List<ManualOrderItem> _cartItems = [];
  
  // Selected table
  TableModel? _selectedTable;
  
  // Customer info (optional)
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  
  // Category filter
  String _selectedCategory = 'Semua';
  List<String> _categories = ['Semua'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final menus = await _service.getMenus();
      // Toppings are now fetched per menu, so we don't load them globally here
      final tables = await _service.getTables(); 
      
      // Extract categories
      final cats = <String>{'Semua'};
      for (final menu in menus) {
        if (menu.categoryName.isNotEmpty) {
          cats.add(menu.categoryName);
        }
      }
      
      if (mounted) {
        setState(() {
          _menus = menus;
          _tables = tables;
          _categories = cats.toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        TopNotification.show(
          message: 'Gagal memuat data: $e',
          backgroundColor: AppColors.danger,
          icon: Icons.error_rounded,
        );
      }
    }
  }

  List<MenuModel> get _filteredMenus {
    var list = _selectedCategory == 'Semua'
        ? List<MenuModel>.from(_menus)
        : _menus.where((m) => m.categoryName == _selectedCategory).toList();
    list.sort((a, b) => a.flyerOrder.compareTo(b.flyerOrder));
    return list;
  }

  int get _totalAmount {
    return _cartItems.fold(0, (sum, item) => sum + (item.totalPerItem * item.quantity));
  }

  int get _totalItems => _cartItems.fold(0, (sum, item) => sum + item.quantity);

  // Helper to get total qty of a specific menu ID in cart for badge display
  int _getMenuQtyInCart(int menuId) {
    return _cartItems
        .where((item) => item.menuId == menuId)
        .fold(0, (sum, item) => sum + item.quantity);
  }

  Future<void> _openItemCustomization(MenuModel menu) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    try {
      // Fetch specific toppings
      final toppings = await _service.getToppings(menuId: menu.id);
      
      if (!mounted) return;
      Navigator.pop(context); // Dismiss loading

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => ItemCustomizationSheet(
          menu: menu,
          availableToppings: toppings,
          onAdd: (quantity, selectedToppings, notes) {
            setState(() {
              // Normalize note comparison (null or empty considered the same)
              final normalizedNewNotes = (notes ?? '').trim();
              
              // Helper to check if two topping lists are identical
              bool areToppingsIdentical(List<ToppingModel> a, List<ToppingModel> b) {
                if (a.length != b.length) return false;
                final mapA = {for (var t in a) t.id: t.quantity};
                final mapB = {for (var t in b) t.id: t.quantity};
                if (mapA.length != mapB.length) return false;
                for (var entry in mapA.entries) {
                  if (mapB[entry.key] != entry.value) return false;
                }
                return true;
              }

              // Check if matching cart item already exists
              final existingIndex = _cartItems.indexWhere((item) {
                if (item.menuId != menu.id) return false;
                final normalizedItemNotes = (item.notes ?? '').trim();
                if (normalizedItemNotes != normalizedNewNotes) return false;
                return areToppingsIdentical(item.toppings, selectedToppings);
              });

              if (existingIndex != -1) {
                // Item with identical toppings & notes exists -> Increment quantity
                final existing = _cartItems[existingIndex];
                _cartItems[existingIndex] = ManualOrderItem(
                  menuId: existing.menuId,
                  menu: existing.menu,
                  quantity: existing.quantity + quantity,
                  toppings: existing.toppings,
                  notes: existing.notes,
                );
              } else {
                // Different topping/note or new item -> Add new card
                _cartItems.add(ManualOrderItem(
                  menuId: menu.id,
                  menu: menu,
                  quantity: quantity,
                  toppings: selectedToppings,
                  notes: notes,
                ));
              }
            });
          },
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Dismiss loading
      TopNotification.show(
        message: 'Gagal memuat topping: $e',
        backgroundColor: AppColors.danger,
        icon: Icons.error_rounded,
      );
    }
  }

  Future<void> _editCartItem(int index) async {
    final item = _cartItems[index];
    final menu = item.menu ?? _menus.firstWhere((m) => m.id == item.menuId);

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    try {
      // Fetch specific toppings
      final toppings = await _service.getToppings(menuId: menu.id);

      if (!mounted) return;
      Navigator.pop(context); // Dismiss loading

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => ItemCustomizationSheet(
          menu: menu,
          availableToppings: toppings,
          initialQuantity: item.quantity,
          initialToppings: item.toppings,
          initialNotes: item.notes,
          ctaLabel: 'Simpan Perubahan',
          onAdd: (quantity, selectedToppings, notes) {
            setState(() {
              _cartItems[index] = ManualOrderItem(
                menuId: menu.id,
                menu: menu,
                quantity: quantity,
                toppings: selectedToppings,
                notes: notes,
              );
            });
          },
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Dismiss loading
      TopNotification.show(
        message: 'Gagal memuat topping: $e',
        backgroundColor: AppColors.danger,
        icon: Icons.error_rounded,
      );
    }
  }

  Future<void> _showTableSelectionSheet({VoidCallback? onStateChanged}) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final filteredTables = _tables.where((t) {
              if (searchQuery.isEmpty) return true;
              final codeMatch = t.code.toLowerCase().contains(searchQuery.toLowerCase());
              final nameMatch = (t.name ?? '').toLowerCase().contains(searchQuery.toLowerCase());
              return codeMatch || nameMatch;
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.92,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Drag Handle
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.table_restaurant_rounded, color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Pilih Nomor Meja',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                  // Search Box
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Cari meja (contoh: A1, Indoor, VIP)...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textSecondary),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (v) {
                        setSheetState(() => searchQuery = v.trim());
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  // Tables List
                  Expanded(
                    child: filteredTables.isEmpty
                        ? const Center(
                            child: Text(
                              'Meja tidak ditemukan',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            itemCount: filteredTables.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final table = filteredTables[index];
                              final isSelected = _selectedTable?.id == table.id;

                              return ListTile(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                tileColor: isSelected ? AppColors.primary.withValues(alpha: 0.08) : Colors.transparent,
                                leading: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.primary : AppColors.background,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      table.code,
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : AppColors.primary,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                ),
                                title: Text(
                                  table.name != null && table.name!.isNotEmpty ? table.name! : 'Meja ${table.code}',
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                    fontSize: 14,
                                  ),
                                ),
                                trailing: isSelected
                                    ? const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 24)
                                    : Container(
                                        width: 20,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.grey.shade300, width: 1.5),
                                        ),
                                      ),
                                onTap: () {
                                  setState(() => _selectedTable = table);
                                  onStateChanged?.call();
                                  Navigator.of(context).pop();
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<bool> _confirmRemoveCartItem(int index) async {
    final item = _cartItems[index];
    final menu = item.menu ?? _menus.firstWhere((m) => m.id == item.menuId);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 22),
            ),
            const SizedBox(width: 12),
            const Text(
              'Hapus Menu?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus "${menu.name}" dari keranjang?',
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text('Ya, Hapus'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Future<void> _updateCartItem(int index, int delta) async {
    final item = _cartItems[index];
    final newQty = item.quantity + delta;
    
    if (newQty > 0) {
      setState(() {
        _cartItems[index] = ManualOrderItem(
          menuId: item.menuId,
          menu: item.menu,
          quantity: newQty,
          toppings: item.toppings,
          notes: item.notes,
        );
      });
    } else {
      final confirmed = await _confirmRemoveCartItem(index);
      if (confirmed) {
        setState(() {
          _cartItems.removeAt(index);
        });
      }
    }
  }

  Future<void> _removeCartItem(int index) async {
    final confirmed = await _confirmRemoveCartItem(index);
    if (confirmed) {
      setState(() {
        _cartItems.removeAt(index);
      });
    }
  }

  Future<void> _submitOrder({bool isMobileModal = false}) async {
    if (_selectedTable == null) {
      TopNotification.show(
        message: 'Pilih nomor meja terlebih dahulu',
        backgroundColor: AppColors.warning,
        icon: Icons.warning_rounded,
      );
      return;
    }

    if (_cartItems.isEmpty) {
      TopNotification.show(
        message: 'Tambahkan minimal 1 menu',
        backgroundColor: AppColors.warning,
        icon: Icons.warning_rounded,
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final orderCode = await _service.createOrder(
        tableCode: _selectedTable!.code,
        items: _cartItems,
        customerName: _nameController.text.trim(),
        customerPhone: _phoneController.text.trim(),
      );

      if (!mounted) return;

      setState(() => _submitting = false);

      TopNotification.show(
        message: 'Order #$orderCode berhasil dibuat!',
        backgroundColor: AppColors.success,
        icon: Icons.check_circle_rounded,
      );

      // If submitted from mobile modal bottom sheet, close the modal first
      if (isMobileModal && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      // Then navigate back to cashier page and refresh orders
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      TopNotification.show(
        message: 'Gagal membuat order: $e',
        backgroundColor: AppColors.danger,
        icon: Icons.error_rounded,
      );
    }
  }

  void _openMobileCart() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Drag handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Expanded(
                  child: _buildCartPanel(
                    isMobileModal: true,
                    onStateChanged: () => setModalState(() {}),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 768;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(isMobile: isMobile),
                if (_loading)
                  const Expanded(
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  )
                else ...[
                  _buildCategoryChips(),
                  Expanded(
                    child: isMobile
                        ? _buildMenuGrid(isMobile: true)
                        : Row(
                            children: [
                              // Menu Grid (Left)
                              Expanded(
                                flex: 3,
                                child: _buildMenuGrid(isMobile: false),
                              ),
                              // Cart Panel (Right)
                              SizedBox(
                                width: 360,
                                child: _buildCartPanel(isMobileModal: false),
                              ),
                            ],
                          ),
                  ),
                ],
              ],
            ),
          ),
          // Mobile Floating Cart Bar / Bottom Sheet trigger
          bottomNavigationBar: (isMobile && !_loading)
              ? _buildMobileBottomBar()
              : null,
        );
      },
    );
  }

  Widget _buildHeader({bool isMobile = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: AppTheme.shadowSm,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, Color(0xFF0D9488)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.point_of_sale_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Buat Order Manual',
                  style: TextStyle(
                    fontSize: isMobile ? 17 : 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Tambahkan pesanan langsung dari kasir',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: isMobile ? 11 : 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = cat == _selectedCategory;
          return Padding(
            padding: const EdgeInsets.only(right: 8, top: 6, bottom: 6),
            child: FilterChip(
              label: Text(cat),
              selected: isSelected,
              onSelected: (_) => setState(() => _selectedCategory = cat),
              backgroundColor: Colors.white,
              selectedColor: AppColors.primaryLight,
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
              ),
              side: BorderSide(
                color: isSelected ? AppColors.primary : Colors.grey.shade200,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMenuGrid({bool isMobile = false}) {
    final menus = _filteredMenus;
    
    if (menus.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu_rounded, size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(
              'Tidak ada menu',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (isMobile) {
      // Mobile 2-column Grid with optimized aspect ratio
      return GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.72,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: menus.length,
        itemBuilder: (context, index) {
          final menu = menus[index];
          final qty = _getMenuQtyInCart(menu.id);
          return _MenuCard(
            menu: menu,
            quantity: qty,
            onTap: () => _openItemCustomization(menu),
          );
        },
      );
    }

    // Tablet/Desktop responsive grid
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: menus.length,
      itemBuilder: (context, index) {
        final menu = menus[index];
        final qty = _getMenuQtyInCart(menu.id);
        return _MenuCard(
          menu: menu,
          quantity: qty,
          onTap: () => _openItemCustomization(menu),
        );
      },
    );
  }

  Widget _buildMobileBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Cart Info & Trigger
            Expanded(
              child: InkWell(
                onTap: _openMobileCart,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.shopping_bag_outlined, size: 18, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text(
                            '$_totalItems Item',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        CurrencyFormatter.rupiah(_totalAmount),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Checkout Button
            ElevatedButton.icon(
              onPressed: _openMobileCart,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 3,
              ),
              icon: const Icon(Icons.shopping_cart_checkout_rounded, size: 18),
              label: const Text(
                'Lihat Order',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartPanel({bool isMobileModal = false, VoidCallback? onStateChanged}) {
    return Container(
      margin: isMobileModal ? EdgeInsets.zero : const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isMobileModal ? 0 : 20),
        boxShadow: isMobileModal ? null : AppTheme.shadowMd,
      ),
      child: Column(
        children: [
          // Cart Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: isMobileModal
                  ? BorderRadius.zero
                  : const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Icon(Icons.shopping_cart_rounded, color: AppColors.primary, size: 22),
                const SizedBox(width: 10),
                const Text(
                  'Keranjang Pesanan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$_totalItems item',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (isMobileModal) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textSecondary),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ],
            ),
          ),
          
          // Cart Items
          Expanded(
            child: _cartItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart_outlined, size: 48, color: AppColors.textMuted),
                        const SizedBox(height: 8),
                        Text(
                          'Keranjang kosong',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _cartItems.length,
                    separatorBuilder: (_, __) => const Divider(height: 16),
                    itemBuilder: (context, index) {
                      final item = _cartItems[index];
                      // Use stored menu or find it
                      final menu = item.menu ?? _menus.firstWhere((m) => m.id == item.menuId);
                      return _CartItemTile(
                        menu: menu,
                        item: item,
                        onUpdateQty: (delta) {
                          _updateCartItem(index, delta);
                          onStateChanged?.call();
                        },
                        onRemove: () {
                          _removeCartItem(index);
                          onStateChanged?.call();
                        },
                        onTap: () async {
                          await _editCartItem(index);
                          onStateChanged?.call();
                        },
                      );
                    },
                  ),
          ),

          // Table Selection
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showTableSelectionSheet(onStateChanged: onStateChanged),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedTable != null ? AppColors.primary : Colors.grey.shade400,
                      width: _selectedTable != null ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.table_restaurant_rounded,
                        size: 20,
                        color: _selectedTable != null ? AppColors.primary : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Nomor Meja *',
                              style: TextStyle(
                                fontSize: 11,
                                color: _selectedTable != null ? AppColors.primary : AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _selectedTable != null
                                  ? (_selectedTable!.name != null && _selectedTable!.name!.isNotEmpty
                                      ? _selectedTable!.name!
                                      : 'Meja ${_selectedTable!.code}')
                                  : 'Pilih meja pesanan...',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: _selectedTable != null ? FontWeight.w700 : FontWeight.normal,
                                color: _selectedTable != null ? AppColors.textPrimary : AppColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down_rounded, color: AppColors.textSecondary, size: 28),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Customer Name (Required)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              controller: _nameController,
              onChanged: (v) {
                setState(() {});
                onStateChanged?.call();
              },
              decoration: InputDecoration(
                labelText: 'Nama Pelanggan *',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                filled: true,
                fillColor: AppColors.background,
              ),
            ),
          ),

          // Customer Phone (Required)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(15),
              ],
              onChanged: (v) {
                setState(() {});
                onStateChanged?.call();
              },
              decoration: InputDecoration(
                labelText: 'No. HP *',
                hintText: '08123456789',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                filled: true,
                fillColor: AppColors.background,
              ),
            ),
          ),

              // Total & Submit
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.rupiah(_totalAmount),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: Builder(
                    builder: (context) {
                      final bool isFormValid = _cartItems.isNotEmpty && 
                          _selectedTable != null && 
                          _nameController.text.trim().isNotEmpty && 
                          _phoneController.text.trim().isNotEmpty;

                      return ElevatedButton.icon(
                        onPressed: _submitting ? null : () async {
                          if (!isFormValid) {
                             String missing = '';
                             if (_cartItems.isEmpty) {
                               missing = 'Pilih menu minimal 1 item';
                             } else if (_selectedTable == null) {
                               missing = 'Nomor Meja';
                             } else if (_nameController.text.trim().isEmpty) {
                               missing = 'Nama Pelanggan';
                             } else if (_phoneController.text.trim().isEmpty) {
                               missing = 'No. HP Pelanggan';
                             }
                             
                             TopNotification.show(
                               message: 'Mohon lengkapi: $missing',
                               backgroundColor: AppColors.warning,
                               icon: Icons.warning_rounded,
                             );
                             return;
                          }
                          onStateChanged?.call();
                          await _submitOrder(isMobileModal: isMobileModal);
                          onStateChanged?.call();
                        },
                        icon: _submitting
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
                          _submitting ? 'Memproses...' : 'Buat Order',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 3,
                          shadowColor: AppColors.primary.withValues(alpha: 0.4),
                        ),
                      );
                    }
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// MENU CARD
// ═══════════════════════════════════════════════════════════

class _MenuCard extends StatelessWidget {
  final MenuModel menu;
  final int quantity;
  final VoidCallback onTap;

  const _MenuCard({
    required this.menu,
    required this.quantity,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image with floating badge if in cart
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: menu.imageUrl != null && menu.imageUrl!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          child: Image.network(
                            menu.imageUrl!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (_, __, ___) => _buildPlaceholder(),
                          ),
                        )
                      : _buildPlaceholder(),
                ),
                if (quantity > 0)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.shopping_bag, color: Colors.white, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            '$quantity',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Info & Add Button
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Builder(
                  builder: (context) {
                    final prefix = TenantProvider.of(context).menuCodePrefix;
                    final codeText = menu.formattedCode(prefix);
                    return Row(
                      children: [
                        if (codeText.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              codeText,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                        ],
                        Expanded(
                          child: Text(
                            menu.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 2),
                Text(
                  CurrencyFormatter.rupiah(menu.price),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                _buildAddButton(onTap),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Icon(
        Icons.restaurant_rounded,
        size: 40,
        color: AppColors.textMuted.withValues(alpha: 0.5),
      ),
    );
  }

  Widget _buildAddButton(VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.25),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.add_rounded,
                size: 16,
                color: Colors.white,
              ),
              const SizedBox(width: 4),
              Text(
                quantity > 0 ? 'Tambah ($quantity)' : 'Tambah',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// CART ITEM TILE
// ═══════════════════════════════════════════════════════════

class _CartItemTile extends StatelessWidget {
  final MenuModel menu;
  final ManualOrderItem item;
  final Function(int) onUpdateQty;
  final VoidCallback onRemove;
  final VoidCallback onTap;

  const _CartItemTile({
    required this.menu,
    required this.item,
    required this.onUpdateQty,
    required this.onRemove,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Thumbnail
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: menu.imageUrl != null && menu.imageUrl!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                menu.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.restaurant, color: AppColors.textMuted),
                              ),
                            )
                          : const Icon(Icons.restaurant, color: AppColors.textMuted),
                    ),
                    const SizedBox(width: 12),
                    
                    // Name & Price
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Builder(
                            builder: (context) {
                              final prefix = TenantProvider.of(context).menuCodePrefix;
                              final codeText = menu.formattedCode(prefix);
                              return Row(
                                children: [
                                  if (codeText.isNotEmpty) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryLight,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        codeText,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                  ],
                                  Expanded(
                                    child: Text(
                                      menu.displayName,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 4),
                          Text(
                            CurrencyFormatter.rupiah(item.totalPerItem * item.quantity),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                          
                          // Explicit Edit Button
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: onTap,
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                                borderRadius: BorderRadius.circular(6),
                                color: AppColors.primary.withValues(alpha: 0.05),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.edit_note_rounded, size: 14, color: AppColors.primary),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'Ubah Topping / Catatan',
                                    style: TextStyle(
                                      fontSize: 10, 
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Delete Button
                    InkWell(
                      onTap: onRemove,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        child: Icon(Icons.close_rounded, size: 16, color: Colors.grey.shade400),
                      ),
                    ),
                  ],
                ),
                
                // Toppings & Notes section
                if (item.toppings.isNotEmpty || (item.notes != null && item.notes!.isNotEmpty)) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.background.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (item.toppings.isNotEmpty)
                          ...item.toppings.map((t) => Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Row(
                              children: [
                                const Icon(Icons.add_circle_outline, size: 10, color: AppColors.textSecondary),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    '${t.name} (x${t.quantity})',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  CurrencyFormatter.rupiah(t.price * t.quantity),
                                  style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          )),
                        if (item.notes != null && item.notes!.isNotEmpty) ...[
                          if (item.toppings.isNotEmpty) const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.sticky_note_2_outlined, size: 10, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  item.notes!,
                                  style: const TextStyle(
                                    fontSize: 11, 
                                    color: AppColors.textSecondary,
                                    fontStyle: FontStyle.italic,
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

                // Qty Control (Bottom)
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    InkWell(
                      onTap: () => onUpdateQty(-1),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: const Icon(Icons.remove, size: 14, color: AppColors.textPrimary),
                      ),
                    ),
                    Container(
                      constraints: const BoxConstraints(minWidth: 30),
                      alignment: Alignment.center,
                      child: Text(
                        '${item.quantity}',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ),
                    InkWell(
                      onTap: () => onUpdateQty(1),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.add, size: 14, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

