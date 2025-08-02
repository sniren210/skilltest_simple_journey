import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'screens/home_screen.dart';
import 'screens/ocr_scanner_screen.dart';
import 'screens/biometric_screen.dart';
import 'screens/nfc_reader_screen.dart';
import 'screens/results_screen.dart';
import 'utils/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  
  runApp(const IDDocumentScannerApp());
}

class IDDocumentScannerApp extends StatelessWidget {
  const IDDocumentScannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppProvider(),
      child: MaterialApp(
        title: AppConstants.appName,
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: const HomeScreen(),
        routes: {
          '/home': (context) => const HomeScreen(),
          '/ocr-scanner': (context) => const OCRScannerScreen(),
          '/biometric': (context) => const BiometricScreen(),
          '/nfc-reader': (context) => const NFCReaderScreen(),
          '/results': (context) => const ResultsScreen(),
        },
      ),
    );
  }
}
