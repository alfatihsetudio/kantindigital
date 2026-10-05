import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kantin_digital/shared/models/tenant_model.dart';
import 'package:kantin_digital/shared/services/demo_session_manager.dart';

void main() {
  group('TenantModel promo settings', () {
    test('uses existing promo copy when the API has no promo fields', () {
      final tenant = TenantModel.fromJson({
        'id': 1,
        'subdomain': 'saycoffee',
        'name': 'SAY COFFEE',
      });

      expect(tenant.promoBadgeText, 'Promo Hari Ini');
      expect(tenant.promoMessage, 'Pesan Sekarang, Nikmati Kemudahannya!');
    });

    test('reads and serializes customized promo copy', () {
      final tenant = TenantModel.fromJson({
        'id': 1,
        'subdomain': 'saycoffee',
        'name': 'SAY COFFEE',
        'promo_badge_text': 'Diskon Akhir Pekan',
        'promo_message': 'Beli 2 gratis 1!',
      });

      expect(tenant.promoBadgeText, 'Diskon Akhir Pekan');
      expect(tenant.promoMessage, 'Beli 2 gratis 1!');
      expect(tenant.toJson()['promo_badge_text'], 'Diskon Akhir Pekan');
      expect(tenant.toJson()['promo_message'], 'Beli 2 gratis 1!');
    });
  });

  test('demo profile save retains customized promo copy', () {
    addTearDown(() {
      DemoSessionManager.disableDemoMode();
      DemoSessionManager.resetDemoData();
    });

    DemoSessionManager.enableDemoMode();
    DemoSessionManager.updateTenantProfile({
      'promo_badge_text': 'Diskon Akhir Pekan',
      'promo_message': 'Beli 2 gratis 1!',
    });

    expect(DemoSessionManager.demoTenant.promoBadgeText, 'Diskon Akhir Pekan');
    expect(DemoSessionManager.demoTenant.promoMessage, 'Beli 2 gratis 1!');
  });

  test('demo profile save retains uploaded logo data', () {
    addTearDown(() {
      DemoSessionManager.disableDemoMode();
      DemoSessionManager.resetDemoData();
    });

    DemoSessionManager.enableDemoMode();
    const logoData = 'data:image/jpeg;base64,AQID';
    DemoSessionManager.updateTenantProfile({'logo_data_url': logoData});

    expect(DemoSessionManager.demoTenant.logoUrl, logoData);
    expect(
      tenantLogoImageProvider(DemoSessionManager.demoTenant.logoUrl),
      isA<MemoryImage>(),
    );
  });
}
