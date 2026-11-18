// lib/features/user/profile_screen.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/theme.dart';
import '../../widgets/loading_button.dart';
import '../../core/services/global_error_handler.dart';
import '../../core/services/supabase_service.dart';
import '../provider/auth_provider.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen>
    with TickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  bool _isDeleting = false;
  bool _isEditing = false;
  String? _profileImageUrl;

  // Background Animation Controllers
  late AnimationController _pulseController;
  late AnimationController _floatingController;

  @override
  void initState() {
    super.initState();
    _loadUserData();

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
    _nameController.dispose();
    _phoneController.dispose();
    _pulseController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;

    if (user != null) {
      _nameController.text = user['full_name'] ?? '';
      _phoneController.text = user['phone'] ?? '';
      _profileImageUrl = user['profile_image'];
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
  // BUILD METHODS
  // ============================================================

  Widget _buildGlassCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Future<void> _pickProfileImage() async {
    final hasPermission = await GlobalErrorHandler.requestGallery(context);
    if (!hasPermission) return;

    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() => _isLoading = true);
      try {
        final bytes = await image.readAsBytes();
        final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final filePath = '${Supabase.instance.client.auth.currentUser!.id}/$fileName'; // ✅ owner folder

        await Supabase.instance.client.storage
            .from('profiles')
            .uploadBinary(
          filePath,
          bytes,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
          ),
        );

        final url = Supabase.instance.client.storage
            .from('profiles')
            .getPublicUrl(filePath);

        setState(() => _profileImageUrl = url);
        GlobalErrorHandler.showCustomSuccess('Profile image uploaded successfully!');
      } catch (e) {
        GlobalErrorHandler.showCustomError('Error uploading image. Please try again.');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);

    try {
      await context.read<AuthProvider>().updateProfile({
        'full_name': _nameController.text,
        'phone': _phoneController.text,
        'profile_image': _profileImageUrl,
      });

      setState(() => _isEditing = false);
      GlobalErrorHandler.showCustomSuccess('Profile updated successfully!');
    } catch (e) {
      GlobalErrorHandler.showCustomError('Failed to update profile.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1D3B27),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Logout', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to logout?',
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
      await context.read<AuthProvider>().logout();
      if (mounted) {
        context.go('/role-selection');
      }
    }
  }

  // ============================================================
  // DELETE ACCOUNT (FIXED)
  // ============================================================
  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1D3B27),
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
          'This action cannot be undone. All your data (profile, requests, chats) will be permanently deleted.',
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

          // ✅ 4. Delete portfolio media (if provider)
          try {
            // ✅ portfolio is keyed by providers.id, not users.id
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
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final role = user?['role'] ?? 'User';

    return Scaffold(
      backgroundColor: const Color(0xFF0F0A2A),
      body: Stack(
        children: [
          _buildBackground(size),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                // ============================================================
                // CUSTOM APP BAR
                // ============================================================
                SliverAppBar(
                  pinned: true,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  // ✅ FIX: Hide the default Flutter back button
                  automaticallyImplyLeading: false,
                  flexibleSpace: Container(
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
                              border: Border.all(
                                color: Colors.white.withOpacity(0.06),
                                width: 1,
                              ),
                            ),
                            child: const Icon(
                              Icons.arrow_back_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
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
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.06),
                              width: 1,
                            ),
                          ),
                          child: IconButton(
                            icon: Icon(
                              _isEditing ? Icons.close_rounded : Icons.edit_rounded,
                              color: _isEditing ? Colors.red : Colors.white.withOpacity(0.8),
                              size: 22,
                            ),
                            onPressed: () => setState(() => _isEditing = !_isEditing),
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ============================================================
                // PROFILE CONTENT
                // ============================================================
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // ... (rest of the profile UI stays the same) ...
                      // ... (Header, Card, etc.) ...

                      Center(
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF49e8c3), Color(0xFF31b999)],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF49e8c3).withOpacity(0.3),
                                        blurRadius: 30,
                                        spreadRadius: 5,
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: CircleAvatar(
                                      radius: 58,
                                      backgroundColor: Colors.white,
                                      backgroundImage: _profileImageUrl != null
                                          ? NetworkImage(_profileImageUrl!)
                                          : null,
                                      child: _profileImageUrl == null
                                          ? Icon(
                                        Icons.person_rounded,
                                        size: 60,
                                        color: Colors.grey.shade400,
                                      )
                                          : null,
                                    ),
                                  ),
                                ),
                                if (_isEditing)
                                  Positioned(
                                    bottom: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: _pickProfileImage,
                                      child: Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [Color(0xFF49e8c3), Color(0xFF31b999)],
                                          ),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF49e8c3).withOpacity(0.3),
                                              blurRadius: 12,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.camera_alt_rounded,
                                          color: Colors.black,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              user?['full_name'] ?? 'User',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF49e8c3), Color(0xFF31b999)],
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                role.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user?['email'] ?? '',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      _buildGlassCard(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ... (Personal Information Card content stays the same) ...
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF49e8c3).withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.person_outline_rounded,
                                      color: Color(0xFF49e8c3),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'Personal Information',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (_isEditing)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF49e8c3).withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'Editing',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFF49e8c3),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildProfileField(
                                icon: Icons.person_outline_rounded,
                                label: 'Full Name',
                                controller: _nameController,
                                enabled: _isEditing,
                              ),
                              const SizedBox(height: 12),
                              _buildProfileField(
                                icon: Icons.phone_outlined,
                                label: 'Phone Number',
                                controller: _phoneController,
                                enabled: _isEditing,
                                keyboardType: TextInputType.phone,
                              ),
                              const SizedBox(height: 12),
                              _buildProfileField(
                                icon: Icons.email_outlined,
                                label: 'Email',
                                value: user?['email'] ?? '',
                                enabled: false,
                              ),
                              const SizedBox(height: 12),
                              _buildProfileField(
                                icon: Icons.work_outline,
                                label: 'Role',
                                value: role,
                                enabled: false,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF49e8c3),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Active',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white.withOpacity(0.6),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Colors.amber,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Verified',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white.withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (_isEditing)
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: LoadingButton(
                            onPressed: _saveProfile,
                            isLoading: _isLoading,
                            label: 'Save Changes',
                            backgroundColor: const Color(0xFF49e8c3),
                            textColor: Colors.black,
                          ),
                        ),
                      if (_isEditing) const SizedBox(height: 16),

                      _buildMenuItem(
                        icon: Icons.favorite_rounded,
                        iconColor: Colors.red,
                        title: 'Favorite Providers',
                        onTap: () {
                          context.push('/user/favorites');
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildMenuItem(
                        icon: Icons.history_rounded,
                        iconColor: const Color(0xFFFF6B6B),
                        title: 'Request History',
                        onTap: () {
                          context.push('/user/requests');
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildMenuItem(
                        icon: Icons.chat_bubble_outline_rounded,
                        iconColor: const Color(0xFF4D96FF),
                        title: 'Messages',
                        onTap: () {
                          context.push('/user/chats');
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildMenuItem(
                        icon: Icons.notifications_outlined,
                        iconColor: const Color(0xFFFFB74D),
                        title: 'Notifications',
                        badge: '3',
                        onTap: () {
                          context.push('/user/notifications');
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildMenuItem(
                        icon: Icons.settings_rounded,
                        iconColor: Colors.grey.shade400,
                        title: 'Settings',
                        onTap: () {},
                      ),
                      const SizedBox(height: 8),
                      _buildMenuItem(
                        icon: Icons.help_outline_rounded,
                        iconColor: const Color(0xFF6C63FF),
                        title: 'Help & Support',
                        onTap: () {},
                      ),
                      const SizedBox(height: 8),
                      _buildMenuItem(
                        icon: Icons.privacy_tip_outlined,
                        iconColor: const Color(0xFF49e8c3),
                        title: 'Privacy Policy',
                        onTap: () => context.push('/legal/privacy'),
                      ),
                      const SizedBox(height: 8),
                      _buildMenuItem(
                        icon: Icons.description_outlined,
                        iconColor: const Color(0xFF49e8c3),
                        title: 'Terms of Service',
                        onTap: () => context.push('/legal/terms'),
                      ),
                      const SizedBox(height: 24),

                      // ============================================================
                      // LOGOUT & DELETE ACCOUNT
                      // ============================================================
                      _buildMenuItem(
                        icon: Icons.logout_rounded,
                        iconColor: Colors.orange,
                        title: 'Logout',
                        onTap: _logout,
                      ),
                      const SizedBox(height: 8),

                      // ✅ DELETE ACCOUNT BUTTON
                      _buildMenuItem(
                        icon: Icons.delete_forever_rounded,
                        iconColor: Colors.red,
                        title: 'Delete Account',
                        isDestructive: true,
                        onTap: _isDeleting ? null : _deleteAccount,
                      ),
                      if (_isDeleting)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: CircularProgressIndicator(color: Colors.red),
                          ),
                        ),
                      const SizedBox(height: 32),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileField({
    required IconData icon,
    required String label,
    TextEditingController? controller,
    String? value,
    required bool enabled,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.4),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: const Color(0xFF49e8c3),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: enabled && controller != null
                  ? TextFormField(
                controller: controller,
                enabled: enabled,
                keyboardType: keyboardType,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              )
                  : Text(
                value ?? controller?.text ?? '',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: enabled ? Colors.white : Colors.white.withOpacity(0.5),
                ),
              ),
            ),
          ],
        ),
        Divider(
          color: Colors.white.withOpacity(0.06),
          height: 1,
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    VoidCallback? onTap,
    bool isDestructive = false,
    String? badge,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDestructive
                ? Colors.red.withOpacity(0.1)
                : Colors.white.withOpacity(0.04),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDestructive
                      ? Colors.red
                      : Colors.white.withOpacity(0.9),
                ),
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Colors.white.withOpacity(0.2),
            ),
          ],
        ),
      ),
    );
  }
}