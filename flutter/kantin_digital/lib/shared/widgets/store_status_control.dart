import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/top_notification.dart';
import '../models/tenant_model.dart';
import '../services/demo_session_manager.dart';
import '../services/tenant_service.dart';

class StoreStatusControl extends StatefulWidget {
  const StoreStatusControl({super.key});

  @override
  State<StoreStatusControl> createState() => _StoreStatusControlState();
}

class _StoreStatusControlState extends State<StoreStatusControl> {
  TenantModel? _tenant;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final tenant = await TenantService.fetchTenantInfo(forceRefresh: true);
    if (mounted) setState(() => _tenant = tenant);
  }

  Future<void> _setStoreStatus(bool isOpen) async {
    if (_isUpdating) return;
    setState(() => _isUpdating = true);
    try {
      await ApiClient().post(
        '/tenant/store-status',
        body: {'is_store_open': isOpen},
      );
      TenantService.clearCache();
      final tenant = await TenantService.fetchTenantInfo(forceRefresh: true);
      if (!mounted) return;
      setState(() => _tenant = tenant);
      TopNotification.show(
        message: isOpen ? 'Toko berhasil dibuka.' : 'Toko berhasil ditutup.',
        backgroundColor: AppColors.success,
        icon: isOpen ? Icons.storefront_rounded : Icons.store_rounded,
      );
    } catch (error) {
      if (!mounted) return;
      TopNotification.show(
        message: 'Status toko gagal diubah: $error',
        backgroundColor: AppColors.danger,
        icon: Icons.error_rounded,
      );
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tenant = _tenant;
    if (tenant == null) {
      return const ListTile(
        leading: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        title: Text('Memuat status toko...'),
      );
    }

    final scheduleOpen = tenant.isOpenAt(DateTime.now().toUtc()) == true;
    final isOpen = tenant.isStoreOpen;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isOpen
            ? AppColors.success.withValues(alpha: 0.08)
            : AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isOpen
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.warning.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        children: [
          ListTile(
            dense: true,
            leading: Icon(
              isOpen
                  ? Icons.storefront_rounded
                  : Icons.store_mall_directory_outlined,
              color: isOpen ? AppColors.success : AppColors.warning,
            ),
            title: Text(
              isOpen ? 'Toko sedang buka' : 'Toko sedang tutup',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text('Jadwal operasional: ${tenant.openingHours}'),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isUpdating
                    ? null
                    : () => _setStoreStatus(!tenant.isStoreOpen),
                icon: _isUpdating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        isOpen ? Icons.store_rounded : Icons.storefront_rounded,
                      ),
                style: isOpen
                    ? FilledButton.styleFrom(
                        backgroundColor: AppColors.danger,
                        foregroundColor: Colors.white,
                      )
                    : null,
                label: Text(
                  _isUpdating
                      ? 'Menyimpan...'
                      : (isOpen ? 'Tutup Toko' : 'Buka Toko'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
