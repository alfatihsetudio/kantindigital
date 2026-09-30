import 'package:flutter/material.dart';

import 'app.dart';
import 'shared/auth/auth_session.dart';
import 'shared/storage/active_order_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthSession().load();
  await ActiveOrderStorage.instance.load();
  runApp(const App());
}

