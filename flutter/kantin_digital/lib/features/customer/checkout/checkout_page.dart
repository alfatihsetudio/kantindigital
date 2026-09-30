import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/glass_components.dart';
import '../../../router/route_name.dart';
import '../../../shared/models/table_model.dart';
import '../../admin/tables/tables_service.dart';
import '../cart/cart_controller.dart';
import 'checkout_controller.dart';
import '../../../shared/storage/active_order_storage.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  List<TableModel> _tables = [];
  TableModel? _selectedTable;
  bool _tablesLoading = true;
  final _controller = CheckoutController();
  bool _loading = false;
  String _selectedPayment = 'qris';
  late TextEditingController _nameController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    
    // Listen to changes to update button state
    _nameController.addListener(() { setState(() {}); });
    _phoneController.addListener(() { setState(() {}); });
    
    _fetchTables();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _checkLockedTable() {
    final lockedCode = CartController.instance.tableNumber;
    if (lockedCode != null && lockedCode.isNotEmpty && _tables.isNotEmpty) {
      try {
        final found = _tables.firstWhere((t) => t.code == lockedCode);
        setState(() {
          _selectedTable = found;
        });
      } catch (_) {}
    }
  }

  Future<void> _fetchTables() async {
    try {
      final tables = await AdminTablesService().getTables();
      setState(() {
        _tables = tables;
        _tablesLoading = false;
      });
      _checkLockedTable();
    } catch (e) {
      setState(() {
        _tablesLoading = false;
      });
      if (mounted) {
        AppSnackBar.show(context, message: 'Gagal mengambil data meja');
      }
    }
  }

  Future<void> _submit() async {
    // Validasi nama
    if (_nameController.text.trim().isEmpty) {
      AppSnackBar.show(context, message: 'Mohon isi nama anda');
      return;
    }
    
    // Validasi nomor telepon
    if (_phoneController.text.trim().isEmpty) {
      AppSnackBar.show(context, message: 'Mohon isi nomor telepon anda');
      return;
    }
    
    if (_selectedTable == null) {
      AppSnackBar.show(context, message: 'Pilih nomor meja terlebih dahulu');
      return;
    }
    if (CartController.instance.items.isEmpty) {
      AppSnackBar.show(context, message: 'Keranjang kosong');
      return;
    }
    setState(() {
      _loading = true;
    });
    final result = await _controller.createOrder(
      tableCode: _selectedTable!.code,
      customerName: _nameController.text.trim(),
      customerPhone: _phoneController.text.trim(),
      paymentMethod: _selectedPayment,
    );
    setState(() {
      _loading = false;
    });
    if (!mounted) return;
    if (result.error != null) {
      AppSnackBar.show(context, message: result.error!);
      return;
    }
    if (result.orderCode == null || result.orderCode!.isEmpty) {
      AppSnackBar.show(context, message: 'Gagal membuat pesanan: Order Code kosong');
      return;
    }
    CartController.instance.clear();
    // Save order code for tracking
    await ActiveOrderStorage.instance.setOrderCode(result.orderCode!);
    Navigator.of(context).pushReplacementNamed(
      RouteName.customerOrderStatus,
      arguments: result.orderCode,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = CartController.instance;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background gradient
          _buildBackgroundGradient(),
          
          // Main content
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 140),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Customer Info
                        _buildCustomerSection(),
                        const SizedBox(height: 20),
                        
                        // Order Summary
                        _buildOrderSummary(cart),
                        const SizedBox(height: 20),
                        
                        // Table Selection
                        _buildTableSection(),
                        const SizedBox(height: 20),
                        
                        // Payment Method
                        _buildPaymentSection(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Bottom Bar
          _buildBottomBar(cart),
        ],
      ),
    );
  }

  Widget _buildBackgroundGradient() {
    return Positioned(
      top: -80,
      right: -60,
      child: Container(
        width: 250,
        height: 250,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              AppColors.primaryLight.withValues(alpha: 0.4),
              AppColors.primaryLight.withValues(alpha: 0.0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppTheme.shadowSm,
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Checkout',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.successLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.security_rounded,
              color: AppColors.success,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Data Pelanggan',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Name field
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Nama Lengkap *',
              labelStyle: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
              hintText: 'Masukkan nama anda',
              hintStyle: const TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.textMuted, width: 0.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.textMuted, width: 0.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
            style: const TextStyle(fontSize: 13),
          ),
          
          const SizedBox(height: 12),
          
          // Phone field
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Nomor Telepon *',
              labelStyle: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
              hintText: 'Masukkan nomor telepon anda',
              hintStyle: const TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.textMuted, width: 0.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.textMuted, width: 0.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(CartController cart) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Ringkasan Pesanan',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${cart.totalItems} item',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Items - Full detailed list with proper alignment
          ...cart.items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Menu name with price and quantity (properly aligned)
                Row(
                  children: [
                    // Menu name on left
                    Expanded(
                      child: Text(
                        item.menu.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    // Quantity column
                    SizedBox(
                      width: 35,
                      child: Text(
                        'x${item.quantity}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Price column
                    SizedBox(
                      width: 85,
                      child: Text(
                        CurrencyFormatter.rupiah(item.menu.price * item.quantity),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
                
                // Toppings if any (indented and aligned)
                if (item.toppings.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, left: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: item.toppings.map((topping) => Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              flex: 1,
                              child: Text(
                                '- ${topping.name}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 80,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'x${topping.quantity}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textMuted,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    CurrencyFormatter.rupiah(topping.price * topping.quantity),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )).toList(),
                    ),
                  ),
                
                // Notes if any
                if (item.notes != null && item.notes!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.textMuted, width: 0.5),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.notes_rounded, size: 14, color: AppColors.textMuted),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              item.notes!,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                // Total for this menu item
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        CurrencyFormatter.rupiah(item.subtotal),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )),
          
          const Divider(height: 24),
          
          // Subtotal
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Subtotal',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                CurrencyFormatter.rupiah(cart.totalAmount),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Biaya Layanan',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                'Gratis',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTableSection() {
    final lockedCode = CartController.instance.tableNumber;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warningLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.table_restaurant_rounded,
                  color: AppColors.warning,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pilih Meja',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      lockedCode != null ? 'Otomatis terisi dari QR' : 'Wajib dipilih',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: lockedCode != null ? AppColors.success : AppColors.danger,
                      ),
                    ),
                  ],
                ),
              ),
              if (lockedCode != null)
                const Icon(Icons.lock_rounded, color: AppColors.textSecondary, size: 18),
            ],
          ),
          const SizedBox(height: 16),
          
          if (_tablesLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (_tables.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.dangerLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: AppColors.danger),
                  const SizedBox(width: 12),
                  Text(
                    'Tidak ada meja tersedia',
                    style: TextStyle(color: AppColors.danger),
                  ),
                ],
              ),
            )
          else if (lockedCode != null)
            // Tampilan Terkunci (Locked View)
             Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.successLight.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.success, width: 1.5),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      'Meja $lockedCode',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Meja Anda sudah terpilih',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
             )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _tables.map((table) {
                final isSelected = _selectedTable?.id == table.id;
                final isOccupied = table.isOccupied ?? false;
                
                return TapScaleContainer(
                  onTap: isOccupied ? null : () {
                    setState(() {
                      _selectedTable = table;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: isOccupied 
                          ? AppColors.background
                          : (isSelected ? AppColors.primary : Colors.white),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isOccupied 
                            ? AppColors.borderLight
                            : (isSelected ? AppColors.primary : AppColors.border),
                        width: 1.5,
                      ),
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ] : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.table_restaurant_rounded,
                          size: 18,
                          color: isOccupied 
                              ? AppColors.textMuted
                              : (isSelected ? Colors.white : AppColors.textSecondary),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          table.name ?? table.code,
                          style: TextStyle(
                            color: isOccupied 
                                ? AppColors.textMuted
                                : (isSelected ? Colors.white : AppColors.textPrimary),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (isOccupied) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.danger.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Terisi',
                              style: TextStyle(
                                color: AppColors.danger,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.infoLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.payment_rounded,
                  color: AppColors.info,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Metode Pembayaran',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // QRIS Option
          _PaymentOption(
            icon: Icons.qr_code_2_rounded,
            label: 'QRIS',
            description: 'Scan QR untuk bayar',
            isSelected: _selectedPayment == 'qris',
            color: AppColors.primary,
            onTap: () => setState(() => _selectedPayment = 'qris'),
          ),
          const SizedBox(height: 12),
          
          // Cash Option
          _PaymentOption(
            icon: Icons.payments_rounded,
            label: 'Tunai',
            description: 'Bayar di kasir',
            isSelected: _selectedPayment == 'cash',
            color: AppColors.success,
            onTap: () => setState(() => _selectedPayment = 'cash'),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(CartController cart) {
    // Check if form is complete
    final isFormComplete = _nameController.text.trim().isNotEmpty &&
        _phoneController.text.trim().isNotEmpty &&
        _selectedTable != null;
    
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Pembayaran',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.rupiah(cart.totalAmount),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              GradientButton(
                label: _loading ? 'Memproses...' : 'Buat Pesanan',
                icon: Icons.check_circle_rounded,
                isLoading: _loading,
                onPressed: isFormComplete ? _submit : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _PaymentOption({
    required this.icon,
    required this.label,
    required this.description,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TapScaleContainer(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : AppColors.borderLight,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? color : AppColors.textMuted.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : AppColors.textSecondary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isSelected ? color : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? color : AppColors.border,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
