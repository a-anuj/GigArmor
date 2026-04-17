import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/claims/presentation/screens/claim_status_screen.dart';
import '../../features/policy/presentation/screens/policy_history_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../theme/app_theme.dart';
import '../providers/locale_provider.dart';
import 'package:hustle_halt/l10n/app_localizations.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    ShellRoute(
      navigatorKey: shellNavigatorKey,
      // Use a ConsumerWidget shell so the locale propagates into GoRouter's
      // own navigator subtree (GoRouter breaks the MaterialApp locale chain).
      builder: (context, state, child) {
        return _LocalizedShell(child: child);
      },
      routes: [
        GoRoute(
          path: '/dashboard',
          pageBuilder: (context, state) => const NoTransitionPage(child: DashboardScreen()),
        ),
        GoRoute(
          path: '/policy_history',
          pageBuilder: (context, state) => const NoTransitionPage(child: PolicyHistoryScreen()),
        ),
        GoRoute(
          path: '/claim_status',
          pageBuilder: (context, state) => const NoTransitionPage(child: ClaimStatusScreen()),
        ),
        GoRoute(
          path: '/profile',
          pageBuilder: (context, state) => const NoTransitionPage(child: ProfileScreen()),
        ),
      ],
    ),
  ],
);

/// Wraps the shell in a [Localizations.override] driven by [localeProvider].
/// This is required because GoRouter's ShellRoute creates its own Navigator
/// which breaks MaterialApp's locale propagation.
class _LocalizedShell extends ConsumerWidget {
  final Widget child;
  const _LocalizedShell({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);

    return Localizations.override(
      context: context,
      locale: locale,
      delegates: AppLocalizations.localizationsDelegates,
      child: Builder(
        builder: (localizedContext) => ScaffoldWithNavBar(child: child),
      ),
    );
  }
}

class ScaffoldWithNavBar extends StatelessWidget {
  final Widget child;

  const ScaffoldWithNavBar({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: child,
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          backgroundColor: AppTheme.surface,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppTheme.accent,
          unselectedItemColor: AppTheme.textSecondary,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          elevation: 8,
          currentIndex: _calculateSelectedIndex(context),
          onTap: (int idx) => _onItemTapped(idx, context),
          items: [
            BottomNavigationBarItem(icon: const Icon(LucideIcons.home), label: l10n.navHome),
            BottomNavigationBarItem(icon: const Icon(LucideIcons.history), label: l10n.navHistory),
            BottomNavigationBarItem(icon: const Icon(LucideIcons.fileText), label: l10n.navClaims),
            BottomNavigationBarItem(icon: const Icon(LucideIcons.user), label: l10n.navProfile),
          ],
        ),
      ),
    );
  }

  static int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/dashboard')) return 0;
    if (location.startsWith('/policy_history')) return 1;
    if (location.startsWith('/claim_status')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        GoRouter.of(context).go('/dashboard');
        break;
      case 1:
        GoRouter.of(context).go('/policy_history');
        break;
      case 2:
        GoRouter.of(context).go('/claim_status');
        break;
      case 3:
        GoRouter.of(context).go('/profile');
        break;
    }
  }
}
