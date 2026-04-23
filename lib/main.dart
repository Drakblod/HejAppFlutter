import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/firebase_config.dart';
import 'core/navigation/app_router.dart';
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase using the manual options from our config
  await Firebase.initializeApp(
    options: HejAppFirebaseConfig.currentPlatform,
  );

  final container = ProviderContainer();
  
  // Initialize Notification Service
  try {
    await container.read(notificationServiceProvider.notifier).initialize();
  } catch (e) {
    debugPrint('Failed to initialize notifications: $e');
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const HejApp(),
    ),
  );
}

class HejApp extends ConsumerWidget {
  const HejApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'HejApp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2F7D32), // "Hej Green"
        ),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
