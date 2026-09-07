// lib/features/provider/dashboard_screen.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../app/theme.dart';
import '../../core/services/supabase_service.dart';
import '../provider/auth_provider.dart';

class ProviderDashboardScreen extends StatefulWidget {
  const ProviderDashboardScreen({super.key});

  @override
  State<ProviderDashboardScreen> createState() => _ProviderDashboardScreenState();
}

class _ProviderDashboardScreenState extends State<ProviderDashboardScreen>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  Map<String, dynamic>? _providerData;
  List<Map<String, dynamic>> _newRequests = [];
  List<Map<String, dynamic>> _businessProducts = [];
  double _totalEarnings = 0;
  int _completedJobs = 0;
  int _totalOrders = 0;
  double rating = 0;
  bool isAvailable = false;
  bool _isBusiness = false;
  int unreadNotifications = 0;

  late AnimationController _pulseController;
  late AnimationController _floatingController;

  @override
  void initState() {
    super.initState();
    _loadData();
    _listenToNotifications();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  Widget _buildBackground(Size size) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF38804f),
                    Color(0xFF1d3b27),
                    Color(0xFF1d3b27),
                    Color(0xFF38804f),
                  ],
                  stops: [0.0, 0.35, 0.70, 1.0],
                ),
              ),
            ),
            Positioned(
              top: -120,
              right: -100,
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final opacity = 0.15 + (0.08 * (1 + math.sin(
                    _pulseController.value * math.pi * 2,
                  )) / 2);
                  return Container(
                    width: 350,
                    height: 350,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF6C63FF).withOpacity(opacity),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Positioned(
              bottom: -150,
              left: -120,
              child: Container(
                width: 350,
                height: 350,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF4D96FF).withOpacity(0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            AnimatedBuilder(
              animation: _floatingController,
              builder: (context, child) {
                final value = math.sin(
                  _floatingController.value * math.pi * 2,
                );
                return Positioned(
                  top: 140 + value * 15,
                  right: 30,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.04),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.06),
                        width: 1.5,
                      ),
                    ),
                  ),
                );
              },
            ),
            AnimatedBuilder(
              animation: _floatingController,
              builder: (context, child) {
                final value = math.sin(
                  _floatingController.value * math.pi * 2,
                );
                return Positioned(
                  bottom: 50 + value * 15,
                  left: 30,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.04),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.06),
                        width: 1.5,
                      ),
                    ),
                  ),
                );
              },
            ),
            AnimatedBuilder(
              animation: _floatingController,
              builder: (context, child) {
                final value = math.cos(
                  _floatingController.value * math.pi * 2 + 1.5,
                );
                return Positioned(
                  bottom: 120 + value * 12,
                  left: 20,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),
                );
              },
            ),
            Positioned(
              top: 80,
              right: 20,
              child: _buildDotPattern(
                rows: 4,
                columns: 4,
                spacing: 18,
              ),
            ),
            Positioned(
              bottom: 100,
              right: 16,
              child: _buildDotPattern(
                rows: 4,
                columns: 4,
                spacing: 18,
              ),
            ),
            Positioned(
              bottom: 100,
              left: 16,
              child: _buildDotPattern(
                rows: 4,
                columns: 4,
                spacing: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDotPattern({
    required int rows,
    required int columns,
    required double spacing,
  }) {
    return SizedBox(
      width: columns * spacing,
      height: rows * spacing,
      child: Column(
        children: List.generate(
          rows,
              (row) {
            return Row(
              children: List.generate(
                columns,
                    (column) {
                  final isEven = (row + column) % 2 == 0;
                  return Container(
                    width: isEven ? 4 : 2.5,
                    height: isEven ? 4 : 2.5,
                    margin: EdgeInsets.only(
                      right: spacing - 4,
                      bottom: spacing - 4,
                    ),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(
                        isEven ? 0.35 : 0.055,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.userId;
      if (userId == null) return;

      final provider = await SupabaseService().getProviderByUserId(userId);
      if (provider != null) {
        setState(() {
          _providerData = provider;
          isAvailable = provider['is_available'] ?? false;
          rating = (provider['rating'] ?? 0).toDouble();
          _isBusiness = provider['is_business'] ?? false;
        });

        final requests = await SupabaseService().getProviderRequests(provider['id']);
        setState(() {
          _newRequests = requests.where((r) => r['status'] == 'pending').toList();
          _completedJobs = requests.where((r) => r['status'] == 'completed').length;
          _totalEarnings = _completedJobs * 500.0;
        });

        final notifications = await SupabaseService().getNotifications(userId);
        setState(() {
          unreadNotifications = notifications.where((n) => n['is_read'] == false).length;
        });

        if (_isBusiness) {
          final products = await Supabase.instance.client
              .from('business_products')
              .select()
              .eq('provider_id', provider['id']);

          setState(() {
            _businessProducts = List<Map<String, dynamic>>.from(products);
            _totalOrders = _businessProducts.length;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _listenToNotifications() {
    final userId = context.read<AuthProvider>().userId;
    if (userId != null) {
      SupabaseService().listenToNotifications(userId).listen((notifications) {
        if (mounted) {
          setState(() {
            unreadNotifications = notifications.where((n) => n['is_read'] == false).length;
          });
        }
      });
    }
  }

  Future<void> _toggleAvailability(bool value) async {
    if (_providerData == null) return;
    try {
      await SupabaseService().updateProviderProfile(_providerData!['id'], {'is_available': value});
      setState(() => isAvailable = value);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating availability: $e'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Map<String, dynamic> _getUserData(Map<String, dynamic> request) {
    if (request['users'] != null) {
      return Map<String, dynamic>.from(request['users']);
    }
    return <String, dynamic>{};
  }

  Future<void> _handleAccept(Map<String, dynamic> request, Map<String, dynamic> user) async {
    try {
      await SupabaseService().updateServiceRequest(request['id'], {'status': 'accepted'});
      await _loadData();
      if (!mounted) return;

      final roomId = await SupabaseService().getOrCreateChatRoom(
        request['user_id'],
        _providerData!['id'],
        requestId: request['id'],
      );

      if (mounted) {
        context.push('/provider/chat/$roomId', extra: {
          'userName': user['full_name'] ?? 'Customer',
          'userId': request['user_id'],
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _handleDecline(Map<String, dynamic> request) async {
    try {
      await SupabaseService().updateServiceRequest(request['id'], {'status': 'rejected'});
      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      final diff = DateTime.now().difference(date);
      if (diff.inDays > 0) return '${diff.inDays}d ago';
      if (diff.inHours > 0) return '${diff.inHours}h ago';
      if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
      return 'Just now';
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0A2A),
      body: Stack(
        children: [
          _buildBackground(size),
          SafeArea(
            child: RefreshIndicator(
              onRefresh: _loadData,
              color: const Color(0xFF49e8c3),
              backgroundColor: Colors.white.withOpacity(0.1),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // App Bar
                  SliverAppBar(
                    expandedHeight: 190,
                    pinned: true,
                    stretch: true,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    flexibleSpace: FlexibleSpaceBar(
                      stretchModes: const [StretchMode.zoomBackground],
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF38804f),
                              Color(0xFF1d3b27),
                              Color(0xFF1d3b27),
                              Color(0xFF38804f),
                            ],
                            stops: [0.0, 0.35, 0.70, 1.0],
                          ),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              right: -50,
                              top: -50,
                              child: Container(
                                width: 200,
                                height: 200,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      const Color(0xFF6C63FF).withOpacity(0.15),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFF49e8c3).withOpacity(0.3),
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF49e8c3).withOpacity(0.2),
                                          blurRadius: 15,
                                        ),
                                      ],
                                    ),
                                    child: CircleAvatar(
                                      radius: 34,
                                      backgroundColor: Colors.white.withOpacity(0.1),
                                      backgroundImage: _providerData?['users']?['profile_image'] != null
                                          ? NetworkImage(_providerData!['users']['profile_image'])
                                          : null,
                                      child: _providerData?['users']?['profile_image'] == null
                                          ? Icon(Icons.person_rounded, size: 34, color: Colors.white.withOpacity(0.5))
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          _providerData?['users']?['full_name'] ?? 'Provider',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: -0.3,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Text(
                                              _isBusiness
                                                  ? (_providerData?['business_name'] ?? 'Business')
                                                  : (_providerData?['profession'] ?? 'Service Expert'),
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(0.7),
                                                fontSize: 12,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            if (_isBusiness) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFFF6B6B).withOpacity(0.2),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: const Text(
                                                  'Business',
                                                  style: TextStyle(
                                                    color: Color(0xFFFF6B6B),
                                                    fontSize: 8,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        // Availability Toggle
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: isAvailable ? const Color(0xFF49e8c3).withOpacity(0.15) : Colors.white.withOpacity(0.05),
                                                borderRadius: BorderRadius.circular(10),
                                                border: Border.all(
                                                  color: isAvailable ? const Color(0xFF49e8c3).withOpacity(0.3) : Colors.white.withOpacity(0.05),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Container(
                                                    width: 5,
                                                    height: 5,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color: isAvailable ? const Color(0xFF49e8c3) : Colors.grey,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    isAvailable ? 'Available' : 'Unavailable',
                                                    style: TextStyle(
                                                      fontSize: 9,
                                                      fontWeight: FontWeight.w600,
                                                      color: isAvailable ? const Color(0xFF49e8c3) : Colors.white.withOpacity(0.3),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Switch(
                                                    value: isAvailable,
                                                    onChanged: _toggleAvailability,
                                                    activeColor: const Color(0xFF49e8c3),
                                                    inactiveThumbColor: Colors.grey,
                                                    activeTrackColor: const Color(0xFF49e8c3).withOpacity(0.3),
                                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                    trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Action Buttons
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // Notification Button
                                      GestureDetector(
                                        onTap: () => context.push('/provider/notifications'),
                                        child: Stack(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(10),
                                                border: Border.all(
                                                  color: Colors.white.withOpacity(0.06),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Icon(
                                                Icons.notifications_none_rounded,
                                                color: Colors.white.withOpacity(0.8),
                                                size: 20,
                                              ),
                                            ),
                                            if (unreadNotifications > 0)
                                              Positioned(
                                                right: 2,
                                                top: 2,
                                                child: Container(
                                                  padding: const EdgeInsets.all(2),
                                                  decoration: const BoxDecoration(
                                                    color: Colors.red,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                                                  child: Text(
                                                    unreadNotifications > 9 ? '9+' : unreadNotifications.toString(),
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 7,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      GestureDetector(
                                        onTap: () => context.push('/provider/chats'),
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(
                                              color: Colors.white.withOpacity(0.06),
                                              width: 1,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.chat_bubble_outline_rounded,
                                            color: Colors.white.withOpacity(0.8),
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                      // Edit Button - Only for Service Providers (Not Business)
                                      if (!_isBusiness)
                                        const SizedBox(height: 6),
                                      if (!_isBusiness)
                                        GestureDetector(
                                          onTap: () => context.push('/provider/cv'),
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                colors: [Color(0xFF49e8c3), Color(0xFF31b999)],
                                              ),
                                              borderRadius: BorderRadius.circular(10),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color(0xFF49e8c3).withOpacity(0.3),
                                                  blurRadius: 8,
                                                ),
                                              ],
                                            ),
                                            child: Icon(
                                              Icons.assignment_rounded,
                                              color: Colors.black,
                                              size: 16,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Content
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Stats Grid - Fixed Size Cards
                          _buildStatsGrid(),
                          const SizedBox(height: 20),

                          // Business Actions
                          if (_isBusiness) _buildBusinessActions(),
                          const SizedBox(height: 16),

                          // Section Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF6B6B).withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.pending_actions_rounded,
                                      color: Color(0xFFFF6B6B),
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Pending Requests',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              TextButton(
                                onPressed: () => context.push('/provider/requests'),
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF49e8c3),
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(0, 0),
                                ),
                                child: const Text(
                                  'View All',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),

                  // Requests List
                  _buildRequestsList(),
                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBusinessActions() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B6B).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  color: Color(0xFFFF6B6B),
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Business Management',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/business/category-selection'),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text(
                    'Add Product',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF49e8c3),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/business/products'),
                  icon: const Icon(Icons.inventory_rounded, size: 16),
                  label: const Text(
                    'Manage',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withOpacity(0.2)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final screenWidth = MediaQuery.of(context).size.width;
    final int crossAxisCount = _isBusiness ? 3 : 2;
    final double tileWidth = (screenWidth - 40) / crossAxisCount - 8;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        SizedBox(
          width: tileWidth,
          child: _buildStatTile(
            'Jobs',
            _completedJobs.toString(),
            Icons.work_history_rounded,
            const Color(0xFF6C63FF),
            Colors.purple.withOpacity(0.1),
          ),
        ),
        SizedBox(
          width: tileWidth,
          child: _buildStatTile(
            'Earnings',
            'Rs. ${_totalEarnings.toInt()}',
            Icons.account_balance_wallet_rounded,
            const Color(0xFF49e8c3),
            const Color(0xFF49e8c3).withOpacity(0.1),
          ),
        ),
        SizedBox(
          width: tileWidth,
          child: _buildStatTile(
            'Rating',
            rating.toStringAsFixed(1),
            Icons.star_rounded,
            const Color(0xFFFFB74D),
            const Color(0xFFFFB74D).withOpacity(0.1),
          ),
        ),
        SizedBox(
          width: tileWidth,
          child: _buildStatTile(
            'Requests',
            _newRequests.length.toString(),
            Icons.notifications_active_rounded,
            const Color(0xFFFF6B6B),
            const Color(0xFFFF6B6B).withOpacity(0.1),
          ),
        ),
        if (_isBusiness) ...[
          SizedBox(
            width: tileWidth,
            child: _buildStatTile(
              'Products',
              _businessProducts.length.toString(),
              Icons.inventory_rounded,
              const Color(0xFF4D96FF),
              const Color(0xFF4D96FF).withOpacity(0.1),
            ),
          ),
          SizedBox(
            width: tileWidth,
            child: _buildStatTile(
              'Orders',
              _totalOrders.toString(),
              Icons.shopping_cart_rounded,
              const Color(0xFF06B6D4),
              const Color(0xFF06B6D4).withOpacity(0.1),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatTile(String title, String value, IconData icon, Color color, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.04),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              color: color,
              size: 16,
            ),
          ),
          const SizedBox(height: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.white.withOpacity(0.4),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsList() {
    if (_isLoading) {
      return const SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF49e8c3)),
              SizedBox(height: 16),
              Text('Loading requests...', style: TextStyle(color: Colors.white70, fontSize: 14)),
            ],
          ),
        ),
      );
    }

    if (_newRequests.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 30),
          child: Column(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.05), width: 1),
                ),
                child: const Icon(Icons.check_circle_outline_rounded, size: 30, color: Colors.white30),
              ),
              const SizedBox(height: 12),
              Text(
                'All caught up!',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.8)),
              ),
              const SizedBox(height: 6),
              Text(
                'New requests will appear here.',
                style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.4)),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
              (context, index) {
            final request = _newRequests[index];
            final user = _getUserData(request);
            return _buildRequestCard(request, user);
          },
          childCount: _newRequests.length > 5 ? 5 : _newRequests.length,
        ),
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request, Map<String, dynamic> user) {
    final isBusiness = request['is_business'] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF49e8c3).withOpacity(0.3), width: 2),
                ),
                child: ClipOval(
                  child: user['profile_image'] != null
                      ? CachedNetworkImage(
                    imageUrl: user['profile_image'],
                    fit: BoxFit.cover,
                    width: 40,
                    height: 40,
                    errorWidget: (context, url, error) => Container(
                      color: const Color(0xFF49e8c3),
                      child: Icon(Icons.person, color: Colors.white, size: 20),
                    ),
                  )
                      : Container(
                    color: const Color(0xFF49e8c3),
                    child: Icon(Icons.person, color: Colors.white, size: 20),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user['full_name'] ?? 'Customer',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        Text(
                          _formatDate(request['created_at']),
                          style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.3)),
                        ),
                        const SizedBox(width: 6),
                        if (isBusiness)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF6B6B).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Business',
                              style: TextStyle(fontSize: 7, color: Color(0xFFFF6B6B), fontWeight: FontWeight.w600),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              _buildUrgencyBadge(request['urgency']),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  isBusiness ? Icons.shopping_bag_outlined : Icons.description_outlined,
                  size: 14,
                  color: Colors.white.withOpacity(0.3),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    request['description'] ?? 'No description provided.',
                    style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7), height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _handleAccept(request, user),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF49e8c3),
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    minimumSize: const Size(0, 0),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_rounded, size: 14),
                      const SizedBox(width: 4),
                      const Text('Accept', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _handleDecline(request),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade400,
                    side: BorderSide(color: Colors.red.shade400),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    minimumSize: const Size(0, 0),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.close_rounded, size: 14),
                      const SizedBox(width: 4),
                      const Text('Decline', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUrgencyBadge(String? urgency) {
    Color color = Colors.green.shade400;
    String label = 'Low';
    if (urgency == 'emergency') { color = Colors.red.shade400; label = 'Emergency'; }
    else if (urgency == 'high') { color = Colors.orange.shade400; label = 'High'; }
    else if (urgency == 'medium') { color = Colors.blue.shade400; label = 'Medium'; }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 0.3),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.transparent,
      selectedItemColor: const Color(0xFF49e8c3),
      unselectedItemColor: Colors.white.withOpacity(0.4),
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 10, letterSpacing: 0.3),
      unselectedLabelStyle: const TextStyle(fontSize: 10, letterSpacing: 0.3),
      elevation: 0,
      currentIndex: 0,
      onTap: (index) {
        switch (index) {
          case 0: break;
          case 1: context.push('/provider/requests'); break;
          case 2: context.push('/provider/chats'); break;
          case 3: context.push('/provider/profile'); break;
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded, size: 22), label: 'Dashboard'),
        BottomNavigationBarItem(icon: Icon(Icons.assignment_rounded, size: 22), label: 'Requests'),
        BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_rounded, size: 22), label: 'Chats'),
        BottomNavigationBarItem(icon: Icon(Icons.person_rounded, size: 22), label: 'Profile'),
      ],
    );
  }
}