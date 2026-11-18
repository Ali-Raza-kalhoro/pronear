// lib/features/provider/business_setup/business_setup_screen.dart
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/theme.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/global_error_handler.dart'; // ✅ Added for permissions
import '../../provider/auth_provider.dart';

class BusinessSetupScreen extends StatefulWidget {
  const BusinessSetupScreen({super.key});

  @override
  State<BusinessSetupScreen> createState() => _BusinessSetupScreenState();
}

class _BusinessSetupScreenState extends State<BusinessSetupScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final _businessNameController = TextEditingController();
  final _professionController = TextEditingController();
  final _aboutController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _radiusController = TextEditingController();

  double? _latitude;
  double? _longitude;
  bool _isLoadingLocation = true;
  bool _isLoading = false;
  String? _profileImageUrl;
  String? _errorMessage;

  final ImagePicker _picker = ImagePicker();

  late AnimationController _pulseController;
  late AnimationController _floatingController;
  late AnimationController _mainController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _mainController,
      curve: Curves.easeOut,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: Curves.easeOutBack,
      ),
    );

    _mainController.forward();

    _getCurrentLocation();
    _loadUserData();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _floatingController.dispose();
    _mainController.dispose();
    _businessNameController.dispose();
    _professionController.dispose();
    _aboutController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;
    if (user != null) {
      _phoneController.text = user['phone'] ?? '';
      _profileImageUrl = user['profile_image'];
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _isLoadingLocation = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingLocation = false;
      });
      GlobalErrorHandler.showCustomError('Could not get location. Please check permissions.');
    }
  }

  Future<void> _pickProfileImage() async {
    // ✅ Check Gallery Permission
    final hasPermission = await GlobalErrorHandler.requestGallery(context);
    if (!hasPermission) return;

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (image == null) return;

      setState(() => _isLoading = true);

      final bytes = await image.readAsBytes();
      final fileName = 'business_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = '${Supabase.instance.client.auth.currentUser!.id}/business/$fileName'; // ✅ owner folder

      await Supabase.instance.client.storage
          .from('profiles')
          .uploadBinary(
        filePath,
        bytes,
        fileOptions: const FileOptions(contentType: 'image/jpeg'),
      );

      final url = Supabase.instance.client.storage
          .from('profiles')
          .getPublicUrl(filePath);

      setState(() {
        _profileImageUrl = url;
        _isLoading = false;
      });

      GlobalErrorHandler.showCustomSuccess('Business image uploaded successfully');
    } catch (e) {
      setState(() => _isLoading = false);
      GlobalErrorHandler.showCustomError('Upload failed. Please try again.');
    }
  }

  Future<void> _saveBusinessSetup() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_latitude == null || _longitude == null) {
      GlobalErrorHandler.showCustomError('Please wait for location to load');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.userId;

      if (userId == null) {
        throw Exception('User not logged in');
      }

      final existingUser = await Supabase.instance.client
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();

      final String radiusText = _radiusController.text.trim();
      double serviceRadius = 20.0;
      if (radiusText.isNotEmpty) {
        final parsed = double.tryParse(radiusText);
        if (parsed != null && parsed > 0) {
          serviceRadius = parsed;
        }
      }

      if (existingUser == null) {
        final authUser = await Supabase.instance.client.auth.getUser();
        final email = authUser.user?.email ?? '';
        final userMetadata = authUser.user?.userMetadata;
        final fullName = userMetadata?['full_name'] as String? ??
            authUser.user?.email?.split('@').first ??
            'User';

        await Supabase.instance.client
            .from('users')
            .insert({
          'id': userId,
          'email': email,
          'full_name': fullName,
          'phone': _phoneController.text.trim(),
          'profile_image': _profileImageUrl,
          'role': 'provider',
          'is_verified': false,
          'is_online': true,
          'is_business': true,
          'business_type': 'business',
          'business_name': _businessNameController.text.trim(),
          'service_radius': serviceRadius,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      } else {
        await Supabase.instance.client
            .from('users')
            .update({
          'profile_image': _profileImageUrl,
          'phone': _phoneController.text.trim(),
          'updated_at': DateTime.now().toIso8601String(),
          'is_business': true,
          'business_type': 'business',
          'business_name': _businessNameController.text.trim(),
          'service_radius': serviceRadius,
        }).eq('id', userId);
      }

      final existingProvider = await SupabaseService().getProviderByUserId(userId);

      final Map<String, dynamic> providerData = {
        'user_id': userId,
        'business_name': _businessNameController.text.trim(),
        'profession': _professionController.text.trim(),
        'about': _aboutController.text.trim(),
        'phone': _phoneController.text.trim(),
        'permanent_address': _addressController.text.trim(),
        'latitude': _latitude,
        'longitude': _longitude,
        'service_radius': serviceRadius,
        'is_business': true,
        'business_type': 'business',
        'is_available': true,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (existingProvider != null) {
        await Supabase.instance.client
            .from('providers')
            .update(providerData)
            .eq('id', existingProvider['id']);
      } else {
        providerData['created_at'] = DateTime.now().toIso8601String();
        await Supabase.instance.client
            .from('providers')
            .insert(providerData);
      }

      if (mounted) {
        GlobalErrorHandler.showCustomSuccess('Business setup completed!');
        context.go('/business/category-selection');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ============================================================
  // BACKGROUND WIDGET
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
                        isEven ? 0.10 : 0.055,
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
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          _buildBackground(size),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        padding: EdgeInsets.zero,
                        alignment: Alignment.centerLeft,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Business Setup',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Set up your business to start offering services',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 24),

                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_errorMessage != null)
                              Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error_outline, color: Colors.red),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: const TextStyle(color: Colors.red),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => setState(() => _errorMessage = null),
                                      child: const Icon(Icons.close, color: Colors.red, size: 20),
                                    ),
                                  ],
                                ),
                              ),

                            _buildProfileHeader(),
                            const SizedBox(height: 20),

                            // Business Details
                            _buildGlassCard(
                              title: 'Business Details',
                              icon: Icons.business_outlined,
                              children: [
                                _buildTextField(
                                  _businessNameController,
                                  'Business Name *',
                                  Icons.store_outlined,
                                ),
                                const SizedBox(height: 12),
                                _buildTextField(
                                  _professionController,
                                  'Business Type *',
                                  Icons.work_outline,
                                ),
                                const SizedBox(height: 12),
                                _buildTextField(
                                  _aboutController,
                                  'About Business',
                                  Icons.info_outline,
                                  maxLines: 3,
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // Contact Info
                            _buildGlassCard(
                              title: 'Contact Information',
                              icon: Icons.contact_phone,
                              children: [
                                _buildTextField(
                                  _phoneController,
                                  'Phone Number *',
                                  Icons.phone_outlined,
                                  keyboardType: TextInputType.phone,
                                ),
                                const SizedBox(height: 12),
                                _buildTextField(
                                  _addressController,
                                  'Business Address *',
                                  Icons.location_on_outlined,
                                  maxLines: 2,
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // Service Area
                            _buildGlassCard(
                              title: 'Service Area',
                              icon: Icons.map_outlined,
                              children: [
                                _buildLocationWidget(),
                                const SizedBox(height: 12),
                                _buildTextField(
                                  _radiusController,
                                  'Service Radius (km) *',
                                  Icons.radar_outlined,
                                  keyboardType: TextInputType.number,
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _saveBusinessSetup,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF49e8c3),
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: _isLoading
                                    ? const CircularProgressIndicator(color: Colors.black)
                                    : const Text(
                                  'Continue to Products',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF49e8c3).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: const Color(0xFF49e8c3), size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller,
      String label,
      IconData icon, {
        int maxLines = 1,
        TextInputType? keyboardType,
      }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(
          fontSize: 15,
          color: Color(0xFF2D3748),
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
          prefixIcon: Icon(icon, color: const Color(0xFF49e8c3), size: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF49e8c3), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          isDense: true,
        ),
        validator: (value) {
          if (label.contains('*') && (value == null || value.trim().isEmpty)) {
            return 'Required';
          }
          if (label.contains('Radius') && value != null && value.trim().isNotEmpty) {
            if (double.tryParse(value.trim()) == null) {
              return 'Please enter a valid number';
            }
            final radius = double.tryParse(value.trim());
            if (radius != null && radius <= 0) {
              return 'Radius must be greater than 0';
            }
            if (radius != null && radius > 100) {
              return 'Radius cannot exceed 100 km';
            }
          }
          return null;
        },
      ),
    );
  }

  // ============================================================
  // PROFILE HEADER (Updated to match green theme)
  // ============================================================
  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF49e8c3), Color(0xFF38804f)], // ✅ Green gradient
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF49e8c3).withOpacity(0.3), // ✅ Green shadow
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                ),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  backgroundImage: _profileImageUrl != null
                      ? NetworkImage(_profileImageUrl!)
                      : null,
                  child: _profileImageUrl == null
                      ? const Icon(
                    Icons.store,
                    size: 40,
                    color: Colors.white,
                  )
                      : null,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.camera_alt,
                      color: Color(0xFF38804f), // ✅ Green camera icon
                      size: 18,
                    ),
                    onPressed: _pickProfileImage,
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Add Business Logo',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationWidget() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF49e8c3).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.location_on,
              color: Color(0xFF49e8c3),
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _isLoadingLocation
                ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF49e8c3),
              ),
            )
                : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Current Location',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white54,
                  ),
                ),
                Text(
                  _latitude != null
                      ? '${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}'
                      : 'Location not available',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _getCurrentLocation,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF49e8c3).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.refresh,
                color: Color(0xFF49e8c3),
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}