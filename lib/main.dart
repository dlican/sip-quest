import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_state.dart';
import 'games/registry.dart';
import 'screens/home_screen.dart';
import 'services/fx.dart';
import 'theme/palette.dart';
import 'widgets/motion.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final state = AppState();
  await state.load();
  Fx.init();
  String? open;
  // Web preview only: ?style=tavern&players=A,B,C&open=kings_cup
  // lets a browser preview jump straight to a styled screen.
  if (kIsWeb) {
    final q = Uri.base.queryParameters;
    for (final p in SipPalette.all) {
      if (p.id == q['style']) state.setPalette(p);
    }
    for (final n in (q['players'] ?? '').split(',')) {
      state.addPlayer(n);
    }
    open = q['open'];
  }
  runApp(SipQuestApp(state: state, open: open));
}

class SipQuestApp extends StatelessWidget {
  const SipQuestApp({super.key, required this.state, this.open});
  final AppState state;
  final String? open;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: state,
      child: Builder(builder: (context) {
        final pal = context.pal;
        return MaterialApp(
          title: 'Sip Quest',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: pal.bg,
            colorScheme: ColorScheme.dark(
              primary: pal.primary,
              secondary: pal.secondary,
              surface: pal.panel,
            ),
            fontFamily: 'VT323',
            splashFactory: NoSplash.splashFactory,
            pageTransitionsTheme: const PageTransitionsTheme(builders: {
              TargetPlatform.android: SmoothPageTransition(),
              TargetPlatform.iOS: SmoothPageTransition(),
              TargetPlatform.linux: SmoothPageTransition(),
              TargetPlatform.macOS: SmoothPageTransition(),
              TargetPlatform.windows: SmoothPageTransition(),
            }),
          ),
          onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => const HomeScreen()),
          onGenerateInitialRoutes: (_) => [
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            for (final g in gameModes)
              if (g.id == open) MaterialPageRoute(builder: g.builder),
          ],
        );
      }),
    );
  }
}
