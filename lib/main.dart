import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/app_theme.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/auth/login_screen.dart';
import 'services/navigation_provider.dart';
import 'services/finance_provider.dart';
import 'services/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

  await Supabase.initialize(
    url: 'https://xbtdqjfmgthbnbgyujkv.supabase.co',
    anonKey: 'sb_publishable_nEIhPHpMPTNk-AkwDk-gPQ_3KKpGQaz',
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => FinanceProvider()..fetchData()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const KeuanganPribadiApp(),
    ),
  );
}

class KeuanganPribadiApp extends StatelessWidget {
  const KeuanganPribadiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Keuangan Pribadi Aidan',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return auth.isAuthenticated ? const DashboardScreen() : const LoginScreen();
        },
      ),
    );
  }
}
