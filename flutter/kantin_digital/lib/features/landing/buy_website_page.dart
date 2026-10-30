import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/image_saver.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../router/route_name.dart';
import '../../shared/services/demo_session_manager.dart';

class BuyWebsitePage extends StatefulWidget {
  final String? initialSubdomain;
  final String? initialPlan;

  const BuyWebsitePage({
    super.key,
    this.initialSubdomain,
    this.initialPlan,
  });

  @override
  State<BuyWebsitePage> createState() => _BuyWebsitePageState();
}

class _BuyWebsitePageState extends State<BuyWebsitePage> {
  final _formKey = GlobalKey<FormState>();
  final _apiClient = ApiClient();
  final _scrollController = ScrollController();
  final _qrisCardKey = GlobalKey();

  // Form Controllers
  late final TextEditingController _storeNameCtrl;
  late final TextEditingController _subdomainCtrl;
  final _ownerNameCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  // States
  String? _selectedCategory;
  String _selectedPlan = 'plan_100k'; // 'plan_30k', 'plan_70k', 'plan_100k', 'plan_1jt'
  final String _selectedPaymentMethod = 'qris'; // QRIS only
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _isDownloadingQris = false;
  String? _formErrorNotice;

  // Pending Registration & Realtime Automatic Payment Polling
  Map<String, dynamic>? _pendingRegistration;
  Timer? _paymentPollTimer;
  bool _isCheckingPayment = false;
  bool _isPaymentConfirmed = false;
  BuildContext? _activeDialogContext;
  void Function(void Function())? _activeDialogSetState;

  // Subdomain live availability
  bool? _isSubdomainAvailable;
  String _subdomainCheckMessage = '';
  bool _isCheckingSubdomain = false;
  Timer? _subdomainDebounce;

  final List<String> _businessCategories = [
    'Kafe & Kopi',
    'Restoran & Rumah Makan',
    'Warung Makan & Kedai',
    'Kantin Sekolah / Kampus',
    'Fast Food & Cemilan',
    'Booth / Food Truck',
    'Bakery & Kue',
    'Lainnya',
  ];

  @override
  void initState() {
    super.initState();
    DemoSessionManager.disableDemoMode();
    _loadPendingRegistration();
    final initialSub = widget.initialSubdomain?.trim() ?? '';
    _storeNameCtrl = TextEditingController(
      text: initialSub.isNotEmpty
          ? initialSub.replaceAll('-', ' ').toUpperCase()
          : '',
    );
    _subdomainCtrl = TextEditingController(text: initialSub);
    if (widget.initialPlan != null) {
      final p = widget.initialPlan!.toLowerCase();
      if (p == 'starter' || p == 'basic' || p == 'plan_30k' || p == '30k') {
        _selectedPlan = 'plan_30k';
      } else if (p == 'plan_70k' || p == '70k') {
        _selectedPlan = 'plan_70k';
      } else if (p == 'pro' || p == 'plan_100k' || p == '100k') {
        _selectedPlan = 'plan_100k';
      } else if (p == 'plan_1jt' || p == '1jt' || p == 'enterprise') {
        _selectedPlan = 'plan_1jt';
      } else {
        _selectedPlan = p;
      }
    } else {
      _selectedPlan = 'plan_100k';
    }

    _subdomainCtrl.addListener(_onSubdomainInputChanged);

    // Cek ketersediaan awal secara otomatis HANYA jika ada parameter subdomain awal
    if (_subdomainCtrl.text.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _checkSubdomainAvailability(autoCheck: true);
        }
      });
    }
  }

  @override
  void dispose() {
    _paymentPollTimer?.cancel();
    _subdomainDebounce?.cancel();
    _scrollController.dispose();
    _subdomainCtrl.removeListener(_onSubdomainInputChanged);
    _storeNameCtrl.dispose();
    _subdomainCtrl.dispose();
    _ownerNameCtrl.dispose();
    _whatsappCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPendingRegistration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('pending_store_registration');
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _pendingRegistration = decoded;
          });
          _startPaymentPolling();
        }
      }
    } catch (_) {}
  }

  Future<void> _savePendingRegistration(Map<String, dynamic> data) async {
    _pendingRegistration = data;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pending_store_registration', jsonEncode(data));
    } catch (_) {}
  }

  Future<void> _clearPendingRegistration() async {
    _paymentPollTimer?.cancel();
    if (_activeDialogContext != null) {
      Navigator.of(_activeDialogContext!).pop();
      _activeDialogContext = null;
    }
    _activeDialogSetState = null;
    setState(() {
      _pendingRegistration = null;
      _isPaymentConfirmed = false;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('pending_store_registration');
    } catch (_) {}
  }

  void _startPaymentPolling() {
    _paymentPollTimer?.cancel();
    _paymentPollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _pollPaymentStatus();
    });
  }

  Future<void> _pollPaymentStatus() async {
    if (_pendingRegistration == null || _isCheckingPayment || _isPaymentConfirmed) return;
    final invoiceMap = _pendingRegistration!['invoice'] as Map<String, dynamic>? ?? {};
    final invoiceCode = invoiceMap['code']?.toString() ?? '';
    if (invoiceCode.isEmpty) return;

    _isCheckingPayment = true;
    try {
      final res = await _apiClient.get('/register-store/status/$invoiceCode');
      if (res is Map && res['data'] != null) {
        final data = res['data'] as Map<String, dynamic>;
        final bool isPaid = data['is_paid'] == true ||
            data['status']?.toString().toUpperCase() == 'PAID';
        if (isPaid) {
          _isPaymentConfirmed = true;
          _paymentPollTimer?.cancel();

          if (_activeDialogSetState != null) {
            _activeDialogSetState!(() {});
          }

          if (mounted) {
            setState(() {});
          }

          // Beri jeda 1.2 detik agar animasi sukses terlihat oleh pengguna
          await Future.delayed(const Duration(milliseconds: 1200));

          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('pending_store_registration');

          if (_activeDialogContext != null && mounted) {
            Navigator.of(_activeDialogContext!).pop();
            _activeDialogContext = null;
          }
          _activeDialogSetState = null;

          if (mounted) {
            final completeData = Map<String, dynamic>.from(_pendingRegistration!);
            if (data['tenant'] != null && data['tenant'] is Map) {
              completeData.addAll(Map<String, dynamic>.from(data['tenant'] as Map));
            }
            setState(() {
              _pendingRegistration = null;
              _isPaymentConfirmed = false;
            });
            _showSuccessDialog(completeData);
          }
        }
      }
    } catch (_) {
      // Abaikan error polling (lanjut cek polling berikutnya)
    } finally {
      _isCheckingPayment = false;
    }
  }

  void _onSubdomainInputChanged() {
    final raw = _subdomainCtrl.text;
    final slug = _generateSlug(raw);
    if (slug != raw) {
      _subdomainCtrl.value = TextEditingValue(
        text: slug,
        selection: TextSelection.collapsed(offset: slug.length),
      );
    }
    setState(() {
      _isSubdomainAvailable = null;
      _subdomainCheckMessage = '';
    });

    // Otomatis cek setelah pengguna berhenti mengetik 600ms
    _subdomainDebounce?.cancel();
    if (slug.length >= 3) {
      _subdomainDebounce = Timer(const Duration(milliseconds: 600), () {
        if (mounted && _subdomainCtrl.text.trim() == slug) {
          _checkSubdomainAvailability(autoCheck: true);
        }
      });
    }
  }

  String _generateSlug(String text) {
    return text
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-');
  }

  Future<void> _checkSubdomainAvailability({bool autoCheck = false}) async {
    final slug = _generateSlug(_subdomainCtrl.text);
    if (slug.isEmpty) {
      if (!autoCheck && mounted) {
        setState(() {
          _isSubdomainAvailable = false;
          _subdomainCheckMessage = 'Subdomain tidak boleh kosong.';
        });
      }
      return;
    }

    if (slug.length < 3) {
      if (!autoCheck && mounted) {
        setState(() {
          _isSubdomainAvailable = false;
          _subdomainCheckMessage = 'Subdomain minimal harus 3 karakter.';
        });
      }
      return;
    }

    setState(() {
      _isCheckingSubdomain = true;
      _subdomainCheckMessage = 'Mengecek ketersediaan di database...';
    });

    try {
      final res = await _apiClient.get(
        '/check-subdomain',
        queryParameters: {'subdomain': slug},
      );
      if (mounted) {
        final bool isAvailable = res is Map && res['available'] == true;
        String msg;
        if (res is Map &&
            res['message'] != null &&
            res['message'].toString().toLowerCase().trim() != 'success' &&
            res['message'].toString().trim().isNotEmpty) {
          msg = res['message'].toString();
        } else {
          msg = isAvailable
              ? 'Subdomain $slug.ekasir.my.id tersedia!'
              : 'Subdomain $slug sudah digunakan oleh toko lain.';
        }

        setState(() {
          _isSubdomainAvailable = isAvailable;
          _subdomainCheckMessage = msg;
          _isCheckingSubdomain = false;
        });
      }
    } catch (e) {
      if (mounted) {
        String errMsg = 'Gagal memeriksa subdomain. Periksa koneksi ke server.';
        if (e is ApiException && e.message.isNotEmpty) {
          errMsg = e.message;
        }
        setState(() {
          _isSubdomainAvailable = false;
          _subdomainCheckMessage = errMsg;
          _isCheckingSubdomain = false;
        });
      }
    }
  }

  int get _planPrice {
    switch (_selectedPlan) {
      case 'plan_30k':
      case 'starter':
      case 'basic':
        return 30000;
      case 'plan_70k':
        return 70000;
      case 'plan_100k':
      case 'pro':
        return 100000;
      case 'plan_1jt':
      case 'enterprise':
        return 1000000;
      default:
        return 30000;
    }
  }

  String get _planPeriod {
    return (_selectedPlan == 'plan_1jt' || _selectedPlan == 'enterprise')
        ? '/tahun'
        : '/bulan';
  }

  String get _planTitle {
    switch (_selectedPlan) {
      case 'plan_30k':
      case 'starter':
      case 'basic':
        return 'Paket Hemat (30rb/bln)';
      case 'plan_70k':
        return 'Paket Standar (70rb/bln)';
      case 'plan_100k':
      case 'pro':
        return 'Paket Pro Unlimited (100rb/bln)';
      case 'plan_1jt':
      case 'enterprise':
        return 'Paket Custom Domain (1jt/thn)';
      default:
        return 'Paket eKasir';
    }
  }

  Future<void> _submitPurchase() async {
    if (!_formKey.currentState!.validate()) {
      final List<String> missingFields = [];
      if (_storeNameCtrl.text.trim().isEmpty) missingFields.add('Nama Usaha/Toko');
      if (_subdomainCtrl.text.trim().isEmpty) missingFields.add('Pilihan Subdomain');
      if (_ownerNameCtrl.text.trim().isEmpty) missingFields.add('Nama Pemilik');
      if (_whatsappCtrl.text.trim().isEmpty) missingFields.add('Nomor WhatsApp');
      if (_emailCtrl.text.trim().isEmpty) missingFields.add('Email Login');
      if (_passwordCtrl.text.isEmpty) {
        missingFields.add('Password');
      } else if (_passwordCtrl.text.length < 6) {
        missingFields.add('Password min. 6 karakter');
      }
      if (_confirmPasswordCtrl.text.isEmpty) {
        missingFields.add('Konfirmasi Password');
      }
      if (_selectedCategory == null || _selectedCategory!.trim().isEmpty) {
        missingFields.add('Kategori Usaha');
      }

      final missingMsg = missingFields.isNotEmpty
          ? 'Mohon lengkapi data: ${missingFields.join(', ')}'
          : 'Mohon lengkapi seluruh formulir data yang ditandai merah.';

      setState(() {
        _formErrorNotice = missingMsg;
      });

      AppSnackBar.show(
        context,
        message: missingMsg,
        backgroundColor: const Color(0xFFDC2626),
        icon: Icons.error_outline_rounded,
      );
      return;
    }

    if (_selectedCategory == null || _selectedCategory!.trim().isEmpty) {
      const err = 'Mohon pilih Kategori Usaha Kuliner Anda.';
      setState(() {
        _formErrorNotice = err;
      });

      AppSnackBar.show(
        context,
        message: err,
        backgroundColor: const Color(0xFFDC2626),
        icon: Icons.error_outline_rounded,
      );
      return;
    }

    if (_passwordCtrl.text != _confirmPasswordCtrl.text) {
      const err = 'Password dan Konfirmasi Password tidak cocok.';
      setState(() {
        _formErrorNotice = err;
      });

      AppSnackBar.show(
        context,
        message: err,
        backgroundColor: const Color(0xFFDC2626),
        icon: Icons.error_outline_rounded,
      );
      return;
    }

    final slug = _generateSlug(_subdomainCtrl.text);
    if (slug.isEmpty) {
      const err = 'Subdomain toko tidak boleh kosong.';
      setState(() {
        _formErrorNotice = err;
      });
      AppSnackBar.show(
        context,
        message: err,
        backgroundColor: const Color(0xFFDC2626),
        icon: Icons.error_outline_rounded,
      );
      return;
    }

    if (slug.length < 3) {
      const err = 'Subdomain toko minimal 3 karakter.';
      setState(() {
        _formErrorNotice = err;
      });
      AppSnackBar.show(
        context,
        message: err,
        backgroundColor: const Color(0xFFDC2626),
        icon: Icons.error_outline_rounded,
      );
      return;
    }

    // Selalu pastikan status ketersediaan subdomain terverifikasi
    if (_isSubdomainAvailable != true) {
      await _checkSubdomainAvailability();
      if (!mounted) return;
    }

    if (_isSubdomainAvailable != true) {
      final err = (_subdomainCheckMessage.isNotEmpty &&
              _subdomainCheckMessage.toLowerCase().trim() != 'success')
          ? _subdomainCheckMessage
          : 'Subdomain "$slug" tidak tersedia atau sudah digunakan toko lain.';
      setState(() {
        _formErrorNotice = err;
      });
      AppSnackBar.show(
        context,
        message: err,
        backgroundColor: const Color(0xFFDC2626),
        icon: Icons.error_outline_rounded,
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _formErrorNotice = null;
    });

    try {
      final payload = {
        'store_name': _storeNameCtrl.text.trim(),
        'subdomain': slug,
        'owner_name': _ownerNameCtrl.text.trim(),
        'owner_email': _emailCtrl.text.trim().toLowerCase(),
        'whatsapp': _whatsappCtrl.text.trim(),
        'password': _passwordCtrl.text,
        'plan': _selectedPlan,
        'payment_method': _selectedPaymentMethod,
        'address': _addressCtrl.text.trim(),
        'category_type': _selectedCategory,
      };

      final response = await _apiClient.post('/register-store', body: payload);

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      final data = response['data'] as Map<String, dynamic>;
      await _savePendingRegistration(data);
      _isPaymentConfirmed = false;
      _startPaymentPolling();
      _showQrisPaymentDialog(data);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _formErrorNotice = e is ApiException ? e.message : e.toString();
      });
      final msg = e is ApiException ? e.message : e.toString();
      AppSnackBar.show(
        context,
        message: msg,
        backgroundColor: const Color(0xFFDC2626),
        icon: Icons.error_outline_rounded,
      );
    }
  }

  void _showQrisPaymentDialog(Map<String, dynamic> data) {
    final invoiceMap = data['invoice'] as Map<String, dynamic>? ?? {};
    final invoiceCode = invoiceMap['code']?.toString() ?? 'INV-PAID';
    final amount = invoiceMap['amount'] is int ? invoiceMap['amount'] as int : _planPrice;
    final qrisMap = data['qris'] as Map<String, dynamic>? ?? {};
    final qrisPayload = qrisMap['payload']?.toString() ??
        '00020101021126570011ID.DANA.WWW011893600915303557205402090355720540303UMI51440014ID.CO.QRIS.WWW0215ID10266058542500303UMI5204581253033605802ID5910Say Coffee6011Kab. Serang6105421176304AB0C';
    final merchantName = qrisMap['merchant_name']?.toString() ?? 'SAYUTIKOPI';
    final merchantCity = qrisMap['merchant_city']?.toString() ?? 'Kab. Serang';
    final nmidMatch = RegExp(r'0215(ID[0-9A-Za-z]+)').firstMatch(qrisPayload);
    final nmid = nmidMatch != null ? nmidMatch.group(1)! : 'ID1026605854250';

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        _activeDialogContext = ctx;
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            _activeDialogSetState = setDialogState;
            final isMobile = MediaQuery.of(ctx).size.width <= 600;
            return Dialog(
              insetPadding: isMobile
                  ? const EdgeInsets.symmetric(horizontal: 14, vertical: 20)
                  : const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isMobile ? 18 : 24)),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 14 : 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header Title
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: Color(0xFFEFF6FF),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.qr_code_2_rounded,
                            color: Color(0xFF2563EB),
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pembayaran QRIS Website',
                                style: TextStyle(
                                  fontSize: isMobile ? 16 : 18,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                isMobile
                                    ? 'Scan QRIS untuk aktivasi toko Anda'
                                    : 'Scan QRIS untuk menyelesaikan aktivasi website toko Anda',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          tooltip: 'Tutup',
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // QRIS Card (RepaintBoundary)
                    RepaintBoundary(
                      key: _qrisCardKey,
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
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
                            // Header Strip
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(
                                vertical: isMobile ? 10 : 12,
                                horizontal: isMobile ? 12 : 16,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B),
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(isMobile ? 14 : 18),
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
                                      if (!isMobile) ...[
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
                                    ],
                                  ),
                                  Flexible(
                                    child: Text(
                                      '#$invoiceCode',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Padding(
                              padding: EdgeInsets.all(isMobile ? 14 : 20),
                              child: Column(
                                children: [
                                  // Merchant Name & City
                                  Text(
                                    merchantName,
                                    style: TextStyle(
                                      fontSize: isMobile ? 16 : 18,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF0F172A),
                                      letterSpacing: 0.5,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    merchantCity,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 14),

                                  // Nominal Box
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
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
                                          CurrencyFormatter.rupiah(amount),
                                          style: TextStyle(
                                            fontSize: isMobile ? 22 : 24,
                                            fontWeight: FontWeight.w800,
                                            color: const Color(0xFF2563EB),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // QR Code
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: const Color(0xFFCBD5E1),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: QrImageView(
                                      data: qrisPayload,
                                      version: QrVersions.auto,
                                      size: isMobile ? 170.0 : 190.0,
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
                                  const SizedBox(height: 10),
                                  Text(
                                    'NMID: $nmid • $merchantName / eKasir',
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
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _isDownloadingQris
                            ? null
                            : () async {
                                setDialogState(() => _isDownloadingQris = true);
                                await _downloadQris(invoiceCode);
                                setDialogState(() => _isDownloadingQris = false);
                              },
                        icon: _isDownloadingQris
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.file_download_outlined, size: 20),
                        label: Text(
                          _isDownloadingQris ? 'Menyimpan QRIS...' : 'Download Gambar QRIS',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF059669),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Instructions Box
                    _buildPaymentGuideBox(),
                    const SizedBox(height: 16),

                    // Realtime Automatic Detection Status Box (Tidak ada tombol konfirmasi manual)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        vertical: isMobile ? 12 : 14,
                        horizontal: isMobile ? 12 : 16,
                      ),
                      decoration: BoxDecoration(
                        color: _isPaymentConfirmed
                            ? const Color(0xFFF0FDF4)
                            : const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _isPaymentConfirmed
                              ? const Color(0xFF86EFAC)
                              : const Color(0xFFBFDBFE),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _isPaymentConfirmed
                                  ? const Color(0xFFDCFCE7)
                                  : const Color(0xFFDBEAFE),
                              shape: BoxShape.circle,
                            ),
                            child: _isPaymentConfirmed
                                ? const Icon(
                                    Icons.check_circle_rounded,
                                    color: Color(0xFF16A34A),
                                    size: 22,
                                  )
                                : const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: Color(0xFF2563EB),
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isPaymentConfirmed
                                      ? 'Pembayaran Berhasil Terverifikasi! 🎉'
                                      : 'Menunggu Pembayaran QRIS...',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: isMobile ? 13 : 14,
                                    color: _isPaymentConfirmed
                                        ? const Color(0xFF166534)
                                        : const Color(0xFF1E40AF),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _isPaymentConfirmed
                                      ? 'Aktivasi website toko berhasil. Mengalihkan ke sistem...'
                                      : 'Sistem mengecek transfer secara otomatis. Tidak perlu klik tombol konfirmasi.',
                                  style: TextStyle(
                                    fontSize: isMobile ? 11 : 11.5,
                                    color: _isPaymentConfirmed
                                        ? const Color(0xFF15803D)
                                        : const Color(0xFF3B82F6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
    ).then((_) {
      _activeDialogContext = null;
      _activeDialogSetState = null;
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<void> _downloadQris(String invoiceCode) async {
    try {
      final boundary =
          _qrisCardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception('Gagal menangkap tampilan QRIS');
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('Gagal memproses file gambar');
      }

      final bytes = byteData.buffer.asUint8List();
      final filename = 'QRIS-eKasir-$invoiceCode.png';
      final success = await ImageSaver.saveImage(bytes, filename);

      if (mounted) {
        AppSnackBar.show(
          context,
          message: success
              ? 'QRIS berhasil diunduh! Silakan buka m-Banking/E-Wallet dan upload dari Galeri.'
              : 'QRIS berhasil dibuat.',
          backgroundColor: const Color(0xFF059669),
          icon: Icons.check_circle_rounded,
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(
          context,
          message: 'Gagal mengunduh QRIS: $e',
          backgroundColor: const Color(0xFFDC2626),
          icon: Icons.error_outline_rounded,
        );
      }
    }
  }

  Widget _buildPaymentGuideBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.phone_android_rounded, size: 16, color: Color(0xFF1D4ED8)),
              SizedBox(width: 8),
              Text(
                'Petunjuk Bayar di HP yang Sama:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Color(0xFF1E3A8A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildGuideStep('1', 'Tekan tombol "Download Gambar QRIS" di atas untuk menyimpan gambar.'),
          _buildGuideStep('2', 'Buka m-Banking (BCA, Livin, BRImo, dll) atau E-Wallet (GoPay, OVO, DANA, ShopeePay).'),
          _buildGuideStep('3', 'Pilih menu Scan QRIS, lalu tekan ikon Galeri/Foto.'),
          _buildGuideStep('4', 'Pilih gambar QRIS tadi dan selesaikan pembayaran.'),
          _buildGuideStep('5', 'Setelah transfer selesai, sistem akan mendeteksi otomatis dalam hitungan detik dan langsung membuka website toko Anda.'),
        ],
      ),
    );
  }

  Widget _buildGuideStep(String step, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 16,
            height: 16,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFF2563EB),
              shape: BoxShape.circle,
            ),
            child: Text(
              step,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF1E293B),
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(Map<String, dynamic> data) {
    final storeName = data['store_name']?.toString() ?? 'Toko Anda';
    final subdomain = data['subdomain']?.toString() ?? '';
    final storeUrl = data['store_url']?.toString() ??
        'https://$subdomain.ekasir.my.id';
    final loginUrl = data['login_url']?.toString() ??
        'https://$subdomain.ekasir.my.id/#/admin/login';
    final ownerMap = data['owner'] as Map<String, dynamic>?;
    final ownerEmail = ownerMap?['email']?.toString() ?? _emailCtrl.text.trim();
    final invoiceMap = data['invoice'] as Map<String, dynamic>?;
    final invoiceCode = invoiceMap?['code']?.toString() ?? 'INV-PAID';

    final isLocal = kIsWeb && (Uri.base.host == 'localhost' || Uri.base.host == '127.0.0.1');
    final activeStoreUrl = isLocal ? '${Uri.base.origin}/?tenant=$subdomain' : storeUrl;
    final activeLoginUrl = isLocal ? '${Uri.base.origin}/#/admin/login?tenant=$subdomain' : loginUrl;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final isMobile = MediaQuery.of(ctx).size.width <= 600;
        return Dialog(
          insetPadding: isMobile
              ? const EdgeInsets.symmetric(horizontal: 14, vertical: 20)
              : const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(isMobile ? 18 : 24)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 18.0 : 28.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon Success
                  Container(
                    width: isMobile ? 54 : 64,
                    height: isMobile ? 54 : 64,
                    decoration: const BoxDecoration(
                      color: Color(0xFFDCFCE7),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: const Color(0xFF16A34A),
                      size: isMobile ? 32 : 38,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Pembelian Berhasil & Toko Aktif! 🎉',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isMobile ? 19 : 22,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Selamat! Website untuk "$storeName" telah berhasil dibuat dan sudah dapat diakses langsung oleh pelanggan maupun kasir.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isMobile ? 12 : 13,
                      color: const Color(0xFF64748B),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Detail Card
                  Container(
                    padding: EdgeInsets.all(isMobile ? 12 : 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        _buildReceiptRow('No. Invoice', invoiceCode),
                        const Divider(height: 16),
                        _buildReceiptRow(
                          'Alamat Website',
                          storeUrl,
                          isLink: true,
                          onTap: () => ImageSaver.openUrl(activeStoreUrl),
                        ),
                        const Divider(height: 16),
                        _buildReceiptRow('Email Login Owner', ownerEmail),
                        const Divider(height: 16),
                        _buildReceiptRow(
                          'Status Aktivasi',
                          'Aktif & Terproteksi SSL',
                          statusColor: const Color(0xFF16A34A),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        ImageSaver.openUrl(activeStoreUrl);
                      },
                      icon: const Icon(Icons.open_in_new_rounded, size: 18),
                      label: const Text(
                        'Buka Website Toko Saya',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        ImageSaver.openUrl(activeLoginUrl);
                      },
                      icon: const Icon(Icons.admin_panel_settings_rounded, size: 18),
                      label: const Text(
                        'Masuk ke Panel Kasir / Admin',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0F172A),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.of(context).pushReplacementNamed(RouteName.customerMenu);
                    },
                    child: const Text('Kembali ke Halaman Beranda'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildReceiptRow(String label, String value,
      {bool isLink = false, Color? statusColor, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  decoration: isLink ? TextDecoration.underline : null,
                  color: statusColor ??
                      (isLink ? const Color(0xFF2563EB) : const Color(0xFF0F172A)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingPaymentBanner() {
    if (_pendingRegistration == null) return const SizedBox.shrink();

    final invoiceMap = _pendingRegistration!['invoice'] as Map<String, dynamic>? ?? {};
    final invoiceCode = invoiceMap['code']?.toString() ?? '-';
    final amount = invoiceMap['amount'] is int ? invoiceMap['amount'] as int : _planPrice;
    final storeName = _pendingRegistration!['store_name']?.toString() ??
        (_storeNameCtrl.text.isNotEmpty ? _storeNameCtrl.text : 'Toko Baru');
    final subdomain = _pendingRegistration!['subdomain']?.toString() ??
        (_subdomainCtrl.text.isNotEmpty ? _subdomainCtrl.text : '-');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF86EFAC), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF16A34A).withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.pending_actions_rounded,
                  color: Color(0xFF15803D),
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Menunggu Pembayaran Invoice #$invoiceCode',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF14532D),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 10,
                                height: 10,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFFD97706),
                                ),
                              ),
                              SizedBox(width: 5),
                              Text(
                                'Cek Otomatis',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFB45309),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Toko: $storeName ($subdomain.ekasir.my.id) • Total: ${CurrencyFormatter.rupiah(amount)}',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF166534),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Sistem otomatis mendeteksi ketika Anda telah membayar QRIS dan akan langsung mengaktifkan toko. Klik tombol di bawah untuk menampilkan QRIS kembali.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF4B5563),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              ElevatedButton.icon(
                onPressed: () => _showQrisPaymentDialog(_pendingRegistration!),
                icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
                label: const Text(
                  'Buka QRIS Pembayaran Kembali',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      title: const Text('Batalkan Tagihan Ini?'),
                      content: const Text(
                        'Tagihan pending saat ini akan dibatalkan sehingga Anda dapat mendaftar ulang dengan data atau paket baru.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Kembali'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFDC2626),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Batalkan Tagihan'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await _clearPendingRegistration();
                  }
                },
                icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFFDC2626)),
                label: const Text(
                  'Batalkan Tagihan',
                  style: TextStyle(
                    color: Color(0xFFDC2626),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFFCA5A5)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;
    final isMobile = size.width <= 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(68),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: const Border(
              bottom: BorderSide(color: Color(0xFFE2E8F0)),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 48.0 : (isMobile ? 12.0 : 16.0),
                vertical: 8.0,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, size: 20),
                    tooltip: 'Kembali',
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        Navigator.pushReplacementNamed(context, RouteName.customerMenu);
                      }
                    },
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.storefront_rounded,
                      color: Colors.white,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isMobile ? 'Beli Website' : 'eKasir',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      if (!isMobile)
                        const Text(
                          'Pendaftaran & Pembelian Website Mandiri',
                          style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: isMobile ? 8 : 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.shield_outlined,
                            size: 14, color: Color(0xFF16A34A)),
                        const SizedBox(width: 4),
                        Text(
                          isMobile ? '24 Jam Aktif' : 'Aktivasi Otomatis 24 Jam',
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF166534),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 48.0 : (isMobile ? 12.0 : 16.0),
            vertical: isMobile ? 18.0 : 32.0,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 880),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_pendingRegistration != null) ...[
                      _buildPendingPaymentBanner(),
                      const SizedBox(height: 24),
                    ],

                    // SECTION 1: IDENTITAS TOKO
                    _buildSectionCard(
                      stepNumber: '1',
                      title: 'Identitas Toko & Pilihan Subdomain',
                      subtitle:
                          'Tentukan nama brand dan alamat link website toko Anda.',
                      children: [
                        _buildTextField(
                          controller: _storeNameCtrl,
                          label: 'Nama Usaha / Toko *',
                          hint: 'Masukkan nama usaha atau toko Anda',
                          icon: Icons.storefront_rounded,
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Nama toko wajib diisi'
                              : null,
                        ),
                        const SizedBox(height: 16),

                        // Subdomain field + live preview
                        const Text(
                          'Pilihan Subdomain Website Toko *',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _subdomainCtrl,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            hintText: 'masukkan-subdomain',
                            prefixIcon: const Icon(Icons.language_rounded,
                                color: Color(0xFF2563EB), size: 20),
                            suffixText: '.ekasir.my.id',
                            suffixStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2563EB),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: Color(0xFFCBD5E1)),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Subdomain wajib diisi';
                            }
                            if (v.trim().length < 3) {
                              return 'Subdomain minimal 3 karakter';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),

                        // Subdomain Preview & Live Check
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _isCheckingSubdomain
                                  ? null
                                  : () => _checkSubdomainAvailability(),
                              icon: _isCheckingSubdomain
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : const Icon(Icons.refresh_rounded, size: 16),
                              label: Text(_isCheckingSubdomain
                                  ? 'Mengecek...'
                                  : 'Cek Ketersediaan'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                textStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                            if (_isCheckingSubdomain)
                              const Text(
                                'Memeriksa ketersediaan ke database...',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                          ],
                        ),
                        if (_isSubdomainAvailable != null && !_isCheckingSubdomain) ...[
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: _isSubdomainAvailable == true
                                  ? const Color(0xFFF0FDF4)
                                  : const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _isSubdomainAvailable == true
                                    ? const Color(0xFF86EFAC)
                                    : const Color(0xFFFECACA),
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _isSubdomainAvailable == true
                                      ? Icons.check_circle_rounded
                                      : Icons.cancel_rounded,
                                  size: 16,
                                  color: _isSubdomainAvailable == true
                                      ? const Color(0xFF16A34A)
                                      : const Color(0xFFDC2626),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _subdomainCheckMessage,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: _isSubdomainAvailable == true
                                          ? const Color(0xFF15803D)
                                          : const Color(0xFFB91C1C),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),

                        // Kategori Usaha
                        const Text(
                          'Kategori Usaha Kuliner *',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _businessCategories.map((cat) {
                            final isSelected = _selectedCategory == cat;
                            return ChoiceChip(
                              label: Text(cat),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedCategory = selected ? cat : null;
                                });
                              },
                              selectedColor: const Color(0xFFEFF6FF),
                              backgroundColor: Colors.white,
                              labelStyle: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? const Color(0xFF1D4ED8)
                                    : const Color(0xFF475569),
                              ),
                              side: BorderSide(
                                color: isSelected
                                    ? const Color(0xFF2563EB)
                                    : const Color(0xFFCBD5E1),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),

                        // Alamat
                        _buildTextField(
                          controller: _addressCtrl,
                          label: 'Alamat Usaha / Lokasi Toko',
                          hint: 'Masukkan alamat atau lokasi toko (opsional)',
                          icon: Icons.location_on_outlined,
                          maxLines: 2,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // SECTION 2: DATA PEMILIK & LOGIN
                    _buildSectionCard(
                      stepNumber: '2',
                      title: 'Data Akun Pemilik (Admin / Kasir)',
                      subtitle:
                          'Akun ini akan menjadi akses pemilik untuk masuk ke dashboard toko.',
                      children: [
                        _buildTextField(
                          controller: _ownerNameCtrl,
                          label: 'Nama Lengkap Pemilik *',
                          hint: 'Masukkan nama lengkap pemilik',
                          icon: Icons.person_outline_rounded,
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Nama pemilik wajib diisi'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _whatsappCtrl,
                          label: 'Nomor WhatsApp Pemilik *',
                          hint: '08xxxxxxxxxx (untuk notifikasi pesanan)',
                          icon: Icons.chat_bubble_outline_rounded,
                          keyboardType: TextInputType.phone,
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Nomor WhatsApp wajib diisi'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _emailCtrl,
                          label: 'Email Login Pemilik *',
                          hint: 'email@domain.com',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Email wajib diisi';
                            }
                            if (!v.contains('@') || !v.contains('.')) {
                              return 'Format email tidak valid';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        if (isMobile) ...[
                          _buildTextField(
                            controller: _passwordCtrl,
                            label: 'Password Login *',
                            hint: 'Minimal 6 karakter',
                            icon: Icons.lock_outline_rounded,
                            obscureText: _obscurePassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            validator: (v) => v == null || v.length < 6
                                ? 'Password minimal 6 karakter'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _confirmPasswordCtrl,
                            label: 'Konfirmasi Password *',
                            hint: 'Ulangi password',
                            icon: Icons.lock_reset_rounded,
                            obscureText: _obscureConfirmPassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword;
                                });
                              },
                            ),
                            validator: (v) => v == null || v.length < 6
                                ? 'Konfirmasi password wajib diisi'
                                : null,
                          ),
                        ] else ...[
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: _passwordCtrl,
                                  label: 'Password Login *',
                                  hint: 'Minimal 6 karakter',
                                  icon: Icons.lock_outline_rounded,
                                  obscureText: _obscurePassword,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                  validator: (v) => v == null || v.length < 6
                                      ? 'Password minimal 6 karakter'
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildTextField(
                                  controller: _confirmPasswordCtrl,
                                  label: 'Konfirmasi Password *',
                                  hint: 'Ulangi password',
                                  icon: Icons.lock_reset_rounded,
                                  obscureText: _obscureConfirmPassword,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureConfirmPassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscureConfirmPassword =
                                            !_obscureConfirmPassword;
                                      });
                                    },
                                  ),
                                  validator: (v) => v == null || v.length < 6
                                      ? 'Konfirmasi password wajib diisi'
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 24),

                    // SECTION 3: PILIHAN PAKET WEBSITE
                    _buildSectionCard(
                      stepNumber: '3',
                      title: 'Pilih Paket Website',
                      subtitle:
                          'Semua paket 0% potongan komisi transaksi seumur hidup.',
                      children: [
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = constraints.maxWidth > 640;

                            final card30k = _buildPlanOptionCard(
                              planId: 'plan_30k',
                              title: 'Paket Hemat',
                              price: 'Rp 30.000',
                              period: '/bln',
                              badge: 'HEMAT',
                              features: const [
                                PlanFeatureItem(
                                    'Hadir semua jenis akun (Owner, Kasir, Dapur)'),
                                PlanFeatureItem('Maksimal menu hanya 10 menu'),
                                PlanFeatureItem(
                                    'Tidak ada sistem barcode per meja',
                                    isIncluded: false),
                                PlanFeatureItem(
                                    'Tidak ada biaya admin (0% Komisi)'),
                                PlanFeatureItem('Subdomain [nama].ekasir.my.id'),
                              ],
                            );

                            final card70k = _buildPlanOptionCard(
                              planId: 'plan_70k',
                              title: 'Paket Standar',
                              price: 'Rp 70.000',
                              period: '/bln',
                              badge: 'POPULER',
                              features: const [
                                PlanFeatureItem(
                                    'Hadir semua jenis akun (Owner, Kasir, Dapur)'),
                                PlanFeatureItem('Maksimal hingga 20 menu'),
                                PlanFeatureItem(
                                    'Ada sistem barcode (Maksimal 15 meja)'),
                                PlanFeatureItem(
                                    'Tidak ada biaya admin (0% Komisi)'),
                                PlanFeatureItem('Subdomain [nama].ekasir.my.id'),
                              ],
                            );

                            final card100k = _buildPlanOptionCard(
                              planId: 'plan_100k',
                              title: 'Paket Pro Unlimited',
                              price: 'Rp 100.000',
                              period: '/bln',
                              badge: '⭐ BEST SELLER',
                              isRecommended: true,
                              features: const [
                                PlanFeatureItem(
                                    'Hadir semua jenis akun (Owner, Kasir, Dapur, Mgr)'),
                                PlanFeatureItem(
                                    'Ada barcode & tidak ada batas meja (Unlimited Meja)',
                                    isHighlight: true),
                                PlanFeatureItem(
                                    'Tidak ada batas maksimal menu (Unlimited Menu)',
                                    isHighlight: true),
                                PlanFeatureItem(
                                    'Tidak ada biaya admin (0% Komisi)'),
                                PlanFeatureItem('Subdomain [nama].ekasir.my.id'),
                              ],
                            );

                            final card1jt = _buildPlanOptionCard(
                              planId: 'plan_1jt',
                              title: 'Paket Custom Domain',
                              price: 'Rp 1.000.000',
                              period: '/thn',
                              badge: '👑 VIP TAHUNAN',
                              features: const [
                                PlanFeatureItem(
                                    'Domain sendiri (Contoh: namatoko.com / .id)',
                                    isHighlight: true),
                                PlanFeatureItem(
                                    'Semua fitur yang ada di pilihan lain (Full Akses)',
                                    isHighlight: true),
                                PlanFeatureItem(
                                    'Hadir semua jenis akun lengkap'),
                                PlanFeatureItem(
                                    'Tanpa batas menu & barcode meja'),
                                PlanFeatureItem(
                                    'Tidak ada biaya admin (0% Komisi)'),
                                PlanFeatureItem(
                                    'Prioritas bantuan teknis & SSL domain'),
                              ],
                            );

                            if (isWide) {
                              return Column(
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(child: card30k),
                                      const SizedBox(width: 16),
                                      Expanded(child: card70k),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(child: card100k),
                                      const SizedBox(width: 16),
                                      Expanded(child: card1jt),
                                    ],
                                  ),
                                ],
                              );
                            } else {
                              return Column(
                                children: [
                                  card30k,
                                  const SizedBox(height: 14),
                                  card70k,
                                  const SizedBox(height: 14),
                                  card100k,
                                  const SizedBox(height: 14),
                                  card1jt,
                                ],
                              );
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // SECTION 4: METODE PEMBAYARAN & CHECKOUT
                    _buildSectionCard(
                      stepNumber: '4',
                      title: 'Metode Pembayaran & Konfirmasi',
                      subtitle:
                          'Pilih metode pembayaran untuk aktivasi instan.',
                      children: [
                        // Single QRIS Payment Method Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF2563EB),
                              width: 2,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDBEAFE),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.qr_code_2_rounded,
                                      color: Color(0xFF1D4ED8),
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Wrap(
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          spacing: 8,
                                          runSpacing: 4,
                                          children: [
                                            const Text(
                                              'QRIS Instan',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF0F172A),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 8, vertical: 2),
                                              decoration: const BoxDecoration(
                                                color: Color(0xFFDCFCE7),
                                                borderRadius: BorderRadius.all(
                                                    Radius.circular(6)),
                                              ),
                                              child: const Text(
                                                'AKTIF & OTOMATIS',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w800,
                                                  color: Color(0xFF166534),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        const Text(
                                          'GoPay, OVO, DANA, ShopeePay, BCA, Mandiri, BRI, BNI & Semua Mobile Banking',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: Color(0xFF2563EB),
                                    size: 24,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: const Color(0xFFBFDBFE)),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.info_outline_rounded,
                                        size: 16, color: Color(0xFF2563EB)),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Kode QRIS resmi dengan nominal tagihan otomatis akan langsung ditampilkan untuk discan atau didownload.',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF1E40AF),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Rincian Pembayaran Box
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Ringkasan Tagihan Pembelian:',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildSummaryRow(
                                'Pilihan Paket Website',
                                _planTitle,
                              ),
                              _buildSummaryRow(
                                'Biaya Pembelian Paket',
                                'Rp ${_planPrice.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} $_planPeriod',
                              ),
                              const Divider(height: 20),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Total Pembayaran',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  Text(
                                    'Rp ${_planPrice.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF2563EB),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Inline Warning Banner jika formulir belum lengkap
                        if (_formErrorNotice != null) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFFCA5A5)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline_rounded,
                                    color: Color(0xFFDC2626), size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _formErrorNotice!,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFB91C1C),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _submitPurchase,
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.qr_code_rounded,
                                    size: 22),
                            label: Text(
                              _isLoading
                                  ? 'Menyiapkan Tagihan & QRIS...'
                                  : (isMobile
                                      ? 'Bayar & Aktifkan Website Sekarang'
                                      : 'Bayar & Aktifkan Website Toko Saya Sekarang'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: isMobile ? 14.5 : 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF16A34A),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: isMobile ? 16 : 20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 3,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Center(
                          child: Text(
                            '🔒 Pembayaran aman • Toko dan database langsung aktif secara instan',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // HELPER WIDGETS
  // ─────────────────────────────────────────────────────────────


  Widget _buildSectionCard({
    required String stepNumber,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    final isMobile = MediaQuery.of(context).size.width <= 600;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 16 : 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: isMobile ? 28 : 32,
                height: isMobile ? 28 : 32,
                decoration: const BoxDecoration(
                  color: Color(0xFF2563EB),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    stepNumber,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: isMobile ? 13 : 15,
                    ),
                  ),
                ),
              ),
              SizedBox(width: isMobile ? 10 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: isMobile ? 16 : 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: isMobile ? 11 : 12,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 14 : 20),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          SizedBox(height: isMobile ? 14 : 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          maxLines: maxLines,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            hintText: hint,
            prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 20),
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFF2563EB), width: 1.8),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildPlanOptionCard({
    required String planId,
    required String title,
    required String price,
    String period = '/bln',
    required String badge,
    required List<PlanFeatureItem> features,
    bool isRecommended = false,
  }) {
    final isSelected = _selectedPlan == planId;
    final isMobile = MediaQuery.of(context).size.width <= 600;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedPlan = planId;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(isMobile ? 14 : 18),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2563EB)
                : const Color(0xFFCBD5E1),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isRecommended
                        ? const Color(0xFF2563EB)
                        : (isSelected
                            ? const Color(0xFFDBEAFE)
                            : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isRecommended
                          ? Colors.white
                          : (isSelected
                              ? const Color(0xFF1D4ED8)
                              : const Color(0xFF475569)),
                    ),
                  ),
                ),
                Icon(
                  isSelected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  color: isSelected
                      ? const Color(0xFF2563EB)
                      : const Color(0xFF94A3B8),
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  price,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  period,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            ...features.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        f.isIncluded
                            ? Icons.check_circle_rounded
                            : Icons.cancel_outlined,
                        size: 15,
                        color: f.isIncluded
                            ? (f.isHighlight
                                ? const Color(0xFF2563EB)
                                : const Color(0xFF16A34A))
                            : const Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          f.text,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: f.isHighlight
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: f.isIncluded
                                ? const Color(0xFF334155)
                                : const Color(0xFF94A3B8),
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PlanFeatureItem {
  final String text;
  final bool isIncluded;
  final bool isHighlight;

  const PlanFeatureItem(
    this.text, {
    this.isIncluded = true,
    this.isHighlight = false,
  });
}
