import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kantin_digital/shared/models/tenant_model.dart';
import 'package:kantin_digital/shared/services/demo_session_manager.dart';
import 'package:kantin_digital/shared/utils/store_opening_hours.dart';
import 'package:kantin_digital/shared/utils/promo_discount_calculator.dart';
import 'package:kantin_digital/shared/models/cart_item_model.dart';
import 'package:kantin_digital/shared/models/menu_model.dart';

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

  test('reads promo discount scope and selected menus', () {
    final tenant = TenantModel.fromJson({
      'id': 1,
      'subdomain': 'saycoffee',
      'name': 'SAY COFFEE',
      'promo_discount_percent': 20,
      'promo_scope': 'selected',
      'promo_menu_ids': [3, 8],
    });

    expect(tenant.promoDiscountPercent, 20);
    expect(tenant.promoScope, 'selected');
    expect(tenant.promoMenuIds, [3, 8]);
    expect(tenant.toJson()['promo_menu_ids'], [3, 8]);
    expect(tenant.hasPromo, isTrue);

    final zeroPromoTenant = TenantModel.fromJson({
      'id': 1,
      'subdomain': 'saycoffee',
      'name': 'SAY COFFEE',
      'promo_discount_percent': 0,
    });
    expect(zeroPromoTenant.hasPromo, isFalse);
  });

  test('promo calculator discounts all menus or only selected menu ids', () {
    final items = [
      CartItemModel(
        menu: const MenuModel(
          id: 3,
          name: 'Menu A',
          categoryName: 'Kopi',
          price: 5000,
        ),
        quantity: 2,
      ),
      CartItemModel(
        menu: const MenuModel(
          id: 8,
          name: 'Menu B',
          categoryName: 'Kopi',
          price: 3000,
        ),
        quantity: 1,
      ),
    ];

    expect(
      PromoDiscountCalculator.calculate(
        items: items,
        percent: 10,
        appliesToAllMenus: true,
        menuIds: {},
      ),
      1300,
    );
    expect(
      PromoDiscountCalculator.calculate(
        items: items,
        percent: 10,
        appliesToAllMenus: false,
        menuIds: {3},
      ),
      1000,
    );
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

  test('updated daily closing time is interpreted in WIB', () {
    const hours = 'Setiap hari, 09:30 - 23:00';

    expect(StoreOpeningHours.isValid(hours), isTrue);
    expect(
      StoreOpeningHours.isOpenAt(hours, DateTime.utc(2026, 10, 5, 15, 59)),
      isTrue,
    );
    expect(
      StoreOpeningHours.isOpenAt(hours, DateTime.utc(2026, 10, 5, 16, 0)),
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

  test('evaluates day-specific hours, off days, and polite closed messages', () {
    const hours = 'Senin-Sabtu 08:00-22:00; Minggu tutup';

    final monday8Am = DateTime.utc(2026, 10, 5, 1, 0);
    final sunday8Am = DateTime.utc(2026, 10, 4, 1, 0);
    final monday6Am = DateTime.utc(2026, 10, 4, 23, 0);
    final monday11Pm = DateTime.utc(2026, 10, 5, 16, 0);

    expect(StoreOpeningHours.isTodayOffDay(hours, sunday8Am), isTrue);
    expect(StoreOpeningHours.isTodayOffDay(hours, monday8Am), isFalse);

    // Case 1: Operasional time, but staff belum buka (permintaan maaf halus)
    final apologyStatus = StoreOpeningHours.getClosedStatus(
      openingHours: hours,
      scheduleOpen: true,
      staffHasOpened: false,
      utcInstant: monday8Am,
    );
    expect(apologyStatus.isPoliteApology, isTrue);
    expect(apologyStatus.title, contains('Mohon Maaf'));
    expect(apologyStatus.message, contains('kendala operasional'));

    // Case 2: Hari Libur (Minggu)
    final offDayStatus = StoreOpeningHours.getClosedStatus(
      openingHours: hours,
      scheduleOpen: false,
      staffHasOpened: false,
      utcInstant: sunday8Am,
    );
    expect(offDayStatus.title, contains('Libur'));
    expect(offDayStatus.message, contains('libur operasional'));

    // Case 3: Sebelum buka
    final beforeOpenStatus = StoreOpeningHours.getClosedStatus(
      openingHours: hours,
      scheduleOpen: false,
      staffHasOpened: false,
      utcInstant: monday6Am,
    );
    expect(beforeOpenStatus.title, 'Toko Belum Buka');
    expect(beforeOpenStatus.message, contains('08:00'));

    // Case 4: Setelah tutup
    final afterCloseStatus = StoreOpeningHours.getClosedStatus(
      openingHours: hours,
      scheduleOpen: false,
      staffHasOpened: false,
      utcInstant: monday11Pm,
    );
    expect(afterCloseStatus.title, 'Toko Sudah Tutup');
  });

  test('flexible day picker extracts open days and formats schedule correctly', () {
    expect(
      StoreOpeningHours.getOpenDays('Setiap hari, 10:00 - 21:00'),
      {1, 2, 3, 4, 5, 6, 7},
    );
    expect(
      StoreOpeningHours.getOpenDays('Senin - Sabtu, 10:00 - 21:00; Minggu Tutup'),
      {1, 2, 3, 4, 5, 6},
    );

    // 1. All days open
    expect(
      StoreOpeningHours.formatScheduleFromOpenDays(
        openDays: {1, 2, 3, 4, 5, 6, 7},
        openTime: '10:00',
        closeTime: '21:00',
      ),
      'Setiap hari, 10:00 - 21:00',
    );

    // 2. Sunday off
    expect(
      StoreOpeningHours.formatScheduleFromOpenDays(
        openDays: {1, 2, 3, 4, 5, 6},
        openTime: '10:00',
        closeTime: '21:00',
      ),
      'Senin - Sabtu, 10:00 - 21:00; Minggu Tutup',
    );

    // 3. Custom: e.g. Thursday off (dadakan)
    final scheduleWithThursdayOff = StoreOpeningHours.formatScheduleFromOpenDays(
      openDays: {1, 2, 3, 5, 6, 7},
      openTime: '10:00',
      closeTime: '21:00',
    );
    expect(scheduleWithThursdayOff, contains('Kamis Tutup'));
    expect(StoreOpeningHours.isValid(scheduleWithThursdayOff), isTrue);

    // 4. Custom: multiple days off (e.g. Wednesday & Sunday off)
    final scheduleWedSunOff = StoreOpeningHours.formatScheduleFromOpenDays(
      openDays: {1, 2, 4, 5, 6},
      openTime: '10:00',
      closeTime: '21:00',
    );
    expect(StoreOpeningHours.isValid(scheduleWedSunOff), isTrue);
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

  test('MenuModel parses topping_ids and indicates whether toppings are available', () {
    final menuWithToppings = MenuModel.fromJson({
      'id': 1,
      'name': 'Kopi Susu',
      'category_name': 'Kopi',
      'price': 15000,
      'topping_ids': [10, 11],
    });
    final menuWithoutToppings = MenuModel.fromJson({
      'id': 2,
      'name': 'Say Aren',
      'category_name': 'Kopi',
      'price': 18000,
      'topping_ids': [],
    });

    expect(menuWithToppings.toppingIds, [10, 11]);
    expect(menuWithToppings.toppingIds.isNotEmpty, isTrue);

    expect(menuWithoutToppings.toppingIds, isEmpty);
    expect(menuWithoutToppings.toppingIds.isNotEmpty, isFalse);
  });
}

