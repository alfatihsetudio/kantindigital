import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/image_saver.dart';
import '../../../core/widgets/app_snackbar.dart';
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
  final GlobalKey _qrisCardKey = GlobalKey();
  Timer? _refreshTimer;
  OrderModel? _order;
  String? _error;
  bool _loading = true;
  String? _orderCode;
  String? _lastStatus;
  bool _isDownloading = false;

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
        if (order.status == OrderStatus.served ||
            order.status == OrderStatus.cancelled) {
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

  Future<void> _downloadQris() async {
    if (_isDownloading || _order == null) return;
    setState(() => _isDownloading = true);

    try {
      final boundary =
          _qrisCardKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception('Gagal menangkap tampilan QRIS');
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('Gagal memproses file gambar');
      }

      final bytes = byteData.buffer.asUint8List();
      final filename = 'QRIS-KantinDigital-${_order!.code}.png';
      final success = await ImageSaver.saveImage(bytes, filename);

      if (mounted) {
        if (success) {
          AppSnackBar.show(
            context,
            message:
                'QRIS berhasil diunduh! Silakan buka m-Banking/E-Wallet dan upload dari Galeri.',
            backgroundColor: const Color(0xFF059669),
            icon: Icons.check_circle_rounded,
          );
        } else {
          AppSnackBar.show(
            context,
            message: 'QRIS berhasil dibuat.',
            backgroundColor: AppColors.primary,
            icon: Icons.check_circle_rounded,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(context, message: 'Gagal mengunduh QRIS: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
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
        return 'Silakan selesaikan pembayaran...';
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
        return Icons.qr_code_2_rounded;
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
        return Colors.amber.shade800;
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
        return 'Menunggu Pembayaran';
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
        body: ErrorView(
          message: "Terjadi kesalahan: Kode pesanan tidak ditemukan.",
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Status Pesanan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
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
    final isQrisUnpaid =
        order.status == OrderStatus.unpaid &&
        order.paymentMethod.toLowerCase() == 'qris';
    final isCashUnpaid =
        order.status == OrderStatus.unpaid &&
        order.paymentMethod.toLowerCase() == 'cash';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // If QRIS & UNPAID -> Show QRIS Payment & Download Card
          if (isQrisUnpaid) ...[
            _buildQrisPaymentSection(order),
            const SizedBox(height: 20),
          ] else if (isCashUnpaid) ...[
            _buildCashPaymentSection(order),
            const SizedBox(height: 20),
          ] else ...[
            _buildStatusCard(order),
            const SizedBox(height: 20),
          ],

          // Order Details Card
          _buildOrderDetailsCard(order),

          const SizedBox(height: 20),

          // Auto-refresh indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Status otomatis diperbarui secara real-time',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStatusCard(OrderModel order) {
    return Container(
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
    );
  }

  Widget _buildCashPaymentSection(OrderModel order) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.shade300, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.payments_rounded,
              size: 40,
              color: Colors.amber.shade800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Pembayaran Tunai di Kasir',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.amber.shade900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Silakan tunjukkan Kode Pesanan ke kasir untuk melakukan pembayaran:',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              order.code,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrisPaymentSection(OrderModel order) {
    final payload = order.qrisPayload ?? order.code;
    final merchant = order.merchantName ?? 'Say Coffee';
    final city = order.merchantCity ?? 'Kab. Serang';
    final nmidMatch = RegExp(r'0215(ID[0-9A-Za-z]+)').firstMatch(payload);
    final nmid = nmidMatch != null ? nmidMatch.group(1)! : 'ID1026605854250';

    return Column(
      children: [
        // Printable / Capturable QRIS Card
        RepaintBoundary(
          key: _qrisCardKey,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
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
                // Top Header Strip
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E293B),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(18),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDC2626),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'QRIS',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'PEMBAYARAN DIGITAL',
                            style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '#${order.code}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Merchant Name & City
                      Text(
                        merchant,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        city,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Nominal Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'TOTAL PEMBAYARAN',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF64748B),
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              CurrencyFormatter.rupiah(order.totalAmount),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // QR Code
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFCBD5E1),
                            width: 1.5,
                          ),
                        ),
                        child: QrImageView(
                          data: payload,
                          version: QrVersions.auto,
                          size: 200.0,
                          backgroundColor: Colors.white,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: Color(0xFF0F172A),
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),
                      Text(
                        'NMID: $nmid • $merchant',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Download QRIS Button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _isDownloading ? null : _downloadQris,
            icon: _isDownloading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.file_download_outlined, size: 22),
            label: Text(
              _isDownloading ? 'Menyimpan QRIS...' : 'Download QRIS',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 2,
            ),
          ),
        ),

        const SizedBox(height: 10),

        // WhatsApp Confirmation Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () => _openWhatsAppConfirmation(order),
            icon: const Icon(
              Icons.chat_bubble_outline_rounded,
              size: 20,
              color: Color(0xFF16A34A),
            ),
            label: const Text(
              'Konfirmasi Bukti Transfer via WhatsApp',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF15803D),
              ),
            ),
            style: OutlinedButton.styleFrom(
              backgroundColor: const Color(0xFFF0FDF4),
              side: const BorderSide(color: Color(0xFF86EFAC), width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),

        const SizedBox(height: 14),

        // Instructions for Single Device (Upload via Gallery)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFF2563EB),
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Petunjuk Bayar di HP yang Sama:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF1E40AF),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildInstructionStep(
                '1',
                'Tekan tombol "Download QRIS" di atas untuk menyimpan gambar.',
              ),
              _buildInstructionStep(
                '2',
                'Buka m-Banking (BCA, Livin, dll) atau E-Wallet (GoPay, OVO, DANA, ShopeePay).',
              ),
              _buildInstructionStep(
                '3',
                'Pilih menu Scan QRIS, lalu tekan ikon Galeri/Foto.',
              ),
              _buildInstructionStep(
                '4',
                'Pilih gambar QRIS tadi dan selesaikan pembayaran.',
              ),
              _buildInstructionStep(
                '5',
                'Setelah transfer, tekan tombol WhatsApp di atas untuk mengirimkan bukti transfer jika diperlukan.',
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _openWhatsAppConfirmation(OrderModel order) {
    var phone = order.whatsappNumber ?? '087771262100';
    phone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (phone.startsWith('0')) {
      phone = '62${phone.substring(1)}';
    } else if (!phone.startsWith('62')) {
      phone = '62$phone';
    }

    final message =
        '''Halo Admin ${order.merchantName ?? 'Kantin Digital'}, saya ingin konfirmasi pembayaran QRIS untuk pesanan:
*Kode Pesanan:* #${order.code}
*Nama:* ${order.customerName ?? 'Pelanggan'}
*Pesanan:* ${order.orderType == 'delivery'
            ? 'Pengantaran'
            : order.orderType == 'pickup'
            ? 'Ambil sendiri'
            : order.table?.name ?? order.table?.code ?? 'Makan di tempat'}
${order.deliveryAddress == null ? '' : '*Alamat Pengantaran:* ${order.deliveryAddress}\n'}*Total Tagihan:* ${CurrencyFormatter.rupiah(order.totalAmount)}

(Berikut saya lampirkan bukti transfer QRIS nya)''';

    final url = 'https://wa.me/$phone?text=${Uri.encodeComponent(message)}';
    ImageSaver.openUrl(url);
  }

  Widget _buildInstructionStep(String step, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18,
            height: 18,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFF3B82F6),
              shape: BoxShape.circle,
            ),
            child: Text(
              step,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF1E3A8A),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetailsCard(OrderModel order) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Kode Pesanan',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              Text(
                order.code,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
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
                  const Text(
                    'Nama',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  Text(
                    order.customerName!,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
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
                  const Text(
                    'Nomor Telepon',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  Text(
                    order.customerPhone!,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Jenis Pesanan',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              Text(
                order.orderType == 'delivery'
                    ? 'Pengantaran'
                    : order.orderType == 'pickup'
                    ? 'Ambil sendiri'
                    : order.table?.name ??
                          order.table?.code ??
                          'Makan di tempat',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          if (order.orderType == 'delivery' &&
              order.deliveryAddress != null) ...[
            const SizedBox(height: 12),
            const Text(
              'Alamat Pengantaran',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              order.deliveryAddress!,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Metode Pembayaran',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: order.paymentMethod.toLowerCase() == 'qris'
                      ? const Color(0xFFDC2626).withValues(alpha: 0.1)
                      : Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  order.paymentMethod.toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: order.paymentMethod.toLowerCase() == 'qris'
                        ? const Color(0xFFDC2626)
                        : Colors.amber.shade900,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          const Text(
            'Detail Menu:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...order.items.map((item) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.menuName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
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
                      const SizedBox(width: 12),
                      Text(
                        CurrencyFormatter.rupiah(item.price * item.quantity),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  if (item.toppings.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, left: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: item.toppings
                            .map(
                              (topping) => Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '+ ${topping.toppingName}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      CurrencyFormatter.rupiah(
                                        topping.toppingPrice * topping.quantity,
                                      ),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  if (item.notes != null && item.notes!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Catatan: ${item.notes}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
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
              const Text(
                'Total Pembayaran',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              Text(
                CurrencyFormatter.rupiah(order.totalAmount),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
