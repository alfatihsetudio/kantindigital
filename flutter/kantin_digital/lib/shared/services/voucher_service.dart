import '../../core/network/api_client.dart';
import 'demo_session_manager.dart';

class VoucherCheckResult {
  final int id;
  final String code;
  final String partnerName;
  final int amount;
  final int discountAmount;
  final bool valid;
  final String message;

  const VoucherCheckResult({
    required this.id,
    required this.code,
    required this.partnerName,
    required this.amount,
    required this.discountAmount,
    this.valid = true,
    this.message = 'Voucher berhasil diterapkan!',
  });

  factory VoucherCheckResult.fromJson(
    Map<String, dynamic> json, {
    String? message,
  }) {
    final amount = (json['amount'] as num?)?.toInt() ?? 0;
    final discount = (json['discount_amount'] as num?)?.toInt() ?? amount;
    return VoucherCheckResult(
      id: (json['id'] as num?)?.toInt() ?? 0,
      code: (json['code'] ?? '').toString(),
      partnerName: (json['partner_name'] ?? 'Umum').toString(),
      amount: amount,
      discountAmount: discount,
      valid: true,
      message: message ?? 'Voucher berhasil diterapkan!',
    );
  }
}

class VoucherItemModel {
  final int id;
  final String partnerName;
  final String code;
  final int amount;
  final String status; // 'unused' or 'used'
  final int? orderId;
  final String? orderCode;
  final String? usedByName;
  final String? usedByPhone;
  final String? usedAt;
  final bool isReported;
  final String? reportedAt;
  final String? notes;
  final String? createdAt;

  const VoucherItemModel({
    required this.id,
    required this.partnerName,
    required this.code,
    required this.amount,
    required this.status,
    this.orderId,
    this.orderCode,
    this.usedByName,
    this.usedByPhone,
    this.usedAt,
    this.isReported = false,
    this.reportedAt,
    this.notes,
    this.createdAt,
  });

  bool get isUsed => status == 'used';

  factory VoucherItemModel.fromJson(Map<String, dynamic> json) {
    return VoucherItemModel(
      id: (json['id'] as num).toInt(),
      partnerName: (json['partner_name'] ?? 'Umum').toString(),
      code: (json['code'] ?? '').toString(),
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      status: (json['status'] ?? 'unused').toString(),
      orderId: (json['order_id'] as num?)?.toInt(),
      orderCode: json['order_code']?.toString(),
      usedByName: json['used_by_name']?.toString(),
      usedByPhone: json['used_by_phone']?.toString(),
      usedAt: json['used_at']?.toString(),
      isReported: json['is_reported'] == true || json['is_reported'] == 1,
      reportedAt: json['reported_at']?.toString(),
      notes: json['notes']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }
}

class VoucherPartnerSummary {
  final String partnerName;
  final int totalCount;
  final int unusedCount;
  final int usedCount;
  final int unreportedCount;
  final int usedAmount;
  final int unreportedAmount;

  int get total => totalCount;

  const VoucherPartnerSummary({
    required this.partnerName,
    required this.totalCount,
    required this.unusedCount,
    required this.usedCount,
    required this.unreportedCount,
    required this.usedAmount,
    required this.unreportedAmount,
  });

  factory VoucherPartnerSummary.fromJson(Map<String, dynamic> json) {
    return VoucherPartnerSummary(
      partnerName: (json['partner_name'] ?? 'Umum').toString(),
      totalCount: (json['total_count'] as num?)?.toInt() ?? 0,
      unusedCount: (json['unused_count'] as num?)?.toInt() ?? 0,
      usedCount: (json['used_count'] as num?)?.toInt() ?? 0,
      unreportedCount: (json['unreported_count'] as num?)?.toInt() ?? 0,
      usedAmount: (json['used_amount'] as num?)?.toInt() ?? 0,
      unreportedAmount: (json['unreported_amount'] as num?)?.toInt() ?? 0,
    );
  }
}

class VoucherListResponse {
  final List<VoucherItemModel> vouchers;
  final int totalVouchers;
  final int unusedCount;
  final int usedCount;
  final int unreportedUsedCount;
  final int reportedUsedCount;
  final int totalUsedAmount;
  final int unreportedUsedAmount;
  final List<String> partners;
  final List<VoucherPartnerSummary> partnerSummaries;

  List<VoucherItemModel> get items => vouchers;
  int get usedAmount => totalUsedAmount;

  const VoucherListResponse({
    required this.vouchers,
    required this.totalVouchers,
    required this.unusedCount,
    required this.usedCount,
    required this.unreportedUsedCount,
    required this.reportedUsedCount,
    required this.totalUsedAmount,
    required this.unreportedUsedAmount,
    required this.partners,
    required this.partnerSummaries,
  });

  factory VoucherListResponse.empty() {
    return const VoucherListResponse(
      vouchers: [],
      totalVouchers: 0,
      unusedCount: 0,
      usedCount: 0,
      unreportedUsedCount: 0,
      reportedUsedCount: 0,
      totalUsedAmount: 0,
      unreportedUsedAmount: 0,
      partners: [],
      partnerSummaries: [],
    );
  }
}

class VoucherService {
  final ApiClient _client;

  VoucherService([ApiClient? client]) : _client = client ?? ApiClient();

  static final List<Map<String, dynamic>> _demoVouchers = [
    {
      'id': 1,
      'partner_name': 'Kerjasama Kampus Untirta',
      'code': 'UNTIRTA10',
      'amount': 10000,
      'status': 'unused',
      'order_id': null,
      'order_code': null,
      'used_by_name': null,
      'used_by_phone': null,
      'used_at': null,
      'is_reported': false,
      'reported_at': null,
      'notes': 'Voucher acara kampus',
      'created_at': DateTime.now().toIso8601String(),
    },
    {
      'id': 2,
      'partner_name': 'Kerjasama Kampus Untirta',
      'code': 'UNTIRTA15',
      'amount': 15000,
      'status': 'used',
      'order_id': 101,
      'order_code': 'ORD9821',
      'used_by_name': 'Rizky Pratama',
      'used_by_phone': '081298765432',
      'used_at': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
      'is_reported': false,
      'reported_at': null,
      'notes': 'Voucher acara kampus',
      'created_at': DateTime.now().toIso8601String(),
    },
  ];

  static int consumeDemoVoucher(
    String code, {
    required int orderId,
    required String orderCode,
    required String usedByName,
    required String usedByPhone,
  }) {
    final cleanCode = code.trim().toUpperCase();
    for (final v in _demoVouchers) {
      if (v['code'].toString().toUpperCase() == cleanCode &&
          v['status'] != 'used') {
        v['status'] = 'used';
        v['order_id'] = orderId;
        v['order_code'] = orderCode;
        v['used_by_name'] = usedByName;
        v['used_by_phone'] = usedByPhone;
        v['used_at'] = DateTime.now().toIso8601String();
        return (v['amount'] as num).toInt();
      }
    }
    return 0;
  }

  Future<VoucherCheckResult> checkVoucher(
    String code, {
    int subtotal = 0,
  }) async {
    final cleanCode = code.trim().toUpperCase();
    if (cleanCode.isEmpty) {
      return const VoucherCheckResult(
        id: 0,
        code: '',
        partnerName: '',
        amount: 0,
        discountAmount: 0,
        valid: false,
        message: 'Masukkan kode voucher terlebih dahulu.',
      );
    }

    if (DemoSessionManager.isDemoMode) {
      final found = _demoVouchers.where(
        (v) => v['code'].toString().toUpperCase() == cleanCode,
      );
      if (found.isEmpty) {
        return VoucherCheckResult(
          id: 0,
          code: cleanCode,
          partnerName: '',
          amount: 0,
          discountAmount: 0,
          valid: false,
          message: 'Kode voucher tidak ditemukan atau tidak terdaftar.',
        );
      }
      final item = found.first;
      if (item['status'] == 'used') {
        return VoucherCheckResult(
          id: 0,
          code: cleanCode,
          partnerName: '',
          amount: 0,
          discountAmount: 0,
          valid: false,
          message: 'Kode voucher ini sudah pernah digunakan.',
        );
      }
      final amount = (item['amount'] as num).toInt();
      return VoucherCheckResult(
        id: (item['id'] as num).toInt(),
        code: item['code'].toString(),
        partnerName: item['partner_name'].toString(),
        amount: amount,
        discountAmount: subtotal > 0 && subtotal < amount ? subtotal : amount,
        valid: true,
        message: 'Voucher ${item['code']} berhasil diterapkan!',
      );
    }

    try {
      final response = await _client.post(
        '/vouchers/check',
        body: {
          'code': cleanCode,
          if (subtotal > 0) 'subtotal': subtotal,
        },
      );
      final data = (response['data'] as Map<String, dynamic>?) ?? {};
      final msg = response['message']?.toString();
      return VoucherCheckResult.fromJson(data, message: msg);
    } catch (e) {
      final errMsg = e.toString().replaceAll('Exception:', '').trim();
      return VoucherCheckResult(
        id: 0,
        code: cleanCode,
        partnerName: '',
        amount: 0,
        discountAmount: 0,
        valid: false,
        message: errMsg.isNotEmpty
            ? errMsg
            : 'Kode voucher tidak valid atau sudah digunakan.',
      );
    }
  }

  Future<VoucherListResponse> getVouchers({
    String? status,
    String? partnerName,
    String? partner,
    bool? isReported,
    String? reported,
    String? search,
  }) async {
    final effectivePartner = partnerName ?? partner;
    final bool? effectiveReported = isReported ??
        (reported == 'reported'
            ? true
            : (reported == 'unreported' ? false : null));

    if (DemoSessionManager.isDemoMode) {
      final items = _demoVouchers
          .map((e) => VoucherItemModel.fromJson(e))
          .where((v) {
            if (status != null && status.isNotEmpty && v.status != status) {
              return false;
            }
            if (effectivePartner != null &&
                effectivePartner.isNotEmpty &&
                effectivePartner != 'ALL' &&
                v.partnerName != effectivePartner) {
              return false;
            }
            if (effectiveReported != null && v.isReported != effectiveReported) {
              return false;
            }
            if (search != null && search.trim().isNotEmpty) {
              final q = search.trim().toLowerCase();
              final match =
                  v.code.toLowerCase().contains(q) ||
                  v.partnerName.toLowerCase().contains(q) ||
                  (v.usedByName?.toLowerCase().contains(q) ?? false) ||
                  (v.orderCode?.toLowerCase().contains(q) ?? false);
              if (!match) return false;
            }
            return true;
          })
          .toList();

      final all = _demoVouchers.map((e) => VoucherItemModel.fromJson(e)).toList();
      final partners = all.map((e) => e.partnerName).toSet().toList();
      return VoucherListResponse(
        vouchers: items,
        totalVouchers: all.length,
        unusedCount: all.where((e) => !e.isUsed).length,
        usedCount: all.where((e) => e.isUsed).length,
        unreportedUsedCount: all.where((e) => e.isUsed && !e.isReported).length,
        reportedUsedCount: all.where((e) => e.isUsed && e.isReported).length,
        totalUsedAmount: all
            .where((e) => e.isUsed)
            .fold(0, (s, e) => s + e.amount),
        unreportedUsedAmount: all
            .where((e) => e.isUsed && !e.isReported)
            .fold(0, (s, e) => s + e.amount),
        partners: partners,
        partnerSummaries: partners.map((p) {
          final pList = all.where((e) => e.partnerName == p).toList();
          return VoucherPartnerSummary(
            partnerName: p,
            totalCount: pList.length,
            unusedCount: pList.where((e) => !e.isUsed).length,
            usedCount: pList.where((e) => e.isUsed).length,
            unreportedCount: pList.where((e) => e.isUsed && !e.isReported).length,
            usedAmount: pList
                .where((e) => e.isUsed)
                .fold(0, (s, e) => s + e.amount),
            unreportedAmount: pList
                .where((e) => e.isUsed && !e.isReported)
                .fold(0, (s, e) => s + e.amount),
          );
        }).toList(),
      );
    }

    final query = <String, String>{};
    if (status != null && status.isNotEmpty) query['status'] = status;
    if (effectivePartner != null &&
        effectivePartner.isNotEmpty &&
        effectivePartner != 'ALL') {
      query['partner_name'] = effectivePartner;
    }
    if (effectiveReported != null) {
      query['is_reported'] = effectiveReported ? '1' : '0';
    }
    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }

    final response = await _client.get('/vouchers', queryParameters: query);
    final data = (response['data'] as Map<String, dynamic>?) ?? {};
    final list = (data['vouchers'] as List?) ?? [];
    final summary = (data['summary'] as Map<String, dynamic>?) ?? {};
    final partners =
        ((data['partners'] as List?) ?? []).map((e) => e.toString()).toList();
    final partnerSummaries = ((data['partner_summaries'] as List?) ?? [])
        .map((e) => VoucherPartnerSummary.fromJson(e as Map<String, dynamic>))
        .toList();

    return VoucherListResponse(
      vouchers: list
          .map((e) => VoucherItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalVouchers: (summary['total_vouchers'] as num?)?.toInt() ?? 0,
      unusedCount: (summary['unused_count'] as num?)?.toInt() ?? 0,
      usedCount: (summary['used_count'] as num?)?.toInt() ?? 0,
      unreportedUsedCount:
          (summary['unreported_used_count'] as num?)?.toInt() ?? 0,
      reportedUsedCount: (summary['reported_used_count'] as num?)?.toInt() ?? 0,
      totalUsedAmount: (summary['total_used_amount'] as num?)?.toInt() ?? 0,
      unreportedUsedAmount:
          (summary['unreported_used_amount'] as num?)?.toInt() ?? 0,
      partners: partners,
      partnerSummaries: partnerSummaries,
    );
  }

  Future<Map<String, dynamic>> importVouchers({
    required String partnerName,
    required int amount,
    String? codesText,
    String? codesRaw,
    String? notes,
  }) async {
    final effectiveCodes = codesText ?? codesRaw ?? '';
    if (DemoSessionManager.isDemoMode) {
      final lines = effectiveCodes
          .split(RegExp(r'[\r\n,;]+'))
          .map((s) => s.trim().toUpperCase())
          .where((s) => s.isNotEmpty)
          .toSet();
      int imported = 0;
      for (final c in lines) {
        _demoVouchers.add({
          'id': DateTime.now().millisecondsSinceEpoch + imported,
          'partner_name': partnerName.trim(),
          'code': c,
          'amount': amount,
          'status': 'unused',
          'order_id': null,
          'order_code': null,
          'used_by_name': null,
          'used_by_phone': null,
          'used_at': null,
          'is_reported': false,
          'reported_at': null,
          'notes': notes,
          'created_at': DateTime.now().toIso8601String(),
        });
        imported++;
      }
      return {
        'imported_count': imported,
        'skipped_count': 0,
        'message': 'Berhasil mengimport $imported voucher (Mode Demo).',
      };
    }

    final response = await _client.post(
      '/vouchers/import',
      body: {
        'partner_name': partnerName.trim(),
        'amount': amount,
        'codes_text': effectiveCodes,
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      },
    );
    final data = (response['data'] as Map<String, dynamic>?) ?? {};
    return {
      'imported_count': (data['imported_count'] as num?)?.toInt() ?? 0,
      'skipped_count': (data['skipped_count'] as num?)?.toInt() ?? 0,
      'message': (response['message'] ?? 'Import selesai.').toString(),
    };
  }

  Future<int> markReported({
    List<int>? voucherIds,
    String? partnerName,
    bool isReported = true,
  }) async {
    if (DemoSessionManager.isDemoMode) {
      int count = 0;
      for (final v in _demoVouchers) {
        if (v['status'] != 'used') continue;
        if (voucherIds != null && !voucherIds.contains(v['id'])) continue;
        if (partnerName != null &&
            partnerName != 'ALL' &&
            v['partner_name'] != partnerName) {
          continue;
        }
        v['is_reported'] = isReported;
        v['reported_at'] = isReported ? DateTime.now().toIso8601String() : null;
        count++;
      }
      return count;
    }

    final response = await _client.post(
      '/vouchers/mark-reported',
      body: {
        if (voucherIds != null) 'voucher_ids': voucherIds,
        if (partnerName != null) 'partner_name': partnerName,
        'is_reported': isReported,
      },
    );
    final data = (response['data'] as Map<String, dynamic>?) ?? {};
    return (data['updated_count'] as num?)?.toInt() ?? 0;
  }

  Future<void> deleteVoucher(int id) async {
    if (DemoSessionManager.isDemoMode) {
      _demoVouchers.removeWhere((v) => v['id'] == id);
      return;
    }
    await _client.delete('/vouchers/$id');
  }

  Future<int> bulkDeleteVouchers({
    List<int>? voucherIds,
    String? partnerName,
    String? status,
  }) async {
    if (DemoSessionManager.isDemoMode) {
      final before = _demoVouchers.length;
      _demoVouchers.removeWhere((v) {
        if (voucherIds != null && voucherIds.contains(v['id'])) return true;
        if (partnerName != null &&
            partnerName != 'ALL' &&
            v['partner_name'] != partnerName) {
          return false;
        }
        if (status != null && v['status'] != status) return false;
        return voucherIds == null;
      });
      return before - _demoVouchers.length;
    }

    final response = await _client.post(
      '/vouchers/bulk-delete',
      body: {
        if (voucherIds != null) 'voucher_ids': voucherIds,
        if (partnerName != null && partnerName != 'ALL')
          'partner_name': partnerName,
        if (status != null) 'status': status,
      },
    );
    final data = (response['data'] as Map<String, dynamic>?) ?? {};
    return (data['deleted_count'] as num?)?.toInt() ?? 0;
  }
}
