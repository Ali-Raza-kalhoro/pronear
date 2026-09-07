// lib/app/routes.dart
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

import '../features/provider/business_setup/BusinessProductsListScreen.dart';
import '../features/provider/business_setup/business_category_selection_screen.dart';
import '../features/provider/business_setup/business_products_setup_screen.dart';
import '../features/provider/business_setup/business_setup_screen.dart';
import '../features/provider/business_setup/business_type_selection_screen.dart';
import '../features/provider/portfolio_screen.dart';
import '../features/provider/request_screen.dart';
import '../features/splash/splash_screen.dart';
import '../features/auth/role_selection_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/user/business_checkout_screen.dart';
import '../features/user/business_products_screen.dart';
import '../features/user/business_request_screen.dart';
import '../features/user/home_screen.dart';
import '../features/user/category_screen.dart';
import '../features/user/notification_screen.dart';
import '../features/user/search_screen.dart';
import '../features/user/map_screen.dart';
import '../features/user/provider_detail_screen.dart';
import '../features/user/request_screen.dart' as user_request;
import '../features/user/chat_screen.dart' as user_chat;
import '../features/user/profile_screen.dart';
import '../features/provider/dashboard_screen.dart';
import '../features/provider/cv_creation_screen.dart';
import '../features/provider/chat_screen.dart' as provider_chat;
import '../features/provider/profile_screen.dart' as provider_profile;
import '../features/chat/chat_list_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/role-selection',
        name: 'role-selection',
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) {
          String? role;
          final extra = state.extra;
          if (extra is String) {
            role = extra;
          } else if (extra is Map<String, dynamic>) {
            role = extra['role'] as String?;
          }
          return LoginScreen(role: role);
        },
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) {
          String? role;
          final extra = state.extra;
          if (extra is String) {
            role = extra;
          } else if (extra is Map<String, dynamic>) {
            role = extra['role'] as String?;
          }
          return RegisterScreen(role: role);
        },
      ),

      // ============================================================
      // USER ROUTES
      // ============================================================
      GoRoute(
        path: '/user/home',
        name: 'user-home',
        builder: (context, state) => const UserHomeScreen(),
      ),
      GoRoute(
        path: '/user/categories',
        name: 'user-categories',
        builder: (context, state) => const CategoryScreen(),
      ),
      GoRoute(
        path: '/user/search',
        name: 'user-search',
        builder: (context, state) {
          final query = state.extra as String?;
          return SearchScreen(initialQuery: query);
        },
      ),
      GoRoute(
        path: '/user/map',
        name: 'user-map',
        builder: (context, state) => const MapScreen(),
      ),
      GoRoute(
        path: '/user/provider/:id',
        name: 'user-provider',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ProviderDetailScreen(providerId: id);
        },
      ),
      GoRoute(
        path: '/user/request/:providerId',
        name: 'user-request',
        builder: (context, state) {
          final providerId = state.pathParameters['providerId']!;
          return user_request.RequestScreen(providerId: providerId);
        },
      ),
      GoRoute(
        path: '/user/chats',
        name: 'user-chats',
        builder: (context, state) => const ChatListScreen(role: 'user'),
      ),
      GoRoute(
        path: '/user/chat/:roomId',
        name: 'user-chat',
        builder: (context, state) {
          final roomId = state.pathParameters['roomId']!;
          final extra = state.extra as Map<String, dynamic>?;
          return user_chat.UserChatScreen(
            roomId: roomId,
            providerName: extra?['providerName'] as String?,
            providerId: extra?['providerId'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/user/profile',
        name: 'user-profile',
        builder: (context, state) => const UserProfileScreen(),
      ),
      GoRoute(
        path: '/user/notifications',
        name: 'user-notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),

      // ✅ Business Routes for Users
      GoRoute(
        path: '/user/business-products/:providerId',
        name: 'user-business-products',
        builder: (context, state) {
          final providerId = state.pathParameters['providerId']!;
          return BusinessProductsScreen(providerId: providerId);
        },
      ),
      GoRoute(
        path: '/user/business-checkout/:providerId',
        name: 'user-business-checkout',
        builder: (context, state) {
          final providerId = state.pathParameters['providerId']!;
          return BusinessCheckoutScreen(providerId: providerId);
        },
      ),
      GoRoute(
        path: '/user/business-request/:providerId',
        name: 'user-business-request',
        builder: (context, state) {
          final providerId = state.pathParameters['providerId']!;
          return BusinessRequestScreen(providerId: providerId);
        },
      ),

      // ============================================================
      // PROVIDER ROUTES
      // ============================================================

      // Business Setup Routes
      GoRoute(
        path: '/business/type',
        name: 'business-type',
        builder: (context, state) => const BusinessTypeSelectionScreen(),
      ),
      GoRoute(
        path: '/business/setup',
        name: 'business-setup',
        builder: (context, state) => const BusinessSetupScreen(),
      ),
      GoRoute(
        path: '/business/category-selection',
        name: 'business-category',
        builder: (context, state) => const BusinessCategorySelectionScreen(),
      ),
      GoRoute(
        path: '/business/products',
        name: 'business-products',
        builder: (context, state) {
          final category = state.extra as Map<String, dynamic>?;
          return BusinessProductsSetupScreen(category: category);
        },
      ),
      GoRoute(
        path: '/business/products/list',
        name: 'business-products-list',
        builder: (context, state) => const BusinessProductsListScreen(),
      ),

      // Provider Dashboard & Features
      GoRoute(
        path: '/provider/dashboard',
        name: 'provider-dashboard',
        builder: (context, state) => const ProviderDashboardScreen(),
      ),
      GoRoute(
        path: '/provider/cv',
        name: 'provider-cv',
        builder: (context, state) => const CVCreationScreen(),
      ),
      GoRoute(
        path: '/provider/requests',
        name: 'provider-requests',
        builder: (context, state) => const ProviderRequestsScreen(),
      ),
      GoRoute(
        path: '/provider/chats',
        name: 'provider-chats',
        builder: (context, state) => const ChatListScreen(role: 'provider'),
      ),
      GoRoute(
        path: '/provider/chat/:roomId',
        name: 'provider-chat',
        builder: (context, state) {
          final roomId = state.pathParameters['roomId']!;
          final extra = state.extra as Map<String, dynamic>?;
          return provider_chat.ProviderChatScreen(
            roomId: roomId,
            userName: extra?['userName'] as String?,
            userId: extra?['userId'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/provider/portfolio',
        name: 'provider-portfolio',
        builder: (context, state) => const ProviderPortfolioScreen(),
      ),
      GoRoute(
        path: '/provider/profile',
        name: 'provider-profile',
        builder: (context, state) => const provider_profile.ProviderProfileScreen(),
      ),
      GoRoute(
        path: '/provider/notifications',
        name: 'provider-notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
    ],
  );
}