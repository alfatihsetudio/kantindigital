import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'core/widgets/top_notification.dart';
import 'router/app_router.dart';
import 'router/route_name.dart';
import 'shared/models/tenant_model.dart';
import 'shared/providers/tenant_provider.dart';
import 'shared/services/tenant_service.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return TenantLoader(
      builder: (TenantModel tenant) {
        return TenantProvider(
          tenant: tenant,
          child: MaterialApp(
            title: tenant.name,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(primaryColor: tenant.primaryColorValue),
            navigatorKey: TopNotification.navigatorKey,
            onGenerateRoute: AppRouter.onGenerateRoute,
            initialRoute: TenantService.isRootDomain
                ? RouteName.landingPage
                : RouteName.customerMenu,
          ),
        );
      },
    );
  }
}
