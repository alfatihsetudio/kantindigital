import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/top_notification.dart';
import '../../../shared/models/menu_model.dart';
import '../../../shared/models/table_model.dart';
import '../../../shared/models/topping_model.dart';
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
  List<ToppingModel> _toppings = [];
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
    if (_selectedCategory == 'Semua') return _menus;
    return _menus.where((m) => m.categoryName == _selectedCategory).toList();
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
              _cartItems.add(ManualOrderItem(
                menuId: menu.id,
                menu: menu,
                quantity: quantity,
                toppings: selectedToppings,
                notes: notes,
              ));
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

  void _updateCartItem(int index, int delta) {
    setState(() {
      final item = _cartItems[index];
      final newQty = item.quantity + delta;
      
      if (newQty > 0) {
        _cartItems[index] = ManualOrderItem(
          menuId: item.menuId,
          menu: item.menu,
          quantity: newQty,
          toppings: item.toppings,
          notes: item.notes,
        );
      } else {
        _cartItems.removeAt(index);
      }
    });
  }

  void _removeCartItem(int index) {
    setState(() {
      _cartItems.removeAt(index);
    });
  }

  Future<void> _submitOrder() async {
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
        items: _cartItems, // _cartItems is now already List<ManualOrderItem>
        customerName: _nameController.text.trim(),
        customerPhone: _phoneController.text.trim(),
      );

      if (!mounted) return;

      TopNotification.show(
        message: 'Order #$orderCode berhasil dibuat!',
        backgroundColor: AppColors.success,
        icon: Icons.check_circle_rounded,
      );

      Navigator.of(context).pop(true); // Return true to refresh orders
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            if (_loading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else ...[
              _buildCategoryChips(),
              Expanded(
                child: Row(
                  children: [
                    // Menu Grid (Left)
                    Expanded(
                      flex: 3,
                      child: _buildMenuGrid(),
                    ),
                    // Cart Panel (Right)
                    SizedBox(
                      width: 360,
                      child: _buildCartPanel(),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: AppTheme.shadowSm,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
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
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.point_of_sale_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Buat Order Manual',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Tambahkan pesanan langsung dari kasir',
                  style: TextStyle(
                    fontSize: 13,
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
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = cat == _selectedCategory;
          return Padding(
            padding: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
            child: FilterChip(
              label: Text(cat),
              selected: isSelected,
              onSelected: (_) => setState(() => _selectedCategory = cat),
              backgroundColor: Colors.white,
              selectedColor: AppColors.primaryLight,
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
              side: BorderSide(
                color: isSelected ? AppColors.primary : Colors.transparent,
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

  Widget _buildMenuGrid() {
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

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
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

  Widget _buildCartPanel() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.shadowMd,
      ),
      child: Column(
        children: [
          // Cart Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                const Icon(Icons.shopping_cart_rounded, color: AppColors.primary),
                const SizedBox(width: 10),
                const Text(
                  'Keranjang',
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
                        onUpdateQty: (delta) => _updateCartItem(index, delta),
                        onRemove: () => _removeCartItem(index),
                        onTap: () => _editCartItem(index),
                      );
                    },
                  ),
          ),

          // Table Selection
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: DropdownButtonFormField<TableModel>(
              value: _selectedTable,
              decoration: InputDecoration(
                labelText: 'Nomor Meja *',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                filled: true,
                fillColor: AppColors.background,
              ),
              items: _tables.map((t) => DropdownMenuItem(
                value: t,
                child: Text('Meja ${t.code}'),
              )).toList(),
              onChanged: (v) => setState(() => _selectedTable = v),
            ),
          ),

          // Customer Name (Required)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              controller: _nameController,
              onChanged: (v) => setState(() {}),
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
              onChanged: (v) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'No. HP *',
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
                        // Always active to allow showing warning
                        onPressed: _submitting ? null : () {
                          if (!isFormValid) {
                             // Show validation errors
                             String missing = '';
                             if (_cartItems.isEmpty) {
                               missing = 'Menu pesan minimal 1';
                             } else if (_selectedTable == null) {
                               missing = 'Nomor Meja';
                             } else if (_nameController.text.trim().isEmpty) {
                               missing = 'Nama Pelanggan';
                             } else if (_phoneController.text.trim().isEmpty) {
                               missing = 'No. HP';
                             }
                             
                             TopNotification.show(
                               message: 'Mohon lengkapi: $missing',
                               backgroundColor: AppColors.warning,
                               icon: Icons.warning_rounded,
                             );
                             return;
                          }
                          _submitOrder();
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
                        label: Text(_submitting ? 'Memproses...' : 'Buat Order'),
                        style: ElevatedButton.styleFrom(
                          // Visual: Grey if invalid, Primary if valid
                          backgroundColor: isFormValid ? AppColors.primary : Colors.grey.shade400,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: isFormValid ? 4 : 0,
                          shadowColor: isFormValid ? AppColors.primary.withValues(alpha: 0.4) : Colors.transparent,
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
          // Image
          Expanded(
            flex: 3,
            child: Container(
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
          ),
          
          // Info
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    menu.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    CurrencyFormatter.rupiah(menu.price),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Badge if item in cart
                      if (quantity > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$quantity di keranjang',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      if (quantity == 0) const Spacer(),
                      _buildAddButton(onTap),
                    ],
                  ),
                ],
              ),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          children: [
            Icon(Icons.add_rounded, size: 16, color: Colors.white),
            SizedBox(width: 4),
            Text(
              'Tambah',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
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
                          Text(
                            menu.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
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

