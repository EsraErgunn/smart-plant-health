import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/gen/app_localizations.dart';

import 'providers/theme_provider.dart';
import 'providers/locale_provider.dart';
import 'screens/home_screen.dart';
import 'config/app_theme.dart';
import 'services/notification_service.dart';

import 'package:hive_flutter/hive_flutter.dart';
import 'services/diagnosis_database_service.dart';
import 'services/image_picker_service.dart';
import 'providers/diagnosis_controller.dart';
import 'providers/map_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter();
  
  // Initialize Database Service
  final diagnosisDb = DiagnosisDatabaseService();
  await diagnosisDb.init();
  
  // Load environment variables
  await dotenv.load(fileName: "assets/.env");

  // Initialize notifications
  final notificationService = NotificationService();
  await notificationService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(
          create: (_) => DiagnosisController(
            dbService: DiagnosisDatabaseService(), 
            pickerService: ImagePickerService(),
          )..loadImages(),
        ),
        ChangeNotifierProvider(create: (_) => MapController()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Plant Health',
      
      // Theme
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      
      // Localization
      locale: localeProvider.locale,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        AppLocalizations.delegate, 
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('tr'),
      ],
      
      home: const HomeScreen(),
    );
  }
}
