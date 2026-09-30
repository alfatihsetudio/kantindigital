import 'package:flutter/material.dart';
import 'dart:async';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/top_notification.dart';
import '../../../shared/constants/order_status.dart';
import '../../../shared/models/order_model.dart';
import 'order_status_controller.dart';
import '../../../shared/storage/active_order_storage.dart';

class OrderStatusPage extends StatefulWidget {
  const OrderStatusPage({super.key});

  @override
  State<OrderStatusPage> createState() => _OrderStatusPageState();
}

class _OrderStatusPageState extends State<OrderStatusPage> {
  final OrderStatusController _controller = OrderStatusController();
  Timer? _refreshTimer;
  OrderModel? _order;
  String? _error;
  bool _loading = true;
  String? _orderCode;
  String? _lastStatus;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String && _orderCode == null) {
      _orderCode = args;
      _loadOrder();
      
      // Auto-refresh every 3 seconds to get status updates
      _refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) {
        _loadOrder(silent: true);
      });
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadOrder({bool silent = false}) async {
    if (_orderCode == null) return;
    
    if (!silent) {
      setState(() => _loading = true);
    }
    
    try {
      final order = await _controller.fetchByCode(_orderCode!);
      if (mounted) {
        // Check if status changed
        if (_lastStatus != null && _lastStatus != order.status.name) {
          _showStatusNotification(order.status);
        }
        _lastStatus = order.status.name;
        
        // Clear active order if served or cancelled
        if (order.status == OrderStatus.served || order.status == OrderStatus.cancelled) {
          ActiveOrderStorage.instance.clear();
        }
        
        setState(() {
          _order = order;
          _loading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted && !silent) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  void _showStatusNotification(OrderStatus newStatus) {
    final message = _getStatusMessage(newStatus);
    TopNotification.show(
      message: message,
      backgroundColor: _getStatusColor(newStatus),
      icon: _getStatusIcon(newStatus),
      duration: const Duration(seconds: 4),
    );
  }

  String _getStatusMessage(OrderStatus status) {
    switch (status) {
      case OrderStatus.unpaid:
        return 'Menunggu konfirmasi kasir...';
      case OrderStatus.paid:
        return 'Pembayaran diterima!';
      case OrderStatus.processing:
        return '🍳 Pesanan sedang diproses!';
      case OrderStatus.ready:
        return '✅ Pesanan siap diantar!';
      case OrderStatus.served:
        return '🎉 Pesanan sudah diantar. Selamat menikmati!';
      case OrderStatus.cancelled:
        return '❌ Pesanan dibatalkan';
    }
  }

  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.unpaid:
        return Icons.hourglass_empty;
      case OrderStatus.paid:
        return Icons.payment;
      case OrderStatus.processing:
        return Icons.restaurant;
      case OrderStatus.ready:
        return Icons.check_circle;
      case OrderStatus.served:
        return Icons.done_all;
      case OrderStatus.cancelled:
        return Icons.cancel;
    }
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.unpaid:
        return Colors.orange;
      case OrderStatus.paid:
        return Colors.blue;
      case OrderStatus.processing:
        return Colors.purple;
      case OrderStatus.ready:
        return Colors.green;
      case OrderStatus.served:
        return AppColors.primary;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  String _statusLabel(OrderStatus status) {
    switch (status) {
      case OrderStatus.unpaid:
        return 'Menunggu Konfirmasi';
      case OrderStatus.paid:
        return 'Sudah Dibayar';
      case OrderStatus.processing:
        return 'Sedang Diproses';
      case OrderStatus.ready:
        return 'Siap Diantar';
      case OrderStatus.served:
        return 'Sudah Diantar';
      case OrderStatus.cancelled:
        return 'Dibatalkan';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_orderCode == null) {
      return const Scaffold(
        body: ErrorView(message: "Terjadi kesalahan: Kode pesanan tidak ditemukan."),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Status Pesanan'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: _loading
          ? const LoadingView(message: 'Memuat status pesanan...')
          : _error != null
              ? ErrorView(message: _error!)
              : _order == null
                  ? const ErrorView(message: "Data pesanan tidak ditemukan.")
                  : _buildOrderStatus(_order!),
    );
  }

  Widget _buildOrderStatus(OrderModel order) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Status Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getStatusIcon(order.status),
                    size: 48,
                    color: _getStatusColor(order.status),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _statusLabel(order.status),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(order.status),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getStatusMessage(order.status),
                  style: const TextStyle(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Order Details Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Kode Pesanan', style: TextStyle(color: AppColors.textSecondary)),
                    Text(order.code, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 12),
                // Customer name
                if (order.customerName != null && order.customerName!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Nama', style: TextStyle(color: AppColors.textSecondary)),
                        Text(order.customerName!, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                // Customer phone
                if (order.customerPhone != null && order.customerPhone!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Nomor Telepon', style: TextStyle(color: AppColors.textSecondary)),
                        Text(order.customerPhone!, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Meja', style: TextStyle(color: AppColors.textSecondary)),
                    Text(order.table.code, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const Divider(height: 24),
                const Text('Detail Pesanan:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...order.items.map((item) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Main item with price
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                item.menuName,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  CurrencyFormatter.rupiah(item.price),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                Text(
                                  'x${item.quantity}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textMuted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        // Toppings if any
                        if (item.toppings.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: item.toppings.map((topping) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '- ${topping.toppingName} (x${topping.quantity})',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      CurrencyFormatter.rupiah(topping.toppingPrice * topping.quantity),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w500,
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
                              const Text(
                                'Total',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                CurrencyFormatter.rupiah(item.price * item.quantity + item.toppings.fold(0, (sum, t) => sum + (t.toppingPrice * t.quantity))),
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
                  );
                }),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(
                      CurrencyFormatter.rupiah(order.totalAmount),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Auto-refresh indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.sync, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(
                'Status diperbarui otomatis',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
