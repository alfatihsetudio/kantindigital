import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/top_notification.dart';
import '../../../shared/models/cashier_order_model.dart';

class DeliveryDispatchHelper {
  static final RegExp _urlRegex = RegExp(
    r'(https?:\/\/[^\s]+)',
    caseSensitive: false,
  );

  /// Extract Google Maps or generic HTTP link from text
  static String? extractMapsUrl(String? text) {
    if (text == null || text.trim().isEmpty) return null;
    final match = _urlRegex.firstMatch(text);
    if (match != null) {
      String url = match.group(0)!;
      // Clean trailing punctuation if any
      while (url.endsWith('.') || url.endsWith(',') || url.endsWith(')')) {
        url = url.substring(0, url.length - 1);
      }
      return url;
    }
    return null;
  }

  /// Clean text address by removing the "Pin Google Maps: ..." line
  static String cleanAddress(String? text) {
    if (text == null || text.trim().isEmpty) return '';
    final lines = text.split('\n');
    final cleaned = lines.where((line) {
      final l = line.toLowerCase().trim();
      if (l.contains('pin google maps:') ||
          l.contains('google maps:') ||
          l.startsWith('http://') ||
          l.startsWith('https://')) {
        return false;
      }
      return true;
    }).join('\n').trim();

    return cleaned.isNotEmpty ? cleaned : text.trim();
  }

  /// Launch Google Maps directly
  static Future<void> openGoogleMaps({
    String? url,
    String? address,
  }) async {
    String? targetUrl = url;
    if (targetUrl == null || targetUrl.trim().isEmpty) {
      if (address != null && address.trim().isNotEmpty) {
        targetUrl =
            'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address.trim())}';
      } else {
        targetUrl = 'https://www.google.com/maps';
      }
    }

    try {
      final uri = Uri.parse(targetUrl);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      TopNotification.show(
        message: 'Gagal membuka Google Maps: $e',
        backgroundColor: AppColors.danger,
        icon: Icons.error_outline_rounded,
      );
    }
  }

  /// Launch Gojek app with address & maps link copied to clipboard
  static Future<void> openGojek({
    required String address,
    String? mapsUrl,
  }) async {
    final buffer = StringBuffer();
    if (address.isNotEmpty) buffer.writeln(address);
    if (mapsUrl != null && mapsUrl.isNotEmpty) {
      buffer.writeln('Pin Lokasi: $mapsUrl');
    }
    final textToCopy = buffer.toString().trim();

    if (textToCopy.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: textToCopy));
    }

    TopNotification.show(
      message: 'Alamat disalin! Membuka aplikasi Gojek...',
      backgroundColor: const Color(0xFF00880C),
      icon: Icons.two_wheeler_rounded,
      duration: const Duration(seconds: 3),
    );

    // Try custom scheme first, then web link, then Play Store
    final gojekScheme = Uri.parse('gojek://');
    final gojekLink = Uri.parse('https://gojek.link');
    final playStore = Uri.parse(
      'https://play.google.com/store/apps/details?id=com.gojek.app',
    );

    try {
      if (await canLaunchUrl(gojekScheme)) {
        await launchUrl(gojekScheme, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {}

    try {
      final launched = await launchUrl(
        gojekLink,
        mode: LaunchMode.externalApplication,
      );
      if (launched) return;
    } catch (_) {}

    try {
      await launchUrl(playStore, mode: LaunchMode.externalApplication);
    } catch (e) {
      TopNotification.show(
        message: 'Tidak dapat membuka Gojek: $e',
        backgroundColor: AppColors.danger,
        icon: Icons.error_outline_rounded,
      );
    }
  }

  /// Launch Maxim app with address & maps link copied to clipboard
  static Future<void> openMaxim({
    required String address,
    String? mapsUrl,
  }) async {
    final buffer = StringBuffer();
    if (address.isNotEmpty) buffer.writeln(address);
    if (mapsUrl != null && mapsUrl.isNotEmpty) {
      buffer.writeln('Pin Lokasi: $mapsUrl');
    }
    final textToCopy = buffer.toString().trim();

    if (textToCopy.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: textToCopy));
    }

    TopNotification.show(
      message: 'Alamat disalin! Membuka aplikasi Maxim...',
      backgroundColor: const Color(0xFFD97706),
      icon: Icons.local_taxi_rounded,
      duration: const Duration(seconds: 3),
    );

    final maximScheme = Uri.parse('maximzakaz://');
    final taxiMaximScheme = Uri.parse('taximaxim://');
    final maximWeb = Uri.parse('https://taximaxim.com');
    final playStore = Uri.parse(
      'https://play.google.com/store/apps/details?id=com.taximaxim.android',
    );

    try {
      if (await canLaunchUrl(maximScheme)) {
        await launchUrl(maximScheme, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {}

    try {
      if (await canLaunchUrl(taxiMaximScheme)) {
        await launchUrl(taxiMaximScheme, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {}

    try {
      final launched = await launchUrl(
        maximWeb,
        mode: LaunchMode.externalApplication,
      );
      if (launched) return;
    } catch (_) {}

    try {
      await launchUrl(playStore, mode: LaunchMode.externalApplication);
    } catch (e) {
      TopNotification.show(
        message: 'Tidak dapat membuka Maxim: $e',
        backgroundColor: AppColors.danger,
        icon: Icons.error_outline_rounded,
      );
    }
  }

  /// Copy full delivery info to clipboard
  static Future<void> copyDeliveryInfo({
    required CashierOrderModel order,
    required String address,
    String? mapsUrl,
  }) async {
    final buffer = StringBuffer();
    buffer.writeln('Pesanan #${order.code}');
    if (order.customerName != null && order.customerName!.isNotEmpty) {
      buffer.writeln('Nama Pemesan: ${order.customerName}');
    }
    if (order.customerPhone != null && order.customerPhone!.isNotEmpty) {
      buffer.writeln('No. HP / WA: ${order.customerPhone}');
    }
    if (address.isNotEmpty) {
      buffer.writeln('Alamat: $address');
    }
    if (mapsUrl != null && mapsUrl.isNotEmpty) {
      buffer.writeln('Link Google Maps: $mapsUrl');
    }

    await Clipboard.setData(ClipboardData(text: buffer.toString().trim()));
    TopNotification.show(
      message: 'Rincian alamat & link Google Maps berhasil disalin!',
      backgroundColor: AppColors.success,
      icon: Icons.copy_rounded,
    );
  }

  /// Show delivery options sheet / dialog
  static void showDeliveryOptionsModal(
    BuildContext context, {
    required CashierOrderModel order,
  }) {
    final rawAddress = order.deliveryAddress ?? '';
    final mapsUrl = extractMapsUrl(rawAddress);
    final cleanAddr = cleanAddress(rawAddress);

    final isWide = MediaQuery.of(context).size.width >= 600;

    if (isWide) {
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: _DeliveryOptionsContent(
              order: order,
              rawAddress: rawAddress,
              cleanAddr: cleanAddr,
              mapsUrl: mapsUrl,
            ),
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: _DeliveryOptionsContent(
              order: order,
              rawAddress: rawAddress,
              cleanAddr: cleanAddr,
              mapsUrl: mapsUrl,
            ),
          ),
        ),
      );
    }
  }
}

class _DeliveryOptionsContent extends StatelessWidget {
  final CashierOrderModel order;
  final String rawAddress;
  final String cleanAddr;
  final String? mapsUrl;

  const _DeliveryOptionsContent({
    required this.order,
    required this.rawAddress,
    required this.cleanAddr,
    required this.mapsUrl,
  });

  @override
  Widget build(BuildContext context) {
    final customer = order.customerName?.isNotEmpty == true
        ? order.customerName!
        : 'Pelanggan';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle on sheet
          Center(
            child: Container(
              width: 38,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.delivery_dining_rounded,
                  color: AppColors.primary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Teruskan ke Ojek Online',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Pesanan #${order.code} • $customer',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, size: 20),
                color: AppColors.textMuted,
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Address & Maps preview box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (cleanAddr.isNotEmpty) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.home_outlined,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          cleanAddr,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (mapsUrl != null && mapsUrl!.isNotEmpty) ...[
                  if (cleanAddr.isNotEmpty) const SizedBox(height: 8),
                  InkWell(
                    onTap: () {
                      DeliveryDispatchHelper.openGoogleMaps(
                        url: mapsUrl,
                        address: cleanAddr,
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            size: 16,
                            color: Color(0xFF1D4ED8),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              mapsUrl!,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF1D4ED8),
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.open_in_new_rounded,
                            size: 14,
                            color: Color(0xFF1D4ED8),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),
          const Text(
            'PILIH APLIKASI TUJUAN',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.textMuted,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),

          // 1. Gojek Button
          _AppDispatchTile(
            title: 'Teruskan ke Gojek',
            subtitle: 'Buka Gojek (GoSend / Ride) & salin alamat otomatis',
            badgeText: 'GoSend / Ojol',
            badgeColor: const Color(0xFF00AA13),
            icon: Icons.two_wheeler_rounded,
            accentColor: const Color(0xFF00880C),
            onTap: () {
              Navigator.of(context).pop();
              DeliveryDispatchHelper.openGojek(
                address: cleanAddr,
                mapsUrl: mapsUrl,
              );
            },
          ),
          const SizedBox(height: 8),

          // 2. Maxim Button
          _AppDispatchTile(
            title: 'Teruskan ke Maxim',
            subtitle: 'Buka Maxim (Delivery / Ojol) & salin alamat otomatis',
            badgeText: 'Maxim',
            badgeColor: const Color(0xFFF59E0B),
            icon: Icons.local_taxi_rounded,
            accentColor: const Color(0xFFD97706),
            onTap: () {
              Navigator.of(context).pop();
              DeliveryDispatchHelper.openMaxim(
                address: cleanAddr,
                mapsUrl: mapsUrl,
              );
            },
          ),
          const SizedBox(height: 8),

          // 3. Google Maps Button
          _AppDispatchTile(
            title: 'Buka di Google Maps',
            subtitle: 'Buka rute navigasi & detail titik pin peta',
            badgeText: 'Peta',
            badgeColor: const Color(0xFF2563EB),
            icon: Icons.map_rounded,
            accentColor: const Color(0xFF1D4ED8),
            onTap: () {
              Navigator.of(context).pop();
              DeliveryDispatchHelper.openGoogleMaps(
                url: mapsUrl,
                address: cleanAddr,
              );
            },
          ),
          const SizedBox(height: 8),

          // 4. Copy Details
          _AppDispatchTile(
            title: 'Salin Alamat & Link',
            subtitle: 'Salin rincian lengkap untuk dikirim manual ke kurir/driver',
            badgeText: 'Salin',
            badgeColor: const Color(0xFF64748B),
            icon: Icons.copy_rounded,
            accentColor: const Color(0xFF475569),
            onTap: () {
              DeliveryDispatchHelper.copyDeliveryInfo(
                order: order,
                address: cleanAddr,
                mapsUrl: mapsUrl,
              );
            },
          ),

          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class _AppDispatchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String badgeText;
  final Color badgeColor;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;

  const _AppDispatchTile({
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.badgeColor,
    required this.icon,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accentColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: badgeColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
