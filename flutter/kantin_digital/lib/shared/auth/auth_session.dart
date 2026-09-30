import '../models/user_model.dart';
import '../constants/user_role.dart';

/// Sesi auth sederhana (in-memory).
/// Untuk produksi bisa diganti ke penyimpanan lokal (SharedPreferences / secure storage).
class AuthSession {
  static final AuthSession _instance = AuthSession._internal();

  factory AuthSession() => _instance;

  AuthSession._internal();

  String? _token;
  UserModel? _user;

  String? get token => _token;
  UserModel? get user => _user;
  UserRole? get role => _user?.role;

  bool get isAuthenticated => _token != null && _token!.isNotEmpty;

  void setSession({
    required String token,
    required UserModel user,
  }) {
    _token = token;
    _user = user;
  }

  void clear() {
    _token = null;
    _user = null;
  }
}

