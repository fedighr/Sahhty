import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/locale_provider.dart';
import 'core/providers/websocket_provider.dart';
import 'core/widgets/realtime_notification_overlay.dart';
import 'features/auth/providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase init failed (non-critical): $e');
  }

  try {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    String? token = await FirebaseMessaging.instance.getToken().timeout(
      const Duration(seconds: 5),
      onTimeout: () => null,
    );
    debugPrint('FCM Token: $token');

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Notification: ${message.notification?.title}');
    });
  } catch (e) {
    debugPrint('FCM initialization failed (non-critical): $e');
  }

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  runApp(const ProviderScope(child: SahhtyApp()));
}

class SahhtyApp extends ConsumerStatefulWidget {
  const SahhtyApp({super.key});

  @override
  ConsumerState<SahhtyApp> createState() => _SahhtyAppState();
}

class _SahhtyAppState extends ConsumerState<SahhtyApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.listen<AuthState>(authProvider, (previous, next) {
        final wsService = ref.read(webSocketServiceProvider);
        if (next.status == AuthStatus.authenticated) {
          wsService.connect();
        } else if (next.status == AuthStatus.unauthenticated) {
          wsService.disconnect();
        }
      });
      final authState = ref.read(authProvider);
      if (authState.status == AuthStatus.authenticated) {
        ref.read(webSocketServiceProvider).connect();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final locale = ref.watch(localeProvider);
    return MaterialApp.router(
      title: 'Sahhty',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
      locale: locale,
      supportedLocales: const [Locale('fr'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        final scaler = MediaQuery.of(context).textScaler;
        final scale = scaler.scale(1.0).clamp(0.8, 1.2);
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
          ),
          child: Builder(
            builder: (innerContext) => RealtimeNotificationOverlay(
              child: child!,
            ),
          ),
        );
      },
    );
  }
}