import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/maps_helper.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/glass_components.dart';
import '../../../router/route_name.dart';
import '../../../shared/models/table_model.dart';
import '../../../shared/models/tenant_model.dart';
import '../../../shared/services/tenant_service.dart';
import '../../../shared/utils/promo_discount_calculator.dart';
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
  TenantModel _promoTenant = TenantService.current;
  bool _loading = false;
  String _selectedPayment = 'qris';
  String _selectedOrderType = 'pickup';
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _mapsUrlController;
  bool _fetchingLocation = false;

  bool get _isQrOrder {
    final tableCode = CartController.instance.tableNumber;
    return tableCode != null && tableCode.isNotEmpty;
  }

  bool _isValidWhatsAppNumber(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleaned.isEmpty) return false;
    // Format nomor HP Indonesia aktif WhatsApp: 08..., 628..., atau +628...
    return RegExp(r'^(?:\+62|62|0)8[1-9][0-9]{6,10}$').hasMatch(cleaned);
  }

  @override
  void initState() {
    super.initState();
    _loadPromoSettings();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
    _mapsUrlController = TextEditingController();

    // Listen to changes to update button state
    _nameController.addListener(() {
      setState(() {});
    });
    _phoneController.addListener(() {
      setState(() {});
    });
    _addressController.addListener(() {
      setState(() {});
    });
    _mapsUrlController.addListener(() {
      setState(() {});
    });

    if (_isQrOrder) {
      _fetchTables();
    } else {
      _tablesLoading = false;
    }
  }

  Future<void> _loadPromoSettings() async {
    final tenant = await TenantService.fetchTenantInfo(forceRefresh: true);
    if (mounted) setState(() => _promoTenant = tenant);
  }

  int _discountFor(CartController cart) {
    if (!_promoTenant.promoAppliesToPayment(_selectedPayment)) return 0;

    return PromoDiscountCalculator.calculate(
      items: cart.items,
      percent: _promoTenant.promoDiscountPercent,
      appliesToAllMenus: _promoTenant.promoScope != 'selected',
      menuIds: _promoTenant.promoMenuIds.toSet(),
    );
  }

  int _totalAfterDiscount(CartController cart) =>
      (cart.totalAmount - _discountFor(cart))
          .clamp(0, cart.totalAmount)
          .toInt();

  String get _selectedPaymentLabel =>
      _selectedPayment == 'cash' ? 'Tunai' : 'QRIS';

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _mapsUrlController.dispose();
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
      if (!mounted) return;
      setState(() {
        _tables = tables;
        _tablesLoading = false;
      });
      _checkLockedTable();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _tablesLoading = false;
      });
      AppSnackBar.show(context, message: 'Gagal mengambil data meja');
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

    // Validasi nomor WhatsApp
    if (!_isValidWhatsAppNumber(_phoneController.text.trim())) {
      AppSnackBar.show(
        context,
        message:
            'Nomor WhatsApp tidak valid. Pastikan nomor diawali 08/628 (contoh: 081234567890)',
      );
      return;
    }

    if (_isQrOrder && _selectedTable == null) {
      AppSnackBar.show(context, message: 'Pilih nomor meja terlebih dahulu');
      return;
    }
    if (!_isQrOrder &&
        _selectedOrderType == 'delivery' &&
        _addressController.text.trim().isEmpty) {
      AppSnackBar.show(context, message: 'Mohon isi alamat pengantaran');
      return;
    }
    if (CartController.instance.items.isEmpty) {
      AppSnackBar.show(context, message: 'Keranjang kosong');
      return;
    }
    setState(() {
      _loading = true;
    });

    String? fullDeliveryAddress;
    if (!_isQrOrder && _selectedOrderType == 'delivery') {
      fullDeliveryAddress = _addressController.text.trim();
      if (_mapsUrlController.text.trim().isNotEmpty) {
        fullDeliveryAddress +=
            '\n📍 Pin Google Maps: ${_mapsUrlController.text.trim()}';
      }
    }

    final result = await _controller.createOrder(
      tableCode: _isQrOrder ? _selectedTable!.code : null,
      orderType: _isQrOrder ? 'dine_in' : _selectedOrderType,
      deliveryAddress: fullDeliveryAddress,
      customerName: _nameController.text.trim(),
      customerPhone: _phoneController.text.trim(),
      paymentMethod: _selectedPayment,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
    });
    if (result.error != null) {
      AppSnackBar.show(context, message: result.error!);
      return;
    }
    if (result.orderCode == null || result.orderCode!.isEmpty) {
      AppSnackBar.show(
        context,
        message: 'Gagal membuat pesanan: Order Code kosong',
      );
      return;
    }
    CartController.instance.clear();
    CartController.instance.setTableNumber(null);
    // Save order code for tracking
    await ActiveOrderStorage.instance.setOrderCode(result.orderCode!);
    if (!mounted) return;
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

                        if (_isQrOrder) ...[
                          _buildTableSection(),
                        ] else ...[
                          _buildOrderTypeSection(),
                        ],
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
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
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
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
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
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.textMuted,
                  width: 0.5,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.textMuted,
                  width: 0.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
            style: const TextStyle(fontSize: 13),
          ),

          const SizedBox(height: 12),

          // Phone field
          Builder(
            builder: (context) {
              final phoneText = _phoneController.text.trim();
              final hasInput = phoneText.isNotEmpty;
              final isValidPhone = _isValidWhatsAppNumber(phoneText);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Nomor WhatsApp *',
                      labelStyle: TextStyle(
                        fontSize: 13,
                        color: hasInput
                            ? (isValidPhone
                                ? AppColors.success
                                : AppColors.danger)
                            : AppColors.textSecondary,
                      ),
                      hintText: 'Contoh: 081234567890',
                      hintStyle: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                      prefixIcon: const Icon(
                        Icons.phone_android_rounded,
                        size: 20,
                        color: AppColors.primary,
                      ),
                      suffixIcon: hasInput
                          ? (isValidPhone
                              ? const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.success,
                                  size: 20,
                                )
                              : const Icon(
                                  Icons.error_outline_rounded,
                                  color: AppColors.danger,
                                  size: 20,
                                ))
                          : null,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.textMuted,
                          width: 0.5,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: hasInput
                              ? (isValidPhone
                                  ? AppColors.success
                                  : AppColors.danger)
                              : AppColors.textMuted,
                          width: hasInput ? 1.0 : 0.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: hasInput
                              ? (isValidPhone
                                  ? AppColors.success
                                  : AppColors.danger)
                              : AppColors.primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                  if (hasInput && !isValidPhone) ...[
                    const SizedBox(height: 6),
                    const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 13,
                            color: AppColors.danger,
                          ),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Nomor WhatsApp belum valid (diawali 08/628, min 10 digit)',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.danger,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else if (hasInput && isValidPhone) ...[
                    const SizedBox(height: 6),
                    const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            size: 13,
                            color: AppColors.success,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Nomor WhatsApp valid untuk konfirmasi pesanan',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.success,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              );
            },
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
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
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
          ...cart.items.map(
            (item) => Padding(
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
                          CurrencyFormatter.rupiah(
                            item.menu.price * item.quantity,
                          ),
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
                        children: item.toppings
                            .map(
                              (topping) => Padding(
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
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
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
                                            CurrencyFormatter.rupiah(
                                              topping.price * topping.quantity,
                                            ),
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
                              ),
                            )
                            .toList(),
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
                          border: Border.all(
                            color: AppColors.textMuted,
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.notes_rounded,
                              size: 14,
                              color: AppColors.textMuted,
                            ),
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
            ),
          ),

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
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          if (_discountFor(cart) > 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Diskon promo $_selectedPaymentLabel (${_promoTenant.promoDiscountPercent}%)',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.success),
                ),
                Text(
                  '- ${CurrencyFormatter.rupiah(_discountFor(cart))}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
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
          if (!_isQrOrder && _selectedOrderType == 'delivery') ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Biaya Pengantaran',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  'Belum termasuk (bayar ke kurir)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFD97706),
                  ),
                ),
              ],
            ),
          ],
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
                      lockedCode != null
                          ? 'Otomatis terisi dari QR'
                          : 'Wajib dipilih',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: lockedCode != null
                            ? AppColors.success
                            : AppColors.danger,
                      ),
                    ),
                  ],
                ),
              ),
              if (lockedCode != null)
                const Icon(
                  Icons.lock_rounded,
                  color: AppColors.textSecondary,
                  size: 18,
                ),
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
                  const Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.danger,
                  ),
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
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.success,
                    size: 48,
                  ),
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
                final isOccupied = table.isOccupied;

                return TapScaleContainer(
                  onTap: isOccupied
                      ? null
                      : () {
                          setState(() {
                            _selectedTable = table;
                          });
                        },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: isOccupied
                          ? AppColors.background
                          : (isSelected ? AppColors.primary : Colors.white),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isOccupied
                            ? AppColors.borderLight
                            : (isSelected
                                  ? AppColors.primary
                                  : AppColors.border),
                        width: 1.5,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.table_restaurant_rounded,
                          size: 18,
                          color: isOccupied
                              ? AppColors.textMuted
                              : (isSelected
                                    ? Colors.white
                                    : AppColors.textSecondary),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          table.name ?? table.code,
                          style: TextStyle(
                            color: isOccupied
                                ? AppColors.textMuted
                                : (isSelected
                                      ? Colors.white
                                      : AppColors.textPrimary),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (isOccupied) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
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

  Widget _buildOrderTypeSection() {
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
          Text(
            'Cara menerima pesanan',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          _PaymentOption(
            icon: Icons.storefront_rounded,
            label: 'Ambil sendiri',
            description: 'Pesanan diambil di kantin',
            isSelected: _selectedOrderType == 'pickup',
            color: AppColors.primary,
            onTap: () => setState(() => _selectedOrderType = 'pickup'),
          ),
          const SizedBox(height: 12),
          _PaymentOption(
            icon: Icons.delivery_dining_rounded,
            label: 'Pengantaran',
            description: 'Pesanan diantar ke alamat Anda',
            isSelected: _selectedOrderType == 'delivery',
            color: AppColors.success,
            onTap: () => setState(() => _selectedOrderType = 'delivery'),
          ),
          if (_selectedOrderType == 'delivery') ...[
            const SizedBox(height: 16),
            // Keterangan Pembayaran Belum Termasuk Biaya Pengantaran
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFFD97706),
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Catatan Biaya Pengantaran',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFB45309),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Pembayaran pesanan belum termasuk biaya pengantaran. Ongkos kirim disepakati dan dibayarkan langsung kepada kurir/pengantar.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF78350F),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _addressController,
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Alamat Pengantaran *',
                hintText: 'Masukkan alamat lengkap (jalan, nomor, patokan)',
                alignLabelWithHint: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 14),
            // Integrasi Google Maps
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.map_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Pin Lokasi Google Maps (Opsional)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Buka Google Maps untuk membagikan link lokasi atau ambil titik GPS otomatis.',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            openMaps();
                          },
                          icon: const Icon(Icons.open_in_new_rounded, size: 16),
                          label: const Text(
                            'Buka Google Maps',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(
                              color: AppColors.primary,
                              width: 1,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _fetchingLocation
                              ? null
                              : () async {
                                  setState(() => _fetchingLocation = true);
                                  try {
                                    final gpsUrl = await getGpsMapsUrl();
                                    if (!mounted) return;
                                    if (gpsUrl != null && gpsUrl.isNotEmpty) {
                                      setState(() {
                                        _mapsUrlController.text = gpsUrl;
                                      });
                                      AppSnackBar.show(
                                        context,
                                        message: 'Lokasi GPS berhasil diambil!',
                                      );
                                    } else {
                                      AppSnackBar.show(
                                        context,
                                        message:
                                            'Tidak dapat mendeteksi lokasi GPS. Pastikan izin GPS aktif atau salin link dari Google Maps.',
                                      );
                                    }
                                  } catch (e) {
                                    if (!mounted) return;
                                    AppSnackBar.show(
                                      context,
                                      message: 'Gagal mengambil GPS: $e',
                                    );
                                  } finally {
                                    if (mounted) {
                                      setState(
                                        () => _fetchingLocation = false,
                                      );
                                    }
                                  }
                                },
                          icon: _fetchingLocation
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.my_location_rounded, size: 16),
                          label: Text(
                            _fetchingLocation ? 'Mencari...' : 'Pin Lokasi GPS',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 10,
                            ),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _mapsUrlController,
                    decoration: InputDecoration(
                      labelText: 'Link Google Maps',
                      labelStyle: const TextStyle(fontSize: 12),
                      hintText: 'Tempel link peta (maps.app.goo.gl/...)',
                      hintStyle: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                      prefixIcon: const Icon(
                        Icons.link_rounded,
                        size: 18,
                        color: AppColors.textMuted,
                      ),
                      suffixIcon: _mapsUrlController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 16),
                              onPressed: () => _mapsUrlController.clear(),
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
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
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // QRIS Option
          _PaymentOption(
            icon: Icons.qr_code_2_rounded,
            label: 'QRIS',
            description:
                _promoTenant.promoDiscountPercent > 0 &&
                    _promoTenant.promoAppliesToPayment('qris')
                ? 'Scan QR untuk bayar dan dapat diskon'
                : 'Scan QR untuk bayar',
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
    final hasName = _nameController.text.trim().isNotEmpty;
    final phoneText = _phoneController.text.trim();
    final hasPhone = phoneText.isNotEmpty;
    final isValidPhone = _isValidWhatsAppNumber(phoneText);
    final hasAddress = _addressController.text.trim().isNotEmpty;

    // Check if form is complete
    final isFormComplete =
        hasName &&
        hasPhone &&
        isValidPhone &&
        (_isQrOrder
            ? _selectedTable != null
            : _selectedOrderType != 'delivery' || hasAddress);

    String reminderText = '';
    if (!hasName || !hasPhone) {
      reminderText = 'Isi nama dan no hp terlebih dahulu agar bisa memesan';
    } else if (!isValidPhone) {
      reminderText =
          'Nomor WhatsApp belum valid (diawali 08/628, min 10 digit)';
    } else if (_isQrOrder && _selectedTable == null) {
      reminderText = 'Pilih nomor meja terlebih dahulu agar bisa memesan';
    } else if (_selectedOrderType == 'delivery' && !hasAddress) {
      reminderText =
          'Isi alamat pengantaran terlebih dahulu agar bisa memesan';
    } else if (!isFormComplete) {
      reminderText = 'Lengkapi data terlebih dahulu agar bisa memesan';
    }

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
                    CurrencyFormatter.rupiah(_totalAfterDiscount(cart)),
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
              if (!isFormComplete && reminderText.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  reminderText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
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
          color: isSelected
              ? color.withValues(alpha: 0.1)
              : AppColors.background,
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
                color: isSelected
                    ? color
                    : AppColors.textMuted.withValues(alpha: 0.1),
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
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 16,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
