import 'package:flutter/material.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/top_notification.dart';
import '../../../shared/auth/auth_session.dart';
import '../../../shared/models/tenant_model.dart';
import '../../../shared/providers/tenant_provider.dart';
import '../widgets/cashier_drawer.dart';
import '../widgets/calculator_widget.dart';
import '../manual_order/manual_order_page.dart';
import '../../../router/route_name.dart';
import 'order_alert_sound.dart';
import 'orders_service.dart';

class CashierOrdersPage extends StatefulWidget {
  const CashierOrdersPage({super.key});

  @override
  State<CashierOrdersPage> createState() => _CashierOrdersPageState();
}

class _CashierOrdersPageState extends State<CashierOrdersPage> {
  final CashierOrdersService _service = CashierOrdersService();
  final OrderAlertSound _orderAlertSound = OrderAlertSound();
  Timer? _refreshTimer;

  // Selected Tab Index: 0=Baru, 1=Proses, 2=Siap, 3=Batal
  int _selectedIndex = 0;

  List<CashierOrderModel> _pendingOrders = [];
  List<CashierOrderModel> _processingOrders = [];
  List<CashierOrderModel> _completedOrders = [];
  List<CashierOrderModel> _cancelledOrders = [];
  final Set<int> _knownPendingOrderIds = {};
  final Set<int> _unacknowledgedOrderIds = {};
  bool _hasLoadedOrders = false;
  bool _isFetchingOrders = false;
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
    _orderAlertSound.dispose();
    super.dispose();
  }

  Future<void> _loadOrders({bool silent = false}) async {
    if (_isFetchingOrders) return;
    _isFetchingOrders = true;
    if (!silent) {
      if (mounted) setState(() => _loading = true);
    }
    var newOrdersArrived = false;
    try {
      final pending = await _service.getOrders(status: 'UNPAID');
      final processing = await _service.getOrders(status: 'PROCESSING');
      final completed = await _service.getOrders(status: 'READY');
      final cancelled = await _service.getOrders(status: 'CANCELLED');

      if (mounted) {
        final incomingOrders = _hasLoadedOrders
            ? pending
                  .where((order) => !_knownPendingOrderIds.contains(order.id))
                  .toList()
            : pending;
        _knownPendingOrderIds.addAll(pending.map((order) => order.id));
        if (incomingOrders.isNotEmpty) {
          _unacknowledgedOrderIds.addAll(
            incomingOrders.map((order) => order.id),
          );
          if (!_isOperations) _selectedIndex = 0;
          newOrdersArrived = true;
        }
        _hasLoadedOrders = true;
        setState(() {
          _pendingOrders = pending;
          _processingOrders = processing;
          _completedOrders = completed;
          _cancelledOrders = cancelled;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted && !silent) {
        setState(() => _loading = false);
        // Silent error to avoid spamming snackbars on auto-refresh
        debugPrint('Error loading orders: $e');
      }
    } finally {
      _isFetchingOrders = false;
    }
    if (newOrdersArrived && _orderAlertSound.isEnabled) {
      await _playOrderAlert();
    }
  }

  Future<void> _toggleOrderSound() async {
    if (_orderAlertSound.isEnabled) {
      _orderAlertSound.disable();
      if (mounted) setState(() {});
      return;
    }

    try {
      await _orderAlertSound.enableFromUserGesture();
      if (!mounted) return;
      setState(() {});
      if (_unacknowledgedOrderIds.isNotEmpty) {
        await _playOrderAlert();
      }
      TopNotification.show(
        message: 'Suara notifikasi pesanan aktif',
        backgroundColor: AppColors.success,
        icon: Icons.volume_up_rounded,
      );
    } catch (e) {
      if (!mounted) return;
      TopNotification.show(
        message: 'Suara gagal diaktifkan. Periksa izin audio browser: $e',
        backgroundColor: AppColors.danger,
        icon: Icons.volume_off_rounded,
      );
    }
  }

  Future<void> _playOrderAlert() async {
    try {
      await _orderAlertSound.play();
    } catch (e) {
      if (!mounted) return;
      TopNotification.show(
        message: 'Gagal membunyikan notifikasi pesanan: $e',
        backgroundColor: AppColors.danger,
        icon: Icons.volume_off_rounded,
      );
    }
  }

  void _acknowledgeAllNewOrders() {
    _unacknowledgedOrderIds.clear();
    _orderAlertSound.stop();
    if (mounted) setState(() {});
  }

  Future<void> _updateStatus(CashierOrderModel order, String newStatus) async {
    try {
      await _service.updateOrderStatus(order.id, newStatus);
      _unacknowledgedOrderIds.remove(order.id);
      if (_unacknowledgedOrderIds.isEmpty) {
        _orderAlertSound.stop();
      }
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

  Future<void> _cancelOrder(CashierOrderModel order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 26),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Batalkan Pesanan?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Apakah Anda yakin pesanan #${order.code} atas nama "${order.customerName?.isNotEmpty == true ? order.customerName : "Pelanggan"}" adalah transaksi palsu atau ingin dibatalkan?',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Tagihan:',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                      ),
                      Text(
                        CurrencyFormatter.rupiah(order.totalAmount),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF991B1B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Metode:',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                      ),
                      Text(
                        order.paymentMethodLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF991B1B),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 12),
                  const Text(
                    '⚠️ Pesanan ini akan dipindahkan ke tab Batal dan TIDAK akan diproses oleh dapur.',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFB91C1C),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Kembali',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Ya, Batalkan Pesanan',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _service.updateOrderStatus(order.id, 'CANCELLED');
      _unacknowledgedOrderIds.remove(order.id);
      if (_unacknowledgedOrderIds.isEmpty) {
        _orderAlertSound.stop();
      }
      _loadOrders(); // Refresh immediately
      if (!mounted) return;

      TopNotification.show(
        message: 'Pesanan #${order.code} telah dibatalkan',
        backgroundColor: AppColors.danger,
        icon: Icons.cancel_rounded,
      );
    } catch (e) {
      if (!mounted) return;
      TopNotification.show(
        message: 'Gagal membatalkan pesanan: $e',
        backgroundColor: AppColors.danger,
        icon: Icons.error_rounded,
      );
    }
  }

  Future<void> _sendWhatsAppMessage(CashierOrderModel order) async {
    final rawPhone = order.customerPhone?.trim() ?? '';
    if (rawPhone.isEmpty) {
      TopNotification.show(
        message: 'Nomor WhatsApp konsumen tidak dicantumkan pada pesanan ini.',
        backgroundColor: AppColors.warning,
        icon: Icons.warning_amber_rounded,
      );
      return;
    }

    String cleanPhone = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanPhone.startsWith('0')) {
      cleanPhone = '62${cleanPhone.substring(1)}';
    } else if (cleanPhone.startsWith('8')) {
      cleanPhone = '62$cleanPhone';
    }

    if (cleanPhone.length < 9) {
      TopNotification.show(
        message: 'Nomor WhatsApp tidak valid: $rawPhone',
        backgroundColor: AppColors.danger,
        icon: Icons.phone_disabled_rounded,
      );
      return;
    }

    final sessionTenant = AuthSession().tenant;
    final contextTenant = TenantProvider.of(context);
    final tenant = (sessionTenant != null &&
            sessionTenant.id != 0 &&
            sessionTenant.name.isNotEmpty)
        ? sessionTenant
        : contextTenant;
    final storeName = tenant.name.isNotEmpty ? tenant.name : 'Kantin Digital';
    final message = _buildWhatsAppVerificationMessage(order, storeName);
    final encoded = Uri.encodeComponent(message);
    final url = 'https://wa.me/$cleanPhone?text=$encoded';
    final uri = Uri.parse(url);

    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      if (!mounted) return;
      TopNotification.show(
        message: 'Gagal membuka WhatsApp: $e',
        backgroundColor: AppColors.danger,
        icon: Icons.error_outline_rounded,
      );
    }
  }

  String _buildWhatsAppVerificationMessage(
    CashierOrderModel order,
    String storeName,
  ) {
    final customer = (order.customerName != null && order.customerName!.trim().isNotEmpty)
        ? order.customerName!.trim()
        : 'Kak';
    final itemsList = order.items
        .map((item) => '• ${item.quantity}x ${item.menuName}')
        .join('\n');
    final totalStr = CurrencyFormatter.rupiah(order.totalAmount);
    final paymentLabel = order.paymentMethodLabel;

    if (order.status.toUpperCase() == 'READY') {
      return 'Halo $customer, pesananmu di $storeName sudah *SIAP*! 🎉\n\n'
          '📋 *Pesanan #${order.code}*\n'
          '• Tipe: ${order.fulfillmentLabel}\n'
          '• Total: $totalStr\n\n'
          'Daftar Menu:\n$itemsList\n\n'
          'Silakan diambil di kasir / meja pengambilan ya kak. Terima kasih! 🙏';
    }

    return 'Halo $customer, terima kasih sudah memesan di $storeName! 🙏\n\n'
        '📋 *Konfirmasi Pesanan #${order.code}*\n'
        '• Tipe: ${order.fulfillmentLabel}\n'
        '• Metode Pembayaran: $paymentLabel\n'
        '• Total Tagihan: $totalStr\n\n'
        'Daftar Menu:\n$itemsList\n\n'
        '📌 *MOHON BUKTI TRANSFER:*\n'
        'Untuk memverifikasi pesanan kakak dan agar dapat segera kami buatkan di dapur, *mohon kirimkan foto / screenshot bukti transfer pembayaran* ke nomor WhatsApp ini ya kak.\n\n'
        'Jika pesanan ini tidak sengaja dibuat atau tidak jadi dipesan, mohon konfirmasi agar kami dapat membatalkannya. Terima kasih! 😊';
  }

  List<CashierOrderModel> get _currentList {
    switch (_selectedIndex) {
      case 0:
        return _pendingOrders;
      case 1:
        return _processingOrders;
      case 2:
        return _completedOrders;
      case 3:
        return _cancelledOrders;
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
                if (_unacknowledgedOrderIds.isNotEmpty)
                  _buildIncomingOrderAlert(),
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

  Widget _buildIncomingOrderAlert() {
    final orderCount = _unacknowledgedOrderIds.length;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.notifications_active_rounded,
            color: AppColors.danger,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$orderCount pesanan baru perlu diperiksa',
              style: const TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: _orderAlertSound.isEnabled
                ? _acknowledgeAllNewOrders
                : _toggleOrderSound,
            child: Text(
              _orderAlertSound.isEnabled ? 'Hentikan bunyi' : 'Aktifkan suara',
            ),
          ),
        ],
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
    final sessionTenant = AuthSession().tenant;
    final contextTenant = TenantProvider.of(context);
    final tenant = (sessionTenant != null &&
            sessionTenant.id != 0 &&
            sessionTenant.name.isNotEmpty)
        ? sessionTenant
        : contextTenant;
    final isOperations = _isOperations;
    final logoProvider = (tenant.logoUrl != null && tenant.logoUrl!.isNotEmpty)
        ? tenantLogoImageProvider(tenant.logoUrl!)
        : null;

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
          const SizedBox(width: 12),
          if (logoProvider != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image(
                image: logoProvider,
                width: 38,
                height: 38,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.storefront_rounded,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tenant.name.isNotEmpty
                      ? tenant.name
                      : (isOperations ? 'Dashboard Operasional' : 'Dashboard Kasir'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Halo, ${user?.name ?? (isOperations ? "Operasional" : "Kasir")}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (!isOperations)
            Row(
              children: [
                // Stock Check button
                Tooltip(
                  message: 'Catatan Stok (Buka / Tutup Toko)',
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushNamed(RouteName.cashierStockCheck);
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
                          Icons.inventory_2_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
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
          IconButton(
            tooltip: _orderAlertSound.isEnabled
                ? 'Matikan suara pesanan'
                : 'Aktifkan dan uji suara pesanan',
            onPressed: _toggleOrderSound,
            icon: Icon(
              _orderAlertSound.isEnabled
                  ? Icons.volume_up_rounded
                  : Icons.volume_off_rounded,
              color: _orderAlertSound.isEnabled
                  ? AppColors.success
                  : AppColors.danger,
            ),
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
            if (!_isOperations)
              _buildTabItem(
                3,
                'Batal',
                _cancelledOrders.length,
                Icons.cancel_rounded,
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
    } else if (index == 2) {
      activeColor = AppColors.info;
    } else {
      activeColor = AppColors.danger;
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
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 17,
                    color: isSelected ? activeColor : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? activeColor : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  if (count > 0) ...[
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
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
                  0.50, // Taller aspect ratio for 2 compact mobile columns with WA & Cancel actions
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
                onCancel: (order) => _cancelOrder(order),
                onWhatsApp: (order) => _sendWhatsAppMessage(order),
              );
            },
          );
        }

        // Tablet / Desktop Grid
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 380,
            childAspectRatio: 0.76,
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
              onCancel: (order) => _cancelOrder(order),
              onWhatsApp: (order) => _sendWhatsAppMessage(order),
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
  final Function(CashierOrderModel) onCancel;
  final Function(CashierOrderModel) onWhatsApp;

  const _OrderTicketCard({
    required this.order,
    required this.tabIndex,
    this.isCompact = false,
    this.actionsEnabled = true,
    required this.onAction,
    required this.onCancel,
    required this.onWhatsApp,
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
    } else if (tabIndex == 2) {
      // Siap
      accentColor = AppColors.info;
      btnLabel = isCompact ? 'Selesai' : 'Selesai & Antar';
      nextStatus = 'SERVED';
      btnIcon = Icons.check_circle_outline_rounded;
    } else {
      // Batal
      accentColor = AppColors.danger;
      btnLabel = 'Dibatalkan';
      nextStatus = '';
      btnIcon = Icons.cancel_outlined;
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
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isCompact ? 6 : 8,
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
                              fontSize: isCompact ? 11 : 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isCompact ? 4 : 6,
                          vertical: isCompact ? 2 : 3,
                        ),
                        decoration: BoxDecoration(
                          color: order.isQris
                              ? const Color(0xFFEFF6FF)
                              : const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: order.isQris
                                ? const Color(0xFFBFDBFE)
                                : const Color(0xFFA7F3D0),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              order.isQris
                                  ? Icons.qr_code_2_rounded
                                  : Icons.payments_rounded,
                              size: isCompact ? 10 : 12,
                              color: order.isQris
                                  ? const Color(0xFF2563EB)
                                  : const Color(0xFF059669),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              order.paymentMethodLabel,
                              style: TextStyle(
                                fontSize: isCompact ? 9 : 10,
                                fontWeight: FontWeight.w700,
                                color: order.isQris
                                    ? const Color(0xFF1D4ED8)
                                    : const Color(0xFF047857),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '#${order.code}',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: isCompact ? 10 : 12,
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
                  if (order.customerPhone != null &&
                      order.customerPhone!.trim().isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Tooltip(
                      message: 'Chat WhatsApp konsumen',
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => onWhatsApp(order),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isCompact ? 6 : 8,
                              vertical: isCompact ? 3 : 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF25D366),
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF25D366).withValues(alpha: 0.3),
                                  blurRadius: 3,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.chat_bubble_rounded,
                                  size: 11,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  isCompact ? 'WA' : 'Chat WA',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

          // List Items
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.all(isCompact ? 10 : 16),
              itemCount: order.items.length,
              separatorBuilder: (_, _) => Divider(height: isCompact ? 10 : 16),
              itemBuilder: (context, index) {
                final item = order.items[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (order.discountAmount > 0)
                      Padding(
                        padding: EdgeInsets.only(bottom: isCompact ? 4 : 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Diskon promo',
                              style: TextStyle(
                                color: AppColors.success,
                                fontSize: isCompact ? 10 : 12,
                              ),
                            ),
                            Text(
                              '- ${CurrencyFormatter.rupiah(order.discountAmount)}',
                              style: TextStyle(
                                color: AppColors.success,
                                fontWeight: FontWeight.w700,
                                fontSize: isCompact ? 10 : 12,
                              ),
                            ),
                          ],
                        ),
                      ),
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
                SizedBox(height: isCompact ? 8 : 12),
                if (tabIndex == 0) ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => onWhatsApp(order),
                          icon: const Icon(
                            Icons.chat_rounded,
                            size: 13,
                            color: Color(0xFF16A34A),
                          ),
                          label: Text(
                            isCompact ? 'Minta Bukti' : 'Minta Bukti TF (WA)',
                            style: TextStyle(
                              fontSize: isCompact ? 10 : 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF16A34A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF22C55E)),
                            backgroundColor: const Color(0xFFF0FDF4),
                            padding: EdgeInsets.symmetric(
                              vertical: isCompact ? 6 : 8,
                              horizontal: 4,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => onCancel(order),
                          icon: const Icon(
                            Icons.cancel_outlined,
                            size: 13,
                            color: Color(0xFFDC2626),
                          ),
                          label: Text(
                            isCompact ? 'Order Palsu' : 'Order Palsu / Batal',
                            style: TextStyle(
                              fontSize: isCompact ? 10 : 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFDC2626),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFEF4444)),
                            backgroundColor: const Color(0xFFFEF2F2),
                            padding: EdgeInsets.symmetric(
                              vertical: isCompact ? 6 : 8,
                              horizontal: 4,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isCompact ? 6 : 8),
                  if (actionsEnabled)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => onAction(order, nextStatus),
                        icon: Icon(btnIcon, size: isCompact ? 14 : 17),
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
                            vertical: isCompact ? 8 : 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 3,
                          shadowColor: accentColor.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                ] else if (tabIndex == 1) ...[
                  Row(
                    children: [
                      if (actionsEnabled)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => onAction(order, nextStatus),
                            icon: Icon(btnIcon, size: isCompact ? 14 : 17),
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
                                vertical: isCompact ? 8 : 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 3,
                              shadowColor: accentColor.withValues(alpha: 0.4),
                            ),
                          ),
                        ),
                      if (actionsEnabled) ...[
                        const SizedBox(width: 6),
                        IconButton(
                          tooltip: 'Batalkan jika orderan palsu',
                          onPressed: () => onCancel(order),
                          icon: const Icon(
                            Icons.cancel_outlined,
                            color: AppColors.danger,
                            size: 20,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFFFEF2F2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: const BorderSide(color: Color(0xFFFECACA)),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ] else if (tabIndex == 2) ...[
                  Row(
                    children: [
                      if (actionsEnabled)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => onAction(order, nextStatus),
                            icon: Icon(btnIcon, size: isCompact ? 14 : 17),
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
                                vertical: isCompact ? 8 : 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 3,
                              shadowColor: accentColor.withValues(alpha: 0.4),
                            ),
                          ),
                        ),
                      if (order.customerPhone != null &&
                          order.customerPhone!.trim().isNotEmpty) ...[
                        const SizedBox(width: 6),
                        IconButton(
                          tooltip: 'Kabari konsumen pesanan siap via WA',
                          onPressed: () => onWhatsApp(order),
                          icon: const Icon(
                            Icons.chat_rounded,
                            color: Color(0xFF16A34A),
                            size: 20,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFFF0FDF4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: const BorderSide(color: Color(0xFFBBF7D0)),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ] else ...[
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      vertical: isCompact ? 8 : 10,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.cancel_rounded,
                          size: 16,
                          color: Color(0xFFDC2626),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            isCompact
                                ? 'Dibatalkan'
                                : 'Pesanan Dibatalkan (Palsu)',
                            style: TextStyle(
                              fontSize: isCompact ? 11 : 12,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFDC2626),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (order.customerPhone != null &&
                      order.customerPhone!.trim().isNotEmpty) ...[
                    SizedBox(height: isCompact ? 6 : 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => onWhatsApp(order),
                        icon: const Icon(
                          Icons.chat_rounded,
                          size: 13,
                          color: Color(0xFF16A34A),
                        ),
                        label: Text(
                          'Chat WA Konsumen',
                          style: TextStyle(
                            fontSize: isCompact ? 10 : 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF16A34A),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF22C55E)),
                          backgroundColor: const Color(0xFFF0FDF4),
                          padding: EdgeInsets.symmetric(
                            vertical: isCompact ? 6 : 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
