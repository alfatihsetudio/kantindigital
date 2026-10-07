import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/models/menu_model.dart';
import '../../../../shared/models/topping_model.dart';

class ItemCustomizationSheet extends StatefulWidget {
  final MenuModel menu;
  final List<ToppingModel> availableToppings;
  final Function(int, List<ToppingModel>, String?) onAdd;

  // Optional initial values for editing
  final int? initialQuantity;
  final List<ToppingModel>? initialToppings;
  final String? initialNotes;
  final String ctaLabel;

  const ItemCustomizationSheet({
    super.key,
    required this.menu,
    required this.availableToppings,
    required this.onAdd,
    this.initialQuantity,
    this.initialToppings,
    this.initialNotes,
    this.ctaLabel = 'Tambah Pesanan',
  });

  @override
  State<ItemCustomizationSheet> createState() => _ItemCustomizationSheetState();
}

class _ItemCustomizationSheetState extends State<ItemCustomizationSheet> {
  int _quantity = 1;
  final List<ToppingModel> _selectedToppings = [];
  String? _selectedNote;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuantity != null) {
      _quantity = widget.initialQuantity!;
    }
    if (widget.menu.noteOptions.contains(widget.initialNotes)) {
      _selectedNote = widget.initialNotes;
    }
    if (widget.initialToppings != null) {
      // Deep copy to prevent reference issues
      _selectedToppings.addAll(
        widget.initialToppings!.map(
          (t) => ToppingModel(
            id: t.id,
            name: t.name,
            price: t.price,
            quantity: t.quantity,
          ),
        ),
      );
    }
  }

  void _updateToppingQty(ToppingModel topping, int newQty) {
    if (newQty < 0) return;

    setState(() {
      final index = _selectedToppings.indexWhere((t) => t.id == topping.id);
      if (index >= 0) {
        if (newQty == 0) {
          _selectedToppings.removeAt(index);
        } else {
          _selectedToppings[index] = ToppingModel(
            id: topping.id,
            name: topping.name,
            price: topping.price,
            quantity: newQty,
          );
        }
      } else if (newQty > 0) {
        _selectedToppings.add(
          ToppingModel(
            id: topping.id,
            name: topping.name,
            price: topping.price,
            quantity: newQty,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Calculate total price preview
    int basePrice = widget.menu.price;
    int toppingsPrice = _selectedToppings.fold(
      0,
      (sum, t) => sum + (t.price * t.quantity),
    );
    int grandTotal = (basePrice * _quantity) + (toppingsPrice * 1);

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
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // Menu Info
                Text(
                  widget.menu.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  CurrencyFormatter.rupiah(widget.menu.price),
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Divider(height: 32),

                // Quantity
                const Text(
                  'Jumlah',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildQtyBtn(Icons.remove, () {
                      if (_quantity > 1) setState(() => _quantity--);
                    }),
                    Container(
                      width: 50,
                      alignment: Alignment.center,
                      child: Text(
                        '$_quantity',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _buildQtyBtn(Icons.add, () => setState(() => _quantity++)),
                  ],
                ),
                const SizedBox(height: 24),

                // Toppings
                if (widget.availableToppings.isNotEmpty) ...[
                  const Text(
                    'Toping Tambahan',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  ...widget.availableToppings.map((topping) {
                    final index = _selectedToppings.indexWhere(
                      (t) => t.id == topping.id,
                    );
                    final qty = index >= 0
                        ? _selectedToppings[index].quantity
                        : 0;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  topping.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  CurrencyFormatter.rupiah(topping.price),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Qty Control
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () =>
                                    _updateToppingQty(topping, qty - 1),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: qty > 0
                                        ? AppColors.danger.withValues(
                                            alpha: 0.1,
                                          )
                                        : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.remove,
                                    size: 16,
                                    color: qty > 0
                                        ? AppColors.danger
                                        : Colors.grey,
                                  ),
                                ),
                              ),
                              Container(
                                width: 32,
                                alignment: Alignment.center,
                                child: Text(
                                  '$qty',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () =>
                                    _updateToppingQty(topping, qty + 1),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.add,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                ],

                if (widget.menu.noteOptions.isNotEmpty) ...[
                  const Text(
                    'Pilihan menu (opsional)',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ...widget.menu.noteOptions.map(
                        (option) => ChoiceChip(
                          label: Text(option),
                          selected: _selectedNote == option,
                          onSelected: (selected) => setState(
                            () => _selectedNote = selected ? option : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Action Button
          Container(
            padding: EdgeInsets.fromLTRB(
              24,
              24,
              24,
              24 + MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onAdd(_quantity, _selectedToppings, _selectedNote);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.ctaLabel,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.rupiah(grandTotal),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQtyBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: 20),
      ),
    );
  }
}
