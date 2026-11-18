import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../app/theme.dart';
import '../../core/services/supabase_service.dart';
import '../../utils/CategoryColors.dart';
import '../../widgets/category_card.dart';
import '../../widgets/provider_card.dart';
import '../provider/auth_provider.dart';
import '../provider/provider_provider.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;
  bool _isLocationLoading = true;
  String? _userName;
  bool _hasLocationPermission = false;

  // Background Animation Controllers
  late AnimationController _pulseController;
  late AnimationController _floatingController;

  // Drawer State
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _checkLocationPermission();

    // Background Animations
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
    _searchController.dispose();
    _pulseController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;
    if (user != null) {
      setState(() {
        _userName = user['full_name'] ?? 'User';
      });
    }
  }

  Future<void> _checkLocationPermission() async {
    final status = await Permission.location.status;

    if (status.isDenied) {
      final result = await Permission.location.request();
      if (result.isGranted) {
        setState(() {
          _hasLocationPermission = true;
        });
        _loadData();
      } else {
        setState(() {
          _hasLocationPermission = false;
          _isLoading = false;
          _isLocationLoading = false;
        });
        _showLocationPermissionDialog();
      }
    } else if (status.isGranted) {
      setState(() {
        _hasLocationPermission = true;
      });
      _loadData();
    } else if (status.isPermanentlyDenied) {
      setState(() {
        _hasLocationPermission = false;
        _isLoading = false;
        _isLocationLoading = false;
      });
      _showLocationPermissionDialog();
    }
  }

  void _showLocationPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Location Permission Required'),
        content: const Text(
          'We need location access to find service providers near you. '
              'Please enable location permission in your device settings.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _loadProvidersWithoutLocation();
            },
            child: const Text('Skip'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await openAppSettings();
              _checkLocationPermission();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF49e8c3),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadData() async {
    if (!_hasLocationPermission) {
      await _loadProvidersWithoutLocation();
      return;
    }

    setState(() => _isLoading = true);

    try {
      final categories = await SupabaseService().getCategories();
      setState(() {
        _categories = categories;
      });

      await _loadNearbyProviders();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error loading data: $e');
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadNearbyProviders() async {
    try {
      setState(() => _isLocationLoading = true);

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final providerProvider = context.read<ProviderProvider>();
      await providerProvider.loadNearbyProviders(
        latitude: position.latitude,
        longitude: position.longitude,
        radius: 10.0,
      );

      setState(() {
        _isLocationLoading = false;
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Location error: $e');
      }
      setState(() {
        _isLocationLoading = false;
        _isLoading = false;
      });

      await _loadProvidersWithoutLocation();
    }
  }

  Future<void> _loadProvidersWithoutLocation() async {
    try {
      final providerProvider = context.read<ProviderProvider>();

      final allProviders = await SupabaseService().getNearbyProviders(
        latitude: 0,
        longitude: 0,
        radius: 1000,
      );

      providerProvider.setProviders(allProviders);
      providerProvider.setLoading(false);

      setState(() {
        _isLoading = false;
        _isLocationLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error loading providers: $e');
      }
      final providerProvider = context.read<ProviderProvider>();
      providerProvider.setError(e.toString());
      providerProvider.setLoading(false);

      setState(() {
        _isLoading = false;
        _isLocationLoading = false;
      });
    }
  }

  void _performSearch() {
    if (_searchController.text.isNotEmpty) {
      context.push('/user/search', extra: _searchController.text);
    }
  }

  // ============================================================
  // BACKGROUND
  // ============================================================
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

  // ============================================================
  // GET COMBINED PROVIDERS
  // ============================================================
  List<Map<String, dynamic>> _getCombinedProviders(BuildContext context) {
    final providerProvider = context.watch<ProviderProvider>();
    final allProviders = providerProvider.providers;

    final sorted = List<Map<String, dynamic>>.from(allProviders);
    sorted.sort((a, b) {
      final aIsBusiness = a['is_business'] ?? false;
      final bIsBusiness = b['is_business'] ?? false;
      if (aIsBusiness && !bIsBusiness) return -1;
      if (!aIsBusiness && bIsBusiness) return 1;
      return 0;
    });

    return sorted;
  }

  // ============================================================
  // DRAWER - ProNear Info
  // ============================================================
  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF1A1A2E),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF38804f),
              const Color(0xFF1d3b27),
              const Color(0xFF1d3b27),
              const Color(0xFF38804f),
            ],
            stops: const [0.0, 0.35, 0.70, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Drawer Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white.withOpacity(0.06),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/icon.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.storefront,
                            color: Color(0xFF38804f),
                            size: 32,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ProNear',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Final Year Project',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.close,
                          color: Colors.white.withOpacity(0.6),
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // University Section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.08),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Image.asset(
                                'assets/imcs.jpeg',
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.school,
                                    color: Colors.white70,
                                    size: 28,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'IMCS University Sindh',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    'Jamshoro',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white.withOpacity(0.6),
                                    ),
                                  ),

                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Divider
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 1,
                              color: Colors.white.withOpacity(0.06),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'OUR TEAM',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white.withOpacity(0.3),
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 1,
                              color: Colors.white.withOpacity(0.06),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Team Members
                      _buildDrawerTeamMember(
                        name: 'Altaf Abro',
                        role: 'Associate Professor',
                        rollNo: 'Supervisor',
                        color: const Color(0xFF49e8c3),
                        icon: Icons.supervisor_account, imagePath: '',
                      ),

                      _buildDrawerTeamMember(
                        name: 'Ali Raza Kalhoro',
                        role: 'Full Stack Developer',
                        rollNo: '2K23/CSM/17',
                        color: const Color(0xFF49e8c3),
                        icon: Icons.code, imagePath: 'assets/ali.jpeg',
                      ),
                      const SizedBox(height: 8),
                      _buildDrawerTeamMember(
                        name: 'Awais',
                        role: 'UI/UX Designer',
                        rollNo: '2K23/CSM/26',
                        color: const Color(0xFF6C63FF),
                        icon: Icons.design_services, imagePath: '',
                      ),
                      const SizedBox(height: 8),
                      _buildDrawerTeamMember(
                        name: 'Ahsan',
                        role: 'Frontend Developer',
                        rollNo: '2K23/CSM/11',
                        color: const Color(0xFFFF6B6B),
                        icon: Icons.web, imagePath: '',
                      ),

                      const SizedBox(height: 24),

                      // Footer
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.computer,
                              color: Colors.red.withOpacity(0.6),
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Built by IMCS Students',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerTeamMember({
    required String name,
    required String role,
    required String rollNo,
    required Color color,
    required IconData icon,
    required String imagePath,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.04),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Profile Image
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withOpacity(0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback to initials if image not found
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color, color.withOpacity(0.5)],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        name[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  role,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
                Text(
                  rollNo,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 16,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final providerProvider = context.watch<ProviderProvider>();
    final isLoading = providerProvider.isLoading;
    final combinedProviders = _getCombinedProviders(context);

    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(),
      backgroundColor: const Color(0xFF0F0A2A),
      body: Stack(
        children: [
          _buildBackground(size),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                // ============================================================
                // MODERN APP BAR WITH DRAWER ICON
                // ============================================================
                SliverAppBar(
                  pinned: true,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  flexibleSpace: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        // Drawer Icon
                        GestureDetector(
                          onTap: () => _scaffoldKey.currentState?.openDrawer(),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.06),
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              Icons.menu_rounded,
                              color: Colors.white.withOpacity(0.8),
                              size: 22,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Logo
                        Container(
                          width: 34,
                          height: 34,
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/icon.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.storefront,
                                color: Color(0xFF38804f),
                                size: 20,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Hello, $_userName 👋',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Find trusted services near you',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Notifications
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.06),
                              width: 1,
                            ),
                          ),
                          child: IconButton(
                            icon: Stack(
                              children: [
                                Icon(
                                  Icons.notifications_none_outlined,
                                  color: Colors.white.withOpacity(0.8),
                                  size: 20,
                                ),
                                Positioned(
                                  top: 2,
                                  right: 2,
                                  child: Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            onPressed: () => context.push('/user/notifications'),
                            tooltip: 'Notifications',
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ============================================================
                // SEARCH BAR
                // ============================================================
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverToBoxAdapter(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onSubmitted: (_) => _performSearch(),
                        style: const TextStyle(
                          color: Color(0xFF2D3748),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search services...',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            size: 24,
                            color: const Color(0xFF38804f),
                          ),
                          suffixIcon: Container(
                            margin: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF38804f), Color(0xFF1d3b27)],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              onPressed: _performSearch,
                              padding: const EdgeInsets.all(10),
                              constraints: const BoxConstraints(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ============================================================
                // LOCATION PERMISSION BANNER
                // ============================================================
                if (!_hasLocationPermission)
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.location_off, color: Colors.orange.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Location disabled. Showing all providers.',
                              style: TextStyle(
                                color: Colors.orange.shade700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: _checkLocationPermission,
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF38804f),
                            ),
                            child: const Text('Enable'),
                          ),
                        ],
                      ),
                    ),
                  ),

                // ============================================================
                // CATEGORIES
                // ============================================================
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Categories',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            TextButton(
                              onPressed: () => context.push('/user/categories'),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF49e8c3),
                              ),
                              child: const Text('View All'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 0.9,
                          ),
                          itemCount: _categories.length > 8 ? 8 : _categories.length,
                          itemBuilder: (context, index) {
                            final category = _categories[index];
                            return CategoryCard(
                              icon: category['icon'] ?? '📌',
                              label: category['name'] ?? '',
                              color: CategoryColors.getColorForCategory(category),
                              onTap: () {
                                context.push('/user/search', extra: category['name']);
                              }, showViewMap: true,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: 12),
                ),

                // ============================================================
                // NEARBY PROVIDERS
                // ============================================================
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _hasLocationPermission ? 'Nearby Providers' : 'All Providers',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        if (_hasLocationPermission)
                          TextButton(
                            onPressed: () => context.push('/user/map'),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF49e8c3),
                            ),
                            child: const Text('View Map'),
                          ),
                      ],
                    ),
                  ),
                ),

                // ============================================================
                // PROVIDER CARDS
                // ============================================================
                isLoading || _isLocationLoading
                    ? SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            const CircularProgressIndicator(
                              color: Color(0xFF49e8c3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _hasLocationPermission
                                  ? 'Finding providers near you...'
                                  : 'Loading providers...',
                              style: const TextStyle(
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
                    : combinedProviders.isEmpty
                    ? SliverPadding(
                  padding: const EdgeInsets.all(32),
                  sliver: SliverToBoxAdapter(
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 80,
                            color: Colors.white.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _hasLocationPermission
                                ? 'No providers found nearby'
                                : 'No providers available',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _hasLocationPermission
                                ? 'Try adjusting your location or search'
                                : 'Check back later for new providers',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _hasLocationPermission
                                ? _loadNearbyProviders
                                : _loadProvidersWithoutLocation,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF49e8c3),
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                    : SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) {
                        final provider = combinedProviders[index];
                        final isBusiness = provider['is_business'] ?? false;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: ProviderCard(
                            provider: provider,
                            onTap: () {
                              context.push('/user/provider/${provider['id']}');
                            },
                            onRequest: () {
                              if (isBusiness) {
                                context.push('/user/business-request/${provider['id']}');
                              } else {
                                context.push('/user/request/${provider['id']}');
                              }
                            },
                          ),
                        );
                      },
                      childCount: combinedProviders.length > 5 ? 5 : combinedProviders.length,
                    ),
                  ),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: 80),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.4),
          ],
        ),
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Color(0xFF1d3b27),
        selectedItemColor: const Color(0xFF49e8c3),
        unselectedItemColor: Colors.white.withOpacity(0.4),
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 11,
          letterSpacing: 0.3,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 11,
          letterSpacing: 0.3,
        ),
        elevation: 0,
        currentIndex: 0,
        onTap: (index) {
          switch (index) {
            case 0:
              break;
            case 1:
              context.push('/user/search');
              break;
            case 2:
              context.push('/user/map');
              break;
            case 3:
              context.push('/user/chats');
              break;
            case 4:
              context.push('/user/profile');
              break;
          }
        },
        items: [
          _buildNavItem(Icons.home_rounded, Icons.home_outlined, 'Home'),
          _buildNavItem(Icons.search_rounded, Icons.search_outlined, 'Search'),
          _buildNavItem(Icons.map_rounded, Icons.map_outlined, 'Map'),
          _buildNavItem(
            Icons.chat_rounded,
            Icons.chat_bubble_outline_rounded,
            'Chat',
            showBadge: true,
          ),
          _buildNavItem(Icons.person_rounded, Icons.person_outline_rounded, 'Profile'),
        ],
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(
      IconData activeIcon,
      IconData inactiveIcon,
      String label, {
        bool showBadge = false,
      }) {
    return BottomNavigationBarItem(
      icon: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.transparent,
            ),
            child: Icon(
              inactiveIcon,
              size: 24,
            ),
          ),
          if (showBadge)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
      activeIcon: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF49e8c3).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              activeIcon,
              size: 24,
              color: const Color(0xFF49e8c3),
            ),
          ),
          if (showBadge)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
      label: label,
    );
  }}