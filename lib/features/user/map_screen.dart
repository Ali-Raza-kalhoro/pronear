import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;

import '../../app/theme.dart';
import '../../features/provider/provider_provider.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  LatLng? _currentLocation;
  Set<Marker> _markers = {};
  Set<Circle> _circles = {};
  bool _isLoading = true;
  bool _isLocationLoading = true;
  bool _hasLocationPermission = false;
  String? _errorMessage;

  // Background Animation Controllers
  late AnimationController _pulseController;
  late AnimationController _floatingController;

  // Cache for marker icons
  final Map<String, BitmapDescriptor> _markerCache = {};

  @override
  void initState() {
    super.initState();
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
    _mapController?.dispose();
    _pulseController.dispose();
    _floatingController.dispose();
    super.dispose();
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
  // MAP METHODS
  // ============================================================

  Future<void> _checkLocationPermission() async {
    final status = await Permission.location.status;

    if (status.isDenied) {
      final result = await Permission.location.request();
      if (result.isGranted) {
        setState(() {
          _hasLocationPermission = true;
        });
        _loadLocation();
      } else {
        setState(() {
          _hasLocationPermission = false;
          _isLoading = false;
          _isLocationLoading = false;
          _errorMessage = 'Location permission denied';
        });
      }
    } else if (status.isGranted) {
      setState(() {
        _hasLocationPermission = true;
      });
      _loadLocation();
    } else if (status.isPermanentlyDenied) {
      setState(() {
        _hasLocationPermission = false;
        _isLoading = false;
        _isLocationLoading = false;
        _errorMessage = 'Location permission permanently denied';
      });
      _showPermissionDialog();
    }
  }

  void _showPermissionDialog() {
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
          'Please enable location permission in settings to find providers near you.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Go Back'),
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

  Future<void> _loadLocation() async {
    setState(() {
      _isLoading = true;
      _isLocationLoading = true;
    });

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );

      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _isLocationLoading = false;
      });

      await _loadProviders();
      _animateToCurrentLocation();
      _startLocationUpdates();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isLocationLoading = false;
        _errorMessage = 'Failed to get location: $e';
      });
    }
  }

  void _startLocationUpdates() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) {
      if (mounted) {
        final newLocation = LatLng(position.latitude, position.longitude);
        setState(() {
          _currentLocation = newLocation;
        });
        _updateMapCamera(newLocation);
        _loadProviders();
      }
    }).onError((error) {
      print('Location stream error: $error');
    });
  }

  Future<void> _animateToCurrentLocation() async {
    if (_currentLocation != null && _mapController != null) {
      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _currentLocation!,
            zoom: 14.5,
          ),
        ),
      );
    }
  }

  Future<void> _updateMapCamera(LatLng position) async {
    if (_mapController != null) {
      await _mapController!.animateCamera(
        CameraUpdate.newLatLng(position),
      );
    }
  }

  // ============================================================
  // CREATE CUSTOM MARKER - LARGER SIZE
  // ============================================================

  Future<BitmapDescriptor> _createCustomMarker({
    String? imageUrl,
    required bool isAvailable,
    required String name,
    required String providerId,
  }) async {
    // Check cache first
    final cacheKey = '${providerId}_$isAvailable';
    if (_markerCache.containsKey(cacheKey)) {
      return _markerCache[cacheKey]!;
    }

    // Create a picture recorder
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);

    // INCREASED SIZES
    const int size = 100;
    const int circleSize = 90;
    const int dotSize = 44;

    // Background circle with gradient
    final Paint circlePaint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(circleSize / 2, circleSize / 2),
        circleSize / 2,
        isAvailable
            ? [const Color(0xFF49e8c3), const Color(0xFF31b999)]
            : [Colors.grey.shade500, Colors.grey.shade700],
        [0.3, 1.0],
      )
      ..style = PaintingStyle.fill;

    // Draw shadow
    final Paint shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    canvas.drawCircle(
      Offset(circleSize / 2 + 2, circleSize / 2 + 2),
      circleSize / 2,
      shadowPaint,
    );

    canvas.drawCircle(
      Offset(circleSize / 2, circleSize / 2),
      circleSize / 2,
      circlePaint,
    );

    // Draw border - thicker
    final Paint borderPaint = Paint()
      ..color = isAvailable
          ? const Color(0xFF49e8c3).withOpacity(0.6)
          : Colors.grey.shade400.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;

    canvas.drawCircle(
      Offset(circleSize / 2, circleSize / 2),
      circleSize / 2 - 2,
      borderPaint,
    );

    // Draw profile image or initials
    if (imageUrl != null && imageUrl.isNotEmpty) {
      try {
        final bytes = await _loadImageBytes(imageUrl);
        if (bytes != null) {
          final ui.Codec codec = await ui.instantiateImageCodec(bytes);
          final ui.FrameInfo frame = await codec.getNextFrame();
          final ui.Image image = frame.image;

          final Path clipPath = Path()..addOval(Rect.fromCircle(
            center: Offset(circleSize / 2, circleSize / 2),
            radius: circleSize / 2 - 3,
          ));
          canvas.clipPath(clipPath);

          final Paint imagePaint = Paint();
          canvas.drawImageRect(
            image,
            Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
            Rect.fromLTWH(3, 3, circleSize - 6, circleSize - 6),
            imagePaint,
          );
        } else {
          _drawInitials(canvas, name, circleSize, isAvailable);
        }
      } catch (e) {
        _drawInitials(canvas, name, circleSize, isAvailable);
      }
    } else {
      _drawInitials(canvas, name, circleSize, isAvailable);
    }

    // Draw status dot glow
    final Paint dotGlowPaint = Paint()
      ..color = isAvailable
          ? const Color(0xFF49e8c3).withOpacity(0.4)
          : Colors.grey.shade400.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawCircle(
      Offset(circleSize - dotSize / 2 + 2, circleSize - dotSize / 2 + 2),
      dotSize / 2 + 4,
      dotGlowPaint,
    );

    // Draw status dot
    final Paint dotPaint = Paint()
      ..color = isAvailable
          ? const Color(0xFF49e8c3)
          : Colors.grey.shade500
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(circleSize - dotSize / 2 + 2, circleSize - dotSize / 2 + 2),
      dotSize / 2,
      dotPaint,
    );

    // Draw dot border
    final Paint dotBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawCircle(
      Offset(circleSize - dotSize / 2 + 2, circleSize - dotSize / 2 + 2),
      dotSize / 2,
      dotBorderPaint,
    );

    // Draw check mark or cross
    if (isAvailable) {
      final Paint checkPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;

      final Path checkPath = Path()
        ..moveTo(circleSize - dotSize / 2 - 5, circleSize - dotSize / 2 + 1)
        ..lineTo(circleSize - dotSize / 2 + 1, circleSize - dotSize / 2 + 7)
        ..lineTo(circleSize - dotSize / 2 + 8, circleSize - dotSize / 2 - 5);

      canvas.drawPath(checkPath, checkPaint);
    } else {
      final Paint crossPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;

      final Path crossPath = Path()
        ..moveTo(circleSize - dotSize / 2 - 6, circleSize - dotSize / 2 - 4)
        ..lineTo(circleSize - dotSize / 2 + 6, circleSize - dotSize / 2 + 8)
        ..moveTo(circleSize - dotSize / 2 + 6, circleSize - dotSize / 2 - 4)
        ..lineTo(circleSize - dotSize / 2 - 6, circleSize - dotSize / 2 + 8);

      canvas.drawPath(crossPath, crossPaint);
    }

    // Convert to bitmap
    final ui.Picture picture = recorder.endRecording();
    final ui.Image image = await picture.toImage(size, size);
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List bytes = byteData!.buffer.asUint8List();

    final BitmapDescriptor bitmap = BitmapDescriptor.fromBytes(bytes);

    // Cache the result
    _markerCache[cacheKey] = bitmap;

    return bitmap;
  }

  void _drawInitials(Canvas canvas, String name, int size, bool isAvailable) {
    final String initial = name.isNotEmpty ? name[0].toUpperCase() : 'P';

    final TextSpan span = TextSpan(
      style: const TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      text: initial,
    );

    final TextPainter textPainter = TextPainter(
      text: span,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size / 2) - (textPainter.width / 2),
        (size / 2) - (textPainter.height / 2),
      ),
    );
  }

  Future<Uint8List?> _loadImageBytes(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ============================================================
  // LOAD PROVIDERS
  // ============================================================
  Future<void> _loadProviders() async {
    if (_currentLocation == null) return;

    final providerProvider = context.read<ProviderProvider>();
    await providerProvider.loadNearbyProviders(
      latitude: _currentLocation!.latitude,
      longitude: _currentLocation!.longitude,
      radius: 10.0,
    );

    final providers = providerProvider.providers;
    final markers = <Marker>{};
    final circles = <Circle>{};

    // User location marker
    markers.add(
      Marker(
        markerId: const MarkerId('user'),
        position: _currentLocation!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(title: 'Your Location'),
        zIndex: 100,
      ),
    );

    // Radius circle
    circles.add(
      Circle(
        circleId: const CircleId('user_radius'),
        center: _currentLocation!,
        radius: 500,
        fillColor: const Color(0xFF49e8c3).withOpacity(0.08),
        strokeColor: const Color(0xFF49e8c3).withOpacity(0.3),
        strokeWidth: 2,
        zIndex: 1,
      ),
    );

    // Provider markers
    for (final provider in providers) {
      final lat = provider['latitude']?.toDouble();
      final lng = provider['longitude']?.toDouble();
      if (lat != null && lng != null) {
        final user = provider['users'] ?? {};
        final isOnline = user['is_online'] ?? false;
        final isAvailable = provider['is_available'] ?? false;
        final name = user['full_name'] ?? 'Provider';
        final profession = provider['profession'] ?? 'Service Provider';
        final distance = provider['distance'] ?? 0.0;
        final profileImage = user['profile_image'];
        final rating = provider['rating'] ?? 0.0;

        // Create custom marker
        final markerIcon = await _createCustomMarker(
          imageUrl: profileImage,
          isAvailable: isAvailable && isOnline,
          name: name,
          providerId: provider['id'].toString(),
        );

        markers.add(
          Marker(
            markerId: MarkerId(provider['id'].toString()),
            position: LatLng(lat, lng),
            icon: markerIcon,
            infoWindow: InfoWindow(
              title: name,
              snippet: '$profession - ${isAvailable && isOnline ? "🟢 Available" : "🔴 Unavailable"}\n⭐ $rating • ${distance.toStringAsFixed(1)} km away',
              onTap: () {
                context.push('/user/provider/${provider['id']}');
              },
            ),
            onTap: () {
              _showProviderBottomSheet(context, provider);
            },
            zIndex: 10,
          ),
        );
      }
    }

    setState(() {
      _markers = markers;
      _circles = circles;
      _isLoading = false;
    });
  }

  void _showProviderBottomSheet(BuildContext context, Map<String, dynamic> provider) {
    final user = provider['users'] ?? {};
    final isAvailable = provider['is_available'] ?? false;
    final isOnline = user['is_online'] ?? false;
    final distance = provider['distance'] ?? 0.0;
    final rating = provider['rating'] ?? 0.0;
    final profileImage = user['profile_image'];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
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
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 60,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Image
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isAvailable && isOnline
                            ? const Color(0xFF49e8c3)
                            : Colors.grey,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isAvailable && isOnline
                              ? const Color(0xFF49e8c3).withOpacity(0.3)
                              : Colors.black.withOpacity(0.1),
                          blurRadius: 15,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: profileImage != null && profileImage.toString().isNotEmpty
                          ? CachedNetworkImage(
                        imageUrl: profileImage,
                        fit: BoxFit.cover,
                        width: 56,
                        height: 56,
                        errorWidget: (context, url, error) => Container(
                          color: isAvailable && isOnline
                              ? const Color(0xFF49e8c3)
                              : Colors.grey,
                          child: Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      )
                          : Container(
                        color: isAvailable && isOnline
                            ? const Color(0xFF49e8c3)
                            : Colors.grey,
                        child: Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Provider Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user['full_name'] ?? 'Provider',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          provider['profession'] ?? 'Service Provider',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.6),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                            const SizedBox(width: 2),
                            Text(
                              rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              width: 3,
                              height: 3,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.location_on_rounded,
                              size: 14,
                              color: Colors.white.withOpacity(0.5),
                            ),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                '${distance.toStringAsFixed(1)} km away',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isAvailable && isOnline
                          ? const Color(0xFF49e8c3).withOpacity(0.2)
                          : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isAvailable && isOnline
                            ? const Color(0xFF49e8c3).withOpacity(0.3)
                            : Colors.white.withOpacity(0.05),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      isAvailable && isOnline ? '🟢' : '🔴',
                      style: const TextStyle(
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        final isBusiness = provider['is_business'] ?? false;
                        if (isBusiness) {
                          context.push('/user/business-request/${provider['id']}');
                        } else {
                          context.push('/user/request/${provider['id']}');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF49e8c3),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            provider['is_business'] ?? false
                                ? Icons.shopping_cart_rounded
                                : Icons.send_rounded,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              provider['is_business'] ?? false
                                  ? 'Order Products'
                                  : 'Request Service',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.05),
                        width: 1,
                      ),
                    ),
                    child: IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                        context.push('/user/provider/${provider['id']}');
                      },
                      icon: Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white.withOpacity(0.8),
                        size: 22,
                      ),
                      style: IconButton.styleFrom(
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    if (_isLoading || _isLocationLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F0A2A),
        body: Stack(
          children: [
            _buildBackground(size),
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Color(0xFF49e8c3),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading map...',
                    style: TextStyle(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null && _currentLocation == null) {
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
                      border: Border.all(
                        color: Colors.white.withOpacity(0.05),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.location_off_outlined,
                      size: 50,
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Unable to get location',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.4),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _checkLocationPermission,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF49e8c3),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
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

    return Scaffold(
      backgroundColor: const Color(0xFF0F0A2A),
      body: Stack(
        children: [
          _buildBackground(size),
          SafeArea(
            child: Stack(
              children: [
                // Google Map
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _currentLocation!,
                    zoom: 14,
                  ),
                  onMapCreated: (controller) {
                    _mapController = controller;
                    _animateToCurrentLocation();
                  },
                  markers: _markers,
                  circles: _circles,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: false,
                  mapType: MapType.normal,
                  onCameraMove: (position) {},
                  padding: const EdgeInsets.only(top: 80, bottom: 100),
                ),

                // Top Info Card
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.08),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF49e8c3).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.location_on_rounded,
                            color: const Color(0xFF49e8c3),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_markers.length - 1} Providers Nearby',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Tap a marker to view provider',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white.withOpacity(0.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: _loadProviders,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.refresh_rounded,
                              color: Colors.white.withOpacity(0.7),
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Center Location Button
                Positioned(
                  bottom: 160,
                  right: 16,
                  child: GestureDetector(
                    onTap: _animateToCurrentLocation,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.08),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 15,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.my_location_rounded,
                        color: const Color(0xFF49e8c3),
                        size: 24,
                      ),
                    ),
                  ),
                ),

                // Bottom Button
                Positioned(
                  bottom: 30,
                  left: 16,
                  right: 16,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        context.push('/user/search');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF49e8c3),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.list_alt_rounded,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'View All Providers',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
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
}