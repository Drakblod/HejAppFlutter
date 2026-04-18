import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/group/presentation/screens/group_screen.dart';
import '../../features/group/presentation/screens/group_admin_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(Ref ref) {
  final authState = ref.watch(authStateChangesProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final isAuthPage = state.matchedLocation == '/login' || state.matchedLocation == '/register';

      if (!isLoggedIn && !isAuthPage) return '/login';
      if (isLoggedIn && isAuthPage) return '/home';

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/group/:groupId',
        builder: (context, state) {
          final groupId = state.pathParameters['groupId']!;
          return GroupScreen(groupId: groupId);
        },
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/group/:groupId/admin',
        builder: (context, state) {
          final groupId = state.pathParameters['groupId']!;
          return GroupAdminScreen(groupId: groupId);
        },
      ),
    ],
  );
}
