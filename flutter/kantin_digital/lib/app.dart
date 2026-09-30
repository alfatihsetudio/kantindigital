import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'core/widgets/top_notification.dart';
import 'router/app_router.dart';
import 'router/route_name.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kantin Digital',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      navigatorKey: TopNotification.navigatorKey,
      onGenerateRoute: AppRouter.onGenerateRoute,
      initialRoute: RouteName.customerMenu,
    );
  }
}

