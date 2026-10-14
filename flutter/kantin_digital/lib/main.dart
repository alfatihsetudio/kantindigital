import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'shared/auth/auth_session.dart';
import 'shared/storage/active_order_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await initializeDateFormatting('id_ID', null);
  } catch (_) {}
  await AuthSession().load();
  await ActiveOrderStorage.instance.load();
  runApp(const App());
}

