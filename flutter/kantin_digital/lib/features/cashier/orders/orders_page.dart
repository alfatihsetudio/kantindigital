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

  bool get _isOperations => AuthSession().user?.role?.name == 'operations';

  @override
  void initState() {
    super.initState();
    if (_isOperations) {
      _selectedIndex = 1;
    }
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
      case 0:
        return _pendingOrders;
      case 1:
        return _processingOrders;
      case 2:
        return _completedOrders;
      default:
        return [];
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
                      ? Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        )
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
    final isOperations = _isOperations;
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
                child: const Icon(
                  Icons.menu_rounded,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Halo, ${user?.name ?? (isOperations ? "Operasional" : "Kasir")}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  isOperations ? 'Dashboard Operasional' : 'Dashboard Kasir',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (!isOperations)
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
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                      boxShadow: AppTheme.shadowSm,
                    ),
                    child: const CircleAvatar(
                      backgroundColor: AppColors.primaryLight,
                      child: Icon(
                        Icons.calculate_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // POS icon - Manual Order
                GestureDetector(
                  onTap: () async {
                    final result = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => const ManualOrderPage(),
                      ),
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
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                      boxShadow: AppTheme.shadowSm,
                    ),
                    child: const CircleAvatar(
                      backgroundColor: AppColors.primaryLight,
                      child: Icon(
                        Icons.point_of_sale_rounded,
                        color: AppColors.primary,
                      ),
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
            if (!_isOperations)
              _buildTabItem(
                0,
                'Baru',
                _pendingOrders.length,
                Icons.new_releases_rounded,
              ),
            _buildTabItem(
              1,
              'Proses',
              _processingOrders.length,
              Icons.inventory_2_rounded,
            ),
            _buildTabItem(
              2,
              'Siap',
              _completedOrders.length,
              Icons.check_circle_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(int index, String label, int count, IconData icon) {
    final isSelected = _selectedIndex == index;
    // Specific colors for tabs
    Color activeColor;
    if (index == 0) {
      activeColor = AppColors.warning;
    } else if (index == 1) {
      activeColor = AppColors.primary;
    } else {
      activeColor = AppColors.info;
    }

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor.withValues(alpha: 0.1)
                : Colors.transparent,
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
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
              child: Icon(
                Icons.inbox_rounded,
                size: 64,
                color: AppColors.textMuted,
              ),
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 768;

        if (isMobile) {
          // 2 Kolom di Mode HP
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 100),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio:
                  0.58, // Taller aspect ratio for 2 compact mobile columns
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              return _OrderTicketCard(
                order: orders[index],
                tabIndex: _selectedIndex,
                isCompact: true,
                actionsEnabled: !_isOperations || _selectedIndex == 1,
                onAction: (order, action) => _updateStatus(order, action),
              );
            },
          );
        }

        // Tablet / Desktop Grid
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 380,
            childAspectRatio: 0.85,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            return _OrderTicketCard(
              order: orders[index],
              tabIndex: _selectedIndex,
              isCompact: false,
              actionsEnabled: !_isOperations || _selectedIndex == 1,
              onAction: (order, action) => _updateStatus(order, action),
            );
          },
        );
      },
    );
  }
}

class _OrderTicketCard extends StatelessWidget {
  final CashierOrderModel order;
  final int tabIndex;
  final bool isCompact;
  final bool actionsEnabled;
  final Function(CashierOrderModel, String) onAction;

  const _OrderTicketCard({
    required this.order,
    required this.tabIndex,
    this.isCompact = false,
    this.actionsEnabled = true,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    Color accentColor;
    String btnLabel;
    String nextStatus;
    IconData btnIcon;

    if (tabIndex == 0) {
      // Baru
      accentColor = AppColors.warning;
      btnLabel = isCompact ? 'Bayar' : 'Konfirmasi Bayar';
      nextStatus = 'PROCESSING';
      btnIcon = Icons.payment_rounded;
    } else if (tabIndex == 1) {
      // Proses
      accentColor = AppColors.primary;
      btnLabel = isCompact ? 'Siap' : 'Pesanan Siap';
      nextStatus = 'READY';
      btnIcon = Icons.dinner_dining_rounded;
    } else {
      // Siap
      accentColor = AppColors.info;
      btnLabel = isCompact ? 'Selesai' : 'Selesai & Antar';
      nextStatus = 'SERVED';
      btnIcon = Icons.check_circle_outline_rounded;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isCompact ? 16 : 20),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.15),
            blurRadius: isCompact ? 8 : 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 10 : 16,
              vertical: isCompact ? 10 : 14,
            ),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(isCompact ? 16 : 20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isCompact ? 6 : 10,
                    vertical: isCompact ? 2 : 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    order.fulfillmentLabel,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: accentColor,
                      fontSize: isCompact ? 13 : 16,
                    ),
                  ),
                ),
                Text(
                  '#${order.code}',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: isCompact ? 11 : 12,
                  ),
                ),
              ],
            ),
          ),

          // Customer info
          if ((order.customerName != null && order.customerName!.isNotEmpty) ||
              (order.customerPhone != null &&
                  order.customerPhone!.isNotEmpty) ||
              (order.deliveryAddress != null &&
                  order.deliveryAddress!.isNotEmpty))
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 10 : 16,
                vertical: isCompact ? 6 : 8,
              ),
              decoration: BoxDecoration(
                color: AppColors.background.withValues(alpha: 0.5),
                border: Border(
                  bottom: BorderSide(color: accentColor.withValues(alpha: 0.2)),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.person_rounded,
                    size: isCompact ? 14 : 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (order.customerName != null &&
                            order.customerName!.isNotEmpty)
                          Text(
                            order.customerName!,
                            style: TextStyle(
                              fontSize: isCompact ? 11 : 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (order.customerPhone != null &&
                            order.customerPhone!.isNotEmpty)
                          Text(
                            order.customerPhone!,
                            style: TextStyle(
                              fontSize: isCompact ? 10 : 12,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (order.deliveryAddress != null &&
                            order.deliveryAddress!.isNotEmpty)
                          Text(
                            order.deliveryAddress!,
                            style: TextStyle(
                              fontSize: isCompact ? 10 : 12,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
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
              padding: EdgeInsets.all(isCompact ? 10 : 16),
              itemCount: order.items.length,
              separatorBuilder: (_, __) => Divider(height: isCompact ? 10 : 16),
              itemBuilder: (context, index) {
                final item = order.items[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isCompact ? 5 : 8,
                            vertical: isCompact ? 3 : 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${item.quantity}x',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: isCompact ? 11 : 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.menuName,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: isCompact ? 12 : 14,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                CurrencyFormatter.rupiah(item.price),
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: isCompact ? 10 : 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    // Toppings if any
                    if (item.toppings.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(
                          top: 4,
                          left: isCompact ? 28 : 40,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: item.toppings
                              .map(
                                (topping) => Padding(
                                  padding: const EdgeInsets.only(bottom: 2),
                                  child: Text(
                                    '+ ${topping.toppingName} (x${topping.quantity})',
                                    style: TextStyle(
                                      fontSize: isCompact ? 10 : 11,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    // Notes if any
                    if (item.notes != null && item.notes!.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(
                          top: 4,
                          left: isCompact ? 28 : 40,
                        ),
                        child: Text(
                          '"${item.notes!}"',
                          style: TextStyle(
                            fontSize: isCompact ? 10 : 11,
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                );
              },
            ),
          ),

          // Footer & Action
          Padding(
            padding: EdgeInsets.all(isCompact ? 10 : 16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: isCompact ? 11 : 13,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.rupiah(order.totalAmount),
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: isCompact ? 14 : 18,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isCompact ? 8 : 14),
                if (actionsEnabled)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => onAction(order, nextStatus),
                      icon: Icon(btnIcon, size: isCompact ? 15 : 18),
                      label: Text(
                        btnLabel,
                        style: TextStyle(
                          fontSize: isCompact ? 12 : 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: isCompact ? 10 : 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 3,
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
