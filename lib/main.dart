import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/firebase_config.dart';
import 'core/navigation/app_router.dart';
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    Firebase.app(); // Check if already initialized
    debugPrint('Firebase already initialized');
  } catch (e) {
    try {
      await Firebase.initializeApp(
        options: HejAppFirebaseConfig.currentPlatform,
      );
    } catch (e) {
      debugPrint('Firebase initialization failed: $e');
    }
  }

  runApp(const ProviderScope(child: HejApp()));
}

class HejApp extends ConsumerStatefulWidget {
  const HejApp({super.key});

  @override
  ConsumerState<HejApp> createState() => _HejAppState();
}

class _HejAppState extends ConsumerState<HejApp> {
  @override
  void initState() {
    super.initState();
    // Initialize Notification Service
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationServiceProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Hej — your group, your space',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF225C32),
          surface: const Color(0xFFFBFCFA),
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF4F6F3),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFD9E1D9)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFD9E1D9)),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 17,
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ),
      routerConfig: router,
    );
  }
}
