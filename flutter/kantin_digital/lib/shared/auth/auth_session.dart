import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../constants/user_role.dart';

/// Persistent Auth Session using SharedPreferences
class AuthSession extends ChangeNotifier {
  static final AuthSession _instance = AuthSession._internal();

  factory AuthSession() => _instance;

  AuthSession._internal();

  static const String _keyToken = 'auth_session_token';
  static const String _keyUser = 'auth_session_user';

  String? _token;
  UserModel? _user;

  String? get token => _token;
  UserModel? get user => _user;
  UserRole? get role => _user?.role;

  bool get isAuthenticated => _token != null && _token!.isNotEmpty;

  /// Load session from local storage on app start
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString(_keyToken);
      final userStr = prefs.getString(_keyUser);
      if (userStr != null && userStr.isNotEmpty) {
        _user = UserModel.fromJson(jsonDecode(userStr));
      } else {
        _user = null;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('AuthSession.load error: $e');
      _token = null;
      _user = null;
    }
  }

  void setSession({
    required String token,
    required UserModel user,
  }) {
    _token = token;
    _user = user;
    notifyListeners();

    // Persist to SharedPreferences
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString(_keyToken, token);
      prefs.setString(_keyUser, jsonEncode(user.toJson()));
    }).catchError((e) {
      debugPrint('AuthSession persist error: $e');
    });
  }

  void clear() {
    _token = null;
    _user = null;
    notifyListeners();

    // Remove from SharedPreferences
    SharedPreferences.getInstance().then((prefs) {
      prefs.remove(_keyToken);
      prefs.remove(_keyUser);
    }).catchError((e) {
      debugPrint('AuthSession clear error: $e');
    });
  }
}
