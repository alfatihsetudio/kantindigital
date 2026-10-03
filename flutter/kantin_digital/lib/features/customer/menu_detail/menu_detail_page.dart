import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/glass_components.dart';
import '../../../core/widgets/top_notification.dart';
import '../../../shared/models/menu_model.dart';
import '../../../shared/providers/tenant_provider.dart';
import '../cart/cart_controller.dart';

import '../../../shared/models/topping_model.dart';

class MenuDetailPage extends StatefulWidget {
  final MenuModel menu;

  const MenuDetailPage({super.key, required this.menu});

  @override
  State<MenuDetailPage> createState() => _MenuDetailPageState();
}

class _MenuDetailPageState extends State<MenuDetailPage> {
  int _qty = 1;
  final TextEditingController _notesController = TextEditingController();
  final ApiClient _client = ApiClient();
  
  List<ToppingModel> _allToppings = [];
  final Map<int, int> _selectedToppings = {}; // Map<ToppingID, Quantity>
  bool _loadingToppings = true;

  @override
  void initState() {
    super.initState();
    _loadToppings();
  }

  Future<void> _loadToppings() async {
    try {
      final response = await _client.get('/toppings?menu_id=${widget.menu.id}');
      final data = response['data'] as List;
      setState(() {
        _allToppings = data.map((e) => ToppingModel.fromJson(e)).toList();
        _loadingToppings = false;
      });
    } catch (e) {
      setState(() => _loadingToppings = false);
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
      notes: _notesController.text,
      toppings: selectedToppings.map((t) => {
        'id': t.id, 
        'name': t.name, 
        'price': t.price,
        'quantity': _selectedToppings[t.id] ?? 1,
      }).toList(),
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
                child: _buildHeroImage(menu),
              ),
              
              // Content
              SliverToBoxAdapter(
                child: _buildContent(menu),
              ),
              
              // Bottom spacing for button
              const SliverToBoxAdapter(
                child: SizedBox(height: 120),
              ),
            ],
          ),
          
          // Back Button
          _buildBackButton(),
          
          // Bottom Add to Cart
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildHeroImage(MenuModel menu) {
    return Stack(
      children: [
        // Image
        Container(
          height: 320,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.background,
          ),
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
                colors: [
                  Colors.transparent,
                  AppColors.background,
                ],
              ),
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

  Widget _buildContent(MenuModel menu) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.background,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category badge & Kode Menu Flyer
          Builder(
            builder: (context) {
              final prefix = TenantProvider.of(context).menuCodePrefix;
              final codeText = menu.formattedCode(prefix);
              return Row(
                children: [
                  if (codeText.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
              );
            },
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
              Text(
                CurrencyFormatter.rupiah(menu.price),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
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
          
          const SizedBox(height: 24),
          
          // Toppings Section
          _buildToppingSection(),
          
          const SizedBox(height: 24),
          
          // Notes Section
          _buildNotesSection(),
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
          else if (_allToppings.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, 
                    color: AppColors.textMuted, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    'Tidak ada topping tersedia',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
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
                    color: isSelected ? AppColors.primary.withValues(alpha: 0.05) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.borderLight,
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
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                                child: const Icon(Icons.remove, size: 14, color: AppColors.textPrimary),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                '$qty',
                                style: const TextStyle(fontWeight: FontWeight.bold),
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
                                child: const Icon(Icons.add, size: 14, color: Colors.white),
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
                      'Catatan Pesanan',
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
          TextField(
            controller: _notesController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Contoh: Tidak pedas, tanpa bawang...',
              hintStyle: TextStyle(color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
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
          child: Row(
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
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
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
                        const Icon(Icons.add_shopping_cart_rounded, 
                          color: Colors.white, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          CurrencyFormatter.rupiah(_itemTotal),
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
