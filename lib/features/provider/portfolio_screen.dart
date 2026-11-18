// lib/features/provider/portfolio_screen.dart
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/global_error_handler.dart'; // ✅ Added
import '../provider/auth_provider.dart';

class ProviderPortfolioScreen extends StatefulWidget {
  const ProviderPortfolioScreen({super.key});

  @override
  State<ProviderPortfolioScreen> createState() => _ProviderPortfolioScreenState();
}

class _ProviderPortfolioScreenState extends State<ProviderPortfolioScreen>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> _portfolio = [];
  bool _isLoading = true;
  bool _isUploading = false;
  String? _errorMessage;
  String? _providerId;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  File? _selectedImage;
  String? _mediaType = 'image';

  // Background Animation Controllers
  late AnimationController _pulseController;
  late AnimationController _floatingController;

  @override
  void initState() {
    super.initState();
    _loadPortfolio();

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
    _titleController.dispose();
    _descriptionController.dispose();
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
            Positioned(top: 80, right: 20, child: _buildDotPattern(rows: 4, columns: 4, spacing: 18)),
            Positioned(bottom: 100, right: 16, child: _buildDotPattern(rows: 4, columns: 4, spacing: 18)),
            Positioned(bottom: 100, left: 16, child: _buildDotPattern(rows: 4, columns: 4, spacing: 18)),
          ],
        ),
      ),
    );
  }

  Widget _buildDotPattern({required int rows, required int columns, required double spacing}) {
    return SizedBox(
      width: columns * spacing,
      height: rows * spacing,
      child: Column(
        children: List.generate(rows, (row) {
          return Row(
            children: List.generate(columns, (column) {
              final isEven = (row + column) % 2 == 0;
              return Container(
                width: isEven ? 4 : 2.5,
                height: isEven ? 4 : 2.5,
                margin: EdgeInsets.only(right: spacing - 4, bottom: spacing - 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(isEven ? 0.35 : 0.055),
                ),
              );
            }),
          );
        }),
      ),
    );
  }

  Future<void> _loadPortfolio() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
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

      final provider = await SupabaseService().getProviderByUserId(userId);
      if (provider != null) {
        _providerId = provider['id'];
        final portfolio = await SupabaseService().getProviderPortfolio(provider['id']);
        final imagesOnly = portfolio.where((item) => item['media_type'] == 'image').toList();
        if (mounted) {
          setState(() {
            _portfolio = imagesOnly;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Provider profile not found';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
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
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF49e8c3).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: Color(0xFF49e8c3), size: 22),
                ),
                title: const Text(
                  'Choose from Gallery',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Select an image from your gallery',
                  style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final picker = ImagePicker();
                  final image = await picker.pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 1024,
                    maxHeight: 1024,
                    imageQuality: 80,
                  );
                  if (image != null) {
                    setState(() {
                      _selectedImage = File(image.path);
                      _mediaType = 'image';
                    });
                    _showAddDialog();
                  }
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B6B).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: Color(0xFFFF6B6B), size: 22),
                ),
                title: const Text(
                  'Take Photo',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Capture a new photo with your camera',
                  style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final picker = ImagePicker();
                  final image = await picker.pickImage(
                    source: ImageSource.camera,
                    maxWidth: 1024,
                    maxHeight: 1024,
                    imageQuality: 80,
                  );
                  if (image != null) {
                    setState(() {
                      _selectedImage = File(image.path);
                      _mediaType = 'image';
                    });
                    _showAddDialog();
                  }
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddDialog() {
    if (_selectedImage == null) {
      GlobalErrorHandler.showCustomError('Please select an image first');
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1d3b27),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF49e8c3).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.image_rounded, color: Color(0xFF49e8c3), size: 18), // ✅ Smaller icon
                ),
                const SizedBox(width: 10),
                const Expanded( // ✅ Wrapped in Expanded to prevent overflow
                  child: Text(
                    'Add Portfolio Image',
                    style: TextStyle(color: Colors.white, fontSize: 16), // ✅ Adjusted font size
                    maxLines: 2, // ✅ Allow wrapping
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_selectedImage != null)
                    Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white.withOpacity(0.05),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _selectedImage!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _titleController,
                    enabled: !_isUploading,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Title *',
                      labelStyle: const TextStyle(color: Colors.white70),
                      hintText: 'Enter work title',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                      prefixIcon: const Icon(Icons.title_rounded, color: Color(0xFF49e8c3)),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF49e8c3)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descriptionController,
                    enabled: !_isUploading,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Description',
                      labelStyle: const TextStyle(color: Colors.white70),
                      hintText: 'Describe your work',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                      prefixIcon: const Icon(Icons.description_rounded, color: Color(0xFF49e8c3)),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF49e8c3)),
                      ),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: _isUploading ? null : () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedImage = null;
                    _titleController.clear();
                    _descriptionController.clear();
                  });
                },
                child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
              ),
              ElevatedButton(
                onPressed: _isUploading ? null : () async {
                  setDialogState(() {
                    _isUploading = true;
                  });
                  await _addPortfolioItem();
                  if (mounted && !_isUploading) {
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF49e8c3),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isUploading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : const Text('Add Image'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _addPortfolioItem() async {
    if (_titleController.text.isEmpty) {
      GlobalErrorHandler.showCustomError('Please enter a title');
      setState(() => _isUploading = false);
      return;
    }

    if (_selectedImage == null) {
      GlobalErrorHandler.showCustomError('Please select an image');
      setState(() => _isUploading = false);
      return;
    }

    try {
      final supabase = SupabaseService();

      final mediaUrl = await supabase.uploadPortfolioMedia(
        _providerId!,
        _selectedImage!,
        'image',
      );

      final Map<String, dynamic> itemData = {
        'provider_id': _providerId,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'media_type': 'image',
        'media_url': mediaUrl,
        'thumbnail_url': mediaUrl,
      };

      await supabase.addPortfolioItem(itemData);

      final portfolio = await SupabaseService().getProviderPortfolio(_providerId!);
      final imagesOnly = portfolio.where((item) => item['media_type'] == 'image').toList();

      if (mounted) {
        setState(() {
          _portfolio = imagesOnly;
          _isUploading = false;
          _selectedImage = null;
          _titleController.clear();
          _descriptionController.clear();
        });

        GlobalErrorHandler.showCustomSuccess('Portfolio image added successfully!');
      }
    } catch (e) {
      debugPrint('❌ Error adding portfolio item: $e');
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
        GlobalErrorHandler.showCustomError('Failed to add image. Please try again.');
      }
    }
  }

  Future<void> _deletePortfolioItem(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1d3b27),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Delete Image', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to delete this image?', style: TextStyle(color: Colors.white70)),
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
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await SupabaseService().deletePortfolioItem(id);
        final portfolio = await SupabaseService().getProviderPortfolio(_providerId!);
        final imagesOnly = portfolio.where((item) => item['media_type'] == 'image').toList();
        if (mounted) {
          setState(() {
            _portfolio = imagesOnly;
          });
          GlobalErrorHandler.showCustomSuccess('Image deleted');
        }
      } catch (e) {
        if (mounted) {
          GlobalErrorHandler.showCustomError('Failed to delete image. Please try again.');
        }
      }
    }
  }

  // ============================================================
  // FULL-SCREEN IMAGE PREVIEWER
  // ============================================================
  void _showImageDetails(int initialIndex) {
    PageController pageController = PageController(initialPage: initialIndex);

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.95),
      builder: (context) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              // Swipeable Image Viewer
              PageView.builder(
                controller: pageController,
                itemCount: _portfolio.length,
                itemBuilder: (context, index) {
                  final item = _portfolio[index];
                  final mediaUrl = item['media_url'] ?? '';

                  return InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Center(
                      child: CachedNetworkImage(
                        imageUrl: mediaUrl,
                        fit: BoxFit.contain,
                        width: double.infinity,
                        height: double.infinity,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(color: Color(0xFF49e8c3)),
                        ),
                        errorWidget: (context, url, error) => const Icon(
                          Icons.broken_image,
                          size: 80,
                          color: Colors.white24,
                        ),
                      ),
                    ),
                  );
                },
              ),

              // Top Bar (Close button)
              Positioned(
                top: MediaQuery.of(context).padding.top + 10,
                right: 20,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
                  ),
                ),
              ),

              // Bottom Info Overlay
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 40, 24, 30),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.9),
                      ],
                    ),
                  ),
                  child: AnimatedBuilder(
                    animation: pageController,
                    builder: (context, child) {
                      int currentIndex = pageController.hasClients
                          ? pageController.page?.round() ?? initialIndex
                          : initialIndex;
                      if (currentIndex >= _portfolio.length) currentIndex = _portfolio.length - 1;

                      final currentItem = _portfolio[currentIndex];
                      final title = currentItem['title'] ?? 'Untitled';
                      final description = currentItem['description'] ?? '';

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          if (description.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              description,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.8),
                                height: 1.5,
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          // Delete Button (only for current image)
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              _deletePortfolioItem(currentItem['id']);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.red.withOpacity(0.4)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.delete_outline, color: Colors.red, size: 18),
                                  SizedBox(width: 8),
                                  Text('Delete Image', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
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
                            border: Border.all(
                              color: Colors.white.withOpacity(0.06),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white.withOpacity(0.8),
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'My Portfolio',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      if (!_isLoading)
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF49e8c3), Color(0xFF31b999)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF49e8c3).withOpacity(0.3),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.add_rounded,
                              color: Colors.black,
                              size: 22,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: _isLoading
                      ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: Color(0xFF49e8c3),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Loading portfolio...',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                      : _errorMessage != null
                      ? _buildErrorWidget()
                      : _portfolio.isEmpty
                      ? _buildEmptyState()
                      : _buildPortfolioList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 64, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPortfolio,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF49e8c3),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.05),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.photo_library_outlined,
                size: 50,
                color: Colors.white.withOpacity(0.3),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No portfolio images yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add photos of your work to showcase your skills',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.4),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Image'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF49e8c3),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPortfolioList() {
    return RefreshIndicator(
      onRefresh: _loadPortfolio,
      color: const Color(0xFF49e8c3),
      backgroundColor: Colors.white.withOpacity(0.1),
      child: GridView.builder(
        padding: const EdgeInsets.all(14),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.75,
        ),
        itemCount: _portfolio.length,
        itemBuilder: (context, index) {
          final item = _portfolio[index];
          return _buildPortfolioCard(item, index);
        },
      ),
    );
  }

  Widget _buildPortfolioCard(Map<String, dynamic> item, int index) {
    final mediaUrl = item['media_url'] ?? '';
    final title = item['title'] ?? 'Untitled';
    final description = item['description'] ?? '';

    return GestureDetector(
      onTap: () => _showImageDetails(index),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withOpacity(0.06),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14),
                ),
                child: CachedNetworkImage(
                  imageUrl: mediaUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  placeholder: (context, url) => Container(
                    color: Colors.white.withOpacity(0.05),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF49e8c3),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.white.withOpacity(0.05),
                    child: Icon(
                      Icons.broken_image,
                      size: 40,
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                ),
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (description.isNotEmpty)
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withOpacity(0.4),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}