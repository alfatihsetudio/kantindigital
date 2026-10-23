import 'package:flutter/material.dart';
import '../auth/auth_session.dart';
import '../models/tenant_model.dart';
import '../services/tenant_service.dart';

/// InheritedWidget yang menyimpan data tenant aktif
/// Diakses dari mana saja dengan: TenantProvider.of(context)
class TenantProvider extends InheritedWidget {
  final TenantModel tenant;

  const TenantProvider({
    super.key,
    required this.tenant,
    required super.child,
  });

  static TenantModel of(BuildContext context) {
    final authTenant = AuthSession().tenant;
    if (authTenant != null &&
        authTenant.id != 0 &&
        authTenant.name.isNotEmpty) {
      return authTenant;
    }
    final provider =
        context.dependOnInheritedWidgetOfExactType<TenantProvider>();
    return provider?.tenant ?? TenantService.current;
  }

  @override
  bool updateShouldNotify(TenantProvider oldWidget) {
    return oldWidget.tenant.id != tenant.id ||
        oldWidget.tenant.primaryColor != tenant.primaryColor ||
        oldWidget.tenant.name != tenant.name ||
        oldWidget.tenant.openingHours != tenant.openingHours ||
        oldWidget.tenant.isStoreOpen != tenant.isStoreOpen ||
        oldWidget.tenant.promoBadgeText != tenant.promoBadgeText ||
        oldWidget.tenant.promoMessage != tenant.promoMessage ||
        oldWidget.tenant.orderNotificationSound != tenant.orderNotificationSound ||
        oldWidget.tenant.isTablesActive != tenant.isTablesActive;
  }
}

/// Widget yang me-load tenant saat startup dan membungkus seluruh app
class TenantLoader extends StatefulWidget {
  final Widget Function(TenantModel tenant) builder;

  const TenantLoader({super.key, required this.builder});

  @override
  State<TenantLoader> createState() => _TenantLoaderState();
}

class _TenantLoaderState extends State<TenantLoader> {
  TenantModel? _tenant;

  @override
  void initState() {
    super.initState();
    AuthSession().addListener(_onAuthSessionChanged);
    _loadTenant();
  }

  @override
  void dispose() {
    AuthSession().removeListener(_onAuthSessionChanged);
    super.dispose();
  }

  void _onAuthSessionChanged() {
    final authTenant = AuthSession().tenant;
    if (authTenant != null &&
        authTenant.id != 0 &&
        authTenant.name.isNotEmpty) {
      if (mounted && _tenant?.id != authTenant.id) {
        setState(() => _tenant = authTenant);
      }
    }
  }

  Future<void> _loadTenant() async {
    final authTenant = AuthSession().tenant;
    if (authTenant != null &&
        authTenant.id != 0 &&
        authTenant.name.isNotEmpty) {
      if (mounted) setState(() => _tenant = authTenant);
      return;
    }
    final tenant = await TenantService.fetchTenantInfo();
    if (mounted) {
      setState(() => _tenant = tenant);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_tenant == null) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Memuat data...', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ),
      );
    }

    return TenantProvider(
      tenant: _tenant!,
      child: widget.builder(_tenant!),
    );
  }
}
