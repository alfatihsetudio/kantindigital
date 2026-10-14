import '../../../core/network/api_client.dart';
import '../../../shared/models/cashier_shift_report_model.dart';
import '../../../shared/services/demo_session_manager.dart';

class CashierShiftService {
  final ApiClient _client = ApiClient();

  Future<CurrentShiftData> fetchCurrentShift() async {
    if (DemoSessionManager.isDemoMode) {
      return DemoSessionManager.getCurrentShiftData();
    }

    final response = await _client.get('/cashier/shift/current');
    if (response['status'] == true && response['data'] != null) {
      return CurrentShiftData.fromJson(response['data'] as Map<String, dynamic>);
    }
    return const CurrentShiftData();
  }

  Future<CashierShiftReportModel> submitShiftReport({
    required double cashReceived,
    String? notes,
  }) async {
    if (DemoSessionManager.isDemoMode) {
      return DemoSessionManager.submitShiftReport(
        cashReceived: cashReceived,
        notes: notes,
      );
    }

    final response = await _client.post(
      '/cashier/shift/submit',
      body: {
        'cash_received': cashReceived,
        if (notes != null && notes.trim().isNotEmpty) 'cashier_notes': notes.trim(),
      },
    );

    return CashierShiftReportModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<List<CashierShiftReportModel>> fetchReports({String? status, int limit = 20}) async {
    if (DemoSessionManager.isDemoMode) {
      return DemoSessionManager.getShiftReports(status: status);
    }

    String path = '/cashier/shift/reports?limit=$limit';
    if (status != null && status.isNotEmpty) {
      path += '&status=$status';
    }

    final response = await _client.get(path);
    final data = response['data'] as List? ?? [];
    return data
        .whereType<Map<String, dynamic>>()
        .map((e) => CashierShiftReportModel.fromJson(e))
        .toList();
  }

  Future<CashierShiftReportModel> approveReport(int reportId, {String? notes}) async {
    if (DemoSessionManager.isDemoMode) {
      return DemoSessionManager.approveShiftReport(reportId, notes: notes);
    }

    final response = await _client.post(
      '/cashier/shift/reports/$reportId/approve',
      body: {
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      },
    );

    return CashierShiftReportModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<CashierShiftReportModel> rejectReport(int reportId, {String? notes}) async {
    if (DemoSessionManager.isDemoMode) {
      return DemoSessionManager.rejectShiftReport(reportId, notes: notes);
    }

    final response = await _client.post(
      '/cashier/shift/reports/$reportId/reject',
      body: {
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      },
    );

    return CashierShiftReportModel.fromJson(response['data'] as Map<String, dynamic>);
  }
}
