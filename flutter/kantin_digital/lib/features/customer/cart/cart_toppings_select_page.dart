import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/models/topping_model.dart';
import '../menu/menu_service.dart';
import 'cart_controller.dart';

class CartToppingsSelectPage extends StatefulWidget {
  final int cartItemIndex;

  const CartToppingsSelectPage({
    super.key,
    required this.cartItemIndex,
  });

  @override
  State<CartToppingsSelectPage> createState() => _CartToppingsSelectPageState();
}

class _CartToppingsSelectPageState extends State<CartToppingsSelectPage> {
  final cart = CartController.instance;
  late List<ToppingModel> _selectedToppings;
  late MenuService _menuService;
  late Future<List<ToppingModel>> _toppingsFuture;

  @override
  void initState() {
    super.initState();
    // Copy current 
    _selectedToppings = List.from(cart.items[widget.cartItemIndex].toppings);
    
    // Initialize MenuService with ApiClient
    _menuService = MenuService(ApiClient());
    
    // Fetch toppings
    _toppingsFuture = _menuService.fetchToppings();
  }

  void _onToppingQuantityChanged(ToppingModel topping, int newQuantity) {
    setState(() {
      final index = _selectedToppings.indexWhere((t) => t.id == topping.id);
      if (index >= 0) {
        if (newQuantity > 0) {
          _selectedToppings[index] = ToppingModel(
            id: topping.id,
            name: topping.name,
            price: topping.price,
            quantity: newQuantity,
          );
        } else {
          _selectedToppings.removeAt(index);
        }
      } else if (newQuantity > 0) {
        _selectedToppings.add(ToppingModel(
          id: topping.id,
          name: topping.name,
          price: topping.price,
          quantity: newQuantity,
        ));
      }
    });
  }

  void _saveToppings() {
    // Update cart item toppings using CartController method
    cart.updateToppings(widget.cartItemIndex, _selectedToppings);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        title: const Text(
          'Pilih Toping',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
      ),
      body: FutureBuilder<List<ToppingModel>>(
        future: _toppingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: AppColors.danger),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                ],
              ),
            );
          }
          
          final toppings = snapshot.data ?? [];
          
          return Stack(
            children: [
              // Toppings list
              ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                itemCount: toppings.length,
                itemBuilder: (context, index) {
                  final topping = toppings[index];
                  // Check if this topping is already selected in cart
                  final selectedIndex = _selectedToppings.indexWhere((t) => t.id == topping.id);
                  final selectedQuantity = selectedIndex >= 0 ? _selectedToppings[selectedIndex].quantity : 0;
                  
                  return _ToppingSelectionCard(
                    topping: topping,
                    selectedQuantity: selectedQuantity,
                    onQuantityChanged: _onToppingQuantityChanged,
                  );
                },
              ),

              // Save button
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: GestureDetector(
                      onTap: _saveToppings,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.primary],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Text(
                            'Simpan Toping',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ToppingSelectionCard extends StatefulWidget {
  final ToppingModel topping;
  final int selectedQuantity;
  final Function(ToppingModel, int) onQuantityChanged;

  const _ToppingSelectionCard({
    required this.topping,
    required this.selectedQuantity,
    required this.onQuantityChanged,
  });

  @override
  State<_ToppingSelectionCard> createState() => _ToppingSelectionCardState();
}

class _ToppingSelectionCardState extends State<_ToppingSelectionCard> {
  late int _quantity;

  @override
  void initState() {
    super.initState();
    // Use selectedQuantity (from cart) instead of topping.quantity (from API default)
    _quantity = widget.selectedQuantity;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.topping.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  CurrencyFormatter.rupiah(widget.topping.price),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          // Quantity controls
          _quantity == 0
              ? GestureDetector(
                  onTap: () => setState(() {
                    _quantity = 1;
                    widget.onQuantityChanged(
                      ToppingModel(
                        id: widget.topping.id,
                        name: widget.topping.name,
                        price: widget.topping.price,
                        quantity: _quantity,
                      ),
                      _quantity,
                    );
                  }),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Icon(Icons.add_rounded, size: 18, color: AppColors.primary),
                  ),
                )
              : Container(
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => setState(() {
                          if (_quantity > 0) _quantity--;
                          widget.onQuantityChanged(
                            ToppingModel(
                              id: widget.topping.id,
                              name: widget.topping.name,
                              price: widget.topping.price,
                              quantity: _quantity,
                            ),
                            _quantity,
                          );
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          child: const Icon(Icons.remove_rounded, size: 14, color: AppColors.textMuted),
                        ),
                      ),
                      SizedBox(
                        width: 28,
                        child: Text(
                          '$_quantity',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() {
                          _quantity++;
                          widget.onQuantityChanged(
                            ToppingModel(
                              id: widget.topping.id,
                              name: widget.topping.name,
                              price: widget.topping.price,
                              quantity: _quantity,
                            ),
                            _quantity,
                          );
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          child: Icon(Icons.add_rounded, size: 14, color: AppColors.primary),
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
