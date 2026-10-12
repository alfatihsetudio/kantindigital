import 'package:flutter/foundation.dart';

import '../constants/order_status.dart';
import '../constants/payment_method.dart';
import '../constants/user_role.dart';
import '../models/category_model.dart';
import '../models/menu_model.dart';
import '../models/order_item_model.dart';
import '../models/order_item_topping_model.dart';
import '../models/order_model.dart';
import '../models/payment_model.dart';
import '../models/qris_setting_model.dart';
import '../models/table_model.dart';
import '../models/tenant_model.dart';
import '../models/topping_model.dart';
import '../models/user_model.dart';
import '../models/cashier_order_model.dart';
import '../models/cart_item_model.dart';
import '../utils/promo_discount_calculator.dart';

import 'tenant_service.dart';
import 'voucher_service.dart';

/// Manajer Sesi Demo Terisolasi (Local Browser Sandbox)
/// Setiap calon pembeli website memiliki ruang simulasi mandiri di browsernya:
/// - Menyimpan data order lokal (tidak terlihat oleh orang lain)
/// - Menghubungkan Customer Self-Order dengan Kasir & Manager di browser yang sama
/// - Menyediakan kredensial login demo (Kasir, Admin, Manager, Operasional)
/// - Mengelola data CRUD lokal untuk Kategori, Menu, Topping, Meja, Staff/User, & Pengaturan Toko
class DemoSessionManager {
  DemoSessionManager._();
  static final DemoSessionManager instance = DemoSessionManager._();

  static bool _isDemoMode = false;
  static bool get isDemoMode => _isDemoMode;

  static void enableDemoMode() {
    _isDemoMode = true;
    TenantService.setDemoSubdomain('demo');
    _initInitialData();
  }

  static void disableDemoMode() {
    _isDemoMode = false;
    TenantService.clearDemoSubdomain();
  }

  // ── TENANT DEMO ──
  static const TenantModel _initialTenant = TenantModel(
    id: 999,
    subdomain: 'demo',
    name: 'DEMO RESTO & CAFE',
    primaryColor: '#2563EB',
    address: 'Kawasan Bisnis Demo No. 88, Jakarta',
    openingHours: '08:00 - 22:00',
    isStoreOpen: false,
    phone: '081234567890',
    whatsapp: '6287771262100',
    plan: 'pro',
    isActive: true,
    metaTitle: 'Demo eKasir - Self Order & POS Resto',
    metaDescription: 'Simulasi Sistem Pemesanan Mandiri & Kasir POS',
    menuCodePrefix: 'DEMO',
  );

  static TenantModel demoTenant = _initialTenant;

  static void updateTenantProfile(Map<String, dynamic> data) {
    demoTenant = TenantModel(
      id: 999,
      subdomain: 'demo',
      name: data['name']?.toString() ?? demoTenant.name,
      logoUrl:
          data['logo_data_url']?.toString() ??
          data['logo_url']?.toString() ??
          demoTenant.logoUrl,
      primaryColor:
          data['primary_color']?.toString() ?? demoTenant.primaryColor,
      address: data['address']?.toString() ?? demoTenant.address,
      openingHours:
          data['opening_hours']?.toString() ?? demoTenant.openingHours,
      isStoreOpen: data['is_store_open'] == null
          ? demoTenant.isStoreOpen
          : data['is_store_open'] == true || data['is_store_open'] == 'true',
      phone: data['phone']?.toString() ?? demoTenant.phone,
      whatsapp: data['whatsapp']?.toString() ?? demoTenant.whatsapp,
      plan: demoTenant.plan,
      isActive: true,
      metaTitle: data['meta_title']?.toString() ?? demoTenant.metaTitle,
      metaDescription:
          data['meta_description']?.toString() ?? demoTenant.metaDescription,
      metaImageUrl:
          data['meta_image_data_url']?.toString() ??
          data['meta_image']?.toString() ??
          data['meta_image_url']?.toString() ??
          demoTenant.metaImageUrl,
      menuCodePrefix:
          data['menu_code_prefix']?.toString() ?? demoTenant.menuCodePrefix,
      promoBadgeText:
          data['promo_badge_text']?.toString() ?? demoTenant.promoBadgeText,
      promoMessage:
          data['promo_message']?.toString() ?? demoTenant.promoMessage,
      promoDiscountPercent:
          int.tryParse(data['promo_discount_percent']?.toString() ?? '') ??
          demoTenant.promoDiscountPercent,
      promoScope: data['promo_scope']?.toString() ?? demoTenant.promoScope,
      promoMenuIds: data['promo_menu_ids'] is List
          ? (data['promo_menu_ids'] as List)
                .map((id) => int.tryParse(id.toString()) ?? 0)
                .where((id) => id > 0)
                .toList()
          : demoTenant.promoMenuIds,
      promoPaymentMethods: data['promo_payment_methods'] is List
          ? (data['promo_payment_methods'] as List)
                .map((method) => method.toString().toLowerCase().trim())
                .where((method) => method.isNotEmpty)
                .toList()
          : demoTenant.promoPaymentMethods,
    );
    TenantService.clearCache();
  }

  static void updateStoreOpenStatus(bool isOpen) {
    updateTenantProfile({'is_store_open': isOpen});
  }

  // ── KREDENSIAL DEMO TERDAFTAR ──
  static const List<DemoCredential> demoCredentials = [
    DemoCredential(
      roleName: 'Kasir (POS Kasir)',
      email: 'cashier@gmail.com',
      password: 'admin123',
      role: UserRole.cashier,
      description: 'Terima order dari meja, proses bayar, & cetak struk.',
      badgeColor: 0xFF16A34A,
    ),
    DemoCredential(
      roleName: 'Admin / Pemilik Usaha',
      email: 'admin@gmail.com',
      password: 'admin123',
      role: UserRole.admin,
      description:
          'Kelola daftar menu, harga, nomor meja, QRIS, & pengaturan toko.',
      badgeColor: 0xFF2563EB,
    ),
    DemoCredential(
      roleName: 'Pimpinan / Manager',
      email: 'manager@gmail.com',
      password: 'admin123',
      role: UserRole.manager,
      description:
          'Pantau grafik omzet penjualan realtime, laba harian, & produk terlaris.',
      badgeColor: 0xFF9333EA,
    ),
    DemoCredential(
      roleName: 'Operasional / Dapur',
      email: 'operasional@gmail.com',
      password: 'admin123',
      role: UserRole.operations,
      description: 'Layar pantau pesanan dapur / barista untuk segera dimasak.',
      badgeColor: 0xFFEA580C,
    ),
  ];

  // ── KATEGORI DEMO ──
  static final List<CategoryModel> _initialCategories = [
    const CategoryModel(id: 1, name: 'Makanan', isActive: true),
    const CategoryModel(id: 2, name: 'Kopi', isActive: true),
    const CategoryModel(id: 3, name: 'Non Kopi', isActive: true),
    const CategoryModel(id: 4, name: 'Snack & Dessert', isActive: true),
  ];

  static List<CategoryModel> demoCategories = List.from(_initialCategories);
  static int _categorySequence = 5;

  static List<CategoryModel> getCategories() {
    return List.unmodifiable(demoCategories);
  }

  static CategoryModel createCategory(String name) {
    final cleanName = name.trim();
    final newCat = CategoryModel(
      id: _categorySequence++,
      name: cleanName.isNotEmpty ? cleanName : 'Kategori Baru',
      isActive: true,
    );
    demoCategories.add(newCat);
    return newCat;
  }

  static CategoryModel updateCategory(int id, String name) {
    final idx = demoCategories.indexWhere((c) => c.id == id);
    if (idx != -1) {
      final updated = demoCategories[idx].copyWith(name: name.trim());
      demoCategories[idx] = updated;
      return updated;
    }
    return CategoryModel(id: id, name: name.trim(), isActive: true);
  }

  static CategoryModel toggleCategory(int id) {
    final idx = demoCategories.indexWhere((c) => c.id == id);
    if (idx != -1) {
      final old = demoCategories[idx];
      final updated = old.copyWith(isActive: !old.isActive);
      demoCategories[idx] = updated;
      return updated;
    }
    return CategoryModel(id: id, name: '', isActive: true);
  }

  static void deleteCategory(int id) {
    demoCategories.removeWhere((c) => c.id == id);
  }

  // ── DAFTAR MAKANAN & MINUMAN DEMO ──
  static final List<MenuModel> _initialMenus = [
    // ── MAKANAN ──
    const MenuModel(
      id: 101,
      code: 'DEMO-01',
      name: 'Nasi Goreng Wagyu Spesial',
      categoryName: 'Makanan',
      price: 38000,
      imageUrl:
          'https://images.unsplash.com/photo-1603133872878-684f208fb84b?auto=format&fit=crop&w=600&q=80',
      description:
          'Nasi goreng harum rempah nusantara dengan potongan wagyu empuk, telur mata sapi, dan acar segar.',
      isAvailable: true,
    ),
    const MenuModel(
      id: 102,
      code: 'DEMO-02',
      name: 'Smash Cheeseburger & Crispy Fries',
      categoryName: 'Makanan',
      price: 35000,
      imageUrl:
          'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&w=600&q=80',
      description:
          '100% daging sapi Australia juicy dengan double cheddar cheese lumer, saus spesial, dan selada renyah.',
      isAvailable: true,
    ),
    const MenuModel(
      id: 103,
      code: 'DEMO-03',
      name: 'Beef Ramen Shoyu Komplit',
      categoryName: 'Makanan',
      price: 42000,
      imageUrl:
          'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?auto=format&fit=crop&w=600&q=80',
      description:
          'Mie kenyal kuah kaldu shoyu autentik dengan topping chashu beef lembut, ajitsuke tamago, nori, dan daun bawang.',
      isAvailable: true,
    ),
    const MenuModel(
      id: 104,
      code: 'DEMO-04',
      name: 'Spaghetti Creamy Carbonara',
      categoryName: 'Makanan',
      price: 34000,
      imageUrl:
          'https://images.unsplash.com/photo-1612874742237-6526221588e3?auto=format&fit=crop&w=600&q=80',
      description:
          'Pasta al dente berpadu saus keju parmesan gurih, potongan smoked beef tebal, dan taburan parsley harum.',
      isAvailable: true,
    ),
    const MenuModel(
      id: 105,
      code: 'DEMO-05',
      name: 'Crispy Golden Fried Chicken Sambal Matah',
      categoryName: 'Makanan',
      price: 28000,
      imageUrl:
          'https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec?auto=format&fit=crop&w=600&q=80',
      description:
          'Ayam goreng keemasan super renyah di luar juicy di dalam, disajikan dengan racikan sambal matah Bali segar.',
      isAvailable: true,
    ),
    const MenuModel(
      id: 106,
      code: 'DEMO-06',
      name: 'Pizza Margherita Napolitana (Personal)',
      categoryName: 'Makanan',
      price: 45000,
      imageUrl:
          'https://images.unsplash.com/photo-1604382355076-af4b0eb60143?auto=format&fit=crop&w=600&q=80',
      description:
          'Adonan tipis berkerak renyah dipanggang dengan saus tomat pomodoro, keju mozzarella mulur, dan daun basil segar.',
      isAvailable: true,
    ),

    // ── KOPI ──
    const MenuModel(
      id: 201,
      code: 'DEMO-07',
      name: 'Iced Kopi Susu Gula Aren Spesial',
      categoryName: 'Kopi',
      price: 18000,
      imageUrl:
          'https://images.unsplash.com/photo-1517701550927-30cf4ba1dba5?auto=format&fit=crop&w=600&q=80',
      description:
          'Espresso house blend arabica dipadukan susu creamy dingin dan legitnya gula aren organik pilihan.',
      isAvailable: true,
    ),
    const MenuModel(
      id: 202,
      code: 'DEMO-08',
      name: 'Caramel Macchiato Double Shot',
      categoryName: 'Kopi',
      price: 24000,
      imageUrl:
          'https://images.unsplash.com/photo-1485808191679-5f86510681a2?auto=format&fit=crop&w=600&q=80',
      description:
          'Kombinasi vanila segar, susu berbusa lembut, double shot espresso, dan topping saus karamel lezat.',
      isAvailable: true,
    ),
    const MenuModel(
      id: 203,
      code: 'DEMO-09',
      name: 'Kyoto Matcha Espresso Fusion',
      categoryName: 'Kopi',
      price: 25000,
      imageUrl:
          'https://images.unsplash.com/photo-1536256263959-770b48d82b0a?auto=format&fit=crop&w=600&q=80',
      description:
          'Lapisan cantik matcha murni Uji Kyoto Jepang berpadu espresso harum dan fresh milk dingin.',
      isAvailable: true,
    ),
    const MenuModel(
      id: 204,
      code: 'DEMO-10',
      name: 'Americano Classic Cold Brew',
      categoryName: 'Kopi',
      price: 16000,
      imageUrl:
          'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?auto=format&fit=crop&w=600&q=80',
      description:
          'Kopi hitam cold brew segar tanpa ampas dengan aroma bunga dan hint citrus yang membangkitkan fokus.',
      isAvailable: true,
    ),

    // ── NON KOPI ──
    const MenuModel(
      id: 301,
      code: 'DEMO-11',
      name: 'Signature Dark Chocolate Fudge',
      categoryName: 'Non Kopi',
      price: 22000,
      imageUrl:
          'https://images.unsplash.com/photo-1542990253-0d0f5be5f0ed?auto=format&fit=crop&w=600&q=80',
      description:
          'Cokelat Belgia pekat kaya rasa berpadu susu segar dingin, nikmat, manis pas, dan tidak bikin eneg.',
      isAvailable: true,
    ),
    const MenuModel(
      id: 302,
      code: 'DEMO-12',
      name: 'Brown Sugar Boba Fresh Milk',
      categoryName: 'Non Kopi',
      price: 20000,
      imageUrl:
          'https://images.unsplash.com/photo-1558857563-b371033873b8?auto=format&fit=crop&w=600&q=80',
      description:
          'Susu sapi murni dingin berpadu mutiara boba tapioka kenyal hangat berbalut sirup gula aren kental.',
      isAvailable: true,
    ),
    const MenuModel(
      id: 303,
      code: 'DEMO-13',
      name: 'Fresh Berry Mojito Sparkle',
      categoryName: 'Non Kopi',
      price: 18000,
      imageUrl:
          'https://images.unsplash.com/photo-1513558161293-cdaf765ed2fd?auto=format&fit=crop&w=600&q=80',
      description:
          'Soda dingin menyegarkan dengan perasan jeruk nipis asli, daun mint segar, dan sirup buah strawberry.',
      isAvailable: true,
    ),

    // ── SNACK & DESSERT ──
    const MenuModel(
      id: 401,
      code: 'DEMO-14',
      name: 'Truffle French Fries with Cheese Mayo',
      categoryName: 'Snack & Dessert',
      price: 18000,
      imageUrl:
          'https://images.unsplash.com/photo-1576107232684-1279f3908594?auto=format&fit=crop&w=600&q=80',
      description:
          'Kentang goreng impor garing harum aroma minyak truffle, disajikan dengan cocolan keju mayo gurih.',
      isAvailable: true,
    ),
    const MenuModel(
      id: 402,
      code: 'DEMO-15',
      name: 'Dimsum Ayam Mentai Mozzarella (4 pcs)',
      categoryName: 'Snack & Dessert',
      price: 22000,
      imageUrl:
          'https://images.unsplash.com/photo-1496116218417-1a781b1c416c?auto=format&fit=crop&w=600&q=80',
      description:
          'Siomay paha ayam tebal juicy dilapisi saus mentai gurih manis dan keju mozzarella yang dibakar harum.',
      isAvailable: true,
    ),
    const MenuModel(
      id: 403,
      code: 'DEMO-16',
      name: 'Warm Butter Croissant Flaky',
      categoryName: 'Snack & Dessert',
      price: 16000,
      imageUrl:
          'https://images.unsplash.com/photo-1555507036-ab1f4038808a?auto=format&fit=crop&w=600&q=80',
      description:
          'Pastry Perancis berlapis-lapis renyah dengan wangi butter premium yang meleleh di mulut.',
      isAvailable: true,
    ),
    const MenuModel(
      id: 404,
      code: 'DEMO-17',
      name: 'Red Velvet Cheesecake Slice',
      categoryName: 'Snack & Dessert',
      price: 25000,
      imageUrl:
          'https://images.unsplash.com/photo-1586788680434-30d324b2d46f?auto=format&fit=crop&w=600&q=80',
      description:
          'Sponge cake red velvet lembut berpadu krim keju tebal gurih manis yang lumer di lidah.',
      isAvailable: true,
    ),
  ];

  static List<MenuModel> demoMenus = List.from(_initialMenus);
  static int _menuSequence = 501;

  static List<MenuModel> getMenus() {
    return List.unmodifiable(demoMenus);
  }

  static MenuModel createMenu(Map<String, dynamic> data) {
    final newId = _menuSequence++;
    final newMenu = MenuModel(
      id: newId,
      code: data['code']?.toString() ?? 'DEMO-$newId',
      name: (data['name'] ?? '').toString(),
      categoryName:
          (data['category_name'] ??
                  (data['category_id'] != null
                      ? _resolveCategoryName(data['category_id'])
                      : 'Makanan'))
              .toString(),
      price: int.tryParse(data['price']?.toString() ?? '0') ?? 0,
      imageUrl:
          data['image_url']?.toString() ??
          'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=600&q=80',
      description: data['description']?.toString() ?? '',
      isAvailable:
          data['is_available'] == true ||
          data['is_available'] == 1 ||
          data['is_available'] == '1',
      noteOptions: _parseMenuNoteOptions(data['note_options']),
      toppingIds: _parseMenuToppingIds(data['topping_ids']),
    );
    demoMenus.add(newMenu);
    return newMenu;
  }

  static MenuModel updateMenu(int id, Map<String, dynamic> data) {
    final idx = demoMenus.indexWhere((m) => m.id == id);
    if (idx != -1) {
      final old = demoMenus[idx];
      final updated = MenuModel(
        id: old.id,
        code: data['code']?.toString() ?? old.code,
        name: data['name']?.toString() ?? old.name,
        categoryName:
            data['category_name']?.toString() ??
            (data['category_id'] != null
                ? _resolveCategoryName(data['category_id'])
                : old.categoryName),
        price: int.tryParse(data['price']?.toString() ?? '') ?? old.price,
        imageUrl: data['image_url']?.toString() ?? old.imageUrl,
        description: data['description']?.toString() ?? old.description,
        isAvailable: data['is_available'] != null
            ? (data['is_available'] == true ||
                  data['is_available'] == 1 ||
                  data['is_available'] == '1')
            : old.isAvailable,
        noteOptions: data['note_options'] == null
            ? old.noteOptions
            : _parseMenuNoteOptions(data['note_options']),
        toppingIds: data['topping_ids'] == null
            ? old.toppingIds
            : _parseMenuToppingIds(data['topping_ids']),
      );
      demoMenus[idx] = updated;
      return updated;
    }
    return demoMenus.first;
  }

  static void deleteMenu(int id) {
    demoMenus.removeWhere((m) => m.id == id);
  }

  static List<String> _parseMenuNoteOptions(dynamic value) {
    if (value is List) {
      return value
          .map((option) => option.toString().trim())
          .where((option) => option.isNotEmpty)
          .toList();
    }
    if (value is String && value.trim().isNotEmpty) {
      return value
          .split(RegExp(r'[\r\n]+'))
          .map((option) => option.trim())
          .where((option) => option.isNotEmpty)
          .toList();
    }
    return const [];
  }

  static List<int> _parseMenuToppingIds(dynamic value) {
    if (value is List) {
      return value
          .map((id) => int.tryParse(id.toString()))
          .whereType<int>()
          .toSet()
          .toList();
    }
    return const [];
  }

  static String _resolveCategoryName(dynamic catId) {
    final id = int.tryParse(catId.toString());
    final cat = demoCategories.firstWhere(
      (c) => c.id == id,
      orElse: () => demoCategories.first,
    );
    return cat.name;
  }

  // ── DAFTAR TOPPING DEMO ──
  static final List<ToppingModel> _initialToppings = [
    const ToppingModel(
      id: 1,
      name: 'Extra Shot Espresso',
      price: 5000,
      categoryIds: [2, 3],
    ),
    const ToppingModel(
      id: 2,
      name: 'Boba Pearl Kenyal',
      price: 4000,
      categoryIds: [2, 3],
    ),
    const ToppingModel(
      id: 3,
      name: 'Keju Mozzarella Melt',
      price: 6000,
      categoryIds: [1, 4],
    ),
    const ToppingModel(
      id: 4,
      name: 'Telur Mata Sapi Setengah Matang',
      price: 5000,
      categoryIds: [1],
    ),
    const ToppingModel(
      id: 5,
      name: 'Ekstra Sambal Matah',
      price: 3000,
      categoryIds: [1],
    ),
  ];

  static List<ToppingModel> demoToppings = List.from(_initialToppings);
  static int _toppingSequence = 10;

  static List<ToppingModel> getToppings() {
    return List.unmodifiable(demoToppings);
  }

  static ToppingModel createTopping(Map<String, dynamic> data) {
    final newId = _toppingSequence++;
    final topping = ToppingModel(
      id: newId,
      name: (data['name'] ?? '').toString(),
      price: int.tryParse(data['price']?.toString() ?? '0') ?? 0,
      quantity: int.tryParse(data['quantity']?.toString() ?? '1') ?? 1,
      categoryIds: _parseMenuToppingIds(data['category_ids']),
    );
    demoToppings.add(topping);
    return topping;
  }

  static ToppingModel updateTopping(int id, Map<String, dynamic> data) {
    final idx = demoToppings.indexWhere((t) => t.id == id);
    if (idx != -1) {
      final old = demoToppings[idx];
      final updated = ToppingModel(
        id: old.id,
        name: data['name']?.toString() ?? old.name,
        price: int.tryParse(data['price']?.toString() ?? '') ?? old.price,
        quantity:
            int.tryParse(data['quantity']?.toString() ?? '') ?? old.quantity,
        categoryIds: data['category_ids'] == null
            ? old.categoryIds
            : _parseMenuToppingIds(data['category_ids']),
      );
      demoToppings[idx] = updated;
      return updated;
    }
    return demoToppings.first;
  }

  static void deleteTopping(int id) {
    demoToppings.removeWhere((t) => t.id == id);
  }

  // ── DAFTAR MEJA DEMO ──
  static final List<TableModel> _initialTables = [
    const TableModel(id: 1, code: '01', isOccupied: false),
    const TableModel(id: 2, code: '02', isOccupied: true),
    const TableModel(id: 3, code: '03', isOccupied: false),
    const TableModel(id: 4, code: '04', isOccupied: true),
    const TableModel(id: 5, code: '05', isOccupied: false),
    const TableModel(id: 6, code: '06', isOccupied: false),
    const TableModel(id: 7, code: '07', isOccupied: false),
    const TableModel(id: 8, code: '08', isOccupied: false),
    const TableModel(id: 9, code: '09', isOccupied: false),
    const TableModel(id: 10, code: '10', isOccupied: false),
  ];

  static List<TableModel> demoTables = List.from(_initialTables);
  static int _tableSequence = 11;

  static List<TableModel> getTables() {
    return List.unmodifiable(demoTables);
  }

  static TableModel createTable(String code) {
    final newId = _tableSequence++;
    final formatted = code.trim().padLeft(2, '0');
    final table = TableModel(
      id: newId,
      code: formatted,
      name: 'Meja $formatted',
      isOccupied: false,
    );
    demoTables.add(table);
    return table;
  }

  static TableModel updateTable(int id, String code) {
    final idx = demoTables.indexWhere((t) => t.id == id);
    final formatted = code.trim().padLeft(2, '0');
    if (idx != -1) {
      final old = demoTables[idx];
      final updated = TableModel(
        id: old.id,
        code: formatted,
        name: 'Meja $formatted',
        isOccupied: old.isOccupied,
      );
      demoTables[idx] = updated;
      return updated;
    }
    return TableModel(id: id, code: formatted, name: 'Meja $formatted');
  }

  static void deleteTable(int id) {
    demoTables.removeWhere((t) => t.id == id);
  }

  // ── PENGGUNA & STAFF DEMO ──
  static final List<UserModel> _initialUsers = [
    const UserModel(
      id: 1,
      name: 'Admin / Pemilik Usaha',
      email: 'admin@gmail.com',
      role: UserRole.admin,
      mustChangePassword: false,
    ),
    const UserModel(
      id: 2,
      name: 'Kasir (POS Kasir)',
      email: 'cashier@gmail.com',
      role: UserRole.cashier,
      mustChangePassword: false,
    ),
    const UserModel(
      id: 3,
      name: 'Operasional / Dapur',
      email: 'operasional@gmail.com',
      role: UserRole.operations,
      mustChangePassword: false,
    ),
    const UserModel(
      id: 4,
      name: 'Pimpinan / Manager',
      email: 'manager@gmail.com',
      role: UserRole.manager,
      mustChangePassword: false,
    ),
  ];

  static List<UserModel> demoUsers = List.from(_initialUsers);
  static int _userSequence = 5;

  static List<UserModel> getUsers() {
    return List.unmodifiable(demoUsers);
  }

  static UserModel createUser(Map<String, dynamic> data) {
    final newId = _userSequence++;
    final roleStr = data['role']?.toString();
    final role = UserRoleX.fromApi(roleStr);
    final user = UserModel(
      id: newId,
      name: (data['name'] ?? '').toString(),
      email: (data['email'] ?? '').toString(),
      role: role,
      mustChangePassword: false,
    );
    demoUsers.add(user);
    return user;
  }

  static UserModel updateUser(int id, Map<String, dynamic> data) {
    final idx = demoUsers.indexWhere((u) => u.id == id);
    if (idx != -1) {
      final old = demoUsers[idx];
      final roleStr = data['role']?.toString();
      final role = roleStr != null ? UserRoleX.fromApi(roleStr) : old.role;
      final updated = UserModel(
        id: old.id,
        name: data['name']?.toString() ?? old.name,
        email: data['email']?.toString() ?? old.email,
        role: role,
        mustChangePassword: false,
      );
      demoUsers[idx] = updated;
      return updated;
    }
    return demoUsers.first;
  }

  static void deleteUser(int id) {
    demoUsers.removeWhere((u) => u.id == id);
  }

  // ── PENGATURAN QRIS DEMO ──
  static QrisSettingModel demoQrisSetting = const QrisSettingModel(
    id: 1,
    merchantName: 'DEMO RESTO & CAFE',
    merchantCity: 'JAKARTA',
    whatsappNumber: '6287771262100',
    basePayload:
        '00020101021226680016ID.CO.QRIS.WWW01189360052300000000005204581253033605802ID5914DEMO RESTO CAFE6007JAKARTA61051234062070703A016304ABCD',
    isActive: true,
  );

  static QrisSettingModel updateQrisSetting({
    required String merchantName,
    required String merchantCity,
    required String whatsappNumber,
    required String basePayload,
    bool isActive = true,
  }) {
    demoQrisSetting = QrisSettingModel(
      id: 1,
      merchantName: merchantName,
      merchantCity: merchantCity,
      whatsappNumber: whatsappNumber,
      basePayload: basePayload,
      isActive: isActive,
    );
    return demoQrisSetting;
  }

  // ── ISOLATED ORDERS ──
  static final List<CashierOrderModel> _orders = [];
  static int _orderSequence = 103;

  static void _initInitialData() {
    if (_orders.isNotEmpty) return;

    _orders.add(
      CashierOrderModel(
        id: 101,
        code: 'DEMO-ORD-101',
        customerName: 'Kak Reza (Demo)',
        customerPhone: '08129998881',
        status: 'PROCESSING',
        totalAmount: 56000,
        tableCode: '02',
        orderType: 'dine_in',
        deliveryAddress: null,
        createdAt: 'Hari ini, 10:15',
        items: [
          CashierOrderItem(
            menuName: 'Nasi Goreng Wagyu Spesial',
            quantity: 1,
            price: 38000,
            toppings: [
              CashierOrderTopping(
                toppingName: 'Telur Mata Sapi Setengah Matang',
                toppingPrice: 5000,
                quantity: 1,
              ),
            ],
            notes: 'Pedas sedang',
          ),
          CashierOrderItem(
            menuName: 'Iced Kopi Susu Gula Aren Spesial',
            quantity: 1,
            price: 18000,
            toppings: [],
            notes: 'Less ice',
          ),
        ],
      ),
    );

    _orders.add(
      CashierOrderModel(
        id: 102,
        code: 'DEMO-ORD-102',
        customerName: 'Bu Sarah (Demo)',
        customerPhone: '08137776662',
        status: 'READY',
        totalAmount: 45000,
        tableCode: '04',
        orderType: 'dine_in',
        deliveryAddress: null,
        createdAt: 'Hari ini, 10:28',
        items: [
          CashierOrderItem(
            menuName: 'Pizza Margherita Napolitana (Personal)',
            quantity: 1,
            price: 45000,
            toppings: [],
            notes: 'Potong 4 bagian',
          ),
        ],
      ),
    );
  }

  /// Create a new demo order from checkout
  static String createDemoOrder({
    String? tableCode,
    required String orderType,
    String? deliveryAddress,
    required List<CartItemModel> items,
    required String customerName,
    required String customerPhone,
    String paymentMethod = 'qris',
    String? voucherCode,
  }) {
    _initInitialData();
    final newId = _orderSequence++;
    final code = 'DEMO-ORD-$newId';

    int total = 0;
    final cashierItems = <CashierOrderItem>[];

    for (final item in items) {
      final menu = item.menu;
      final qty = item.quantity;
      final notes = item.notes;
      final toppings = item.toppings
          .map(
            (topping) => CashierOrderTopping(
              toppingName: topping.name,
              toppingPrice: topping.price,
              quantity: topping.quantity,
            ),
          )
          .toList();

      int itemSubtotal = menu.price * qty;
      for (final top in toppings) {
        itemSubtotal += top.toppingPrice * top.quantity;
      }
      total += itemSubtotal;

      cashierItems.add(
        CashierOrderItem(
          menuName: menu.name,
          quantity: qty,
          price: menu.price,
          toppings: toppings,
          notes: notes,
        ),
      );
    }

    final discount = demoTenant.promoAppliesToPayment(paymentMethod)
        ? PromoDiscountCalculator.calculate(
            items: items,
            percent: demoTenant.promoDiscountPercent,
            appliesToAllMenus: demoTenant.promoScope != 'selected',
            menuIds: demoTenant.promoMenuIds.toSet(),
          )
        : 0;

    final afterPromo = (total - discount).clamp(0, total).toInt();
    int voucherDiscount = 0;
    if (voucherCode != null && voucherCode.trim().isNotEmpty) {
      final vAmt = VoucherService.consumeDemoVoucher(
        voucherCode.trim(),
        orderId: newId,
        orderCode: code,
        usedByName: customerName,
        usedByPhone: customerPhone,
      );
      voucherDiscount = vAmt.clamp(0, afterPromo).toInt();
    }

    final newOrder = CashierOrderModel(
      id: newId,
      code: code,
      customerName: customerName.isNotEmpty
          ? customerName
          : 'Pelanggan Meja $tableCode',
      customerPhone: customerPhone,
      status: 'UNPAID',
      totalAmount: afterPromo - voucherDiscount,
      discountAmount: discount + voucherDiscount,
      tableCode: tableCode ?? '-',
      orderType: orderType,
      deliveryAddress: deliveryAddress,
      createdAt: 'Baru saja',
      items: cashierItems,
    );

    _orders.insert(0, newOrder);
    debugPrint(
      'DemoSessionManager: order baru dibuat $code (Total: Rp ${afterPromo - voucherDiscount})',
    );
    return code;
  }

  /// Manual Order dari Layar POS Kasir
  static String createManualOrder({
    required String tableCode,
    required String customerName,
    required String customerPhone,
    required List<dynamic> items,
    String? voucherCode,
  }) {
    _initInitialData();
    final newId = _orderSequence++;
    final code = 'DEMO-POS-$newId';
    int total = 0;
    final cashierItems = <CashierOrderItem>[];

    for (final it in items) {
      final menuId = it['menu_id'] as int;
      final qty = (it['quantity'] as num).toInt();
      final notes = it['notes'] as String?;
      final menu = demoMenus.firstWhere(
        (m) => m.id == menuId,
        orElse: () => demoMenus.first,
      );

      final toppingIds = (it['topping_ids'] as List?)?.cast<int>() ?? [];
      final toppings = <CashierOrderTopping>[];
      int itemToppingsPrice = 0;

      for (final tid in toppingIds) {
        final top = demoToppings.firstWhere(
          (t) => t.id == tid,
          orElse: () => demoToppings.first,
        );
        toppings.add(
          CashierOrderTopping(
            toppingName: top.name,
            toppingPrice: top.price,
            quantity: 1,
          ),
        );
        itemToppingsPrice += top.price;
      }

      final subtotal = (menu.price * qty) + (itemToppingsPrice * qty);
      total += subtotal;

      cashierItems.add(
        CashierOrderItem(
          menuName: menu.name,
          quantity: qty,
          price: menu.price,
          toppings: toppings,
          notes: notes,
        ),
      );
    }

    int voucherDiscount = 0;
    if (voucherCode != null && voucherCode.trim().isNotEmpty) {
      final vAmt = VoucherService.consumeDemoVoucher(
        voucherCode.trim(),
        orderId: newId,
        orderCode: code,
        usedByName: customerName,
        usedByPhone: customerPhone,
      );
      voucherDiscount = vAmt.clamp(0, total).toInt();
    }

    final newOrder = CashierOrderModel(
      id: newId,
      code: code,
      customerName: customerName.isNotEmpty
          ? customerName
          : 'Pelanggan POS Meja $tableCode',
      customerPhone: customerPhone,
      status: 'PAID',
      totalAmount: total - voucherDiscount,
      discountAmount: voucherDiscount,
      tableCode: tableCode,
      orderType: 'dine_in',
      deliveryAddress: null,
      createdAt: 'Baru saja',
      items: cashierItems,
    );

    _orders.insert(0, newOrder);
    return code;
  }

  /// Ambil order kasir yang difilter status
  static List<CashierOrderModel> getCashierOrders({String? status}) {
    _initInitialData();
    if (status == null || status.isEmpty) return List.unmodifiable(_orders);
    final norm = status.toUpperCase();
    return _orders.where((o) => o.status.toUpperCase() == norm).toList();
  }

  /// Update status order oleh kasir
  static void updateOrderStatus(int orderId, String newStatus) {
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx != -1) {
      final old = _orders[idx];
      _orders[idx] = CashierOrderModel(
        id: old.id,
        code: old.code,
        customerName: old.customerName,
        customerPhone: old.customerPhone,
        status: newStatus.toUpperCase(),
        totalAmount: old.totalAmount,
        tableCode: old.tableCode,
        orderType: old.orderType,
        deliveryAddress: old.deliveryAddress,
        createdAt: old.createdAt,
        paymentMethod: old.paymentMethod,
        items: old.items,
      );
      debugPrint(
        'DemoSessionManager: order ${old.code} status diubah jadi $newStatus',
      );
    }
  }

  /// Batalkan pesanan oleh customer di halaman status pesanan
  static void cancelOrderByCode(String code) {
    _initInitialData();
    final idx = _orders.indexWhere((o) => o.code == code);
    if (idx != -1) {
      updateOrderStatus(_orders[idx].id, 'CANCELLED');
    }
  }

  /// Hapus pesanan oleh admin
  static void deleteOrder(int orderId) {
    _initInitialData();
    _orders.removeWhere((o) => o.id == orderId);
  }

  /// Hapus banyak pesanan sekaligus oleh admin
  static int bulkDeleteOrders({String? status, List<int>? orderIds}) {
    _initInitialData();
    final before = _orders.length;
    if (orderIds != null && orderIds.isNotEmpty) {
      _orders.removeWhere((o) => orderIds.contains(o.id));
    } else if (status != null && status.isNotEmpty) {
      final norm = status.toUpperCase();
      _orders.removeWhere((o) => o.status.toUpperCase() == norm);
    } else {
      _orders.removeWhere((o) => o.status.toUpperCase() == 'CANCELLED');
    }
    return before - _orders.length;
  }

  /// Ambil OrderModel untuk halaman pelacakan status customer
  static OrderModel? getOrderByCode(String code) {
    _initInitialData();
    final found = _orders.firstWhere(
      (o) => o.code == code,
      orElse: () => _orders.first,
    );

    final status = OrderStatusX.fromApi(found.status);

    final orderItems = found.items
        .map(
          (i) => OrderItemModel(
            id: 1,
            menuId: 101,
            menuName: i.menuName,
            price: i.price,
            quantity: i.quantity,
            toppings: i.toppings
                .map(
                  (t) => OrderItemToppingModel(
                    id: 1,
                    toppingId: 1,
                    toppingName: t.toppingName,
                    toppingPrice: t.toppingPrice,
                    quantity: t.quantity,
                  ),
                )
                .toList(),
            notes: i.notes,
          ),
        )
        .toList();

    return OrderModel(
      id: found.id,
      code: found.code,
      customerName: found.customerName,
      customerPhone: found.customerPhone,
      status: status,
      paymentMethod: 'qris',
      qrisPayload: demoQrisSetting.basePayload,
      merchantName: demoTenant.name,
      merchantCity: 'JAKARTA',
      whatsappNumber: demoTenant.whatsapp ?? '6287771262100',
      orderType: found.orderType,
      deliveryAddress: found.deliveryAddress,
      table: TableModel(id: 1, code: found.tableCode, isOccupied: true),
      totalAmount: found.totalAmount,
      items: orderItems,
      payment: const PaymentModel(
        id: 1,
        method: PaymentMethod.qris,
        amount: 50000,
      ),
    );
  }

  /// Autentikasi Demo Instan 1-Klik untuk Calon Pembeli
  static ({String token, UserModel user, TenantModel? tenant})? tryDemoLogin(
    String email,
    String password,
  ) {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPassword = password.trim();
    DemoCredential? cred;
    for (final candidate in demoCredentials) {
      if (candidate.email.toLowerCase() == cleanEmail &&
          candidate.password == cleanPassword) {
        cred = candidate;
        break;
      }
    }
    if (cred == null) return null;

    final user = UserModel(
      id: cred.role == UserRole.cashier
          ? 2
          : (cred.role == UserRole.manager
                ? 4
                : (cred.role == UserRole.operations ? 3 : 1)),
      name: cred.roleName,
      email: cred.email,
      role: cred.role,
      mustChangePassword: false,
    );

    return (
      token: 'demo-local-token-${DateTime.now().millisecondsSinceEpoch}',
      user: user,
      tenant: demoTenant,
    );
  }

  /// Mock Stats untuk Halaman Manager Sales & Admin Dashboard
  /// Format struktur data presisi sesuai OrderController::salesStats
  static Map<String, dynamic> getMockStats() {
    _initInitialData();
    int todayRevenue = 0;
    int todayOrdersCount = _orders.length;
    for (final o in _orders) {
      todayRevenue += o.totalAmount;
    }

    final totalRevenue = todayRevenue + 12540000;
    final totalOrders = todayOrdersCount + 312;
    final monthRevenue = todayRevenue + 18450000;
    final monthOrders = todayOrdersCount + 420;
    final averageOrderValue = totalOrders > 0
        ? (totalRevenue / totalOrders).round()
        : 38000;

    final now = DateTime.now();
    final dayNames = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];

    // 7 hari riwayat omzet penjualan
    final dailySales = <Map<String, dynamic>>[];
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayStr = dayNames[date.weekday % 7];
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      int dayTotal;
      int dayOrderCount;

      if (i == 0) {
        dayTotal = todayRevenue > 0 ? todayRevenue : 650000;
        dayOrderCount = todayOrdersCount > 0 ? todayOrdersCount : 15;
      } else {
        final multipliers = [1.2, 0.9, 1.4, 1.1, 1.6, 1.8];
        final mult = multipliers[(i - 1) % multipliers.length];
        dayTotal = (1200000 * mult).round();
        dayOrderCount = (28 * mult).round();
      }

      dailySales.add({
        'date': dateStr,
        'day': dayStr,
        'total': dayTotal,
        'orders': dayOrderCount,
      });
    }

    // Menu terlaris
    final topMenus = [
      {
        'menu_name': 'Nasi Goreng Wagyu Spesial',
        'total_qty': 48,
        'total_sales': 1824000,
        'sales_share': 27.5,
      },
      {
        'menu_name': 'Iced Kopi Susu Gula Aren Spesial',
        'total_qty': 72,
        'total_sales': 1296000,
        'sales_share': 19.5,
      },
      {
        'menu_name': 'Smash Cheeseburger & Crispy Fries',
        'total_qty': 35,
        'total_sales': 1225000,
        'sales_share': 18.5,
      },
      {
        'menu_name': 'Pizza Margherita Napolitana',
        'total_qty': 22,
        'total_sales': 990000,
        'sales_share': 14.9,
      },
      {
        'menu_name': 'Kyoto Matcha Espresso Fusion',
        'total_qty': 25,
        'total_sales': 625000,
        'sales_share': 9.4,
      },
    ];

    // Hari paling ramai
    final busyDays = [
      {'day': 'Sabtu', 'orders': 84, 'revenue': 3850000},
      {'day': 'Minggu', 'orders': 92, 'revenue': 4200000},
      {'day': 'Jumat', 'orders': 65, 'revenue': 2950000},
      {'day': 'Rabu', 'orders': 48, 'revenue': 1980000},
      {'day': 'Kamis', 'orders': 45, 'revenue': 1820000},
      {'day': 'Selasa', 'orders': 42, 'revenue': 1710000},
      {'day': 'Senin', 'orders': 38, 'revenue': 1530000},
    ];

    final busiestDay = busyDays.first;

    return {
      'daily_sales': dailySales,
      'summary': {
        'total_revenue': totalRevenue,
        'total_orders': totalOrders,
        'today_revenue': todayRevenue > 0 ? todayRevenue : 650000,
        'today_orders': todayOrdersCount > 0 ? todayOrdersCount : 15,
        'month_revenue': monthRevenue,
        'month_orders': monthOrders,
        'average_order_value': averageOrderValue,
      },
      'top_menus': topMenus,
      'busy_days': busyDays,
      'busiest_day': busiestDay,
      // Field cadangan untuk kompatibilitas
      'today_sales': todayRevenue > 0 ? todayRevenue : 650000,
      'month_sales': monthRevenue,
      'completed_orders': todayOrdersCount,
      'today_customers': todayOrdersCount + 14,
      'avg_order_value': averageOrderValue,
    };
  }

  /// Reset semua data pesanan & master data demo lokal ke kondisi awal
  static void resetDemoData() {
    _orders.clear();
    _orderSequence = 103;
    demoCategories = List.from(_initialCategories);
    _categorySequence = 5;
    demoMenus = List.from(_initialMenus);
    _menuSequence = 501;
    demoToppings = List.from(_initialToppings);
    _toppingSequence = 10;
    demoTables = List.from(_initialTables);
    _tableSequence = 11;
    demoUsers = List.from(_initialUsers);
    _userSequence = 5;
    demoTenant = _initialTenant;
    _initInitialData();
  }
}

class DemoCredential {
  final String roleName;
  final String email;
  final String password;
  final UserRole role;
  final String description;
  final int badgeColor;

  const DemoCredential({
    required this.roleName,
    required this.email,
    required this.password,
    required this.role,
    required this.description,
    required this.badgeColor,
  });
}
