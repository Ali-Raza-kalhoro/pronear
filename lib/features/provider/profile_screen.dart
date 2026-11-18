// lib/features/provider/profile_screen.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/theme.dart';
import '../../core/services/supabase_service.dart';
import '../legal/legal_screen.dart';
import '../../core/services/global_error_handler.dart'; // ✅ Added Error Handler
import 'auth_provider.dart';

class ProviderProfileScreen extends StatefulWidget {
  const ProviderProfileScreen({super.key});

  @override
  State<ProviderProfileScreen> createState() => _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends State<ProviderProfileScreen>
    with TickerProviderStateMixin {
  Map<String, dynamic>? _provider;
  Map<String, dynamic>? _user;
  List<Map<String, dynamic>> _services = [];
  List<Map<String, dynamic>> _certificates = [];
  bool _isLoading = true;
  bool _isLoggingOut = false;
  bool _isDeleting = false;
  String? _errorMessage;
  bool _isBusiness = false;

  late AnimationController _pulseController;
  late AnimationController _floatingController;

  // Controllers for Edit Profile
  final _nameController = TextEditingController();
  final _professionController = TextEditingController();
  final _aboutController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();

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
    _nameController.dispose();
    _professionController.dispose();
    _aboutController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
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
            Positioned(
              top: 80,
              right: 20,
              child: _buildDotPattern(rows: 4, columns: 4, spacing: 18),
            ),
            Positioned(
              bottom: 100,
              right: 16,
              child: _buildDotPattern(rows: 4, columns: 4, spacing: 18),
            ),
            Positioned(
              bottom: 100,
              left: 16,
              child: _buildDotPattern(rows: 4, columns: 4, spacing: 18),
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

  Future<void> _loadProfile() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.userId;

    if (userId == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'User not logged in';
        });
      }
      return;
    }

    try {
      _user = await SupabaseService().getUserProfile(userId);

      final providers = await Supabase.instance.client
          .from('providers')
          .select()
          .eq('user_id', userId);

      if (providers.isNotEmpty) {
        _provider = providers.first;
        _isBusiness = _provider?['is_business'] ?? false;
        _services = await SupabaseService().getProviderServices(_provider!['id']);

        final certs = await Supabase.instance.client
            .from('provider_certificates')
            .select()
            .eq('provider_id', _provider!['id']);
        _certificates = certs;

        // Pre-fill edit controllers
        _nameController.text = _user?['full_name'] ?? '';
        _professionController.text = _provider?['profession'] ?? '';
        _aboutController.text = _provider?['about'] ?? '';
        _phoneController.text = _provider?['phone'] ?? '';
        _addressController.text = _provider?['permanent_address'] ?? '';
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1d3b27),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Logout', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to logout?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;
      setState(() => _isLoggingOut = true);
      await context.read<AuthProvider>().logout();
      if (mounted) {
        context.go('/role-selection');
      }
    }
  }

  // ============================================================
  // DELETE ACCOUNT
  // ============================================================
  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1d3b27),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 8),
            Text('Delete Account?', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          'This action cannot be undone. All your data, services, and requests will be permanently deleted.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Delete Forever'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isDeleting = true);

      final success = await GlobalErrorHandler.run<bool>(
        context: context,
        action: () async {
          final userId = Supabase.instance.client.auth.currentUser?.id;
          if (userId == null) throw Exception('User not found');

          // ✅ 1. Fetch user data to find storage file URLs
          final userProfile = await Supabase.instance.client
              .from('users')
              .select('profile_image, cnic_front_image, cnic_back_image, face_image')
              .eq('id', userId)
              .maybeSingle();

          // ✅ 2. Delete profile image
          if (userProfile != null && userProfile['profile_image'] != null) {
            await _deleteStorageFile('profiles', userProfile['profile_image']);
          }

          // ✅ 3. Delete verification images (new private table + legacy columns)
          final verification = await SupabaseService().getMyVerification();
          if (verification != null) {
            for (var key in ['cnic_front_path', 'cnic_back_path', 'face_path']) {
              final String? path = verification[key];
              if (path != null && path.isNotEmpty) {
                await _deleteStorageFile('verification_images', path);
              }
            }
          }
          if (userProfile != null) {
            for (var key in ['cnic_front_image', 'cnic_back_image', 'face_image']) {
              final String? url = userProfile[key];
              if (url != null && url.isNotEmpty) {
                await _deleteStorageFile('verification_images', url);
              }
            }
          }

          // ✅ 4. Delete portfolio media (important for providers)
          try {
            final provider = await Supabase.instance.client
                .from('providers')
                .select('id')
                .eq('user_id', userId)
                .maybeSingle();

            if (provider != null) {
              final portfolioItems = await Supabase.instance.client
                  .from('provider_portfolio')
                  .select('media_url')
                  .eq('provider_id', provider['id']);
              for (var item in portfolioItems) {
                final String mediaUrl = item['media_url'] ?? '';
                if (mediaUrl.isNotEmpty) {
                  await _deleteStorageFile('portfolio_media', mediaUrl);
                }
              }
            }
          } catch (e) {
            debugPrint('⚠️ Portfolio cleanup: $e');
          }

          // ✅ 5. Delete database rows + auth user via SQL
          await Supabase.instance.client.rpc('delete_my_account');
          return true;
        },
      );

      if (success == true && mounted) {
        await context.read<AuthProvider>().logout();
        if (mounted) {
          GlobalErrorHandler.showCustomSuccess('Your account has been deleted.');
          context.go('/role-selection');
        }
      } else {
        if (mounted) setState(() => _isDeleting = false);
      }
    }
  }

  // ✅ Helper: Deletes a file from a bucket given its public URL
  Future<void> _deleteStorageFile(String bucket, String publicUrl) async {
    try {
      // ✅ New uploads store a plain storage path (e.g. verification images)
      if (!publicUrl.startsWith('http')) {
        await Supabase.instance.client.storage.from(bucket).remove([publicUrl]);
        debugPrint('✅ Deleted $bucket/$publicUrl');
        return;
      }
      final uri = Uri.parse(publicUrl);
      final pathSegments = uri.pathSegments;
      final int bucketIndex = pathSegments.indexOf(bucket);
      if (bucketIndex != -1 && bucketIndex < pathSegments.length - 1) {
        final String filePath = pathSegments.sublist(bucketIndex + 1).join('/');
        await Supabase.instance.client.storage.from(bucket).remove([filePath]);
        debugPrint('✅ Deleted $bucket/$filePath');
      }
    } catch (e) {
      debugPrint('⚠️ Failed to delete from $bucket: $e');
    }
  }

  // ============================================================
  // EDIT PROFILE
  // ============================================================
  Future<void> _editProfile() async {
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            bool isSaving = false;

            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                // ✅ Green Gradient Background
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
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              padding: const EdgeInsets.all(24),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Edit Profile',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Update your personal and professional details',
                      style: TextStyle(fontSize: 14, color: Colors.white60),
                    ),
                    const SizedBox(height: 24),

                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            _buildEditField(_nameController, 'Full Name', Icons.person_outline),
                            const SizedBox(height: 16),
                            _buildEditField(_professionController, 'Profession / Business Type', Icons.work_outline),
                            const SizedBox(height: 16),
                            _buildEditField(_aboutController, 'About / Bio', Icons.info_outline, maxLines: 4),
                            const SizedBox(height: 16),
                            _buildEditField(_phoneController, 'Phone Number', Icons.phone_outlined, keyboardType: TextInputType.phone),
                            const SizedBox(height: 16),
                            _buildEditField(_addressController, 'Address', Icons.location_on_outlined, maxLines: 2),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: isSaving ? null : () async {
                          if (!(formKey.currentState?.validate() ?? false)) return;
                          setModalState(() => isSaving = true);

                          final success = await GlobalErrorHandler.run<bool>(
                            context: context,
                            action: () async {
                              // 1. Update users table
                              await Supabase.instance.client
                                  .from('users')
                                  .update({
                                'full_name': _nameController.text.trim(),
                                'phone': _phoneController.text.trim(),
                                'updated_at': DateTime.now().toIso8601String(),
                              }).eq('id', _provider!['user_id']);

                              // 2. Update providers table
                              await Supabase.instance.client
                                  .from('providers')
                                  .update({
                                'profession': _professionController.text.trim(),
                                'about': _aboutController.text.trim(),
                                'phone': _phoneController.text.trim(),
                                'permanent_address': _addressController.text.trim(),
                                'updated_at': DateTime.now().toIso8601String(),
                              }).eq('id', _provider!['id']);

                              return true;
                            },
                          );

                          if (success == true) {
                            Navigator.pop(context);
                            GlobalErrorHandler.showCustomSuccess('Profile updated successfully!');
                            _loadProfile(); // Refresh UI
                          } else {
                            setModalState(() => isSaving = false);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF49e8c3),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: isSaving
                            ? const CircularProgressIndicator(color: Colors.black)
                            : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
  Widget _buildEditField(
      TextEditingController controller,
      String label,
      IconData icon, {
        int maxLines = 1,
        TextInputType? keyboardType,
      }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: Colors.white, // ✅ White text
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Colors.white70, // ✅ Translucent white label
          fontSize: 13,
        ),
        hintText: 'Enter $label',
        hintStyle: TextStyle(
          color: Colors.white.withOpacity(0.5),
          fontSize: 14,
        ),
        prefixIcon: Icon(
          icon,
          color: Colors.white70, // ✅ Translucent white icon
          size: 22,
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1), // ✅ Transparent glass background
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)), // ✅ Translucent border
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white, width: 2), // ✅ Solid white on focus
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Required';
        }
        return null;
      },
    );
  }
  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F0A2A),
        body: Stack(
          children: [
            _buildBackground(size),
            const Center(child: CircularProgressIndicator(color: Color(0xFF49e8c3))),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F0A2A),
        body: Stack(
          children: [
            _buildBackground(size),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline_rounded, size: 64, color: Colors.red.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading profile',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.8)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage!,
                    style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.4)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _loadProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF49e8c3),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (_provider == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F0A2A),
        body: Stack(
          children: [
            _buildBackground(size),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.05), width: 1),
                    ),
                    child: Icon(Icons.person_off_outlined, size: 50, color: Colors.white.withOpacity(0.3)),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'No profile found',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.8)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please create your CV first',
                    style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.4)),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.push('/provider/cv'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF49e8c3),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Create CV'),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final isAvailable = _provider?['is_available'] ?? false;
    final rating = _provider?['rating'] ?? 0.0;
    final totalReviews = _provider?['total_reviews'] ?? 0;
    final profileImage = _user?['profile_image'];
    final fullName = _user?['full_name'] ?? 'Provider';
    final profession = _provider?['profession'] ?? 'Service Provider';

    return Scaffold(
      backgroundColor: const Color(0xFF0F0A2A),
      body: Stack(
        children: [
          _buildBackground(size),
          SafeArea(
            child: Column(
              children: [
                // Custom App Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.06), width: 1),
                          ),
                          child: Icon(Icons.arrow_back_rounded, color: Colors.white.withOpacity(0.8), size: 22),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'My Profile',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),

                      // Portfolio Button - Only for Service Providers
                      if (!_isBusiness)
                        GestureDetector(
                          onTap: () => context.pushNamed('provider-portfolio'),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withOpacity(0.06), width: 1),
                            ),
                            child: Icon(Icons.photo_library_outlined, color: Colors.white.withOpacity(0.8), size: 22),
                          ),
                        ),
                      const SizedBox(width: 8),

                      // Edit Button - Opens Bottom Sheet
                      GestureDetector(
                        onTap: _editProfile,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFF49e8c3), Color(0xFF31b999)]),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(color: const Color(0xFF49e8c3).withOpacity(0.3), blurRadius: 8),
                            ],
                          ),
                          child: const Icon(Icons.edit_rounded, color: Colors.black, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),

                // Profile Content
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Profile Card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 8)),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Profile Image
                              Stack(
                                children: [
                                  Container(
                                    width: 110,
                                    height: 110,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: const Color(0xFF49e8c3).withOpacity(0.3), width: 3),
                                      boxShadow: [
                                        BoxShadow(color: const Color(0xFF49e8c3).withOpacity(0.2), blurRadius: 20, spreadRadius: 5),
                                      ],
                                    ),
                                    child: ClipOval(
                                      child: profileImage != null && profileImage.isNotEmpty
                                          ? CachedNetworkImage(
                                        imageUrl: profileImage,
                                        fit: BoxFit.cover,
                                        width: 110,
                                        height: 110,
                                        placeholder: (context, url) => Container(
                                          color: Colors.white.withOpacity(0.05),
                                          child: const Center(child: CircularProgressIndicator(color: Color(0xFF49e8c3))),
                                        ),
                                        errorWidget: (context, url, error) => Container(
                                          color: Colors.white.withOpacity(0.05),
                                          child: Icon(Icons.person_rounded, size: 50, color: Colors.white.withOpacity(0.2)),
                                        ),
                                      )
                                          : Container(
                                        color: Colors.white.withOpacity(0.05),
                                        child: Icon(Icons.person_rounded, size: 50, color: Colors.white.withOpacity(0.2)),
                                      ),
                                    ),
                                  ),
                                  if (isAvailable)
                                    Positioned(
                                      bottom: 4,
                                      right: 4,
                                      child: Container(
                                        width: 20,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF49e8c3),
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 3),
                                          boxShadow: [
                                            BoxShadow(color: const Color(0xFF49e8c3).withOpacity(0.4), blurRadius: 8),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Text(
                                fullName,
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.3),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                profession,
                                style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.6)),
                              ),
                              const SizedBox(height: 10),
                              // Status Badges
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isAvailable ? const Color(0xFF49e8c3).withOpacity(0.15) : Colors.white.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isAvailable ? const Color(0xFF49e8c3).withOpacity(0.3) : Colors.white.withOpacity(0.05),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: isAvailable ? const Color(0xFF49e8c3) : Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          isAvailable ? 'Available' : 'Unavailable',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: isAvailable ? const Color(0xFF49e8c3) : Colors.white.withOpacity(0.3),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _provider?['is_verified'] == true ? Colors.blue.withOpacity(0.15) : Colors.white.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _provider?['is_verified'] == true ? Colors.blue.withOpacity(0.3) : Colors.white.withOpacity(0.05),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _provider?['is_verified'] == true ? Icons.verified_rounded : Icons.pending_rounded,
                                          size: 14,
                                          color: _provider?['is_verified'] == true ? Colors.blue : Colors.white.withOpacity(0.3),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _provider?['is_verified'] == true ? 'Verified' : 'Pending',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: _provider?['is_verified'] == true ? Colors.blue : Colors.white.withOpacity(0.3),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Rating Row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                                  const SizedBox(width: 4),
                                  Text(
                                    rating.toStringAsFixed(1),
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '($totalReviews reviews)',
                                    style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.4)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // About Section
                        if (_provider?['about'] != null && _provider!['about'].toString().isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF6C63FF).withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.info_outline_rounded, color: Color(0xFF6C63FF), size: 20),
                                    ),
                                    const SizedBox(width: 10),
                                    const Text(
                                      'About',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _provider!['about'] ?? '',
                                  style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.7), height: 1.5),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 16),

                        // Contact Information
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF4D96FF).withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.contact_phone_rounded, color: Color(0xFF4D96FF), size: 20),
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'Contact Information',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              _buildContactItem(Icons.phone_rounded, _provider?['phone'] ?? 'Not provided', const Color(0xFF49e8c3)),
                              _buildContactItem(Icons.email_rounded, _user?['email'] ?? 'Not provided', const Color(0xFF4D96FF)),
                              _buildContactItem(Icons.location_on_rounded, _provider?['permanent_address'] ?? 'Not provided', const Color(0xFFFF6B6B)),
                              if (_provider?['latitude'] != null)
                                _buildContactItem(
                                  Icons.pin_drop_rounded,
                                  '${_provider!['latitude']?.toStringAsFixed(6)}, ${_provider!['longitude']?.toStringAsFixed(6)}',
                                  const Color(0xFFFFB74D),
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Services
                        if (_services.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFF6B6B).withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.work_outline_rounded, color: Color(0xFFFF6B6B), size: 20),
                                    ),
                                    const SizedBox(width: 10),
                                    const Text(
                                      'Services',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    for (var service in _services)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFF6B6B).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: const Color(0xFFFF6B6B).withOpacity(0.2), width: 1),
                                        ),
                                        child: Text(
                                          service['service_name'] ?? '',
                                          style: const TextStyle(fontSize: 12, color: Color(0xFFFF6B6B), fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 16),

                        // Certificates
                        if (_certificates.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFB74D).withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.verified_rounded, color: Color(0xFFFFB74D), size: 20),
                                    ),
                                    const SizedBox(width: 10),
                                    const Text(
                                      'Certificates',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                for (var cert in _certificates)
                                  Container(
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                    child: Row(
                                      children: [
                                        Icon(
                                          cert['is_verified'] == true ? Icons.check_circle_rounded : Icons.pending_rounded,
                                          size: 18,
                                          color: cert['is_verified'] == true ? const Color(0xFF49e8c3) : Colors.white.withOpacity(0.3),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                cert['name'] ?? '',
                                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white.withOpacity(0.9)),
                                              ),
                                              Text(
                                                cert['issuing_authority'] ?? '',
                                                style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.4)),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 16),

                        // Stats
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem('Completed', _provider?['total_reviews']?.toString() ?? '0'),
                              _buildStatItem('Experience', _provider?['experience'] ?? '0 yrs'),
                              _buildStatItem('Response', '95%'),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Logout Button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton.icon(
                            onPressed: _isLoggingOut ? null : _logout,
                            icon: _isLoggingOut
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange))
                                : const Icon(Icons.logout_rounded, color: Colors.orange),
                            label: Text(
                              _isLoggingOut ? 'Logging out...' : 'Logout',
                              style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w700, fontSize: 15),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.orange),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // ✅ NEW: Delete Account Button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton.icon(
                            onPressed: _isDeleting ? null : _deleteAccount,
                            icon: _isDeleting
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red))
                                : const Icon(Icons.delete_forever_rounded, color: Colors.red),
                            label: Text(
                              _isDeleting ? 'Deleting...' : 'Delete Account',
                              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w700, fontSize: 15),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.red.shade400),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),
                        const LegalLinksRow(showDeletion: false),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.7)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF49e8c3)),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.4)),
        ),
      ],
    );
  }
}