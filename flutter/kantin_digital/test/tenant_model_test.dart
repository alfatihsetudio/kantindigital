import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kantin_digital/shared/models/tenant_model.dart';
import 'package:kantin_digital/shared/services/demo_session_manager.dart';
import 'package:kantin_digital/shared/utils/store_opening_hours.dart';

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

  test('reads and serializes store opening hours', () {
    final tenant = TenantModel.fromJson({
      'id': 1,
      'subdomain': 'saycoffee',
      'name': 'SAY COFFEE',
      'opening_hours': 'Senin-Sabtu, 08:00 - 22:00',
      'is_store_open': true,
    });

    expect(tenant.openingHours, 'Senin-Sabtu, 08:00 - 22:00');
    expect(tenant.toJson()['opening_hours'], 'Senin-Sabtu, 08:00 - 22:00');
    expect(tenant.isStoreOpen, isTrue);
    expect(tenant.toJson()['is_store_open'], isTrue);
  });

  test('evaluates daily opening hours in WIB and closes at closing time', () {
    const hours = '08:00 - 22:00';

    expect(
      StoreOpeningHours.isOpenAt(hours, DateTime.utc(2026, 10, 5, 1, 0)),
      isTrue,
    );
    expect(
      StoreOpeningHours.isOpenAt(hours, DateTime.utc(2026, 10, 5, 15, 0)),
      isFalse,
    );
  });

  test('evaluates day-specific hours and closed weekdays', () {
    const hours = 'Senin-Sabtu 08:00-22:00; Minggu tutup';

    expect(
      StoreOpeningHours.isOpenAt(hours, DateTime.utc(2026, 10, 5, 1, 0)),
      isTrue,
    );
    expect(
      StoreOpeningHours.isOpenAt(hours, DateTime.utc(2026, 10, 4, 1, 0)),
      isFalse,
    );
    expect(
      StoreOpeningHours.isValid('Senin-Sabtu 08:00-22:00; Minggu tutup'),
      isTrue,
    );
    expect(StoreOpeningHours.isValid('jam bebas'), isFalse);
  });

  test('demo profile save retains customized opening hours', () {
    addTearDown(() {
      DemoSessionManager.disableDemoMode();
      DemoSessionManager.resetDemoData();
    });

    DemoSessionManager.enableDemoMode();
    DemoSessionManager.updateTenantProfile({
      'opening_hours': 'Senin-Sabtu, 08:00 - 22:00',
    });

    expect(
      DemoSessionManager.demoTenant.openingHours,
      'Senin-Sabtu, 08:00 - 22:00',
    );
  });

  test('demo staff can toggle the store open status', () {
    addTearDown(() {
      DemoSessionManager.disableDemoMode();
      DemoSessionManager.resetDemoData();
    });

    DemoSessionManager.enableDemoMode();
    DemoSessionManager.updateStoreOpenStatus(true);
    expect(DemoSessionManager.demoTenant.isStoreOpen, isTrue);

    DemoSessionManager.updateStoreOpenStatus(false);
    expect(DemoSessionManager.demoTenant.isStoreOpen, isFalse);
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
