import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/glass_components.dart';
import '../../../core/widgets/top_notification.dart';
import '../../../shared/models/menu_model.dart';
import '../../../shared/providers/tenant_provider.dart';
import '../menu/menu_service.dart';
import '../cart/cart_controller.dart';

import '../../../shared/models/tenant_model.dart';
import '../../../shared/services/tenant_service.dart';
import '../../../shared/models/topping_model.dart';

class MenuDetailPage extends StatefulWidget {
  final MenuModel menu;

  const MenuDetailPage({super.key, required this.menu});

  @override
  State<MenuDetailPage> createState() => _MenuDetailPageState();
}

class _MenuDetailPageState extends State<MenuDetailPage> {
  int _qty = 1;
  final MenuService _menuService = MenuService(ApiClient());
  List<ToppingModel> _allToppings = [];
  final Map<int, int> _selectedToppings = {}; // Map<ToppingID, Quantity>
  String? _selectedNote;
  bool _loadingToppings = true;
  String? _toppingsError;
  TenantModel _promoTenant = TenantService.current;

  @override
  void initState() {
    super.initState();
    _loadPromoSettings();
    if (widget.menu.toppingIds.isNotEmpty) {
      _loadToppings();
    } else {
      _loadingToppings = false;
    }
  }

  Future<void> _loadPromoSettings() async {
    try {
      final tenant = await TenantService.fetchTenantInfo(forceRefresh: true);
      if (mounted) setState(() => _promoTenant = tenant);
    } catch (_) {}
  }

  Future<void> _loadToppings() async {
    try {
      final data = await _menuService.fetchToppings(widget.menu.id);
      if (!mounted) return;
      setState(() {
        _allToppings = data;
        _loadingToppings = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingToppings = false;
        _toppingsError = e.toString();
      });
    }
  }

  int get _toppingTotal {
    int total = 0;
    _selectedToppings.forEach((id, qty) {
      final topping = _allToppings.firstWhere((t) => t.id == id);
      total += topping.price * qty;
    });
    return total;
  }

  int get _itemTotal => (widget.menu.price + _toppingTotal) * _qty;

  void _incQty() {
    setState(() {
      _qty++;
    });
  }

  void _decQty() {
    if (_qty == 1) return;
    setState(() {
      _qty--;
    });
  }

  void _addToCart() {
    final selectedToppings = _allToppings
        .where((t) => _selectedToppings.containsKey(t.id))
        .toList();

    CartController.instance.addMenu(
      widget.menu,
      quantity: _qty,
      notes: _selectedNote,
      toppings: selectedToppings
          .map(
            (t) => {
              'id': t.id,
              'name': t.name,
              'price': t.price,
              'quantity': _selectedToppings[t.id] ?? 1,
            },
          )
          .toList(),
    );
    Navigator.of(context).pop();
    TopNotification.show(
      message: 'Berhasil ditambahkan ke keranjang',
      backgroundColor: AppColors.success,
      icon: Icons.check_circle_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    final menu = widget.menu;
    final tenantFromContext = TenantProvider.of(context);
    final activeTenant = (_promoTenant.id != 0 && _promoTenant.name.isNotEmpty)
        ? _promoTenant
        : tenantFromContext;

    final hasPromo = activeTenant.promoDiscountPercent > 0 &&
        (activeTenant.promoScope != 'selected' ||
            activeTenant.promoMenuIds.contains(menu.id));
    final promoForQris = hasPromo && activeTenant.promoAppliesToPayment('qris');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Main Content
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Hero Image
              SliverToBoxAdapter(
                child: _buildHeroImage(
                  menu,
                  promoBadge: promoForQris
                      ? (activeTenant.promoBadgeText.isNotEmpty
                          ? activeTenant.promoBadgeText
                          : 'Hemat ${activeTenant.promoDiscountPercent}%')
                      : null,
                ),
              ),

              // Content
              SliverToBoxAdapter(child: _buildContent(menu, activeTenant)),

              // Bottom spacing for button
              const SliverToBoxAdapter(child: SizedBox(height: 150)),
            ],
          ),

          // Back Button
          _buildBackButton(),

          // Bottom Add to Cart
          _buildBottomBar(activeTenant),
        ],
      ),
    );
  }

  Widget _buildHeroImage(MenuModel menu, {String? promoBadge}) {
    return Stack(
      children: [
        // Image
        Container(
          height: 320,
          width: double.infinity,
          decoration: BoxDecoration(color: AppColors.background),
          child: menu.imageUrl != null && menu.imageUrl!.isNotEmpty
              ? Image.network(
                  menu.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, st) => _buildImagePlaceholder(),
                )
              : _buildImagePlaceholder(),
        ),

        // Bottom gradient overlay
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, AppColors.background],
              ),
            ),
          ),
        ),

        // Floating promo badge
        if (promoBadge != null)
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE11D48), Color(0xFFF43F5E)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE11D48).withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bolt_rounded, size: 16, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    promoBadge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: AppColors.primaryLight.withValues(alpha: 0.3),
      child: Center(
        child: Icon(
          Icons.fastfood_rounded,
          size: 80,
          color: AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 16,
      child: TapScaleContainer(
        onTap: () => Navigator.pop(context),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: AppTheme.shadowMd,
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildContent(MenuModel menu, TenantModel tenant) {
    final prefix = tenant.menuCodePrefix;
    final codeText = menu.formattedCode(prefix);

    final hasPromo = tenant.promoDiscountPercent > 0 &&
        (tenant.promoScope != 'selected' ||
            tenant.promoMenuIds.contains(menu.id));
    final promoForQris = hasPromo && tenant.promoAppliesToPayment('qris');

    final discountPerUnit = hasPromo
        ? ((menu.price * tenant.promoDiscountPercent + 50) ~/ 100)
        : 0;
    final qrisPricePerUnit = (menu.price - discountPerUnit).clamp(0, menu.price);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(color: AppColors.background),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category badge & Kode Menu Flyer
          Row(
            children: [
              if (codeText.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    codeText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  menu.categoryName,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Name and Price
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  menu.displayName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              if (promoForQris) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyFormatter.rupiah(menu.price),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                        decoration: TextDecoration.lineThrough,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      CurrencyFormatter.rupiah(qrisPricePerUnit),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2.5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.successLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Diskon ${tenant.promoDiscountPercent}% QRIS',
                        style: const TextStyle(
                          color: AppColors.success,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Text(
                  CurrencyFormatter.rupiah(menu.price),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ],
          ),

          // Description
          if (menu.description != null && menu.description!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              menu.description!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],

          // Payment Discount Promo Card
          if (promoForQris) ...[
            const SizedBox(height: 16),
            _buildPaymentPromoCard(
              menu: menu,
              tenant: tenant,
              discountPerUnit: discountPerUnit,
              qrisPricePerUnit: qrisPricePerUnit,
            ),
          ],

          const SizedBox(height: 24),

          if (widget.menu.toppingIds.isNotEmpty &&
              (_loadingToppings ||
                  _allToppings.isNotEmpty ||
                  _toppingsError != null)) ...[
            _buildToppingSection(),
            const SizedBox(height: 24),
          ],
          if (menu.noteOptions.isNotEmpty) _buildNotesSection(),
        ],
      ),
    );
  }

  Widget _buildPaymentPromoCard({
    required MenuModel menu,
    required TenantModel tenant,
    required int discountPerUnit,
    required int qrisPricePerUnit,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.local_offer_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tenant.promoBadgeText.isNotEmpty
                      ? tenant.promoBadgeText
                      : 'Promo Spesial Pembayaran',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Hemat ${tenant.promoDiscountPercent}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Comparison 1: Bayar via QRIS (Rekomendasi)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner_rounded,
                    size: 20,
                    color: Color(0xFF15803D),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Bayar via QRIS',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF166534),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF166534),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'HEMAT',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Hemat ${CurrencyFormatter.rupiah(discountPerUnit)} (Diskon ${tenant.promoDiscountPercent}%)',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF15803D),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyFormatter.rupiah(menu.price),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF9CA3AF),
                        decoration: TextDecoration.lineThrough,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.rupiah(qrisPricePerUnit),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF166534),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Comparison 2: Bayar di Kasir (Tunai)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.storefront_rounded,
                    size: 20,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bayar di Kasir (Tunai)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF374151),
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Harga normal tanpa diskon',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  CurrencyFormatter.rupiah(menu.price),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF374151),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Tip footnote
          Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 13,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Potongan diskon otomatis dihitung saat memilih pembayaran QRIS di checkout.',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToppingSection() {
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
                  Icons.add_circle_outline_rounded,
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
                      'Tambahan Topping',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Opsional',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_loadingToppings)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (_toppingsError != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Topping gagal dimuat. Periksa koneksi lalu coba lagi.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppColors.danger),
                    ),
                  ),
                ],
              ),
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _allToppings.map((topping) {
                final qty = _selectedToppings[topping.id] ?? 0;
                final isSelected = qty > 0;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.05)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.borderLight,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        topping.name,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '+${CurrencyFormatter.rupiah(topping.price)}',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Quantity Controls
                      if (!isSelected)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedToppings[topping.id] = 1;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: const Text(
                              'Tambah',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )
                      else
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (qty > 1) {
                                    _selectedToppings[topping.id] = qty - 1;
                                  } else {
                                    _selectedToppings.remove(topping.id);
                                  }
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: AppColors.border),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.remove,
                                  size: 14,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Text(
                                '$qty',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedToppings[topping.id] = qty + 1;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.add,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
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
                  Icons.edit_note_rounded,
                  color: AppColors.info,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pilih Opsi Menu',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Opsional - khusus ${widget.menu.displayName}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...widget.menu.noteOptions.map(
                (option) => ChoiceChip(
                  label: Text(option),
                  selected: _selectedNote == option,
                  onSelected: (selected) =>
                      setState(() => _selectedNote = selected ? option : null),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(TenantModel tenant) {
    final hasPromo = tenant.promoDiscountPercent > 0 &&
        (tenant.promoScope != 'selected' ||
            tenant.promoMenuIds.contains(widget.menu.id));
    final promoForQris = hasPromo && tenant.promoAppliesToPayment('qris');

    final discountPerUnit = hasPromo
        ? ((widget.menu.price * tenant.promoDiscountPercent + 50) ~/ 100)
        : 0;
    final totalDiscount = discountPerUnit * _qty;
    final qrisTotal = (_itemTotal - totalDiscount).clamp(0, _itemTotal);

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
              if (promoForQris) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.qr_code_scanner_rounded,
                        size: 16,
                        color: Color(0xFF15803D),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF166534),
                            ),
                            children: [
                              const TextSpan(text: 'Bayar via QRIS: '),
                              TextSpan(
                                text: CurrencyFormatter.rupiah(qrisTotal),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              TextSpan(
                                text:
                                    ' (Hemat ${CurrencyFormatter.rupiah(totalDiscount)})',
                                style: const TextStyle(
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
              ],
              Row(
                children: [
                  // Quantity Selector
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        _QuantityButton(
                          icon: Icons.remove_rounded,
                          onTap: _decQty,
                          enabled: _qty > 1,
                        ),
                        Container(
                          constraints: const BoxConstraints(minWidth: 40),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            '$_qty',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        _QuantityButton(
                          icon: Icons.add_rounded,
                          onTap: _incQty,
                          isPrimary: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Add to Cart Button
                  Expanded(
                    child: TapScaleContainer(
                      onTap: _addToCart,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.add_shopping_cart_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '+ Keranjang • ${CurrencyFormatter.rupiah(_itemTotal)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isPrimary;
  final bool enabled;

  const _QuantityButton({
    required this.icon,
    required this.onTap,
    this.isPrimary = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return TapScaleContainer(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isPrimary
              ? Colors.white
              : (enabled ? AppColors.textPrimary : AppColors.textMuted),
        ),
      ),
    );
  }
}
