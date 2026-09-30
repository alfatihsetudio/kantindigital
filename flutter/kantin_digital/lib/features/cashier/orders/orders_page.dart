import 'package:flutter/material.dart';
import 'dart:async';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/top_notification.dart';
import '../../../shared/auth/auth_session.dart';
import '../widgets/cashier_drawer.dart';
import '../widgets/calculator_widget.dart';
import '../manual_order/manual_order_page.dart';
import 'orders_service.dart';

class CashierOrdersPage extends StatefulWidget {
  const CashierOrdersPage({super.key});

  @override
  State<CashierOrdersPage> createState() => _CashierOrdersPageState();
}

class _CashierOrdersPageState extends State<CashierOrdersPage> {
  final CashierOrdersService _service = CashierOrdersService();
  Timer? _refreshTimer;

  // Selected Tab Index: 0=Baru, 1=Proses, 2=Siap
  int _selectedIndex = 0;

  List<CashierOrderModel> _pendingOrders = [];
  List<CashierOrderModel> _processingOrders = [];
  List<CashierOrderModel> _completedOrders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
    
    // Auto-refresh every 5 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _loadOrders(silent: true);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadOrders({bool silent = false}) async {
    if (!silent) {
      if (mounted) setState(() => _loading = true);
    }
    try {
      final pending = await _service.getOrders(status: 'UNPAID');
      final processing = await _service.getOrders(status: 'PROCESSING');
      final completed = await _service.getOrders(status: 'READY');
      
      if (mounted) {
        setState(() {
          _pendingOrders = pending;
          _processingOrders = processing;
          _completedOrders = completed;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted && !silent) {
        setState(() => _loading = false);
        // Silent error to avoid spamming snackbars on auto-refresh
        debugPrint('Error loading orders: $e');
      }
    }
  }

  Future<void> _updateStatus(CashierOrderModel order, String newStatus) async {
    try {
      await _service.updateOrderStatus(order.id, newStatus);
      _loadOrders(); // Refresh immediately
      if (!mounted) return;
      
      TopNotification.show(
        message: 'Pesanan #${order.code} berhasil diproses',
        backgroundColor: AppColors.success,
        icon: Icons.check_circle_rounded,
      );
    } catch (e) {
      if (!mounted) return;
      TopNotification.show(
        message: 'Gagal update: $e',
        backgroundColor: AppColors.danger,
        icon: Icons.error_rounded,
      );
    }
  }

  List<CashierOrderModel> get _currentList {
    switch (_selectedIndex) {
      case 0: return _pendingOrders;
      case 1: return _processingOrders;
      case 2: return _completedOrders;
      default: return [];
    }
  }

  Color get _currentColor {
    switch (_selectedIndex) {
      case 0: return AppColors.warning; // Orange for New/Unpaid
      case 1: return AppColors.primary; // Green for Processing (Cooking)
      case 2: return AppColors.info;    // Blue for Ready/Served
      default: return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const CashierDrawer(),
      body: Stack(
        children: [
          _buildBackgroundDecorations(),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(context),
                _buildTabSelectors(),
                Expanded(
                  child: _loading 
                      ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                      : _buildOrderGrid(),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _loadOrders(),
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('Refresh'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildBackgroundDecorations() {
    return Stack(
      children: [
        Positioned(
          top: -100,
          right: -50,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.1),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final user = AuthSession().user;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          Builder(
            builder: (context) => IconButton(
              onPressed: () => Scaffold.of(context).openDrawer(),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: AppTheme.shadowSm,
                ),
                child: const Icon(Icons.menu_rounded, color: AppColors.textPrimary),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Halo, ${user?.name ?? "Kasir"}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Text(
                  'Dashboard Kasir',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              // Calculator button
              GestureDetector(
                onTap: () => CalculatorWidget.show(context),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                    boxShadow: AppTheme.shadowSm,
                  ),
                  child: const CircleAvatar(
                    backgroundColor: AppColors.primaryLight,
                    child: Icon(Icons.calculate_rounded, color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // POS icon - Manual Order
              GestureDetector(
                onTap: () async {
                  final result = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(builder: (_) => const ManualOrderPage()),
                  );
                  if (result == true) {
                    _loadOrders(); // Refresh after creating order
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                    boxShadow: AppTheme.shadowSm,
                  ),
                  child: const CircleAvatar(
                    backgroundColor: AppColors.primaryLight,
                    child: Icon(Icons.point_of_sale_rounded, color: AppColors.primary),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabSelectors() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: AppTheme.shadowSm,
        ),
        child: Row(
          children: [
            _buildTabItem(0, 'Baru', _pendingOrders.length, Icons.new_releases_rounded),
            _buildTabItem(1, 'Proses', _processingOrders.length, Icons.soup_kitchen_rounded),
            _buildTabItem(2, 'Siap', _completedOrders.length, Icons.check_circle_rounded),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(int index, String label, int count, IconData icon) {
    final isSelected = _selectedIndex == index;
    // Specific colors for tabs
    Color activeColor;
    if (index == 0) activeColor = AppColors.warning;
    else if (index == 1) activeColor = AppColors.primary;
    else activeColor = AppColors.info;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isSelected ? activeColor.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(21),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? activeColor : AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? activeColor : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected ? activeColor : AppColors.textMuted,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    count.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderGrid() {
    final orders = _currentList;

    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: AppTheme.shadowMd,
              ),
              child: Icon(Icons.inbox_rounded, size: 64, color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada pesanan',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 400, // Responsive width
        childAspectRatio: 0.85, // Taller cards for list
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        return _OrderTicketCard(
          order: orders[index],
          tabIndex: _selectedIndex,
          onAction: (order, action) => _updateStatus(order, action),
        );
      },
    );
  }
}

class _OrderTicketCard extends StatelessWidget {
  final CashierOrderModel order;
  final int tabIndex;
  final Function(CashierOrderModel, String) onAction;

  const _OrderTicketCard({
    required this.order,
    required this.tabIndex,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    Color accentColor;
    String btnLabel;
    String nextStatus;
    IconData btnIcon;

    if (tabIndex == 0) { // Baru
      accentColor = AppColors.warning;
      btnLabel = 'Konfirmasi Bayar';
      nextStatus = 'PROCESSING';
      btnIcon = Icons.payment_rounded;
    } else if (tabIndex == 1) { // Proses
      accentColor = AppColors.primary;
      btnLabel = 'Pesanan Siap';
      nextStatus = 'READY';
      btnIcon = Icons.dinner_dining_rounded;
    } else { // Siap
      accentColor = AppColors.info;
      btnLabel = 'Selesai & Antar';
      nextStatus = 'SERVED';
      btnIcon = Icons.check_circle_outline_rounded;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    'Meja ${order.tableCode}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: accentColor,
                      fontSize: 16,
                    ),
                  ),
                ),
                Text(
                  '#${order.code}',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // Customer info
          if ((order.customerName != null && order.customerName!.isNotEmpty) ||
              (order.customerPhone != null && order.customerPhone!.isNotEmpty))
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.background.withValues(alpha: 0.5),
                border: Border(
                  bottom: BorderSide(color: accentColor.withValues(alpha: 0.2)),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.person_rounded, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (order.customerName != null && order.customerName!.isNotEmpty)
                          Text(
                            order.customerName!,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        if (order.customerPhone != null && order.customerPhone!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Row(
                              children: [
                                Icon(Icons.phone_rounded, size: 12, color: AppColors.textMuted),
                                const SizedBox(width: 4),
                                Text(
                                  order.customerPhone!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          
          // List Items
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: order.items.length,
              separatorBuilder: (_, __) => const Divider(height: 16),
              itemBuilder: (context, index) {
                final item = order.items[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${item.quantity}x',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.menuName,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  CurrencyFormatter.rupiah(item.price),
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          CurrencyFormatter.rupiah(item.price * item.quantity),
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ],
                    ),
                    // Toppings if any
                    if (item.toppings.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, left: 50),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: item.toppings.map((topping) => Padding(
                            padding: const EdgeInsets.only(bottom: 3),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '- ${topping.toppingName} (x${topping.quantity})',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Text(
                                  CurrencyFormatter.rupiah(topping.toppingPrice * topping.quantity),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.primary,
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
                        padding: const EdgeInsets.only(top: 8, left: 50),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppColors.textMuted, width: 0.5),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.notes_rounded, size: 12, color: AppColors.textMuted),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  item.notes!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                    fontStyle: FontStyle.italic,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),

          // Footer & Action
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total', style: TextStyle(color: AppColors.textSecondary)),
                    Text(
                      CurrencyFormatter.rupiah(order.totalAmount),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => onAction(order, nextStatus),
                    icon: Icon(btnIcon, size: 18),
                    label: Text(btnLabel),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      shadowColor: accentColor.withValues(alpha: 0.4),
                    ),
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
