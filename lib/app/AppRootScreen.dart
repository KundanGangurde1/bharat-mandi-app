import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/active_firm_provider.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/firm_setup/firm_form_screen.dart';

class AppRootScreen extends StatelessWidget {
  const AppRootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ActiveFirmProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (provider.activeFirm == null) {
          return const FirmFormScreen(isFirstSetup: true);
        }

        return const DashboardScreen();
      },
    );
  }
}
