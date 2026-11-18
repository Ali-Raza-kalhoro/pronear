// lib/main.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';

import 'app/routes.dart';
import 'app/theme.dart';
import 'core/services/supabase_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/global_error_handler.dart';
import 'features/provider/auth_provider.dart';
import 'features/provider/chat_provider.dart';
import 'features/provider/provider_provider.dart';
import 'features/provider/request_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Release builds: silence logs (they contain emails / CNIC numbers)
  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }

  try {
    await Supabase.initialize(
      url: 'https://kgjnmyrcmlhmwvqsfuei.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imtnam5teXJjbWxobXd2cXNmdWVpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODcyMTg2MDcsImV4cCI6MjEwMjc5NDYwN30.8MnrVxupQuhBr9WFgJA0pgPXMO_4nkElw_htMG8U6Iw',
    );
  } catch (e) {
    debugPrint('❌ Failed to initialize Supabase: $e');
    // ✅ Without Supabase nothing works – show a retry screen instead of crashing
    runApp(const _StartupErrorApp());
    return;
  }

  await SupabaseService().init();
  try {
    await NotificationService().init();
  } catch (e) {
    debugPrint('⚠️ Notification init failed: $e');
  }

  // ✅ Short delay to let DNS resolve before realtime connects
  await Future.delayed(const Duration(milliseconds: 500));

  runApp(const MyApp());
}

class _StartupErrorApp extends StatelessWidget {
  const _StartupErrorApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.wifi_off_rounded, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Could not connect. Please check your internet connection and reopen the app.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription? _notificationSubscription;
  final Set<String> _notifiedIds = {};

  @override
  void initState() {
    super.initState();
    _setupNotificationListeners();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  void _setupNotificationListeners() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null) {
        final userId = session.user.id;
        _notificationSubscription?.cancel();

        _notificationSubscription = SupabaseService()
            .listenToNotifications(userId)
            .listen(
              (notifications) {
            for (var notification in notifications) {
              final id = notification['id'].toString();
              final isRead = notification['is_read'] ?? false;
              if (!isRead && !_notifiedIds.contains(id)) {
                final createdAt = DateTime.parse(notification['created_at']);
                if (DateTime.now().difference(createdAt).inSeconds < 15) {
                  _showNotification(notification);
                  _notifiedIds.add(id);
                }
              }
            }
          },
          // ✅ Catch the error silently
          onError: (error) {
            debugPrint('⚠️ Notification stream error (likely offline): $error');
          },
          cancelOnError: false, // ✅ Keep the stream alive
        );
      } else {
        _notificationSubscription?.cancel();
        _notifiedIds.clear();
      }
    });
  }

  void _showNotification(Map<String, dynamic> notification) {
    final title = notification['title'] ?? 'New Notification';
    final body = notification['body'] ?? '';
    NotificationService().showNotification(
      id: notification['id'].hashCode,
      title: title,
      body: body,
      payload: notification['type'],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProviderProvider()),
        ChangeNotifierProvider(create: (_) => RequestProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: MaterialApp.router(
        title: 'ProNear',
        scaffoldMessengerKey: GlobalErrorHandler.scaffoldMessengerKey,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        debugShowCheckedModeBanner: false,
        routerConfig: AppRouter.router,
      ),
    );
  }
}