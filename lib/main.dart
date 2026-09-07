import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import 'app/routes.dart';
import 'app/theme.dart';
import 'core/services/supabase_service.dart';
import 'core/services/notification_service.dart';
import 'features/provider/auth_provider.dart';
import 'features/provider/chat_provider.dart';
import 'features/provider/provider_provider.dart';
import 'features/provider/request_provider.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Supabase.initialize(
      url: 'https://kgjnmyrcmlhmwvqsfuei.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imtnam5teXJjbWxobXd2cXNmdWVpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODcyMTg2MDcsImV4cCI6MjEwMjc5NDYwN30.8MnrVxupQuhBr9WFgJA0pgPXMO_4nkElw_htMG8U6Iw',
    );
    debugPrint('✅ Supabase initialized successfully');
  } catch (e) {
    debugPrint('❌ Failed to initialize Supabase: $e');
  }

  // Initialize Services
  await SupabaseService().init();
  await NotificationService().init();

  runApp(const MyApp());
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
        _notificationSubscription = SupabaseService().listenToNotifications(userId).listen((notifications) {
          for (var notification in notifications) {
            final id = notification['id'].toString();
            final isRead = notification['is_read'] ?? false;
            
            if (!isRead && !_notifiedIds.contains(id)) {
              final createdAt = DateTime.parse(notification['created_at']);
              // Only show if it's very recent (last 15 seconds) to avoid spam on login
              if (DateTime.now().difference(createdAt).inSeconds < 15) {
                _showNotification(notification);
                _notifiedIds.add(id);
              }
            }
          }
        });
      } else {
        _notificationSubscription?.cancel();
        _notifiedIds.clear();
      }
    });
  }

  void _showNotification(Map<String, dynamic> notification) {
    final title = notification['title'] ?? 'New Notification';
    final body = notification['body'] ?? '';

    // 1. Device System Notification
    NotificationService().showNotification(
      id: notification['id'].hashCode,
      title: title,
      body: body,
      payload: notification['type'],
    );

    // 2. In-App Notification (SnackBar)

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
        scaffoldMessengerKey: scaffoldMessengerKey,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        debugShowCheckedModeBanner: false,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
