import '../../../shared/models/table_model.dart';
import 'tables_service.dart';
import 'tables_pdf_service.dart';

class AdminTablesController {
  final AdminTablesService _service = AdminTablesService();
  final TablesPdfService _pdfService = TablesPdfService();

  Future<List<TableModel>> fetchTables() => _service.getTables();
  Future<void> addTable(String code) => _service.createTable(code);
  
  Future<void> addBulkTables(String prefix, int start, int end) async {
    for (int i = start; i <= end; i++) {
      final code = '$prefix$i';
      await _service.createTable(code);
      // Small delay to prevent overwhelming the server/database connection if needed
      await Future.delayed(const Duration(milliseconds: 50)); 
    }
  }

  Future<void> editTable(int id, String code) => _service.updateTable(id, code);
  Future<void> deleteTable(int id) => _service.deleteTable(id);
  
  Future<void> deleteBulkTables(List<int> ids) async {
    for (final id in ids) {
      await _service.deleteTable(id);
      // Small delay
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  Future<void> generatePdf(List<TableModel> tables) => _pdfService.generateAndDownloadPdf(tables);
}
