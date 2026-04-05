import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:dio/dio.dart';
import 'firebase_options.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'data/services/dio_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Request notification permission
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  String? token = await FirebaseMessaging.instance.getToken();
  print('FCM Token: $token');

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Notification: ${message.notification?.title}');
  });

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(ProviderScope(child: FcmGate(token: token)));
}

class FcmGate extends ConsumerStatefulWidget {
  final String? token;
  const FcmGate({super.key, this.token});

  @override
  ConsumerState<FcmGate> createState() => _FcmGateState();
}

class _FcmGateState extends ConsumerState<FcmGate> {
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _registerToken();
  }

  Future<void> _registerToken() async {
    if (widget.token == null) {
      if (mounted) {
        setState(() {
          _error = 'Impossible de récupérer le token FCM';
          _isLoading = false;
        });
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final dio = ref.read(authDioProvider); // using unauthenticated dio as specified, though the endpoint requires auth in backend

      // According to requirement: Wait for the backend response
      final response = await dio.post(
        AppConstants.registerDevice,
        data: {'fcm_token': widget.token},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) setState(() => _isLoading = false);
      } else {
        if (mounted) {
          setState(() {
            _error = 'Erreur serveur: ${response.statusCode}';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Erreur réseau de connexion. Vérifiez votre connexion.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Container(
            decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   Container(
                    width: 96, height: 96,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withOpacity(0.3), width: 2),
                    ),
                    child: const Icon(Icons.health_and_safety_rounded, color: Colors.white, size: 52),
                  ),
                  const SizedBox(height: 20),
                  const Text('Sahhty', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800, letterSpacing: 1)),
                  const SizedBox(height: 20),
                  const CircularProgressIndicator(color: Colors.white),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (_error != null) {
       return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Container(
            decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   Container(
                    width: 96, height: 96,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withOpacity(0.3), width: 2),
                    ),
                    child: const Icon(Icons.error_outline, color: Colors.white, size: 52),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _registerToken,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.primary),
                    child: const Text('Réessayer'),
                  ),
                  // Option to skip if we assume user can't register without auth
                  TextButton(
                    onPressed: () => setState(() => _error = null),
                    child: const Text('Ignorer', style: TextStyle(color: Colors.white70)),
                  )
                ],
              ),
            ),
          ),
        ),
      );
    }

    // After success (200) or skip, load the actual app (which goes to Login since there's no auth session)
    return const SahhtyApp();
  }
}

class SahhtyApp extends ConsumerWidget {
  const SahhtyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'Sahhty',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
      locale: const Locale('fr'),
      supportedLocales: const [Locale('fr'), Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(MediaQuery.of(context).textScaleFactor.clamp(0.8, 1.2)),
        ),
        child: child!,
      ),
    );
  }
}
