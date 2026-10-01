import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/glass_components.dart';
import '../../../router/route_name.dart';
import '../../../shared/models/menu_model.dart';
import '../../../shared/providers/tenant_provider.dart';
import '../../../shared/storage/active_order_storage.dart';
import '../cart/cart_controller.dart';
import 'menu_controller.dart' as local;

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> with TickerProviderStateMixin {
  late final local.MenuController _controller;
  late Future<List<MenuModel>> _future;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  String _selectedCategory = 'Semua';
  final List<String> _categories = ['Semua'];
  
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Color get _brandColor => TenantProvider.of(context).primaryColorValue;
  LinearGradient get _brandGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color.lerp(_brandColor, Colors.white, 0.2) ?? _brandColor,
      _brandColor,
    ],
  );

  @override
  void initState() {
    super.initState();
    _controller = local.MenuController();
    _future = _controller.fetchMenus();
    
    // Animation setup
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
    
    // Set status bar
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _reload({bool animate = true}) {
    setState(() {
      _future = _controller.fetchMenus();
    });
    if (animate) {
      _fadeController.reset();
      _fadeController.forward();
    }
  }

  void _extractCategories(List<MenuModel> items) {
    final cats = items.map((e) => e.categoryName).toSet().toList();
    if (_categories.length == 1) {
      // Schedule setState after build completes to avoid "setState during build" error
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _categories.length == 1) {
          setState(() {
            _categories.addAll(cats);
          });
        }
      });
    }
  }

  List<MenuModel> _filterItems(List<MenuModel> items) {
    var filtered = items;
    
    // Filter by Category
    if (_selectedCategory != 'Semua') {
      filtered = filtered.where((e) => e.categoryName == _selectedCategory).toList();
    }
    
    // Filter by Search Query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((e) => 
        e.name.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Gradient Background Effect
          _buildBackgroundGradient(),
          
          // Main Content
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: FutureBuilder<List<MenuModel>>(
                    future: _future,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return _buildLoadingState();
                      }
                      if (snapshot.hasError) {
                        return ErrorView(
                          message: snapshot.error.toString(),
                          onRetry: _reload,
                        );
                      }
                      final items = snapshot.data ?? const [];
                      if (items.isEmpty) {
                        return const EmptyView(message: 'Menu tidak tersedia');
                      }
                      
                      _extractCategories(items);
                      final filteredItems = _filterItems(items);

                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: RefreshIndicator(
                          onRefresh: () async {
                            _reload(animate: false);
                            await _future;
                          },
                          color: _brandColor,
                          backgroundColor: Colors.white,
                          child: CustomScrollView(
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            slivers: [
                            // Category Chips
                            SliverToBoxAdapter(
                              child: _buildCategoryChips(),
                            ),
                            
                            // Promo Banner (optional showcase)
                            SliverToBoxAdapter(
                              child: _buildPromoSection(),
                            ),
                            
                            // Section Title
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _selectedCategory == 'Semua' 
                                          ? 'Menu Populer' 
                                          : _selectedCategory,
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      '${filteredItems.length} item',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            
                            // Menu Grid
                            // Menu Grid or Empty State
                            filteredItems.isEmpty 
                              ? SliverToBoxAdapter(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(20),
                                          decoration: BoxDecoration(
                                            color: AppColors.background,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.search_off_rounded,
                                            size: 48,
                                            color: AppColors.textSecondary.withValues(alpha: 0.5),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Yah, menu tidak ditemukan 😔',
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Coba cari dengan kata kunci lain',
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : SliverPadding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  sliver: SliverGrid(
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 16,
                                      mainAxisSpacing: 16,
                                      childAspectRatio: 0.72,
                                    ),
                                    delegate: SliverChildBuilderDelegate(
                                      (context, index) => _MenuCard(
                                        menu: filteredItems[index],
                                        index: index,
                                      ),
                                      childCount: filteredItems.length,
                                    ),
                                  ),
                                ),
                            
                            // Bottom Spacing
                            const SliverToBoxAdapter(
                              child: SizedBox(height: 100),
                            ),
                          ],
                        ),
                      ),
                    );
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Floating Cart Button
          _buildFloatingCartButton(),
          
          // Floating Order Status Button (when has active order)
          _buildFloatingOrderButton(),
        ],
      ),
    );
  }

  Widget _buildBackgroundGradient() {
    return Positioned(
      top: -100,
      right: -50,
      child: Container(
        width: 300,
        height: 300,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              _brandColor.withValues(alpha: 0.15),
              _brandColor.withValues(alpha: 0.0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row
          Row(
            children: [
              // Location & Store Info
              Expanded(
                child: Builder(
                  builder: (context) {
                    final tenant = TenantProvider.of(context);
                    final brandColor = tenant.primaryColorValue;
                    final hasLogo = tenant.logoUrl != null && tenant.logoUrl!.isNotEmpty;

                    return Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: brandColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: brandColor.withValues(alpha: 0.25),
                              width: 1,
                            ),
                          ),
                          child: hasLogo
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(11),
                                  child: Image.network(
                                    tenant.logoUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Icon(
                                      Icons.storefront_rounded,
                                      color: brandColor,
                                      size: 22,
                                    ),
                                  ),
                                )
                              : Icon(
                                  Icons.storefront_rounded,
                                  color: brandColor,
                                  size: 22,
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tenant.name,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: AppColors.success,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Buka',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (tenant.address != null && tenant.address!.isNotEmpty) ...[
                                    const SizedBox(width: 6),
                                    const Text('•', style: TextStyle(color: Colors.grey, fontSize: 11)),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        tenant.address!,
                                        style: const TextStyle(color: Colors.grey, fontSize: 11),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              
              // Admin Button
              IconContainer(
                icon: Icons.admin_panel_settings_outlined,
                backgroundColor: Colors.white,
                iconColor: AppColors.textSecondary,
                size: 42,
                iconSize: 20,
                onTap: () => Navigator.pushNamed(context, RouteName.adminLogin),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Search Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppTheme.shadowSm,
            ),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search, // Tombol keyboard jadi 'Search'
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              onSubmitted: (value) {
                // Tutup keyboard saat enter
                FocusScope.of(context).unfocus();
              },
              decoration: InputDecoration(
                hintText: 'Mau pesan apa hari ini?',
                hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMuted,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: AppColors.textMuted,
                  size: 22,
                ),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Tombol Clear (X) - Hanya muncul jika ada text
                    if (_searchQuery.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textSecondary),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      ),
                    
                    // Tombol Cari (Visual Action)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _brandColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Cari',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategory == cat;
          
          return CategoryChip(
            label: cat,
            isSelected: isSelected,
            activeColor: _brandColor,
            icon: index == 0 ? Icons.grid_view_rounded : null,
            onTap: () {
              setState(() {
                _selectedCategory = cat;
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildPromoSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      height: 120,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Gradient Background
            Container(
              decoration: BoxDecoration(
                gradient: _brandGradient,
              ),
            ),
            
            // Pattern overlay
            Positioned(
              right: -20,
              bottom: -20,
              child: Icon(
                Icons.fastfood_rounded,
                size: 140,
                color: Colors.white.withValues(alpha: 0.15),
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      '🔥 Promo Hari Ini',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Pesan Sekarang,\nNikmati Kemudahannya!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Shimmer effect for category
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 4,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, __) => Container(
                width: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Shimmer for grid
          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.72,
              ),
              itemCount: 4,
              itemBuilder: (_, __) => Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingCartButton() {
    return Positioned(
      bottom: 24,
      left: 20,
      right: 20,
      child: ListenableBuilder(
        listenable: CartController.instance,
        builder: (context, _) {
          final cart = CartController.instance;
          if (cart.items.isEmpty) return const SizedBox.shrink();
          
          return TapScaleContainer(
            onTap: () => Navigator.pushNamed(context, RouteName.customerCart),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                gradient: _brandGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _brandColor.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          '${cart.totalItems}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    CurrencyFormatter.rupiah(cart.totalAmount),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: _brandColor,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFloatingOrderButton() {
    return Positioned(
      bottom: 24,
      left: 20,
      child: ListenableBuilder(
        listenable: ActiveOrderStorage.instance,
        builder: (context, _) {
          final storage = ActiveOrderStorage.instance;
          
          // Don't show if no active order or if cart has items (cart button takes priority)
          if (!storage.hasActiveOrder || CartController.instance.items.isNotEmpty) {
            return const SizedBox.shrink();
          }
          
          return TapScaleContainer(
            onTap: () => Navigator.pushNamed(
              context,
              RouteName.customerOrderStatus,
              arguments: storage.orderCode,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.info,
                    AppColors.info.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.info.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Pesanan Aktif',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        'Lihat Status →',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// MENU CARD - Modern soft card design
// ═══════════════════════════════════════════════════════════

class _MenuCard extends StatelessWidget {
  final MenuModel menu;
  final int index;

  const _MenuCard({
    required this.menu,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final brandColor = TenantProvider.of(context).primaryColorValue;
    final brandGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.lerp(brandColor, Colors.white, 0.2) ?? brandColor,
        brandColor,
      ],
    );

    return TapScaleContainer(
      onTap: () {
        Navigator.of(context).pushNamed(
          RouteName.customerMenuDetail,
          arguments: menu,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Container
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  // Image
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: menu.imageUrl != null && menu.imageUrl!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                            child: Image.network(
                              menu.imageUrl!,
                              fit: BoxFit.cover,
                               errorBuilder: (ctx, err, st) => _buildPlaceholder(brandColor),
                            ),
                          )
                        : _buildPlaceholder(brandColor),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      menu.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      menu.categoryName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            CurrencyFormatter.rupiah(menu.price),
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: brandColor,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            gradient: brandGradient,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.add_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(Color color) {
    return Center(
      child: Icon(
        Icons.fastfood_rounded,
        size: 40,
        color: color.withValues(alpha: 0.2),
      ),
    );
  }
}
