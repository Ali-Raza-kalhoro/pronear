import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter/foundation.dart' show kDebugMode;

import '../../app/theme.dart';
import '../../core/services/supabase_service.dart';
import '../../widgets/provider_card.dart';

class SearchScreen extends StatefulWidget {
  final String? initialQuery;

  const SearchScreen({super.key, this.initialQuery});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _isLoading = false;
  List<Map<String, dynamic>> _results = [];
  List<Map<String, dynamic>> _categories = [];
  String? _searchMode;
  bool _hasLocationPermission = false;
  String? _aiDetectedCategory;
  double? _latitude;
  double? _longitude;
  Timer? _debounceTimer;

  // Background Animation Controllers
  late AnimationController _pulseController;
  late AnimationController _floatingController;

  // Category keywords for AI matching
  final Map<String, List<String>> _keywordMap = {
    'Automotive': [
      'car', 'mechanic', 'auto', 'vehicle', 'tyre', 'tire', 'puncture',
      'engine', 'breakdown', 'oil', 'battery', 'tow', 'wheel', 'brake',
      'transmission', 'repair car', 'auto repair'
    ],
    'Home Repair': [
      'electrician', 'plumber', 'ac', 'fridge', 'refrigerator', 'carpenter',
      'painter', 'mason', 'welder', 'lock', 'repair', 'fix', 'broken',
      'pipe', 'leak', 'wire', 'switch', 'socket', 'door', 'window',
      'home repair', 'house repair'
    ],
    'Cleaning': [
      'clean', 'cleaning', 'house', 'office', 'sofa', 'carpet', 'maid',
      'sweep', 'mop', 'dust', 'wash', 'bathroom', 'kitchen', 'tile',
      'home cleaning', 'deep cleaning'
    ],
    'Tutors': [
      'tutor', 'teacher', 'teach', 'math', 'english', 'science', 'computer',
      'study', 'learn', 'homework', 'physics', 'chemistry', 'biology',
      'education', 'mathematics', 'english teacher', 'math tutor',
      'home tutor', 'private tutor'
    ],
    'Technology': [
      'computer', 'laptop', 'mobile', 'phone', 'tech', 'software', 'network',
      'cctv', 'internet', 'wifi', 'printer', 'hardware', 'screen repair'
    ],
    'Personal': [
      'barber', 'hair', 'makeup', 'beauty', 'photographer', 'videographer',
      'salon', 'style', 'shave', 'facial', 'mehndi', 'bride'
    ],
    'Care': [
      'baby', 'elder', 'nurse', 'caregiver', 'home care', 'aged', 'child',
      'health', 'patient', 'elderly', 'newborn', 'babysitter'
    ],
    'Delivery': [
      'driver', 'delivery', 'moving', 'transport', 'loader', 'cargo',
      'parcel', 'pickup', 'shift', 'goods', 'furniture', 'courier'
    ],
    'Outdoor': [
      'garden', 'pest', 'pool', 'lawn', 'yard', 'plants', 'tree',
      'grass', 'pesticide', 'gardening'
    ],
  };

  final Map<String, List<String>> _categoryNameVariations = {
    'Tutors': ['tutor', 'teacher', 'tutoring', 'tuition', 'coaching'],
    'Automotive': ['car', 'auto', 'vehicle', 'automobile'],
    'Home Repair': ['repair', 'home repair', 'house repair', 'maintenance'],
    'Cleaning': ['clean', 'cleaning', 'housekeeping'],
    'Technology': ['tech', 'computer', 'it'],
    'Personal': ['beauty', 'salon', 'personal'],
    'Care': ['care', 'healthcare', 'nursing'],
    'Delivery': ['delivery', 'transport', 'moving'],
    'Outdoor': ['garden', 'outdoor', 'landscaping'],
  };

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _loadCategories();
    _getLocation();
    _searchController.addListener(_onSearchChanged);

    // Background Animations
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _performSearch();
      });
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounceTimer?.cancel();
    _pulseController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer!.cancel();
    }
    _debounceTimer = Timer(const Duration(milliseconds: 600), () {
      if (_searchController.text.length >= 2) {
        _performSearch();
      } else if (_searchController.text.isEmpty) {
        setState(() {
          _results = [];
          _searchMode = null;
          _aiDetectedCategory = null;
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _getLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _hasLocationPermission = true;
      });
      if (kDebugMode) {
        print('✅ Location obtained: $_latitude, $_longitude');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Location error: $e');
      }
      setState(() {
        _hasLocationPermission = false;
      });
    }
  }

  Future<void> _initSpeech() async {
    await _speech.initialize(
      onStatus: (status) {
        if (status == 'notListening') {
          setState(() => _isListening = false);
        }
      },
    );
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await SupabaseService().getCategories();
      setState(() => _categories = categories);
      if (kDebugMode) {
        print('✅ Loaded ${categories.length} categories');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading categories: $e');
      }
    }
  }

  void _startListening() async {
    if (!_isListening) {
      setState(() => _isListening = true);
      await _speech.listen(
        onResult: (result) {
          setState(() {
            _searchController.text = result.recognizedWords;
          });
          if (result.finalResult) {
            _performSearch();
          }
        },
        listenMode: stt.ListenMode.dictation,
        localeId: 'en_US',
      );
    } else {
      _speech.stop();
      setState(() => _isListening = false);
    }
  }

  String? _detectCategoryFromQuery(String query) {
    final queryLower = query.toLowerCase();

    for (final category in _categories) {
      final catName = (category['name'] ?? '').toString().toLowerCase();
      if (queryLower.contains(catName)) {
        return category['name'];
      }
    }

    for (final entry in _categoryNameVariations.entries) {
      for (final variation in entry.value) {
        if (queryLower.contains(variation)) {
          return entry.key;
        }
      }
    }

    Map<String, int> categoryScores = {};

    for (final entry in _keywordMap.entries) {
      int score = 0;
      for (final keyword in entry.value) {
        if (queryLower.contains(keyword)) {
          score++;
          final words = queryLower.split(' ');
          for (final word in words) {
            if (word == keyword) {
              score += 2;
            }
          }
        }
      }
      if (score > 0) {
        categoryScores[entry.key] = score;
      }
    }

    if (categoryScores.isNotEmpty) {
      final sorted = categoryScores.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      if (sorted.first.value >= 1) {
        return sorted.first.key;
      }
    }

    return null;
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _results = [];
        _isLoading = false;
      });
      return;
    }

    if (kDebugMode) {
      print('🔍 Searching for: "$query"');
    }

    setState(() {
      _isLoading = true;
      _results = [];
      _searchMode = null;
      _aiDetectedCategory = null;
    });

    try {
      if (_latitude == null || _longitude == null) {
        await _getLocation();
      }

      final lat = _latitude ?? 0.0;
      final lng = _longitude ?? 0.0;

      final detectedCategory = _detectCategoryFromQuery(query);
      String? matchedCategoryId;
      String? matchedCategoryName;

      if (detectedCategory != null) {
        matchedCategoryName = detectedCategory;
        for (final category in _categories) {
          if (category['name'] == detectedCategory) {
            matchedCategoryId = category['id'];
            break;
          }
        }
      }

      List<Map<String, dynamic>> results = [];

      if (matchedCategoryId != null) {
        _searchMode = 'category';
        _aiDetectedCategory = matchedCategoryName;

        String cleanQuery = query;
        if (matchedCategoryName != null) {
          final keywords = _keywordMap[matchedCategoryName] ?? [];
          for (final keyword in keywords) {
            cleanQuery = cleanQuery.replaceAll(RegExp(keyword, caseSensitive: false), '').trim();
          }
          final variations = _categoryNameVariations[matchedCategoryName] ?? [];
          for (final variation in variations) {
            cleanQuery = cleanQuery.replaceAll(RegExp(variation, caseSensitive: false), '').trim();
          }
        }

        final stopWords = ['looking', 'for', 'a', 'near', 'me', 'need', 'want', 'find', 'search', 'help', 'please'];
        for (final word in stopWords) {
          cleanQuery = cleanQuery.replaceAll(RegExp('\\b$word\\b', caseSensitive: false), '').trim();
        }

        if (cleanQuery.length < 3) {
          cleanQuery = query;
        }

        results = await SupabaseService().getNearbyProviders(
          latitude: lat,
          longitude: lng,
          radius: 10.0,
          categoryId: matchedCategoryId,
          searchQuery: cleanQuery,
        );
      }

      if (results.isEmpty) {
        _searchMode = 'ai';

        String meaningfulQuery = query;
        final stopWords = ['looking', 'for', 'a', 'near', 'me', 'need', 'want', 'find', 'search', 'help', 'please', 'to', 'the', 'and', 'with'];
        for (final word in stopWords) {
          meaningfulQuery = meaningfulQuery.replaceAll(RegExp('\\b$word\\b', caseSensitive: false), '').trim();
        }

        if (meaningfulQuery.length < 2) {
          meaningfulQuery = query;
        }

        results = await SupabaseService().getNearbyProviders(
          latitude: lat,
          longitude: lng,
          radius: 10.0,
          searchQuery: meaningfulQuery,
        );
      }

      if (kDebugMode) {
        print('📊 Found ${results.length} providers');
      }

      setState(() {
        _results = results;
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ Search error: $e');
      }
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Search failed: ${e.toString()}'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  void _showAISearchInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Color(0xFF38804f)),
            SizedBox(width: 8),
            Text('AI-Powered Search'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Describe your problem in natural language and our AI will find relevant providers.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            const Text(
              'Try these examples:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            _buildExampleTile('🔧', 'My car has a puncture'),
            _buildExampleTile('🔌', 'I need a plumber for a leaky pipe'),
            _buildExampleTile('📚', 'Looking for a math tutor near me'),
            _buildExampleTile('❄️', 'My AC is not cooling properly'),
            _buildExampleTile('🏠', 'I want to repair my home'),
            _buildExampleTile('🧹', 'Need house cleaning service'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF38804f),
            ),
            child: const Text(
              'Got it',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExampleTile(String icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
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
  // EMPTY STATE
  // ============================================================
  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.05),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.search_off_outlined,
                size: 40,
                color: Colors.white.withOpacity(0.3),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _searchController.text.isNotEmpty
                  ? 'No providers found'
                  : 'Search for services',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _searchController.text.isNotEmpty
                  ? 'Try describing your problem in more detail'
                  : 'Type or describe what you need',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.4),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            if (!_hasLocationPermission)
              ElevatedButton.icon(
                onPressed: _getLocation,
                icon: const Icon(Icons.location_on),
                label: const Text('Enable Location'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF49e8c3),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildSuggestionChip('mechanic'),
                _buildSuggestionChip('plumber'),
                _buildSuggestionChip('tutor'),
                _buildSuggestionChip('cleaner'),
                _buildSuggestionChip('electrician'),
                _buildSuggestionChip('AC repair'),
                _buildSuggestionChip('looking for a tutor'),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '💡 Try searching by profession name or describe your need',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withOpacity(0.3),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String label) {
    return ActionChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          color: Colors.white.withOpacity(0.8),
        ),
      ),
      onPressed: () {
        _searchController.text = label;
        _performSearch();
      },
      backgroundColor: Colors.white.withOpacity(0.08),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
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
      backgroundColor: const Color(0xFF0F0A2A),
      body: Stack(
        children: [
          _buildBackground(size),
          SafeArea(
            child: Column(
              children: [
                // ============================================================
                // CUSTOM APP BAR
                // ============================================================
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      // Back Button
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
                          'Search Services',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      // AI Info Button
                      GestureDetector(
                        onTap: _showAISearchInfo,
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
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.auto_awesome,
                            color: Colors.black,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ============================================================
                // SEARCH BAR
                // ============================================================
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
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
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            style: const TextStyle(
                              color: Color(0xFF2D3748),
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search category or describe...',
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
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _results = [];
                                    _searchMode = null;
                                    _aiDetectedCategory = null;
                                    _isLoading = false;
                                  });
                                },
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              )
                                  : null,
                            ),
                          ),
                        ),
                        // Voice Search Button
                        Container(
                          margin: const EdgeInsets.only(right: 4),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF38804f), Color(0xFF1d3b27)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: IconButton(
                            icon: Icon(
                              _isListening ? Icons.mic : Icons.mic_none,
                              color: _isListening ? Colors.red : Colors.white,
                              size: 20,
                            ),
                            onPressed: _startListening,
                            tooltip: 'Voice Search',
                            padding: const EdgeInsets.all(10),
                            constraints: const BoxConstraints(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // ============================================================
                // SEARCH MODE INDICATOR
                // ============================================================
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      if (_searchMode == 'category')
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.category, size: 14, color: Colors.blue),
                              const SizedBox(width: 4),
                              const Text(
                                'Category Search',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (_searchMode == 'ai')
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF49e8c3).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.auto_awesome, size: 14, color: Color(0xFF49e8c3)),
                              const SizedBox(width: 4),
                              Text(
                                _aiDetectedCategory != null
                                    ? 'AI: ${_aiDetectedCategory!}'
                                    : 'AI Search',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF49e8c3),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const Spacer(),
                      Text(
                        _results.isEmpty && !_isLoading
                            ? 'No results'
                            : '${_results.length} results',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.4),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // ============================================================
                // RESULTS
                // ============================================================
                if (_isLoading)
                  const Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: Color(0xFF49e8c3),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Searching for providers...',
                            style: TextStyle(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (_results.isEmpty)
                  Expanded(
                    child: _buildEmptyState(),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _results.length,
                      itemBuilder: (context, index) {
                        final provider = _results[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: ProviderCard(
                            provider: provider,
                            onTap: () {
                              context.push('/user/provider/${provider['id']}');
                            },
                            onRequest: () {
                              context.push('/user/request/${provider['id']}');
                            },
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}