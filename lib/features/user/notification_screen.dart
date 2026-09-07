import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/services/supabase_service.dart';
import '../provider/auth_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  Stream<List<Map<String, dynamic>>>? _notificationStream;

  // ✅ Track notification IDs that have been shown to prevent duplicates
  final Set<String> _shownNotificationIds = {};

  // Background Animation Controllers
  late AnimationController _pulseController;
  late AnimationController _floatingController;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _subscribeToNotifications();

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
    _pulseController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    final userId = context.read<AuthProvider>().userId;
    if (userId != null) {
      try {
        final notifications = await SupabaseService().getNotifications(userId);
        if (mounted) {
          setState(() {
            _notifications = notifications;
            _isLoading = false;
          });

          // ✅ Mark existing notifications as shown
          for (var notification in notifications) {
            final id = notification['id'].toString();
            if (!_shownNotificationIds.contains(id)) {
              _shownNotificationIds.add(id);
            }
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          // ❌ Removed error snackbar
        }
      }
    }
  }

  void _subscribeToNotifications() {
    final userId = context.read<AuthProvider>().userId;
    if (userId != null) {
      final supabaseService = SupabaseService();

      _notificationStream = supabaseService.listenToNotifications(userId);

      _notificationStream?.listen((data) {
        if (mounted) {
          setState(() {
            _notifications = data;
          });

          // ✅ Only show notification if it's new and not already shown
          for (var notification in data) {
            final id = notification['id'].toString();
            final isRead = notification['is_read'] ?? false;

            // Only show if not read, not already shown, and not in shown set
            if (!isRead && !_shownNotificationIds.contains(id)) {
              _shownNotificationIds.add(id);
              // ✅ Show device notification only (no snackbar)
              _showDeviceNotification(notification);
            }
          }
        }
      }, onError: (error) {
        debugPrint('Error in notification stream: $error');
      });
    }
  }

  // ✅ Only show device notification, NO snackbar
  void _showDeviceNotification(Map<String, dynamic> notification) {
    // ❌ No snackbar notification
    // ❌ Removed ScaffoldMessenger.showSnackBar completely

    // Device notification is handled in main.dart
    // The _showNotification method in main.dart handles the device notification
  }

  Future<void> _markAsRead(String id) async {
    try {
      await SupabaseService().markNotificationRead(id);
      if (mounted) {
        setState(() {
          final index = _notifications.indexWhere((n) => n['id'] == id);
          if (index != -1) {
            _notifications[index]['is_read'] = true;
          }
        });
      }
    } catch (e) {
      // ❌ Removed error snackbar
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    final userId = context.read<AuthProvider>().userId;
    if (userId != null) {
      try {
        await SupabaseService().markAllNotificationsRead(userId);
        if (mounted) {
          setState(() {
            for (var notification in _notifications) {
              notification['is_read'] = true;
            }
          });
          // ❌ Removed success snackbar
        }
      } catch (e) {
        // ❌ Removed error snackbar
        debugPrint('Error marking all notifications as read: $e');
      }
    }
  }

  Future<void> _deleteNotification(String id) async {
    try {
      await SupabaseService().deleteNotification(id);
      if (mounted) {
        setState(() {
          _notifications.removeWhere((n) => n['id'] == id);
        });
      }
    } catch (e) {
      // ❌ Removed error snackbar
      debugPrint('Error deleting notification: $e');
    }
  }

  void _handleNotificationTap(Map<String, dynamic> notification) async {
    // Mark as read if unread
    if (notification['is_read'] == false) {
      await _markAsRead(notification['id']);
    }

    // Navigate based on type
    final type = notification['type'] ?? 'system';
    final data = notification['data'] as Map<String, dynamic>?;

    switch (type) {
      case 'message':
        if (data != null && data.containsKey('chat_id')) {
          context.push('/user/chats/${data['chat_id']}');
        } else {
          context.push('/user/chats');
        }
        break;
      case 'service_request':
        if (data != null && data.containsKey('request_id')) {
          context.push('/user/requests/${data['request_id']}');
        } else {
          context.push('/user/requests');
        }
        break;
      case 'status':
        if (data != null && data.containsKey('request_id')) {
          context.push('/user/requests/${data['request_id']}');
        }
        break;
      case 'review':
        if (data != null && data.containsKey('provider_id')) {
          context.push('/user/provider/${data['provider_id']}');
        }
        break;
      default:
        break;
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
                    Color(0xFF1A1040),
                    Color(0xFF2D1B69),
                    Color(0xFF1A0B2E),
                    Color(0xFF0F0A2A),
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
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final unreadCount = _notifications.where((n) => n['is_read'] == false).length;

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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Notifications',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: -0.3,
                              ),
                            ),
                            if (unreadCount > 0)
                              Text(
                                '$unreadCount unread',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: const Color(0xFF49e8c3),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (unreadCount > 0)
                        GestureDetector(
                          onTap: _markAllAsRead,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF49e8c3), Color(0xFF31b999)],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF49e8c3).withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.done_all,
                                  color: Colors.black,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Read All',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // ============================================================
                // NOTIFICATIONS LIST
                // ============================================================
                Expanded(
                  child: _isLoading
                      ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF49e8c3),
                    ),
                  )
                      : _notifications.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      final isRead = notification['is_read'] ?? false;
                      final type = notification['type'] ?? 'system';

                      return Dismissible(
                        key: Key(notification['id']),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) => _deleteNotification(notification['id']),
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: Colors.red.shade500,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.delete_outline,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: isRead
                                ? Colors.white.withOpacity(0.05)
                                : Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isRead
                                  ? Colors.white.withOpacity(0.05)
                                  : const Color(0xFF49e8c3).withOpacity(0.2),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _handleNotificationTap(notification),
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Icon Container
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: _getIconColor(type).withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: _getIconColor(type).withOpacity(0.1),
                                          width: 1,
                                        ),
                                      ),
                                      child: Icon(
                                        _getIcon(type),
                                        color: _getIconColor(type),
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    // Content
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  notification['title'] ?? 'Notification',
                                                  style: TextStyle(
                                                    fontWeight: isRead
                                                        ? FontWeight.w500
                                                        : FontWeight.w700,
                                                    fontSize: 14,
                                                    color: isRead
                                                        ? Colors.white.withOpacity(0.8)
                                                        : Colors.white,
                                                  ),
                                                ),
                                              ),
                                              if (!isRead)
                                                Container(
                                                  width: 8,
                                                  height: 8,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: const Color(0xFF49e8c3),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: const Color(0xFF49e8c3).withOpacity(0.5),
                                                        blurRadius: 6,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            notification['body'] ?? '',
                                            style: TextStyle(
                                              fontSize: 13,
                                              height: 1.4,
                                              color: isRead
                                                  ? Colors.white.withOpacity(0.5)
                                                  : Colors.white.withOpacity(0.8),
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.access_time_rounded,
                                                size: 14,
                                                color: Colors.white.withOpacity(0.3),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                _formatDate(notification['created_at']),
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.white.withOpacity(0.3),
                                                ),
                                              ),
                                              if (!isRead) ...[
                                                const SizedBox(width: 10),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    gradient: const LinearGradient(
                                                      colors: [Color(0xFF49e8c3), Color(0xFF31b999)],
                                                    ),
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Text(
                                                    'NEW',
                                                    style: TextStyle(
                                                      fontSize: 9,
                                                      fontWeight: FontWeight.w700,
                                                      color: Colors.black,
                                                      letterSpacing: 0.5,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                              // Type badge
                                              const Spacer(),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: _getIconColor(type).withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(10),
                                                  border: Border.all(
                                                    color: _getIconColor(type).withOpacity(0.1),
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Text(
                                                  _getTypeLabel(type),
                                                  style: TextStyle(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w500,
                                                    color: _getIconColor(type).withOpacity(0.7),
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

  Widget _buildEmptyState() {
    return Center(
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
              Icons.notifications_off_outlined,
              size: 50,
              color: Colors.white.withOpacity(0.3),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Notifications',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "You're all caught up!",
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================
  IconData _getIcon(String type) {
    switch (type) {
      case 'service_request':
        return Icons.request_page_outlined;
      case 'message':
        return Icons.chat_bubble_outline;
      case 'status':
        return Icons.update_outlined;
      case 'review':
        return Icons.star_outline;
      case 'system':
        return Icons.notifications_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getIconColor(String type) {
    switch (type) {
      case 'service_request':
        return Colors.orange.shade400;
      case 'message':
        return const Color(0xFF49e8c3);
      case 'status':
        return Colors.purple.shade300;
      case 'review':
        return Colors.amber.shade400;
      case 'system':
        return Colors.blue.shade400;
      default:
        return Colors.white;
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'service_request':
        return 'Request';
      case 'message':
        return 'Message';
      case 'status':
        return 'Update';
      case 'review':
        return 'Review';
      case 'system':
        return 'System';
      default:
        return 'Notification';
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inDays > 7) {
        return '${date.day}/${date.month}/${date.year}';
      } else if (diff.inDays > 0) {
        return '${diff.inDays}d ago';
      } else if (diff.inHours > 0) {
        return '${diff.inHours}h ago';
      } else if (diff.inMinutes > 0) {
        return '${diff.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return '';
    }
  }
}