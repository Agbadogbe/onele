import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'services/auth_provider.dart';
import 'services/onele_api.dart';
import 'services/realtime_provider.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/home_shell.dart';
import 'widgets/common.dart';

void main() {
  runApp(const OneleApp());
}

class OneleApp extends StatelessWidget {
  const OneleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(OneleApi())),
        // La liaison temps réel suit l'authentification : elle s'ouvre dès la
        // connexion et se referme à la déconnexion.
        ChangeNotifierProxyProvider<AuthProvider, RealtimeProvider>(
          create: (_) => RealtimeProvider(OneleApi()),
          update: (_, auth, tempsReel) {
            tempsReel!.synchroniser(
              auth.status == AuthStatus.authenticated ? auth.user?.id : null,
            );
            return tempsReel;
          },
        ),
      ],
      child: MaterialApp(
        title: 'Onélé',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        locale: const Locale('fr', 'FR'),
        supportedLocales: const [Locale('fr', 'FR'), Locale('en', 'US')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        // Au-delà de 1,4x, les cartes et l'en-tête déborderaient : on bride
        // l'agrandissement système tout en servant l'accessibilité courante.
        builder: (context, child) {
          final mq = MediaQuery.of(context);
          return MediaQuery(
            data: mq.copyWith(
              textScaler: mq.textScaler.clamp(maxScaleFactor: 1.4),
            ),
            child: child!,
          );
        },
        home: const _RootDecider(),
      ),
    );
  }
}

class _RootDecider extends StatelessWidget {
  const _RootDecider();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    switch (auth.status) {
      case AuthStatus.checking:
        return const _EcranDemarrage();
      case AuthStatus.authenticated:
        return const HomeShell();
      case AuthStatus.unauthenticated:
        return const LoginScreen();
    }
  }
}

/// Écran affiché le temps de vérifier le jeton enregistré.
class _EcranDemarrage extends StatelessWidget {
  const _EcranDemarrage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.rail,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BrandStamp(taille: 56, surFondSombre: true),
            SizedBox(height: 20),
            Wordmark(taille: 22, couleur: AppColors.railInk),
            SizedBox(height: 26),
            SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.railAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
