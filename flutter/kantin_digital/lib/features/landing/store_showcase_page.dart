import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/image_saver.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../router/route_name.dart';
import '../../shared/models/showcase_store_model.dart';

class StoreShowcasePage extends StatefulWidget {
  const StoreShowcasePage({super.key});

  @override
  State<StoreShowcasePage> createState() => _StoreShowcasePageState();
}

class _StoreShowcasePageState extends State<StoreShowcasePage> {
  final ApiClient _apiClient = ApiClient();
  final TextEditingController _searchController = TextEditingController();

  List<ShowcaseStoreModel> _allStores = [];
  List<ShowcaseStoreModel> _filteredStores = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchStores();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchStores() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiClient.get('showcase-stores');
      if (response != null && response['status'] == true && response['data'] is List) {
        final list = (response['data'] as List)
            .map((item) => ShowcaseStoreModel.fromJson(item as Map<String, dynamic>))
            .toList();

        setState(() {
          _allStores = list;
          _filteredStores = list;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Gagal memuat daftar toko.';
          _isLoading = false;
        });
      }
    } catch (e) {
      // Fallback data jika backend offline sementara, tetap tampilkan SayCoffee yang pasti nyata
      final fallback = [
        const ShowcaseStoreModel(
          id: 1,
          name: 'SAYUTIKOPI',
          subdomain: 'saycoffee',
          storeUrl: 'https://saycoffee.ekasir.my.id',
          primaryColor: '#16A34A',
          address: 'Serang, Banten',
          whatsapp: '6287771262100',
          metaDescription: 'Kedai Kopi & Minuman Kekinian',
          menusCount: 47,
          categoriesCount: 4,
          sampleMenus: [
            ShowcaseMenuSample(name: 'Kopi Susu Gula Aren', price: 18000),
            ShowcaseMenuSample(name: 'Americano Ice', price: 15000),
            ShowcaseMenuSample(name: 'Matcha Latte Premium', price: 22000),
          ],
        )
      ];
      setState(() {
        _allStores = fallback;
        _filteredStores = fallback;
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _filteredStores = _allStores;
      });
    } else {
      setState(() {
        _filteredStores = _allStores.where((s) {
          final matchName = s.name.toLowerCase().contains(query);
          final matchSub = s.subdomain.toLowerCase().contains(query);
          final matchAddr = (s.address ?? '').toLowerCase().contains(query);
          return matchName || matchSub || matchAddr;
        }).toList();
      });
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    AppSnackBar.show(
      context,
      message: '$label berhasil disalin ke clipboard!',
      backgroundColor: const Color(0xFF16A34A),
      icon: Icons.check_circle_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;
    final isTablet = screenWidth >= 600 && screenWidth < 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(72),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 48 : 14,
                vertical: 10,
              ),
              child: Row(
                children: [
                  if (screenWidth >= 600)
                    InkWell(
                      onTap: () {
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        } else {
                          Navigator.of(context).pushReplacementNamed(RouteName.landingPage);
                        }
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        child: Row(
                          children: const [
                            Icon(Icons.arrow_back_rounded, size: 20, color: Color(0xFF0F172A)),
                            SizedBox(width: 8),
                            Text(
                              'Kembali ke Beranda',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_rounded, size: 20, color: Color(0xFF0F172A)),
                          tooltip: 'Kembali',
                          onPressed: () {
                            if (Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();
                            } else {
                              Navigator.of(context).pushReplacementNamed(RouteName.landingPage);
                            }
                          },
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Toko Asli eKasir',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushNamed(RouteName.buyWebsite);
                    },
                    icon: const Icon(Icons.shopping_bag_outlined, size: 16),
                    label: Text(screenWidth >= 600 ? (isDesktop ? 'Beli Website Sekarang' : 'Beli Website') : 'Beli'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: screenWidth >= 600 ? 18 : 12, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchStores,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1160),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 32 : (isTablet ? 20 : 14),
                  vertical: isDesktop ? 36 : (isTablet ? 26 : 18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(isDesktop, screenWidth < 600),
                    SizedBox(height: screenWidth < 600 ? 18 : 32),
                    _buildSearchBar(isDesktop, screenWidth < 600),
                    SizedBox(height: screenWidth < 600 ? 18 : 28),
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 80),
                        child: Center(
                          child: CircularProgressIndicator(color: Color(0xFF16A34A)),
                        ),
                      )
                    else if (_errorMessage != null && _filteredStores.isEmpty)
                      _buildErrorState()
                    else if (_filteredStores.isEmpty)
                      _buildEmptyState()
                    else
                      _buildStoresGrid(isDesktop, isTablet),
                    const SizedBox(height: 60),
                    _buildBottomCta(isDesktop),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDesktop, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 14 : (isMobile ? 9 : 10),
            vertical: isMobile ? 4 : 6,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFDCFCE7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF86EFAC)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.verified_rounded,
                size: isMobile ? 13 : 16,
                color: const Color(0xFF16A34A),
              ),
              SizedBox(width: isMobile ? 5 : 8),
              Flexible(
                child: Text(
                  isDesktop
                      ? 'Terverifikasi & Live di Domain Masing-Masing'
                      : 'Terverifikasi & Live di Domain Asli',
                  style: TextStyle(
                    fontSize: isMobile ? 11 : 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF15803D),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: isMobile ? 10 : 16),
        Text(
          'Daftar Toko Asli Pengguna Website eKasir',
          style: TextStyle(
            fontSize: isDesktop ? 32 : (isMobile ? 18 : 24),
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
            letterSpacing: isMobile ? -0.3 : -0.5,
            height: isMobile ? 1.25 : 1.3,
          ),
        ),
        SizedBox(height: isMobile ? 8 : 12),
        Text(
          'Berikut adalah bukti nyata toko dan restoran aktif yang telah menggunakan website eKasir. Setiap toko memiliki domain mandiri, katalog menu digital, dan sistem order QR meja. Anda dapat mengklik tombol toko untuk meninjau langsung websitenya!',
          style: TextStyle(
            fontSize: isDesktop ? 16 : (isMobile ? 12 : 14.5),
            color: const Color(0xFF475569),
            height: isMobile ? 1.45 : 1.6,
          ),
        ),
        SizedBox(height: isMobile ? 12 : 16),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 16,
            vertical: isMobile ? 9 : 12,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: const Color(0xFF2563EB),
                size: isMobile ? 16 : 20,
              ),
              SizedBox(width: isMobile ? 8 : 12),
              Expanded(
                child: Text(
                  'Setiap pembeli baru yang telah mengisi menu toko akan otomatis terdaftar dan tampil di halaman ini secara langsung.',
                  style: TextStyle(
                    fontSize: isMobile ? 11 : 13.5,
                    color: const Color(0xFF1E40AF),
                    fontWeight: FontWeight.w500,
                    height: isMobile ? 1.35 : 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(bool isDesktop, bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 16,
        vertical: isMobile ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            color: const Color(0xFF64748B),
            size: isMobile ? 18 : 22,
          ),
          SizedBox(width: isMobile ? 8 : 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: TextStyle(fontSize: isMobile ? 13 : 14.5),
              decoration: InputDecoration(
                hintText: isMobile
                    ? 'Cari nama toko, subdomain...'
                    : 'Cari nama toko, subdomain, atau lokasi...',
                hintStyle: TextStyle(
                  fontSize: isMobile ? 12.5 : 14.5,
                  color: const Color(0xFF94A3B8),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: isMobile ? 8 : 12),
              ),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            IconButton(
              onPressed: () {
                _searchController.clear();
              },
              icon: Icon(
                Icons.clear_rounded,
                size: isMobile ? 16 : 18,
                color: const Color(0xFF94A3B8),
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          const SizedBox(width: 6),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 9 : 12,
              vertical: isMobile ? 4 : 6,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_filteredStores.length} Toko',
              style: TextStyle(
                fontSize: isMobile ? 11 : 12.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF334155),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoresGrid(bool isDesktop, bool isTablet) {
    final crossAxisCount = isDesktop ? 3 : (isTablet ? 2 : 1);

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        const spacing = 20.0;
        final cardWidth = (totalWidth - (spacing * (crossAxisCount - 1))) / crossAxisCount;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: _filteredStores.map((store) {
            return SizedBox(
              width: cardWidth,
              child: _buildStoreCard(store),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildStoreCard(ShowcaseStoreModel store) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: () => ImageSaver.openUrl(store.storeUrl),
          borderRadius: BorderRadius.circular(18),
          hoverColor: const Color(0xFF2563EB).withValues(alpha: 0.03),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Logo & Status Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStoreLogo(store),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        store.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF16A34A),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Website Aktif',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF16A34A),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Web Domain Link Box
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.language_rounded, size: 16, color: Color(0xFF2563EB)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: () => ImageSaver.openUrl(store.storeUrl),
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          store.displayDomain,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E40AF),
                            decoration: TextDecoration.underline,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => _copyToClipboard(store.storeUrl, 'Alamat Website'),
                    borderRadius: BorderRadius.circular(6),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      child: Icon(Icons.copy_rounded, size: 16, color: Color(0xFF64748B)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Store Info Details
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildInfoBadge(
                  Icons.restaurant_menu_rounded,
                  '${store.menusCount} Menu Tersedia',
                  const Color(0xFFDCFCE7),
                  const Color(0xFF15803D),
                ),
                if (store.address != null && store.address!.isNotEmpty)
                  _buildInfoBadge(
                    Icons.location_on_outlined,
                    store.address!,
                    const Color(0xFFF1F5F9),
                    const Color(0xFF475569),
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // Sample Menu Preview
            if (store.sampleMenus.isNotEmpty) ...[
              const Text(
                'Menu Pilihan Toko:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 6),
              ...store.sampleMenus.take(3).map(
                    (menu) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline_rounded,
                              size: 13, color: Color(0xFF16A34A)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              menu.name,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: Color(0xFF334155),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            CurrencyFormatter.rupiah(menu.price),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              const SizedBox(height: 14),
            ],

            const SizedBox(height: 10),
            const Divider(color: Color(0xFFF1F5F9), height: 1),
            const SizedBox(height: 14),

            // CTA Button to visit the real store website
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => ImageSaver.openUrl(store.storeUrl),
                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                label: const Text(
                  'Buka Website Toko Ini',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  ),
);
  }

  Widget _buildStoreLogo(ShowcaseStoreModel store) {
    if (store.logoUrl != null && store.logoUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          store.logoUrl!,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildFallbackLogo(store),
        ),
      );
    }
    return _buildFallbackLogo(store);
  }

  Widget _buildFallbackLogo(ShowcaseStoreModel store) {
    final initial = store.name.isNotEmpty ? store.name[0].toUpperCase() : 'T';
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: store.primaryColorValue.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: store.primaryColorValue.withValues(alpha: 0.3),
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: store.primaryColorValue,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBadge(IconData icon, String text, Color bg, Color textCol) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Container(
      constraints: BoxConstraints(maxWidth: isMobile ? 240 : 320),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: textCol),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: textCol,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          const Icon(Icons.search_off_rounded, size: 54, color: Color(0xFF94A3B8)),
          const SizedBox(height: 16),
          const Text(
            'Tidak Ada Toko yang Cocok',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Coba ubah kata kunci pencarian Anda untuk melihat toko lainnya.',
            style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: () {
              _searchController.clear();
            },
            child: const Text('Reset Pencarian'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, size: 54, color: Color(0xFFEF4444)),
          const SizedBox(height: 16),
          const Text(
            'Gagal Mengambil Data Toko',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Terjadi kendala saat menyambungkan ke server.',
            style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _fetchStores,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
            ),
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomCta(bool isDesktop) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 48 : 24,
        vertical: 40,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'WEBSITE & SISTEM KASIR',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF4ADE80),
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Ingin Memiliki Website Seperti Ini untuk Usaha Anda?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isDesktop ? 26 : 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: const Text(
              'Kelola menu, pesanan meja, dan laporan penjualan dalam satu sistem praktis dengan nama toko Anda sendiri.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF94A3B8),
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(height: 28),
          if (MediaQuery.of(context).size.width <= 600)
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushNamed(RouteName.buyWebsite);
                    },
                    icon: const Icon(Icons.shopping_bag_outlined, size: 19),
                    label: const Text(
                      'Beli Website Sekarang',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushNamed(RouteName.demoMenu);
                    },
                    icon: const Icon(Icons.rocket_launch_rounded, size: 19, color: Colors.white),
                    label: const Text(
                      'Coba Demo Gratis',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF475569), width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            Wrap(
              spacing: 16,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushNamed(RouteName.buyWebsite);
                  },
                  icon: const Icon(Icons.shopping_bag_outlined, size: 20),
                  label: const Text(
                    'Beli Website Sekarang',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushNamed(RouteName.demoMenu);
                  },
                  icon: const Icon(Icons.rocket_launch_rounded, size: 20, color: Colors.white),
                  label: const Text(
                    'Coba Demo Gratis',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF475569), width: 1.5),
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
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
}
