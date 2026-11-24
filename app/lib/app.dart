import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kahve_core/kahve_core.dart';
import 'package:material_ui/material_ui.dart';

import 'state/settings.dart';
import 'ui/calculator.dart';
import 'ui/equipment.dart';
import 'ui/guided_brew.dart';
import 'ui/help.dart';
import 'ui/home.dart';
import 'ui/log.dart';
import 'ui/onboarding.dart';
import 'ui/recipe_detail.dart';
import 'ui/settings_screen.dart';
import 'ui/taste.dart';
import 'ui/theme.dart';

final _rootKey = GlobalKey<NavigatorState>();

/// Uygulama yönlendirmesi. Ana gezinme 4 hedefli alt çubuktur
/// (KHV-HMI-027).
GoRouter buildRouter(Ref ref) {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/',
    redirect: (context, state) {
      final s = ref.read(settingsProvider);
      if (s.isLoading) return null;
      final done = s.value?.onboardingDone ?? false;
      final onOnboarding = state.matchedLocation == '/onboarding';
      if (!done && !onOnboarding) return '/onboarding';
      return null;
    },
    refreshListenable: _SettingsListenable(ref),
    routes: [
      GoRoute(path: '/onboarding', builder: (c, s) => const OnboardingScreen()),
      StatefulShellRoute.indexedStack(
        builder: (c, s, shell) => _Shell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (c, s) => const HomeScreen(),
                routes: [
                  GoRoute(
                    path: 'recipe/:id',
                    builder: (c, s) =>
                        RecipeDetailScreen(recipeId: s.pathParameters['id']!),
                  ),
                  GoRoute(
                    path: 'calculator',
                    builder: (c, s) => const CalculatorScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/log',
                builder: (c, s) => const LogScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    builder: (c, s) => const ManualBrewScreen(),
                  ),
                  GoRoute(
                    path: ':id',
                    builder: (c, s) =>
                        BrewDetailScreen(brewId: s.pathParameters['id']!),
                  ),
                ],
              ),
              GoRoute(
                path: '/beans/new',
                builder: (c, s) => const BeanEditScreen(),
              ),
              GoRoute(
                path: '/beans/:id',
                builder: (c, s) =>
                    BeanEditScreen(beanId: s.pathParameters['id']),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/equipment',
                builder: (c, s) => const EquipmentScreen(),
                routes: [
                  GoRoute(
                    path: 'model/:id',
                    builder: (c, s) =>
                        ModelScreen(modelId: s.pathParameters['id']!),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (c, s) => const SettingsScreen(),
                routes: [
                  GoRoute(
                    path: 'equipment',
                    builder: (c, s) => const EquipmentProfileScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      // Rehber mod ve tat ekranı tam ekran açılır.
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/brew',
        builder: (c, s) => GuidedBrewScreen(
          launch: BrewLaunch(
            recipe: s.extra is Recipe ? s.extra! as Recipe : null,
            recipeId: s.uri.queryParameters['recipe'],
            quick: s.uri.queryParameters['quick'] == '1',
            longBrewId: s.uri.queryParameters['long'],
          ),
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/taste/:id',
        builder: (c, s) => TasteScreen(brewId: s.pathParameters['id']!),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/help',
        builder: (c, s) => const HelpScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/legal',
        builder: (c, s) => const LegalScreen(),
      ),
    ],
  );
}

class _SettingsListenable extends ChangeNotifier {
  _SettingsListenable(Ref ref) {
    ref.listen(settingsProvider, (_, _) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final r = buildRouter(ref);
  ref.onDispose(r.dispose);
  return r;
});

class _Shell extends StatelessWidget {
  const _Shell({required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: shell,
    bottomNavigationBar: NavigationBar(
      selectedIndex: shell.currentIndex,
      onDestinationSelected: (i) =>
          shell.goBranch(i, initialLocation: i == shell.currentIndex),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.coffee_outlined),
          selectedIcon: Icon(Icons.coffee),
          label: 'Demle',
        ),
        NavigationDestination(
          icon: Icon(Icons.menu_book_outlined),
          selectedIcon: Icon(Icons.menu_book),
          label: 'Günlük',
        ),
        NavigationDestination(
          icon: Icon(Icons.devices_other_outlined),
          selectedIcon: Icon(Icons.devices_other),
          label: 'Ekipman',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: 'Ayarlar',
        ),
      ],
    ),
  );
}

class EvKahvesiApp extends ConsumerWidget {
  const EvKahvesiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode =
        ref.watch(settingsProvider).value?.themeMode ?? ThemeMode.system;
    return MaterialApp.router(
      title: 'Ev Kahvesi',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: themeMode,
      locale: const Locale('tr', 'TR'),
      supportedLocales: const [Locale('tr', 'TR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
