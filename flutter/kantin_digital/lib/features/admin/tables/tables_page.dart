import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/config/api_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/top_notification.dart';
import '../../../shared/models/table_model.dart';
import '../../admin/widgets/admin_drawer.dart';
import 'tables_controller.dart';

class AdminTablesPage extends StatefulWidget {
  const AdminTablesPage({super.key});

  @override
  State<AdminTablesPage> createState() => _AdminTablesPageState();
}

class _AdminTablesPageState extends State<AdminTablesPage> {
  final AdminTablesController _controller = AdminTablesController();
  final TextEditingController _searchController = TextEditingController();
  late Future<List<TableModel>> _future;
  final Set<int> _selectedTableIds = {};
  bool _isSelectMode = false;
  
  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _future = _controller.fetchTables();
    });
  }

  void _enterSelectMode() {
    setState(() {
      _isSelectMode = true;
      _selectedTableIds.clear();
    });
  }

  void _exitSelectMode() {
    setState(() {
      _isSelectMode = false;
      _selectedTableIds.clear();
    });
  }

  void _toggleTableSelection(int id) {
    setState(() {
      if (_selectedTableIds.contains(id)) {
        _selectedTableIds.remove(id);
      } else {
        _selectedTableIds.add(id);
      }
    });
  }

  Future<void> _deleteBulk() async {
    final ids = _selectedTableIds.toList();
    if (ids.isEmpty) return;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus ${ids.length} Meja?'),
        content: const Text('Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Hapus Semua'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sedang menghapus...')),
      );
      
      try {
        await _controller.deleteBulkTables(ids);
        _selectedTableIds.clear();
        _isSelectMode = false;
        _reload();
        
        if (!mounted) return;
        TopNotification.show(
          message: 'Berhasil menghapus ${ids.length} meja',
          backgroundColor: AppColors.success,
          icon: Icons.check_circle_rounded,
        );
      } catch (e) {
        if (!mounted) return;
        TopNotification.show(
          message: 'Gagal hapus: $e',
          backgroundColor: AppColors.danger,
          icon: Icons.error_rounded,
        );
      }
    }
  }

  Future<void> _delete(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Meja?'),
        content: const Text('Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      try {
        await _controller.deleteTable(id);
        _reload();
        if (!mounted) return;
        TopNotification.show(
          message: 'Meja berhasil dihapus',
          backgroundColor: AppColors.success,
          icon: Icons.check_circle_rounded,
        );
      } catch (e) {
        if (!mounted) return;
        TopNotification.show(
          message: 'Gagal menghapus: $e',
          backgroundColor: AppColors.danger,
          icon: Icons.error_rounded,
        );
      }
    }
  }

  Future<void> _showForm({TableModel? table}) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _TableFormDialog(
        table: table,
        onSaveSingle: (code) async {
            if (table == null) {
              await _controller.addTable(code);
            } else {
              await _controller.editTable(table.id, code);
            }
        },
        onSaveBulk: (prefix, start, end) async {
            await _controller.addBulkTables(prefix, start, end);
        },
        onSuccess: () {
            _reload();
            TopNotification.show(
              message: 'Berhasil disimpan',
              backgroundColor: AppColors.success,
              icon: Icons.check_circle_rounded,
            );
        },
      ),
    );
  }

  void _showQrDialog(TableModel table) {
    final qrData = '${ApiConfig.webBaseUrl}/#/?table=${table.code}';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('QR Code Meja ${table.code}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 200,
              height: 200,
              child: QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 200.0,
              ),
            ),
            const SizedBox(height: 16),
            Text(qrData, style: const TextStyle(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            const Text('Scan untuk memesan', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup')),
        ],
      ),
    );
  }

  Future<void> _showPrintDialog(List<TableModel> allTables) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Download PDF'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Pilih meja yang ingin dicetak:'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _generateAndDownloadPdf(allTables);
              },
              icon: const Icon(Icons.print),
              label: Text('Semua Meja (${allTables.length} meja)'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _enterSelectMode();
              },
              icon: const Icon(Icons.check_box),
              label: const Text('Pilih Meja Tertentu'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
        ],
      ),
    );
  }

  Future<void> _generateAndDownloadPdf(List<TableModel> allTables) async {
    final selectedTables = _selectedTableIds.isEmpty
        ? allTables
        : allTables.where((t) => _selectedTableIds.contains(t.id)).toList();

    if (selectedTables.isEmpty) {
      TopNotification.show(
        message: 'Pilih minimal 1 meja untuk dicetak',
        backgroundColor: AppColors.warning,
        icon: Icons.warning_rounded,
      );
      return;
    }

    try {
      TopNotification.show(
        message: 'Menghasilkan PDF untuk ${selectedTables.length} meja...',
        backgroundColor: AppColors.info,
        icon: Icons.print_rounded,
      );
      await _controller.generatePdf(selectedTables);
      if (!mounted) return;
      TopNotification.show(
        message: 'PDF berhasil dihasilkan!',
        backgroundColor: AppColors.success,
        icon: Icons.check_circle_rounded,
      );
      setState(() {
        _isSelectMode = false;
        _selectedTableIds.clear();
      });
    } catch (e) {
      if (!mounted) return;
      TopNotification.show(
        message: 'Error: $e',
        backgroundColor: AppColors.danger,
        icon: Icons.error_rounded,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: _isSelectMode 
            ? Text('${_selectedTableIds.length} dipilih')
            : const Text('Kelola Meja (QR)'),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: _isSelectMode ? 0 : null,
        leading: _isSelectMode 
          ? IconButton(
              icon: const Icon(Icons.close), 
              onPressed: _exitSelectMode,
            )
          : null,
        titleTextStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        actions: _isSelectMode
            ? [
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: _deleteBulk,
                  tooltip: 'Hapus Terpilih',
                ),
                IconButton(
                  icon: const Icon(Icons.print),
                  onPressed: () {
                    _future.then((tables) => _generateAndDownloadPdf(tables));
                  },
                  tooltip: 'Cetak Terpilih',
                ),
                const SizedBox(width: 8),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.print),
                  onPressed: () {
                    _future.then((tables) => _showPrintDialog(tables));
                  },
                  tooltip: 'Download PDF',
                ),
                IconButton(
                  icon: const Icon(Icons.checklist_rtl_rounded),
                  onPressed: _enterSelectMode,
                  tooltip: 'Pilih Banyak',
                ),
              ],
      ),
      drawer: const AdminDrawer(),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Cari nomor meja...',
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          
          Expanded(
            child: FutureBuilder<List<TableModel>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final allItems = snapshot.data ?? [];
                
                // Filter logic
                final query = _searchController.text.toLowerCase().trim();
                final items = allItems.where((t) {
                  return t.code.toLowerCase().contains(query);
                }).toList();
      
                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.table_restaurant_outlined, size: 64, color: AppColors.textMuted),
                        const SizedBox(height: 16),
                        Text(
                          allItems.isEmpty ? 'Belum ada meja' : 'Tidak ditemukan',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }
      
                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.85, 
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final isSelected = _selectedTableIds.contains(item.id);
                    
                    return GestureDetector(
                      onTap: _isSelectMode ? () => _toggleTableSelection(item.id) : null,
                      onLongPress: () {
                         if (!_isSelectMode) {
                           _enterSelectMode();
                           _toggleTableSelection(item.id);
                         }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.white,
                          border: isSelected 
                              ? Border.all(color: AppColors.primary, width: 2)
                              : null,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_isSelectMode)
                              Align(
                                alignment: Alignment.topRight,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected ? AppColors.primary : Colors.grey[300],
                                    ),
                                    child: isSelected
                                        ? const Icon(Icons.check, color: Colors.white, size: 14)
                                        : null,
                                  ),
                                ),
                              ),
                            InkWell(
                              onTap: _isSelectMode 
                                  ? () => _toggleTableSelection(item.id)
                                  : () => _showQrDialog(item),
                              child: Icon(Icons.qr_code_2, size: 64, color: AppColors.primary),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Meja ${item.code}',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            if (!_isSelectMode)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => _showForm(table: item),
                                    tooltip: 'Edit Kode',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _delete(item.id),
                                    tooltip: 'Hapus Meja',
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _isSelectMode
          ? FloatingActionButton.extended(
              onPressed: () {
                _future.then((tables) => _generateAndDownloadPdf(tables));
              },
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.print, color: Colors.white),
              label: const Text('Download PDF', style: TextStyle(color: Colors.white)),
            )
          : FloatingActionButton(
              onPressed: () => _showForm(),
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: Colors.white),
            ),
    );
  }
}

class _TableFormDialog extends StatefulWidget {
  final TableModel? table;
  final Function(String code) onSaveSingle;
  final Function(String prefix, int start, int end) onSaveBulk;
  final VoidCallback onSuccess;

  const _TableFormDialog({
    this.table,
    required this.onSaveSingle,
    required this.onSaveBulk,
    required this.onSuccess,
  });

  @override
  State<_TableFormDialog> createState() => _TableFormDialogState();
}

class _TableFormDialogState extends State<_TableFormDialog> {
  final TextEditingController _codeCtrl = TextEditingController();
  final TextEditingController _prefixCtrl = TextEditingController(text: 'A');
  final TextEditingController _startCtrl = TextEditingController(text: '1');
  final TextEditingController _endCtrl = TextEditingController(text: '10');
  
  bool _isBulkMode = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.table != null) {
      _codeCtrl.text = widget.table!.code;
      _isBulkMode = false;
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _prefixCtrl.dispose();
    _startCtrl.dispose();
    _endCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    
    try {
      if (_isBulkMode) {
        final prefix = _prefixCtrl.text.trim();
        final start = int.tryParse(_startCtrl.text) ?? 0;
        final end = int.tryParse(_endCtrl.text) ?? 0;

        if (prefix.isEmpty || start == 0 || end == 0) {
           throw 'Mohon lengkapi semua field';
        }
        if (end < start) {
           throw 'Angka akhir harus lebih besar';
        }
        if ((end - start) > 50) {
           throw 'Maksimal 50 meja sekaligus';
        }

        await widget.onSaveBulk(prefix, start, end);
        
      } else {
        final code = _codeCtrl.text.trim();
        if (code.isEmpty) throw 'Kode tidak boleh kosong';
        
        await widget.onSaveSingle(code);
      }
      
      if (!mounted) return;
      Navigator.pop(context); // Close dialog
      widget.onSuccess(); // Trigger callback
      
    } catch (e) {
      if (!mounted) return;
      
      String message = e.toString();
      
      // Clean generic prefixes
      message = message.replaceAll('Exception: ', '').replaceAll('ApiException: ', '');
      
      // Handle known errors with user-friendly messages
      if (message.contains('code has already been taken') || message.contains('Duplicate entry')) {
        message = 'Gagal: Kode meja tersebut sudah digunakan.';
      } else if (message.contains('422')) {
        message = 'Validasi gagal. Cek kembali input Anda.';
      } else if (message.contains('Connection refused') || message.contains('SocketException')) {
        message = 'Tidak dapat terhubung ke server. Cek koneksi internet.';
      } else if (message.contains('500')) {
        message = 'Terjadi kesalahan internal server (500).';
      }
      
      // Fallback: If message is still raw JSON or very long, truncate or simplify? 
      // User requested "sesuai pesan nya", so we keep custom messages.

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating, // Floating is better for dialogs
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.table == null 
          ? (_isBulkMode ? 'Buat Banyak Meja' : 'Tambah Meja') 
          : 'Edit Meja'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Mode Toggle
            if (widget.table == null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isBulkMode = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: !_isBulkMode ? AppColors.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Satuan',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: !_isBulkMode ? Colors.white : Colors.grey.shade600,
                              fontWeight: !_isBulkMode ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isBulkMode = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _isBulkMode ? AppColors.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Otomatis',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _isBulkMode ? Colors.white : Colors.grey.shade600,
                              fontWeight: _isBulkMode ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            if (!_isBulkMode)
              TextField(
                controller: _codeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Kode Meja',
                  hintText: 'Contoh: A1, B2',
                ),
              )
            else
              Column(
                children: [
                   TextField(
                      controller: _prefixCtrl,
                      decoration: const InputDecoration(labelText: 'Awalan (A)'),
                   ),
                   const SizedBox(height: 12),
                   Row(
                     children: [
                       Expanded(child: TextField(controller: _startCtrl, decoration: const InputDecoration(labelText: 'Mulai'), keyboardType: TextInputType.number)),
                       const SizedBox(width: 12),
                       Expanded(child: TextField(controller: _endCtrl, decoration: const InputDecoration(labelText: 'Sampai'), keyboardType: TextInputType.number)),
                     ],
                   ),
                   const SizedBox(height: 12),
                   Container(
                      padding: const EdgeInsets.all(8),
                      width: double.infinity,
                      decoration: BoxDecoration(color: AppColors.infoLight, borderRadius: BorderRadius.circular(8)),
                      child: Text(
                        'Preview: ${_prefixCtrl.text}${_startCtrl.text}...',
                        style: const TextStyle(color: AppColors.info, fontSize: 12),
                      ),
                   ),
                ],
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context), 
          child: const Text('Batal')
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(_isBulkMode ? 'Buat Semua' : 'Simpan'),
        ),
      ],
    );
  }
}
