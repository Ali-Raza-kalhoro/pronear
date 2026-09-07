import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;
  static SupabaseService? _instance;

  SupabaseService._internal();

  static SupabaseService get instance {
    _instance ??= SupabaseService._internal();
    return _instance!;
  }

  factory SupabaseService() => instance;

  Future<void> init() async {
    try {
      final session = _client.auth.currentSession;
      if (session != null) {
        debugPrint('✅ Supabase session exists for user: ${session.user.email}');
        await updateOnlineStatus(session.user.id, true);
      } else {
        debugPrint('ℹ️ No active Supabase session');
      }

      _client.auth.onAuthStateChange.listen((data) {
        final session = data.session;
        if (session != null) {
          updateOnlineStatus(session.user.id, true);
        }
      });

      debugPrint('✅ SupabaseService initialized');
    } catch (e) {
      debugPrint('❌ Supabase initialization error: $e');
    }
  }

// Get provider portfolio items
  Future<List<Map<String, dynamic>>> getProviderPortfolio(String providerId) async {
    try {
      final response = await _client
          .from('provider_portfolio')
          .select()
          .eq('provider_id', providerId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ Error getting portfolio: $e');
      return [];
    }
  }

// ============================================================
// BUSINESS METHODS
// ============================================================

// Get business products
  Future<List<Map<String, dynamic>>> getBusinessProducts(String providerId) async {
    try {
      final response = await _client
          .from('business_products')
          .select()
          .eq('provider_id', providerId)
          .eq('is_available', true)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ Error getting business products: $e');
      return [];
    }
  }

// Get product by ID
  Future<Map<String, dynamic>?> getProductById(String productId) async {
    try {
      return await _client
          .from('business_products')
          .select()
          .eq('id', productId)
          .maybeSingle();
    } catch (e) {
      debugPrint('❌ Error getting product: $e');
      return null;
    }
  }

// Get business categories
  Future<List<Map<String, dynamic>>> getBusinessCategories() async {
    try {
      final response = await _client
          .from('business_categories')
          .select()
          .order('name');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ Error getting business categories: $e');
      return [];
    }
  }

// Check if provider is in service range
  Future<bool> isProviderInRange(String providerId, double userLat, double userLng) async {
    try {
      final provider = await getProvider(providerId);
      if (provider == null) return false;

      final serviceRadius = provider['service_radius'] ?? 20.0;
      final providerLat = provider['latitude']?.toDouble() ?? 0;
      final providerLng = provider['longitude']?.toDouble() ?? 0;

      final distance = Geolocator.distanceBetween(
        userLat,
        userLng,
        providerLat,
        providerLng,
      ) / 1000; // Convert to km

      return distance <= serviceRadius;
    } catch (e) {
      debugPrint('❌ Error checking range: $e');
      return false;
    }
  }

  Future<void> addPortfolioItem(Map<String, dynamic> data) async {
    try {
      // ✅ Ensure all required fields are present with default values
      final Map<String, dynamic> itemData = {
        'provider_id': data['provider_id'],
        'title': data['title'] ?? 'Untitled',
        'description': data['description'] ?? '',
        'media_type': data['media_type'] ?? 'image', // ✅ Default to 'image'
        'media_url': data['media_url'] ?? '',
        'thumbnail_url': data['thumbnail_url'] ?? data['media_url'] ?? '',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      // ✅ Validate required fields
      if (itemData['provider_id'] == null || itemData['provider_id'].toString().isEmpty) {
        throw Exception('provider_id is required');
      }
      if (itemData['media_url'] == null || itemData['media_url'].toString().isEmpty) {
        throw Exception('media_url is required');
      }
      if (itemData['media_type'] == null || itemData['media_type'].toString().isEmpty) {
        throw Exception('media_type is required');
      }

      debugPrint('📤 Adding portfolio item: $itemData');

      await _client.from('provider_portfolio').insert(itemData);
      debugPrint('✅ Portfolio item added');
    } catch (e) {
      debugPrint('❌ Error adding portfolio item: $e');
      throw Exception('Failed to add portfolio item: $e');
    }
  }
// Delete portfolio item
  Future<void> deletePortfolioItem(String itemId) async {
    try {
      await _client
          .from('provider_portfolio')
          .delete()
          .eq('id', itemId);
      debugPrint('✅ Portfolio item deleted');
    } catch (e) {
      debugPrint('❌ Error deleting portfolio item: $e');
      throw Exception('Failed to delete portfolio item: $e');
    }
// Add these to your SupabaseService

// Get provider portfolio
    Future<List<Map<String, dynamic>>> getProviderPortfolio(String providerId) async {
      try {
        final response = await _client
            .from('provider_portfolio')
            .select()
            .eq('provider_id', providerId)
            .order('created_at', ascending: false);

        return List<Map<String, dynamic>>.from(response);
      } catch (e) {
        debugPrint('❌ Error getting portfolio: $e');
        return [];
      }
    }

// Add portfolio item
    Future<void> addPortfolioItem(Map<String, dynamic> data) async {
      try {
        data['created_at'] = DateTime.now().toIso8601String();
        data['updated_at'] = DateTime.now().toIso8601String();
        await _client.from('provider_portfolio').insert(data);
        debugPrint('✅ Portfolio item added');
      } catch (e) {
        debugPrint('❌ Error adding portfolio item: $e');
        throw Exception('Failed to add portfolio item: $e');
      }
    }

// Delete portfolio item
    Future<void> deletePortfolioItem(String itemId) async {
      try {
        await _client
            .from('provider_portfolio')
            .delete()
            .eq('id', itemId);
        debugPrint('✅ Portfolio item deleted');
      } catch (e) {
        debugPrint('❌ Error deleting portfolio item: $e');
        throw Exception('Failed to delete portfolio item: $e');
      }
    }

// Upload portfolio media
    Future<String> uploadPortfolioMedia(String providerId, File file, String type) async {
      try {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final extension = type == 'video' ? 'mp4' : 'jpg';
        final fileName = '${providerId}_${timestamp}.$extension';
        final filePath = 'portfolio/$fileName';

        await _client.storage
            .from('portfolio_media')
            .upload(
          filePath,
          file,
          fileOptions: FileOptions(
            contentType: type == 'video' ? 'video/mp4' : 'image/jpeg',
          ),
        );

        return _client.storage
            .from('portfolio_media')
            .getPublicUrl(filePath);
      } catch (e) {
        debugPrint('❌ Error uploading portfolio media: $e');
        throw Exception('Failed to upload media: $e');
      }
    }

// Stream portfolio changes
    Stream<List<Map<String, dynamic>>> listenToPortfolio(String providerId) {
      return _client
          .from('provider_portfolio')
          .stream(primaryKey: ['id'])
          .eq('provider_id', providerId)
          .order('created_at', ascending: false);
    }  }

// Upload portfolio media
  Future<String> uploadPortfolioMedia(String providerId, File file, String type) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = type == 'video' ? 'mp4' : 'jpg';
      final fileName = 'portfolio/${providerId}_${timestamp}.$extension';

      await _client.storage
          .from('portfolio_media')
          .upload(
        fileName,
        file,
        fileOptions: FileOptions(
          contentType: type == 'video' ? 'video/mp4' : 'image/jpeg',
        ),
      );

      return _client.storage
          .from('portfolio_media')
          .getPublicUrl(fileName);
    } catch (e) {
      debugPrint('❌ Error uploading portfolio media: $e');
      throw Exception('Failed to upload media: $e');
    }
  }

// Get portfolio with streaming
  Stream<List<Map<String, dynamic>>> listenToPortfolio(String providerId) {
    return _client
        .from('provider_portfolio')
        .stream(primaryKey: ['id'])
        .eq('provider_id', providerId)
        .order('created_at', ascending: false);
  }


  // ============ AUTH METHODS ============

  Future<AuthResponse> signUp(String email, String password, String fullName, String role) async {
    try {
      debugPrint('📝 Attempting sign up for: $email with role: $role');

      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'role': role,
        },
      );

      if (response.user != null) {
        final userId = response.user!.id;
        try {
          final existing = await _client
              .from('users')
              .select()
              .eq('id', userId)
              .maybeSingle();

          if (existing == null) {
            await _client.from('users').insert({
              'id': userId,
              'email': email,
              'full_name': fullName,
              'role': role,
              'is_online': true,
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            });
            debugPrint('✅ User created in public.users table: $userId');
          }
        } catch (e) {
          debugPrint('⚠️ Failed to insert user into table: $e');
        }
      }
      return response;
    } catch (e) {
      debugPrint('❌ SignUp error: $e');
      rethrow;
    }
  }

  Future<void> ensureUserExists(String userId, {String? email, String? fullName, String? role}) async {
    try {
      final existing = await _client.from('users').select().eq('id', userId).maybeSingle();
      if (existing != null) {
        // Update role if needed
        if (role != null && existing['role'] != role) {
          await _client.from('users').update({'role': role}).eq('id', userId);
        }
        return;
      }

      final user = _client.auth.currentUser;
      final userEmail = email ?? user?.email ?? 'unknown@email.com';
      final defaultRole = role ?? 'user';

      await _client.from('users').insert({
        'id': userId,
        'email': userEmail,
        'full_name': fullName ?? userEmail.split('@').first,
        'role': defaultRole,
        'is_online': true,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('❌ Error ensuring user exists: $e');
    }
  }

  Future<String?> getUserRole(String userId) async {
    try {
      final response = await _client.from('users').select('role').eq('id', userId).maybeSingle();
      return response?['role'] as String?;
    } catch (e) {
      return null;
    }
  }

  Future<AuthResponse> signIn(String email, String password) async {
    try {
      final response = await _client.auth.signInWithPassword(email: email, password: password);
      if (response.user != null) {
        await updateOnlineStatus(response.user!.id, true);
      }
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      final user = _client.auth.currentUser;
      if (user != null) {
        await updateOnlineStatus(user.id, false);
      }
      await _client.auth.signOut();
    } catch (e) {
      debugPrint('❌ SignOut error: $e');
    }
  }

  Future<void> updateOnlineStatus(String userId, bool isOnline) async {
    try {
      await _client
          .from('users')
          .update({'is_online': isOnline, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', userId);
    } catch (e) {
      debugPrint('❌ Error updating user status: $e');
    }
  }

  User? get currentUser => _client.auth.currentUser;
  String? get userId => currentUser?.id;

  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      return await _client.from('users').select().eq('id', userId).maybeSingle();
    } catch (e) {
      return null;
    }
  }

  Future<void> createProviderProfile(Map<String, dynamic> data) async {
    try {
      final userId = data['user_id'];
      final email = data['email'];
      final fullName = data['full_name'];

      if (userId != null) {
        await ensureUserExists(userId, email: email, fullName: fullName, role: 'provider');
      }

      final providerData = Map<String, dynamic>.from(data);
      providerData.remove('email');
      providerData.remove('full_name');

      await _client.from('providers').insert(providerData);
    } catch (e) {
      debugPrint('❌ Error in createProviderProfile: $e');
      rethrow;
    }
  }

  Future<void> updateProviderProfile(String providerId, Map<String, dynamic> data) async {
    try {
      final updateData = Map<String, dynamic>.from(data);
      updateData.remove('email');
      updateData.remove('full_name');
      updateData['updated_at'] = DateTime.now().toIso8601String();
      await _client.from('providers').update(updateData).eq('id', providerId);
    } catch (e) {
      debugPrint('❌ Error in updateProviderProfile: $e');
      rethrow;
    }
  }

  Future<void> updateProviderLocation(String providerId, double latitude, double longitude) async {
    try {
      await _client.from('providers').update({
        'latitude': latitude,
        'longitude': longitude,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', providerId);
    } catch (e) {
      debugPrint('❌ Error updating provider location: $e');
    }
  }

  Future<void> updateUserProfile(String userId, Map<String, dynamic> data) async {
    try {
      data['updated_at'] = DateTime.now().toIso8601String();
      await _client.from('users').update(data).eq('id', userId);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      return await _client.from('categories').select().eq('is_active', true).order('name');
    } catch (e) {
      return [];
    }
  }
  Future<List<Map<String, dynamic>>> getNearbyProviders({
    required double latitude,
    required double longitude,
    double radius = 10.0,
    String? categoryId,
    String? searchQuery,
  }) async {
    try {
      print('📍 getNearbyProviders called with lat: $latitude, lng: $longitude');

      // ✅ Use LEFT JOIN instead of INNER JOIN so providers without services still appear
      var query = _client.from('providers').select('''
        *,
        users!inner(full_name, email, profile_image, is_online),
        provider_services!left(*)
      ''');

      query = query.eq('is_available', true);

      // Only filter by category if provided and if it's a valid category
      if (categoryId != null && categoryId.isNotEmpty) {
        // For business providers, check category_id on providers table
        // For individual providers, check provider_services
        query = query.or('category_id.eq.$categoryId,provider_services.category_id.eq.$categoryId');
      }

      final response = await query;
      print('📦 Raw response count: ${response.length}');

      // Deduplicate providers
      final uniqueProvidersMap = <String, Map<String, dynamic>>{};
      for (var provider in response) {
        if (provider['id'] != null) {
          // If provider already exists, merge services
          if (uniqueProvidersMap.containsKey(provider['id'])) {
            final existing = uniqueProvidersMap[provider['id']]!;
            final existingServices = existing['provider_services'] as List? ?? [];
            final newServices = provider['provider_services'] as List? ?? [];
            existing['provider_services'] = [...existingServices, ...newServices];
          } else {
            uniqueProvidersMap[provider['id']] = provider;
          }
        }
      }
      var filteredProviders = uniqueProvidersMap.values.toList();
      print('📦 After deduplication: ${filteredProviders.length}');

      // Apply search query filter
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final searchLower = searchQuery.toLowerCase();
        filteredProviders = filteredProviders.where((provider) {
          final profession = (provider['profession'] ?? '').toString().toLowerCase();
          final name = (provider['users']?['full_name'] ?? '').toString().toLowerCase();
          final businessName = (provider['business_name'] ?? '').toString().toLowerCase();
          return profession.contains(searchLower) ||
              name.contains(searchLower) ||
              businessName.contains(searchLower);
        }).toList();
        print('📦 After search filter: ${filteredProviders.length}');
      }

      // Calculate distance for each provider
      final providersWithDistance = filteredProviders.map((provider) {
        final lat = provider['latitude']?.toDouble();
        final lon = provider['longitude']?.toDouble();
        if (lat != null && lon != null && lat != 0 && lon != 0) {
          final distance = Geolocator.distanceBetween(latitude, longitude, lat, lon) / 1000;
          provider['distance'] = distance;

          // Check if provider is in range (for business providers)
          final isBusiness = provider['is_business'] ?? false;
          if (isBusiness) {
            final serviceRadius = provider['service_radius']?.toDouble() ?? 20.0;
            provider['in_range'] = distance <= serviceRadius;
          } else {
            provider['in_range'] = true;
          }
        } else {
          provider['distance'] = -1.0;
          provider['in_range'] = true;
        }
        return provider;
      }).toList();

      // Filter by radius
      final radiusInKm = radius;
      final providersInRange = providersWithDistance
          .where((p) => p['distance'] >= 0 && p['distance'] <= radiusInKm)
          .toList();

      print('📦 After radius filter: ${providersInRange.length}');

      // Sort by distance
      providersInRange.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));

      return providersInRange;
    } catch (e) {
      debugPrint('❌ Error getting nearby providers: $e');
      return [];
    }
  }

  // Add this method to SupabaseService
  Future<List<Map<String, dynamic>>> getAllProviders() async {
    try {
      print('📊 Fetching all providers...');

      final response = await _client.from('providers').select('''
        *,
        users!inner(full_name, email, profile_image, is_online),
        provider_services!left(*)
      ''').eq('is_available', true);

      print('📊 Found ${response.length} providers');

      // Deduplicate providers
      final uniqueProvidersMap = <String, Map<String, dynamic>>{};
      for (var provider in response) {
        if (provider['id'] != null) {
          if (uniqueProvidersMap.containsKey(provider['id'])) {
            final existing = uniqueProvidersMap[provider['id']]!;
            final existingServices = existing['provider_services'] as List? ?? [];
            final newServices = provider['provider_services'] as List? ?? [];
            existing['provider_services'] = [...existingServices, ...newServices];
          } else {
            uniqueProvidersMap[provider['id']] = provider;
          }
        }
      }

      return uniqueProvidersMap.values.toList();
    } catch (e) {
      print('❌ Error fetching providers: $e');
      return [];
    }
  }


  Future<Map<String, dynamic>?> getProvider(String providerId) async {
    try {
      return await _client
          .from('providers')
          .select('*, users!inner(full_name, email, profile_image, is_online)')
          .eq('id', providerId)
          .maybeSingle();
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getProviderByUserId(String userId) async {
    try {
      return await _client
          .from('providers')
          .select('*, users!inner(full_name, email, profile_image, is_online)')
          .eq('user_id', userId)
          .maybeSingle();
    } catch (e) {
      return null;
    }
  }

  Future<void> addProviderService(Map<String, dynamic> data) async {
    try {
      await _client.from('provider_services').insert(data);
    } catch (e) {
      rethrow;
    }
  }



  // In supabase_service.dart, add this method:

  Future<Map<String, dynamic>> createBusinessRequest(Map<String, dynamic> data) async {
    try {
      // Ensure business_category_id is set
      if (data['category_id'] != null) {
        data['business_category_id'] = data['category_id'];
        data['category_id'] = null;
      }

      data['is_business'] = true;
      data['created_at'] = DateTime.now().toIso8601String();
      data['status'] = 'pending';

      final response = await _client
          .from('service_requests')
          .insert(data)
          .select()
          .maybeSingle();

      if (response != null) {
        await _notifyUserOfRequestChange(
            response['provider_id'],
            'New Order',
            'You have a new order from a customer',
            'service_request',
            response['id'],
            isProvider: true
        );
      }
      return response ?? {};
    } catch (e) {
      print('❌ Error creating business request: $e');
      rethrow;
    }
  }


  Future<List<Map<String, dynamic>>> getProviderServices(String providerId) async {
    try {
      return await _client.from('provider_services').select().eq('provider_id', providerId);
    } catch (e) {
      return [];
    }
  }

  String classifyRequest(String text) {
    final lowerText = text.toLowerCase();
    if (lowerText.contains('electric') || lowerText.contains('light') || lowerText.contains('wire') || lowerText.contains('fan')) {
      return 'Electrical Issue';
    } else if (lowerText.contains('pipe') || lowerText.contains('leak') || lowerText.contains('water') || lowerText.contains('tap')) {
      return 'Plumbing Issue';
    } else if (lowerText.contains('wood') || lowerText.contains('door') || lowerText.contains('furniture')) {
      return 'Carpentry Issue';
    } else if (lowerText.contains('ac') || lowerText.contains('cooling') || lowerText.contains('fridge')) {
      return 'Appliance Repair';
    }
    return 'General Inquiry';
  }

// In supabase_service.dart - update createServiceRequest

// In supabase_service.dart - update createServiceRequest

  Future<Map<String, dynamic>> createServiceRequest(Map<String, dynamic> data) async {
    try {
      // ✅ Handle both regular and business categories
      final isBusiness = data['is_business'] ?? false;

      // Ensure category_id is valid
      if (!isBusiness) {
        if (data['category_id'] != null) {
          final categoryExists = await _client
              .from('categories')
              .select('id')
              .eq('id', data['category_id'])
              .maybeSingle();

          if (categoryExists == null) {
            final defaultCategory = await _client
                .from('categories')
                .select('id')
                .limit(1)
                .maybeSingle();
            data['category_id'] = defaultCategory?['id'];
          }
        }
      } else {
        data['business_category_id'] = data['category_id'];
        data['category_id'] = null;
      }

      // ✅ Ensure latitude and longitude have values
      data['latitude'] = data['latitude'] ?? 0.0;
      data['longitude'] = data['longitude'] ?? 0.0;

      data['created_at'] = DateTime.now().toIso8601String();
      data['status'] = 'pending';

      // Remove any keys that shouldn't be inserted directly
      data.remove('is_business');

      final response = await _client
          .from('service_requests')
          .insert(data)
          .select()
          .maybeSingle();

      if (response != null) {
        await _notifyUserOfRequestChange(
            response['provider_id'],
            isBusiness ? 'New Order!' : 'New Service Request',
            isBusiness
                ? 'You have a new order from a customer!'
                : 'You have a new service request',
            'service_request',
            response['id'],
            isProvider: true
        );
      }
      return response ?? {};
    } catch (e) {
      print('❌ Error creating service request: $e');
      rethrow;
    }
  }  Future<void> updateServiceRequest(String requestId, Map<String, dynamic> data) async {
    try {
      await _client.from('service_requests').update(data).eq('id', requestId);

      // Notify user of status change
      if (data.containsKey('status')) {
        final request = await _client.from('service_requests').select().eq('id', requestId).single();
        final status = data['status'];
        final title = 'Request $status';
        final body = 'Your service request has been $status by the provider';

        await _notifyUserOfRequestChange(
          request['user_id'],
          title,
          body,
          'request_status',
          requestId,
          isProvider: false
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getProviderRequests(String providerId) async {
    try {
      return await _client
          .from('service_requests')
          .select('*, users!inner(full_name, email, profile_image)')
          .eq('provider_id', providerId)
          .order('created_at', ascending: false);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getUserRequests(String userId) async {
    try {
      return await _client
          .from('service_requests')
          .select('*, providers!inner(profession, users!inner(full_name))')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
    } catch (e) {
      return [];
    }
  }

  Stream<List<Map<String, dynamic>>> listenToUserRequests(String userId) {
    return _client
        .from('service_requests')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .asyncMap((requests) async {
          if (requests.isEmpty) return [];

          final providerIds = requests.map((r) => r['provider_id'] as String).toSet().toList();
          final providers = await _client
              .from('providers')
              .select('id, profession, users!inner(full_name)')
              .filter('id', 'in', providerIds);

          final providerMap = {for (var p in providers) p['id']: p};

          for (var r in requests) {
            r['providers'] = providerMap[r['provider_id']];
          }
          return List<Map<String, dynamic>>.from(requests);
        });
  }

  Stream<List<Map<String, dynamic>>> listenToProviderRequests(String providerId) {
    return _client
        .from('service_requests')
        .stream(primaryKey: ['id'])
        .eq('provider_id', providerId)
        .order('created_at', ascending: false)
        .asyncMap((requests) async {
          if (requests.isEmpty) return [];

          final userIds = requests.map((r) => r['user_id'] as String).toSet().toList();
          final users = await _client
              .from('users')
              .select('id, full_name, email, profile_image')
              .filter('id', 'in', userIds);

          final userMap = {for (var u in users) u['id']: u};

          for (var r in requests) {
            r['users'] = userMap[r['user_id']];
          }
          return List<Map<String, dynamic>>.from(requests);
        });
  }

  // ============ FAVORITES ============

  Future<void> toggleFavorite(String userId, String providerId) async {
    try {
      final existing = await _client
          .from('favorites')
          .select()
          .eq('user_id', userId)
          .eq('provider_id', providerId)
          .maybeSingle();

      if (existing == null) {
        await _client.from('favorites').insert({
          'user_id': userId,
          'provider_id': providerId,
          'created_at': DateTime.now().toIso8601String(),
        });
      } else {
        await _client
            .from('favorites')
            .delete()
            .eq('user_id', userId)
            .eq('provider_id', providerId);
      }
    } catch (e) {
      debugPrint('❌ Error toggling favorite: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getFavorites(String userId) async {
    try {
      return await _client
          .from('favorites')
          .select('*, providers!inner(*, users!inner(*))')
          .eq('user_id', userId);
    } catch (e) {
      debugPrint('❌ Error getting favorites: $e');
      return [];
    }
  }

  // ============ REVIEWS ============

  Future<List<Map<String, dynamic>>> getProviderReviews(String providerId) async {
    try {
      return await _client
          .from('reviews')
          .select('*, users!inner(full_name, profile_image)')
          .eq('provider_id', providerId)
          .order('created_at', ascending: false);
    } catch (e) {
      debugPrint('❌ Error getting provider reviews: $e');
      return [];
    }
  }

  // ============ NOTIFICATIONS ============

  Future<List<Map<String, dynamic>>> getNotifications(String userId) async {
    try {
      return await _client
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
    } catch (e) {
      debugPrint('❌ Error getting notifications: $e');
      return [];
    }
  }

  Future<void> markNotificationRead(String id) async {
    try {
      await _client.from('notifications').update({'is_read': true}).eq('id', id);
    } catch (e) {
      debugPrint('❌ Error marking notification read: $e');
    }
  }

  Future<void> markAllNotificationsRead(String userId) async {
    try {
      await _client.from('notifications').update({'is_read': true}).eq('user_id', userId);
    } catch (e) {
      debugPrint('❌ Error marking all notifications read: $e');
    }
  }

  Future<void> deleteNotification(String id) async {
    try {
      await _client.from('notifications').delete().eq('id', id);
    } catch (e) {
      debugPrint('❌ Error deleting notification: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> listenToNotifications(String userId) {
    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false);
  }

  // ============ CHAT METHODS ============

  Future<List<Map<String, dynamic>>> getMessages(String roomId) async {
    try {
      final response = await _client
          .from('messages')
          .select('*, users:sender_id(id, full_name, profile_image)')
          .eq('room_id', roomId)
          .order('created_at', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to load messages: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> listenToMessages(String roomId) {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .order('created_at', ascending: true)
        .asyncMap((messages) async {
          if (messages.isEmpty) return [];

          final senderIds = messages.map((m) => m['sender_id'] as String).toSet().toList();
          final users = await _client.from('users').select('id, full_name, profile_image').filter('id', 'in', senderIds);
          final userMap = {for (var u in users) u['id']: u};

          for (var m in messages) {
            m['users'] = userMap[m['sender_id']];
          }
          return List<Map<String, dynamic>>.from(messages);
        });
  }

  Future<void> markMessagesAsRead(String roomId, String userId) async {
    try {
      final updated = await _client
          .from('messages')
          .update({'is_read': true})
          .eq('room_id', roomId)
          .neq('sender_id', userId)
          .eq('is_read', false)
          .select();

      if (updated.isNotEmpty) {
        try {
          await _client.from('chat_rooms').update({
            'updated_at': DateTime.now().toIso8601String(),
          }).eq('id', roomId);
        } catch (e) {
          debugPrint('⚠️ Failed to touch chat room: $e');
        }
      }
    } catch (e) {
      debugPrint('❌ Error in markMessagesAsRead: $e');
    }
  }

// lib/core/services/supabase_service.dart

// Check if CNIC already exists and get user details
  Future<Map<String, dynamic>?> getUserByCNIC(String cnicNumber) async {
    try {
      final response = await _client
          .from('users')
          .select('id, email, full_name, phone, role, cnic, cnic_verified, face_verified')
          .eq('cnic', cnicNumber)
          .maybeSingle();

      if (response != null) {
        debugPrint('✅ User found with CNIC: $cnicNumber');
        return response;
      }

      debugPrint('ℹ️ No user found with CNIC: $cnicNumber');
      return null;
    } catch (e) {
      debugPrint('❌ Error checking CNIC: $e');
      return null;
    }
  }

// Check if CNIC already exists (returns bool)
  Future<bool> checkCNICExists(String cnicNumber) async {
    try {
      final user = await getUserByCNIC(cnicNumber);
      return user != null;
    } catch (e) {
      debugPrint('❌ Error checking CNIC: $e');
      return false;
    }
  }
// Save user with verification data
  Future<void> saveUserWithVerification({
    required String userId,
    required String cnicNumber,
    required String cnicFrontImage,
    required String cnicBackImage,
    required String faceImage,
    required String faceEmbedding,
  }) async {
    try {
      await _client.from('users').update({
        'cnic': cnicNumber,
        'cnic_front_image': cnicFrontImage,
        'cnic_back_image': cnicBackImage,
        'face_image': faceImage,
        'face_embedding': faceEmbedding,
        'cnic_verified': true,
        'face_verified': true,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);

      debugPrint('✅ User verification data saved');
    } catch (e) {
      debugPrint('❌ Error saving verification data: $e');
      throw Exception('Failed to save verification data: $e');
    }
  }



// Upload verification image to storage
  Future<String> uploadVerificationImage(
      String userId,
      String type,
      File imageFile,
      ) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${userId}_${type}_$timestamp.jpg';
      final filePath = 'verification/$fileName';

      await _client.storage
          .from('verification_images')
          .upload(
        filePath,
        imageFile,
        fileOptions: const FileOptions(
          contentType: 'image/jpeg',
        ),
      );

      final publicUrl = _client.storage
          .from('verification_images')
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      print('❌ Error uploading verification image: $e');
      throw Exception('Failed to upload image: $e');
    }
  }




  Future<void> sendMessage(String roomId, String senderId, String content,
      {String? type, String? mediaUrl}) async {
    try {
      final now = DateTime.now().toIso8601String();
      final msgResponse = await _client.from('messages').insert({
        'room_id': roomId,
        'sender_id': senderId,
        'content': content,
        'message_type': type ?? 'text',
        'media_url': mediaUrl,
        'is_read': false,
        'created_at': now,
      }).select().single();

      // Create notification entry for the receiver
      final room = await _client.from('chat_rooms').select('user_id, provider_id').eq('id', roomId).single();
      String receiverId;
      if (room['user_id'] == senderId) {
        // Current user is the 'user', so receiver is the provider's USER ID
        final provider = await _client.from('providers').select('user_id').eq('id', room['provider_id']).single();
        receiverId = provider['user_id'];
      } else {
        // Current user is the provider (using user_id to match), so receiver is the 'user'
        receiverId = room['user_id'];
      }

      await _client.from('notifications').insert({
        'user_id': receiverId,
        'title': 'New Message',
        'body': content,
        'type': 'message',
        'data': {'room_id': roomId, 'message_id': msgResponse['id']},
        'created_at': now,
      });

      try {
        await _client.from('chat_rooms').update({
          'updated_at': now,
          'last_message': content,
          'last_message_time': now,
        }).eq('id', roomId);
      } catch (e) {
        debugPrint('⚠️ Could not update all chat_rooms summary columns: $e');
        await _client.from('chat_rooms').update({'updated_at': now}).eq('id', roomId);
      }
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getChatRooms(String userId, String role) async {
    try {
      String filterId = userId;
      String filterColumn = 'user_id';

      if (role == 'provider') {
        final provider = await getProviderByUserId(userId);
        if (provider != null) {
          filterId = provider['id'];
          filterColumn = 'provider_id';
        }
      }

      final response = await _client.from('chat_rooms').select('''
          *,
          provider:provider_id(id, users:user_id(full_name, profile_image, is_online)),
          user:user_id(id, full_name, profile_image, is_online)
        ''').eq(filterColumn, filterId).order('updated_at', ascending: false);

      final List<Map<String, dynamic>> rooms = List<Map<String, dynamic>>.from(response);

      for (var room in rooms) {
        // 1. Get unread count
        final unreadResponse = await _client
            .from('messages')
            .select('id')
            .eq('room_id', room['id'])
            .eq('is_read', false)
            .neq('sender_id', userId);

        room['unread_count'] = (unreadResponse as List).length;

        // 2. Get last message details if missing from chat_rooms
        if (room['last_message_sender_id'] == null) {
          final lastMsg = await _client
              .from('messages')
              .select('sender_id, is_read, content, created_at')
              .eq('room_id', room['id'])
              .order('created_at', ascending: false)
              .limit(1)
              .maybeSingle();

          if (lastMsg != null) {
            room['last_message_sender_id'] = lastMsg['sender_id'];
            room['last_message_read'] = lastMsg['is_read'];
            if (room['last_message'] == null) room['last_message'] = lastMsg['content'];
            if (room['last_message_time'] == null) room['last_message_time'] = lastMsg['created_at'];
          }
        }
      }

      return rooms;
    } catch (e) {
      debugPrint('❌ Error in getChatRooms: $e');
      throw Exception('Failed to load chat rooms: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> listenToChatRooms(String userId, String role) {
    return Stream.fromFuture(Future.value(null)).asyncExpand((_) async* {
      String filterColumn = 'user_id';
      String filterId = userId;

      if (role == 'provider') {
        final provider = await getProviderByUserId(userId);
        if (provider != null) {
          filterId = provider['id'];
          filterColumn = 'provider_id';
        }
      }

      yield* _client
          .from('chat_rooms')
          .stream(primaryKey: ['id'])
          .eq(filterColumn, filterId)
          .asyncMap((event) async {
            return await getChatRooms(userId, role);
          });
    });
  }

  Future<String> getOrCreateChatRoom(String userId, String providerId, {String? requestId}) async {
    try {
      final existing = await _client
          .from('chat_rooms')
          .select()
          .eq('user_id', userId)
          .eq('provider_id', providerId)
          .maybeSingle();

      if (existing != null) return existing['id'];

      final response = await _client.from('chat_rooms').insert({
        'user_id': userId,
        'provider_id': providerId,
        'request_id': requestId,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).select().single();

      return response['id'];
    } catch (e) {
      throw Exception('Failed to get or create chat room: $e');
    }
  }


  // In supabase_service.dart - add this method

  Future<Map<String, dynamic>> createBusinessServiceRequest(Map<String, dynamic> data) async {
    try {
      // Ensure business_category_id is set
      if (data['category_id'] != null) {
        data['business_category_id'] = data['category_id'];
        data['category_id'] = null;
      }

      data['is_business'] = true;
      data['created_at'] = DateTime.now().toIso8601String();
      data['status'] = 'pending';

      // Create the request
      final response = await _client
          .from('service_requests')
          .insert(data)
          .select()
          .maybeSingle();

      if (response != null) {
        // Send notification to provider
        await _notifyUserOfRequestChange(
            response['provider_id'],
            'New Order! 🛒',
            'You have a new order from a customer. Check the details and confirm!',
            'service_request',
            response['id'],
            isProvider: true
        );
      }
      return response ?? {};
    } catch (e) {
      print('❌ Error creating business request: $e');
      rethrow;
    }
  }


  Future<void> _notifyUserOfRequestChange(String id, String title, String body, String type, String requestId, {required bool isProvider}) async {
    try {
      String targetUserId = id;
      if (isProvider) {
        // id passed is providerId, need to get user_id
        final provider = await _client.from('providers').select('user_id').eq('id', id).single();
        targetUserId = provider['user_id'];
      }

      await _client.from('notifications').insert({
        'user_id': targetUserId,
        'title': title,
        'body': body,
        'type': type,
        'data': {'request_id': requestId},
        'created_at': DateTime.now().toIso8601String(),
        'is_read': false,
      });
    } catch (e) {
      debugPrint('❌ Notification error: $e');
    }
  }
}
