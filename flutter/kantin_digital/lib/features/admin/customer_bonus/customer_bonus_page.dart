import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/top_notification.dart';
import '../../../shared/models/customer_bonus_model.dart';
import '../../../shared/services/customer_bonus_service.dart';

class CustomerBonusPage extends StatefulWidget {
  const CustomerBonusPage({super.key});

  @override
  State<CustomerBonusPage> createState() => _CustomerBonusPageState();
}

class _CustomerBonusPageState extends State<CustomerBonusPage> {
  final CustomerBonusService _service = CustomerBonusService();
  final TextEditingController _searchCtrl = TextEditingController();

  bool _loading = true;
  bool _withBalanceOnly = false;
  CustomerBonusSummary _summary = CustomerBonusSummary();
  List<CustomerBonusModel> _bonuses = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final res = await _service.getBonuses(
        search: _searchCtrl.text.trim(),
        withBalanceOnly: _withBalanceOnly,
      );
      if (!mounted) return;
      setState(() {
        _summary = res['summary'] as CustomerBonusSummary;
        _bonuses = res['bonuses'] as List<CustomerBonusModel>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      TopNotification.show(
        message: 'Gagal memuat data bonus konsumen: $e',
        backgroundColor: AppColors.danger,
        icon: Icons.error_rounded,
      );
    }
  }

  void _openWhatsApp(String phone) async {
    var clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.startsWith('0')) {
      clean = '62${clean.substring(1)}';
    }
    final uri = Uri.parse('https://wa.me/$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      TopNotification.show(
        message: 'Tidak dapat membuka WhatsApp untuk nomor $phone',
        backgroundColor: AppColors.warning,
        icon: Icons.warning_rounded,
      );
    }
  }

  Future<void> _showAddCustomerDialog() async {
    final phoneCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final percentCtrl = TextEditingController(text: '5');
    final notesCtrl = TextEditingController();
    bool saving = false;

    await showDialog(
      context: context,
      barrierDismissible: !saving,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.person_add_rounded, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Daftar Konsumen Bonus',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Daftarkan nomor HP konsumen tertentu agar setiap transaksinya mengumpulkan bonus belanja.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  const Text('Nomor HP / WhatsApp *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      hintText: 'Contoh: 081234567890',
                      prefixIcon: const Icon(Icons.phone_android_rounded, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Nama Konsumen', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      hintText: 'Nama pelanggan (opsional)',
                      prefixIcon: const Icon(Icons.badge_rounded, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Persentase Bonus Konsumen Ini (%) *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: percentCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      suffixText: '%',
                      hintText: 'Misal: 5 atau 10',
                      prefixIcon: const Icon(Icons.percent_rounded, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [2, 5, 7, 10, 15].map((pct) {
                      return ActionChip(
                        label: Text('$pct%'),
                        backgroundColor: percentCtrl.text == pct.toString()
                            ? AppColors.primary
                            : Colors.grey.shade100,
                        labelStyle: TextStyle(
                          color: percentCtrl.text == pct.toString() ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        onPressed: () {
                          setDialogState(() {
                            percentCtrl.text = pct.toString();
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  const Text('Catatan / Kategori', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: notesCtrl,
                    decoration: InputDecoration(
                      hintText: 'Misal: Member VIP, Reseller, Langganan Kantor...',
                      prefixIcon: const Icon(Icons.notes_rounded, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(dialogCtx),
                child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                ),
                onPressed: saving
                    ? null
                    : () async {
                        final phone = phoneCtrl.text.trim();
                        final pct = int.tryParse(percentCtrl.text.trim()) ?? 0;
                        if (phone.isEmpty || phone.length < 8) {
                          TopNotification.show(
                            message: 'Masukkan nomor HP yang valid',
                            backgroundColor: AppColors.warning,
                          );
                          return;
                        }
                        if (pct <= 0 || pct > 100) {
                          TopNotification.show(
                            message: 'Persentase bonus harus antara 1% - 100%',
                            backgroundColor: AppColors.warning,
                          );
                          return;
                        }

                        setDialogState(() => saving = true);
                        try {
                          await _service.createBonusCustomer(
                            customerPhone: phone,
                            customerName: nameCtrl.text.trim(),
                            bonusPercent: pct,
                            notes: notesCtrl.text.trim(),
                          );
                          if (!dialogCtx.mounted) return;
                          Navigator.pop(dialogCtx);
                          TopNotification.show(
                            message: 'Konsumen $phone berhasil didaftarkan!',
                            backgroundColor: AppColors.success,
                            icon: Icons.check_circle_rounded,
                          );
                          _loadData();
                        } catch (e) {
                          setDialogState(() => saving = false);
                          TopNotification.show(
                            message: 'Gagal mendaftarkan konsumen: $e',
                            backgroundColor: AppColors.danger,
                            icon: Icons.error_rounded,
                          );
                        }
                      },
                child: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Daftarkan'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showEditCustomerDialog(CustomerBonusModel item) async {
    final nameCtrl = TextEditingController(text: item.customerName ?? '');
    final percentCtrl = TextEditingController(text: item.bonusPercent.toString());
    final notesCtrl = TextEditingController(text: item.notes ?? '');
    bool isActive = item.isActive;
    bool saving = false;

    await showDialog(
      context: context,
      barrierDismissible: !saving,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.edit_rounded, color: Color(0xFFD97706), size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Edit Konsumen Bonus',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.phone_android_rounded, size: 18, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Text(
                          item.customerPhone,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Nama Konsumen', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      hintText: 'Nama pelanggan',
                      prefixIcon: const Icon(Icons.badge_rounded, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Persentase Bonus (%) *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: percentCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      suffixText: '%',
                      hintText: 'Misal: 5 atau 10',
                      prefixIcon: const Icon(Icons.percent_rounded, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [2, 5, 7, 10, 15].map((pct) {
                      return ActionChip(
                        label: Text('$pct%'),
                        backgroundColor: percentCtrl.text == pct.toString()
                            ? const Color(0xFFF59E0B)
                            : Colors.grey.shade100,
                        labelStyle: TextStyle(
                          color: percentCtrl.text == pct.toString() ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        onPressed: () {
                          setDialogState(() {
                            percentCtrl.text = pct.toString();
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  const Text('Catatan / Kategori', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: notesCtrl,
                    decoration: InputDecoration(
                      hintText: 'Misal: Reseller, Member VIP...',
                      prefixIcon: const Icon(Icons.notes_rounded, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: isActive,
                    activeColor: const Color(0xFF10B981),
                    title: const Text('Status Bonus Aktif', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    subtitle: const Text(
                      'Jika dinonaktifkan, transaksi konsumen ini tidak akan dihitung bonus.',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                    onChanged: (val) => setDialogState(() => isActive = val),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(dialogCtx),
                child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                ),
                onPressed: saving
                    ? null
                    : () async {
                        final pct = int.tryParse(percentCtrl.text.trim()) ?? 0;
                        if (pct <= 0 || pct > 100) {
                          TopNotification.show(
                            message: 'Persentase bonus harus antara 1% - 100%',
                            backgroundColor: AppColors.warning,
                          );
                          return;
                        }

                        setDialogState(() => saving = true);
                        try {
                          await _service.updateBonusCustomer(
                            item.id,
                            customerName: nameCtrl.text.trim(),
                            bonusPercent: pct,
                            isActive: isActive,
                            notes: notesCtrl.text.trim(),
                          );
                          if (!dialogCtx.mounted) return;
                          Navigator.pop(dialogCtx);
                          TopNotification.show(
                            message: 'Data konsumen berhasil diperbarui!',
                            backgroundColor: AppColors.success,
                            icon: Icons.check_circle_rounded,
                          );
                          _loadData();
                        } catch (e) {
                          setDialogState(() => saving = false);
                          TopNotification.show(
                            message: 'Gagal memperbarui: $e',
                            backgroundColor: AppColors.danger,
                            icon: Icons.error_rounded,
                          );
                        }
                      },
                child: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Simpan Perubahan'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showDeleteConfirm(CustomerBonusModel item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: AppColors.danger, size: 24),
            SizedBox(width: 8),
            Text('Hapus Konsumen Bonus?'),
          ],
        ),
        content: Text(
          'Nomor HP ${item.customerPhone} (${item.customerName ?? "Pelanggan"}) akan dihapus dari program bonus. Seluruh riwayat mutasi bonus nomor ini juga akan dibersihkan.',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _service.deleteBonusCustomer(item.id);
        TopNotification.show(
          message: 'Konsumen berhasil dihapus dari program bonus.',
          backgroundColor: AppColors.success,
          icon: Icons.check_circle_rounded,
        );
        _loadData();
      } catch (e) {
        TopNotification.show(
          message: 'Gagal menghapus konsumen: $e',
          backgroundColor: AppColors.danger,
          icon: Icons.error_rounded,
        );
      }
    }
  }

  Future<void> _showClaimDialog(CustomerBonusModel bonus) async {
    final amountCtrl = TextEditingController(text: bonus.bonusBalance.toString());
    final notesCtrl = TextEditingController(text: 'Pencairan bonus tunai');
    bool claiming = false;

    await showDialog(
      context: context,
      barrierDismissible: !claiming,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.paid_rounded, color: Color(0xFF10B981), size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Cairkan Bonus Konsumen',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bonus.customerName?.isNotEmpty == true
                              ? bonus.customerName!
                              : 'Pelanggan Setia',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'No. HP: ${bonus.customerPhone}',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Sisa Saldo Bonus:', style: TextStyle(fontSize: 13)),
                            Text(
                              CurrencyFormatter.format(bonus.bonusBalance),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF10B981),
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Nominal Dicairkan (Rp)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      prefixText: 'Rp ',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Catatan / Keterangan', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: notesCtrl,
                    decoration: InputDecoration(
                      hintText: 'Misal: Pencairan tunai di kasir...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: claiming ? null : () => Navigator.pop(dialogCtx),
                child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                ),
                onPressed: claiming
                    ? null
                    : () async {
                        final val = int.tryParse(amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                        if (val <= 0) {
                          TopNotification.show(
                            message: 'Masukkan nominal pencairan yang valid',
                            backgroundColor: AppColors.warning,
                          );
                          return;
                        }
                        if (val > bonus.bonusBalance) {
                          TopNotification.show(
                            message: 'Nominal pencairan melebihi sisa saldo bonus!',
                            backgroundColor: AppColors.warning,
                          );
                          return;
                        }

                        setDialogState(() => claiming = true);
                        try {
                          await _service.claimBonus(
                            bonus.id,
                            amount: val,
                            notes: notesCtrl.text.trim(),
                          );
                          if (!dialogCtx.mounted) return;
                          Navigator.pop(dialogCtx);
                          TopNotification.show(
                            message: 'Bonus berhasil dicairkan sebesar ${CurrencyFormatter.format(val)}',
                            backgroundColor: AppColors.success,
                            icon: Icons.check_circle_rounded,
                          );
                          _loadData();
                        } catch (e) {
                          setDialogState(() => claiming = false);
                          TopNotification.show(
                            message: 'Gagal mencairkan bonus: $e',
                            backgroundColor: AppColors.danger,
                            icon: Icons.error_rounded,
                          );
                        }
                      },
                child: claiming
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Proses Cairkan'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showLogsSheet(CustomerBonusModel bonus) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.history_rounded, color: Color(0xFF6366F1), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Riwayat Bonus & Belanja',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          '${bonus.customerName ?? "Pelanggan"} (${bonus.customerPhone}) • Rate: ${bonus.bonusPercent}%',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: FutureBuilder<List<CustomerBonusLogModel>>(
                future: _service.getLogs(bonus.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Gagal memuat riwayat: ${snapshot.error}'),
                    );
                  }
                  final logs = snapshot.data ?? [];
                  if (logs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text('Belum ada riwayat mutasi bonus.', style: TextStyle(color: Colors.grey.shade500)),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: logs.length,
                    separatorBuilder: (_, __) => const Divider(height: 16),
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      final isClaim = log.type == 'claim';
                      final isCancel = log.type == 'cancel';

                      Color badgeColor = const Color(0xFF10B981);
                      IconData icon = Icons.add_circle_outline_rounded;
                      String title = 'Bonus Masuk (${log.bonusPercent}%)';

                      if (isClaim) {
                        badgeColor = const Color(0xFFEF4444);
                        icon = Icons.remove_circle_outline_rounded;
                        title = 'Bonus Dicairkan';
                      } else if (isCancel) {
                        badgeColor = const Color(0xFFF59E0B);
                        icon = Icons.cancel_outlined;
                        title = 'Bonus Dibatalkan';
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: badgeColor.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(icon, color: badgeColor, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      title,
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: badgeColor),
                                    ),
                                    Text(
                                      (log.bonusAmount >= 0 ? '+' : '') + CurrencyFormatter.format(log.bonusAmount),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: badgeColor,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                if (log.notes?.isNotEmpty == true)
                                  Text(
                                    log.notes!,
                                    style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                                  ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      log.createdAt != null
                                          ? '${log.createdAt!.day.toString().padLeft(2, '0')}/${log.createdAt!.month.toString().padLeft(2, '0')}/${log.createdAt!.year} ${log.createdAt!.hour.toString().padLeft(2, '0')}:${log.createdAt!.minute.toString().padLeft(2, '0')}'
                                          : '-',
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                    ),
                                    Text(
                                      'Saldo: ${CurrencyFormatter.format(log.balanceAfter)}',
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Bonus & Loyalty Konsumen'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Segarkan',
            onPressed: _loadData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary cards
              _buildSummarySection(),
              const SizedBox(height: 16),

              // Filter & Search bar with Add Customer button
              _buildSearchFilterBar(),
              const SizedBox(height: 16),

              // Customer List
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_bonuses.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.stars_rounded, size: 56, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      const Text(
                        'Belum Ada Konsumen Terdaftar',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Hanya konsumen tertentu yang didaftarkan yang berhak mengumpulkan transaksi dan mendapatkan bonus cashback. Tekan tombol "+ Tambah Konsumen" di atas untuk mendaftarkan.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _bonuses.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = _bonuses[index];
                    return _buildCustomerBonusCard(item);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummarySection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        final count = isWide ? 4 : 2;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: count,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: isWide ? 2.2 : 1.7,
          children: [
            _buildStatCard(
              title: 'Konsumen Terdaftar',
              value: '${_summary.totalCustomers} Orang',
              icon: Icons.people_alt_rounded,
              color: const Color(0xFF3B82F6),
            ),
            _buildStatCard(
              title: 'Total Belanja Terkumpul',
              value: CurrencyFormatter.format(_summary.totalSpend),
              icon: Icons.shopping_bag_rounded,
              color: const Color(0xFF8B5CF6),
            ),
            _buildStatCard(
              title: 'Total Bonus Diterbitkan',
              value: CurrencyFormatter.format(_summary.totalBonusEarned),
              icon: Icons.stars_rounded,
              color: const Color(0xFFF59E0B),
            ),
            _buildStatCard(
              title: 'Sisa Saldo Bonus Aktif',
              value: CurrencyFormatter.format(_summary.totalBonusBalance),
              icon: Icons.account_balance_wallet_rounded,
              color: const Color(0xFF10B981),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchFilterBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  onSubmitted: (_) => _loadData(),
                  decoration: InputDecoration(
                    hintText: 'Cari nomor HP, nama, atau catatan...',
                    hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              _loadData();
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                ),
                onPressed: _showAddCustomerDialog,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Tambah'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              FilterChip(
                label: const Text('Semua Konsumen', style: TextStyle(fontSize: 12)),
                selected: !_withBalanceOnly,
                onSelected: (val) {
                  setState(() => _withBalanceOnly = false);
                  _loadData();
                },
                selectedColor: AppColors.primary.withValues(alpha: 0.15),
                checkmarkColor: AppColors.primary,
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Hanya Saldo > Rp 0', style: TextStyle(fontSize: 12)),
                selected: _withBalanceOnly,
                onSelected: (val) {
                  setState(() => _withBalanceOnly = val);
                  _loadData();
                },
                selectedColor: const Color(0xFF10B981).withValues(alpha: 0.15),
                checkmarkColor: const Color(0xFF10B981),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerBonusCard(CustomerBonusModel item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.isActive ? Colors.grey.shade200 : Colors.grey.shade300,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Name, Phone, and Action Menu
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: item.isActive
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : Colors.grey.shade200,
                child: Icon(
                  Icons.person_rounded,
                  color: item.isActive ? AppColors.primary : Colors.grey.shade500,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.customerName?.isNotEmpty == true ? item.customerName! : 'Pelanggan Khusus',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Badge Persentase Khusus
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            '⭐ ${item.bonusPercent}% Bonus',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFD97706),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.phone_android_rounded, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          item.customerPhone,
                          style: TextStyle(color: Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 8),
                        if (!item.isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('Nonaktif', style: TextStyle(fontSize: 10, color: Colors.grey)),
                          ),
                      ],
                    ),
                    if (item.notes?.isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.notes!,
                          style: const TextStyle(fontSize: 11, color: Color(0xFF4F46E5), fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chat_rounded, color: Color(0xFF25D366)),
                tooltip: 'Hubungi via WhatsApp',
                onPressed: () => _openWhatsApp(item.customerPhone),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, size: 20),
                onSelected: (val) {
                  if (val == 'edit') {
                    _showEditCustomerDialog(item);
                  } else if (val == 'delete') {
                    _showDeleteConfirm(item);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_rounded, size: 18, color: Color(0xFFF59E0B)),
                        SizedBox(width: 8),
                        Text('Edit Data & Bonus'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.danger),
                        SizedBox(width: 8),
                        Text('Hapus Konsumen', style: TextStyle(color: AppColors.danger)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 20),

          // Statistics Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Belanja', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                    const SizedBox(height: 2),
                    Text(
                      CurrencyFormatter.format(item.totalSpend),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    Text('(${item.totalOrders}x Transaksi)', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Didapat', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                    const SizedBox(height: 2),
                    Text(
                      CurrencyFormatter.format(item.totalBonusEarned),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFF59E0B)),
                    ),
                    Text('Dicairkan: ${CurrencyFormatter.format(item.totalBonusClaimed)}', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Sisa Saldo Bonus', style: TextStyle(fontSize: 10, color: Color(0xFF047857), fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(
                      CurrencyFormatter.format(item.bonusBalance),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF047857),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF6366F1),
                    side: const BorderSide(color: Color(0xFF6366F1)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  onPressed: () => _showLogsSheet(item),
                  icon: const Icon(Icons.receipt_long_rounded, size: 16),
                  label: const Text('Riwayat Mutasi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: item.bonusBalance > 0 ? const Color(0xFF10B981) : Colors.grey.shade300,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  onPressed: item.bonusBalance > 0 ? () => _showClaimDialog(item) : null,
                  icon: const Icon(Icons.account_balance_wallet_rounded, size: 16),
                  label: const Text('Cairkan Bonus', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
