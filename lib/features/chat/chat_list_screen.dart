import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../app/theme.dart';
import '../provider/auth_provider.dart';
import '../provider/chat_provider.dart';

class ChatListScreen extends StatefulWidget {
  final String role;

  const ChatListScreen({super.key, required this.role});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen>
    with TickerProviderStateMixin {
  // Background Animation Controllers
  late AnimationController _pulseController;
  late AnimationController _floatingController;

  @override
  void initState() {
    super.initState();
    _initializeRooms();

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
    final chatProvider = context.read<ChatProvider>();
    chatProvider.disposeRooms();
    _pulseController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  void _initializeRooms() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.userId != null) {
        final chatProvider = context.read<ChatProvider>();
        chatProvider.loadRooms(authProvider.userId!, widget.role);
        chatProvider.subscribeToRooms(authProvider.userId!, widget.role);
      }
    });
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final authProvider = context.watch<AuthProvider>();
    final currentUserId = authProvider.userId;

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
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF49e8c3).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.chat_bubble_outline_rounded,
                          color: Color(0xFF49e8c3),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Messages',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ============================================================
                // CHAT LIST
                // ============================================================
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      if (currentUserId != null) {
                        await context.read<ChatProvider>().loadRooms(
                          currentUserId,
                          widget.role,
                        );
                      }
                    },
                    color: const Color(0xFF49e8c3),
                    backgroundColor: Colors.white.withOpacity(0.1),
                    child: Consumer<ChatProvider>(
                      builder: (context, chatProvider, child) {
                        if (chatProvider.isLoading && chatProvider.rooms.isEmpty) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF49e8c3),
                            ),
                          );
                        }

                        if (chatProvider.error != null && chatProvider.rooms.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline_rounded,
                                  size: 48,
                                  color: Colors.red.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Error loading chats: ${chatProvider.error}',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _initializeRooms,
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
                          );
                        }

                        final rooms = chatProvider.rooms;

                        if (rooms.isEmpty) {
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
                                    Icons.chat_bubble_outline_rounded,
                                    size: 50,
                                    color: Colors.white.withOpacity(0.3),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'No conversations yet',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Start chatting with a provider',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.4),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: rooms.length,
                          separatorBuilder: (context, index) => Divider(
                            height: 1,
                            color: Colors.white.withOpacity(0.04),
                          ),
                          itemBuilder: (context, index) {
                            final room = rooms[index];

                            Map<String, dynamic>? otherParty;
                            String otherId;
                            String otherName;
                            String? profileImage;
                            bool isOnline = false;

                            if (widget.role == 'provider') {
                              otherParty = room['user'] as Map<String, dynamic>?;
                              otherId = room['user_id']?.toString() ?? '';
                              otherName = otherParty?['full_name'] ?? 'Customer';
                              profileImage = otherParty?['profile_image'];
                              isOnline = otherParty?['is_online'] ?? false;
                            } else {
                              final providerMap = room['provider'] as Map<String, dynamic>?;
                              final providerUser = providerMap?['users'] as Map<String, dynamic>?;
                              otherParty = providerUser;
                              otherId = room['provider_id']?.toString() ?? '';
                              otherName = providerUser?['full_name'] ?? 'Service Provider';
                              profileImage = providerUser?['profile_image'];
                              isOnline = providerUser?['is_online'] ?? false;
                            }

                            final lastMessage = room['last_message'] ?? 'No messages yet';
                            final lastTime = room['last_message_time'] ?? room['updated_at'];
                            final formattedTime = lastTime != null ? _formatTime(lastTime) : '';

                            final unreadCount = room['unread_count'] ?? 0;
                            final isLastMessageMine = room['last_message_sender_id'] == currentUserId;
                            final isRead = room['last_message_read'] ?? false;

                            return GestureDetector(
                              onTap: () {
                                final routePrefix = widget.role == 'provider' ? '/provider' : '/user';
                                final extraKey = widget.role == 'provider' ? 'userName' : 'providerName';
                                final idKey = widget.role == 'provider' ? 'userId' : 'providerId';

                                context.push(
                                  '$routePrefix/chat/${room['id']}',
                                  extra: {
                                    extraKey: otherName,
                                    idKey: otherId,
                                  },
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: unreadCount > 0
                                      ? const Color(0xFF49e8c3).withOpacity(0.05)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Stack(
                                      children: [
                                        Container(
                                          width: 56,
                                          height: 56,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: isOnline
                                                  ? const Color(0xFF49e8c3)
                                                  : Colors.grey.shade600,
                                              width: 2,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: isOnline
                                                    ? const Color(0xFF49e8c3).withOpacity(0.3)
                                                    : Colors.black.withOpacity(0.1),
                                                blurRadius: 10,
                                              ),
                                            ],
                                          ),
                                          child: ClipOval(
                                            child: profileImage != null && profileImage.isNotEmpty
                                                ? CachedNetworkImage(
                                              imageUrl: profileImage,
                                              fit: BoxFit.cover,
                                              width: 56,
                                              height: 56,
                                              errorWidget: (context, url, error) => Container(
                                                color: const Color(0xFF49e8c3),
                                                child: Center(
                                                  child: Text(
                                                    otherName.isNotEmpty ? otherName[0].toUpperCase() : 'C',
                                                    style: const TextStyle(
                                                      fontSize: 20,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            )
                                                : Container(
                                              color: const Color(0xFF49e8c3),
                                              child: Center(
                                                child: Text(
                                                  otherName.isNotEmpty ? otherName[0].toUpperCase() : 'C',
                                                  style: const TextStyle(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        if (isOnline)
                                          Positioned(
                                            bottom: 2,
                                            right: 2,
                                            child: Container(
                                              width: 14,
                                              height: 14,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF49e8c3),
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: Colors.white,
                                                  width: 2,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: const Color(0xFF49e8c3).withOpacity(0.3),
                                                    blurRadius: 6,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  otherName,
                                                  style: TextStyle(
                                                    fontWeight: unreadCount > 0
                                                        ? FontWeight.bold
                                                        : FontWeight.w600,
                                                    fontSize: 15,
                                                    color: unreadCount > 0
                                                        ? Colors.white
                                                        : Colors.white.withOpacity(0.7),
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              Text(
                                                formattedTime,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: unreadCount > 0
                                                      ? const Color(0xFF49e8c3)
                                                      : Colors.white.withOpacity(0.3),
                                                  fontWeight: unreadCount > 0
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              if (isLastMessageMine) ...[
                                                Icon(
                                                  Icons.done_all,
                                                  size: 14,
                                                  color: isRead
                                                      ? const Color(0xFF49e8c3)
                                                      : Colors.white.withOpacity(0.3),
                                                ),
                                                const SizedBox(width: 4),
                                              ],
                                              Expanded(
                                                child: Text(
                                                  lastMessage,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontWeight: unreadCount > 0
                                                        ? FontWeight.w600
                                                        : FontWeight.normal,
                                                    color: unreadCount > 0
                                                        ? Colors.white.withOpacity(0.9)
                                                        : Colors.white.withOpacity(0.4),
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ),
                                              if (unreadCount > 0)
                                                Container(
                                                  margin: const EdgeInsets.only(left: 8),
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    gradient: const LinearGradient(
                                                      colors: [Color(0xFF49e8c3), Color(0xFF31b999)],
                                                    ),
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Text(
                                                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                                                    style: const TextStyle(
                                                      color: Colors.black,
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.bold,
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
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String timeString) {
    try {
      final date = DateTime.parse(timeString).toLocal();
      final now = DateTime.now();
      if (date.day == now.day && date.month == now.month && date.year == now.year) {
        return DateFormat('hh:mm a').format(date);
      }
      final diff = now.difference(date);
      if (diff.inDays < 7) {
        return DateFormat('EEEE').format(date);
      }
      return DateFormat('MMM d').format(date);
    } catch (e) {
      return '';
    }
  }
}