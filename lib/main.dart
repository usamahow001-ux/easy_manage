import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/app_state_provider.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  final storageService = await StorageService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AppStateProvider(storageService),
        ),
      ],
      child: const EasyManageApp(),
    ),
  );
}

class EasyManageApp extends StatelessWidget {
  const EasyManageApp({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppStateProvider>();

    return MaterialApp(
      title: 'EasyManage',
      debugShowCheckedModeBanner: false,
      themeMode: provider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      home: const SplashScreen(),
    );
  }
}
