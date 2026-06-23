import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'database/app_database.dart';
import 'repositories/task_repository.dart';
import 'services/app_state.dart';
import 'notifications/notification_service.dart';
import 'home_widget/home_widget_service.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/main_shell.dart';
import 'screens/task_details_screen.dart';

// מפתח ניווט גלובלי — לניווט מתוך callback של התראה.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<MainShellState> shellKey = GlobalKey<MainShellState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // אתחול פורמט תאריכים עברי.
  await initializeDateFormatting('he', null);

  // אתחול שירותים.
  final db = AppDatabase();
  final repo = TaskRepository(db);
  final appState = AppState(repo);

  await NotificationService.instance.init();
  await HomeWidgetService.instance.init();

  // טעינת נתונים.
  await appState.load();

  // בקשת הרשאות התראה (לא חוסם — רץ ברקע).
  NotificationService.instance.requestPermissions();

  runApp(RadarApp(appState: appState));
}

class RadarApp extends StatefulWidget {
  final AppState appState;
  const RadarApp({super.key, required this.appState});

  @override
  State<RadarApp> createState() => _RadarAppState();
}

class _RadarAppState extends State<RadarApp> {
  @override
  void initState() {
    super.initState();
    // טיפול בלחיצה על התראה — ניווט למסך המתאים.
    NotificationService.onNotificationTap = _handleNotificationTap;
  }

  void _handleNotificationTap(String? payload) {
    if (payload == null) return;
    if (payload == 'morning') {
      // ניווט למסך "היום שלי".
      shellKey.currentState?.goToTab(1);
    } else if (payload.startsWith('task:')) {
      final id = payload.substring(5);
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => TaskDetailsScreen(taskId: id)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: widget.appState,
      child: MaterialApp(
        title: 'רדאר התלויות הניהולי',
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey,
        theme: AppTheme.dark(),
        themeMode: ThemeMode.dark,
        locale: const Locale('he'),
        supportedLocales: const [Locale('he'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        // כפיית RTL בכל האפליקציה.
        builder: (context, child) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: child!,
          );
        },
        home: const _RootRouter(),
      ),
    );
  }
}

/// מנתב ראשי: Splash → Onboarding (אם צריך) → Main.
class _RootRouter extends StatefulWidget {
  const _RootRouter();

  @override
  State<_RootRouter> createState() => _RootRouterState();
}

class _RootRouterState extends State<_RootRouter> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    // השהיה קצרה כדי להציג Splash.
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const SplashScreen();

    final state = context.watch<AppState>();
    if (state.loading) return const SplashScreen();

    if (!state.settings.onboardingDone) {
      return OnboardingScreen(
        onDone: () => setState(() {}),
      );
    }
    return MainShell(key: shellKey);
  }
}
